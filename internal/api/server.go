package api

import (
	"encoding/json"
	"net/http"
	_ "net/http/pprof" // Enable pprof endpoints
	"time"

	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"axiomx/internal/cache"
	"axiomx/internal/engine"
	"axiomx/internal/events"
	"axiomx/internal/logging"
	"axiomx/internal/metrics"
	"axiomx/internal/risk"
	"axiomx/internal/storage"
	broadcasterws "axiomx/internal/websocket"
)

type Server struct {
	processor   *engine.MatchingProcessor
	store       *storage.TradeStore
	publisher   *events.Publisher
	riskEngine  *risk.RiskEngine
	cache       *cache.Cache
	broadcaster *broadcasterws.Broadcaster
	metrics     *metrics.Metrics
	logger      *logging.Logger
	upgrader    websocket.Upgrader
}

func NewServer(processor *engine.MatchingProcessor, store *storage.TradeStore, publisher *events.Publisher, riskEngine *risk.RiskEngine, cache *cache.Cache) *Server {
	return &Server{
		processor:   processor,
		store:       store,
		publisher:   publisher,
		riskEngine:  riskEngine,
		cache:       cache,
		broadcaster: broadcasterws.NewBroadcaster(),
		metrics:     metrics.NewMetrics(),
		logger:      logging.NewLogger("trading-engine", "api-1"),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for demo; restrict in production
			},
		},
	}
}

func (s *Server) Router() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/orders", s.handleOrders)
	mux.HandleFunc("/book", s.handleBook)
	mux.HandleFunc("/risk/position", s.handlePosition)
	mux.HandleFunc("/stats", s.handleStats)

	// Milestone 3: Metrics, WebSocket, and Profiling
	mux.Handle("/metrics", promhttp.Handler())
	mux.HandleFunc("/ws", s.handleWebSocket)
	// pprof endpoints are registered automatically via net/http/pprof import

	// Start broadcaster
	go s.broadcaster.Run()

	return mux
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		s.metrics.RecordHTTPLatency(time.Since(start))
		s.logger.HTTPRequest(r.Method, r.URL.Path, "", http.StatusOK, time.Since(start))
	}()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

type OrderRequest struct {
	OrderID    string `json:"order_id"`
	UserID     string `json:"user_id,omitempty"` // Added for risk checks
	Side       string `json:"side"`
	OrderType  string `json:"order_type"`
	PriceTicks int64  `json:"price_ticks,omitempty"`
	Qty        int64  `json:"qty"`
}

type OrderResponse struct {
	Success bool           `json:"success"`
	Trades  []engine.Trade `json:"trades,omitempty"`
	Error   string         `json:"error,omitempty"`
}

func (s *Server) handleOrders(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	var req OrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	// Default user ID if not provided
	if req.UserID == "" {
		req.UserID = "default_user"
	}

	// Parse side
	var side engine.Side
	if req.Side == "buy" {
		side = engine.Buy
	} else if req.Side == "sell" {
		side = engine.Sell
	} else {
		http.Error(w, "Invalid side", http.StatusBadRequest)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	// Parse order type
	var orderType engine.OrderType
	if req.OrderType == "limit" {
		orderType = engine.Limit
		if req.PriceTicks <= 0 {
			http.Error(w, "Limit order requires price", http.StatusBadRequest)
			s.metrics.RecordHTTPLatency(time.Since(start))
			return
		}
	} else if req.OrderType == "market" {
		orderType = engine.Market
	} else {
		http.Error(w, "Invalid order type", http.StatusBadRequest)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	// **MILESTONE 2: Risk Check**
	riskStart := time.Now()
	riskResult := s.riskEngine.ValidateOrder(req.UserID, req.Side, req.Qty, req.PriceTicks)
	s.metrics.RecordRiskValidationLatency(time.Since(riskStart))

	if !riskResult.Approved {
		s.metrics.RecordRiskCheckFailed()
		s.logger.RiskCheck(req.UserID, req.OrderID, false, riskResult.Reason)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(OrderResponse{
			Success: false,
			Error:   "Risk check failed: " + riskResult.Reason,
		})
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	s.logger.RiskCheck(req.UserID, req.OrderID, true, "Order approved")

	// **MILESTONE 2: Publish order submitted event**
	s.publisher.PublishOrderSubmitted(req.OrderID, req.Side, req.OrderType, req.PriceTicks, req.Qty)
	s.logger.Info("api", "Order submitted", map[string]string{"order_id": req.OrderID, "user_id": req.UserID})

	// **MILESTONE 3: Broadcast WebSocket event**
	s.broadcaster.BroadcastOrderSubmitted(req.OrderID, req.Side, req.PriceTicks, req.Qty)

	// Create and submit order
	matchStart := time.Now()
	order := engine.NewOrder(req.OrderID, side, req.PriceTicks, req.Qty, time.Now().UnixNano())
	result := s.processor.Submit(order, orderType)
	matchLatency := time.Since(matchStart)

	s.logger.MatchingLatency(req.OrderID, matchLatency.Microseconds())
	s.metrics.RecordMatchingLatency(matchLatency)

	// Persist trades to database and publish events
	if result.Err == nil && len(result.Trades) > 0 {
		for _, trade := range result.Trades {
			// Save trade
			if err := s.store.SaveTrade(trade); err != nil {
				s.logger.Error("api", "Failed to save trade", err.Error(), nil)
			}

			// **MILESTONE 2: Publish trade event**
			if err := s.publisher.PublishTrade(trade); err != nil {
				s.logger.Error("api", "Failed to publish trade", err.Error(), nil)
			}

			// **MILESTONE 2: Update risk position**
			s.riskEngine.UpdatePosition(req.UserID, req.Side, trade.Qty)

			// **MILESTONE 2: Increment trade count in Redis**
			s.cache.IncrementTradeCount()

			// **MILESTONE 3: Broadcast trade**
			s.broadcaster.BroadcastTrade(trade.MakerOrderID, trade.TakerOrderID, trade.PriceTicks, trade.Qty)
			s.logger.TradeExecuted(trade.MakerOrderID, trade.TakerOrderID, trade.PriceTicks, trade.Qty)

			s.metrics.RecordTradeExecution()
		}
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	resp := OrderResponse{
		Success: result.Err == nil,
		Trades:  result.Trades,
	}
	if result.Err != nil {
		resp.Error = result.Err.Error()
	}
	json.NewEncoder(w).Encode(resp)
	s.metrics.RecordHTTPLatency(time.Since(start))
}

func (s *Server) handleBook(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	// Try to get from cache first
	cached, err := s.cache.GetBookSnapshot("BTC-USD")
	if err == nil && cached != nil {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		json.NewEncoder(w).Encode(cached)
		s.metrics.RecordHTTPLatency(time.Since(start))
		return
	}

	// Cache miss, get from engine
	symbol, bidLevels, askLevels := s.processor.Snapshot()
	snapshot := cache.BookSnapshot{
		Symbol:    symbol,
		BidLevels: bidLevels,
		AskLevels: askLevels,
		Timestamp: time.Now().UnixNano(),
	}

	// Store in cache
	s.cache.SetBookSnapshot(snapshot)

	// Update metrics
	s.metrics.UpdateOrderBook(bidLevels+askLevels, bidLevels, askLevels)
	w.Header().Set("X-Cache", "MISS")
	json.NewEncoder(w).Encode(snapshot)
	s.metrics.RecordHTTPLatency(time.Since(start))
}

func (s *Server) handlePosition(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		s.metrics.RecordHTTPLatency(time.Since(start))
	}()

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		userID = "default_user"
	}

	pos := s.riskEngine.GetPosition(userID)
	w.Header().Set("Content-Type", "application/json")

	if pos == nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"user_id":  userID,
			"position": 0,
			"symbol":   "BTC-USD",
		})
	} else {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"user_id":  userID,
			"position": pos.Qty,
			"symbol":   pos.Symbol,
		})
	}
}

func (s *Server) handleStats(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	defer func() {
		s.metrics.RecordHTTPLatency(time.Since(start))
	}()

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tradeCount, _ := s.cache.GetTradeCount()
	symbol, bidLevels, askLevels := s.processor.Snapshot()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"symbol":      symbol,
		"bid_levels":  bidLevels,
		"ask_levels":  askLevels,
		"trade_count": tradeCount,
		"ws_clients":  s.broadcaster.ClientCount(),
		"timestamp":   time.Now().UnixNano(),
	})
}

// handleWebSocket handles WebSocket connections for real-time market data
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		s.logger.Error("websocket", "Failed to upgrade connection", err.Error(), nil)
		return
	}

	s.logger.Info("websocket", "Client connected", map[string]string{
		"remote_addr": conn.RemoteAddr().String(),
	})

	// Register client with broadcaster and send initial order book
	s.broadcaster.RegisterClient(conn)

	// Send welcome message
	_, bidLevels, askLevels := s.processor.Snapshot()
	welcomeMsg := broadcasterws.Message{
		Type:      "welcome",
		Timestamp: time.Now().UnixNano(),
		Data: json.RawMessage(`{
			"message": "Connected to trading engine",
			"symbol": "BTC-USD",
			"bid_levels": ` + string(rune(bidLevels)) + `,
			"ask_levels": ` + string(rune(askLevels)) + `
		}`),
	}
	conn.WriteJSON(welcomeMsg)
}
