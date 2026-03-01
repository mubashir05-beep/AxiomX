package websocket

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/gorilla/websocket"
)

// Message represents a WebSocket message sent to clients
type Message struct {
	Type      string          `json:"type"` // "trade", "book_update", "order"
	Timestamp int64           `json:"timestamp"`
	Data      json.RawMessage `json:"data"`
}

// Broadcaster manages WebSocket connections and broadcasts market data
type Broadcaster struct {
	clients   map[*Client]bool
	register  chan *Client
	broadcast chan Message
	mu        sync.RWMutex
}

// Client represents a WebSocket client connection
type Client struct {
	conn *websocket.Conn
	send chan Message
}

// NewBroadcaster creates a new WebSocket broadcaster
func NewBroadcaster() *Broadcaster {
	return &Broadcaster{
		clients:   make(map[*Client]bool),
		register:  make(chan *Client),
		broadcast: make(chan Message, 100),
	}
}

// Run starts the broadcaster event loop
func (b *Broadcaster) Run() {
	for {
		select {
		case client := <-b.register:
			b.mu.Lock()
			b.clients[client] = true
			b.mu.Unlock()
			log.Printf("[WebSocket] Client registered, total: %d\n", len(b.clients))

		case msg := <-b.broadcast:
			b.mu.RLock()
			for client := range b.clients {
				select {
				case client.send <- msg:
				default:
					// Send channel full, skip this client
					go b.closeClient(client)
				}
			}
			b.mu.RUnlock()
		}
	}
}

// RegisterClient registers a new WebSocket client
func (b *Broadcaster) RegisterClient(conn *websocket.Conn) {
	client := &Client{
		conn: conn,
		send: make(chan Message, 50),
	}
	b.register <- client

	// Start client message writer
	go b.writeMessages(client)
}

// writeMessages writes messages from the send channel to the WebSocket connection
func (b *Broadcaster) writeMessages(client *Client) {
	defer func() {
		b.closeClient(client)
	}()

	for msg := range client.send {
		if err := client.conn.WriteJSON(msg); err != nil {
			log.Printf("[WebSocket] Write error: %v\n", err)
			return
		}
	}
}

// closeClient closes and removes a client
func (b *Broadcaster) closeClient(client *Client) {
	b.mu.Lock()
	if _, ok := b.clients[client]; ok {
		delete(b.clients, client)
		close(client.send)
		client.conn.Close()
		log.Printf("[WebSocket] Client closed, remaining: %d\n", len(b.clients))
	}
	b.mu.Unlock()
}

// BroadcastTrade broadcasts a trade execution
func (b *Broadcaster) BroadcastTrade(buyOrderID, sellOrderID string, priceTicks, qty int64) {
	data := map[string]interface{}{
		"buy_order_id":  buyOrderID,
		"sell_order_id": sellOrderID,
		"price_ticks":   priceTicks,
		"qty":           qty,
		"price_usd":     float64(priceTicks) / 1_000_000,
	}

	payload, _ := json.Marshal(data)
	b.broadcast <- Message{
		Type:      "trade",
		Timestamp: 0, // Will be set server-side
		Data:      payload,
	}
}

// BroadcastOrderSubmitted broadcasts a new order
func (b *Broadcaster) BroadcastOrderSubmitted(orderID, side string, priceTicks, qty int64) {
	data := map[string]interface{}{
		"order_id":    orderID,
		"side":        side,
		"price_ticks": priceTicks,
		"qty":         qty,
		"price_usd":   float64(priceTicks) / 1_000_000,
	}

	payload, _ := json.Marshal(data)
	b.broadcast <- Message{
		Type:      "order",
		Timestamp: 0,
		Data:      payload,
	}
}

// BroadcastBookSnapshot broadcasts the current order book
func (b *Broadcaster) BroadcastBookSnapshot(bidLevels, askLevels map[int64]int64) {
	data := map[string]interface{}{
		"bids": bidLevels,
		"asks": askLevels,
	}

	payload, _ := json.Marshal(data)
	b.broadcast <- Message{
		Type:      "book_update",
		Timestamp: 0,
		Data:      payload,
	}
}

// ClientCount returns the current number of connected clients
func (b *Broadcaster) ClientCount() int {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return len(b.clients)
}
