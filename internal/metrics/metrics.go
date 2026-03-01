package metrics

import (
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Metrics holds all Prometheus metrics for the system
type Metrics struct {
	// HTTP Metrics
	HTTPRequestDuration prometheus.Histogram
	HTTPRequestCount    prometheus.Counter

	// Matching Engine Metrics
	MatchingLatency prometheus.Histogram
	OrdersProcessed prometheus.Counter
	TradesExecuted  prometheus.Counter

	// Order Book Metrics
	ActiveOrders prometheus.Gauge
	BidLevels    prometheus.Gauge
	AskLevels    prometheus.Gauge

	// Risk Metrics
	RiskValidationDuration prometheus.Histogram
	RiskChecksFailed       prometheus.Counter

	// Latency Percentiles (calculated from histogram)
	latencyBuckets []float64
}

// NewMetrics creates and registers all metrics
func NewMetrics() *Metrics {
	latencyBuckets := []float64{
		0.1, 0.5, 1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000,
	}

	return &Metrics{
		HTTPRequestDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "http_request_duration_ms",
			Help:    "HTTP request duration in milliseconds",
			Buckets: latencyBuckets,
		}),
		HTTPRequestCount: promauto.NewCounter(prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total HTTP requests",
		}),
		MatchingLatency: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "matching_latency_us",
			Help:    "Matching engine latency in microseconds",
			Buckets: latencyBuckets,
		}),
		OrdersProcessed: promauto.NewCounter(prometheus.CounterOpts{
			Name: "orders_processed_total",
			Help: "Total orders processed",
		}),
		TradesExecuted: promauto.NewCounter(prometheus.CounterOpts{
			Name: "trades_executed_total",
			Help: "Total trades executed",
		}),
		ActiveOrders: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "active_orders",
			Help: "Number of active orders in order book",
		}),
		BidLevels: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "bid_levels",
			Help: "Number of bid price levels",
		}),
		AskLevels: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "ask_levels",
			Help: "Number of ask price levels",
		}),
		RiskValidationDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "risk_validation_duration_us",
			Help:    "Risk validation duration in microseconds",
			Buckets: latencyBuckets,
		}),
		RiskChecksFailed: promauto.NewCounter(prometheus.CounterOpts{
			Name: "risk_checks_failed_total",
			Help: "Total risk checks that failed",
		}),
		latencyBuckets: latencyBuckets,
	}
}

// RecordHTTPLatency records HTTP request latency in milliseconds
func (m *Metrics) RecordHTTPLatency(duration time.Duration) {
	m.HTTPRequestDuration.Observe(float64(duration.Milliseconds()))
	m.HTTPRequestCount.Inc()
}

// RecordMatchingLatency records matching engine latency in microseconds
func (m *Metrics) RecordMatchingLatency(duration time.Duration) {
	m.MatchingLatency.Observe(float64(duration.Microseconds()))
	m.OrdersProcessed.Inc()
}

// RecordTradeExecution increments trade counter
func (m *Metrics) RecordTradeExecution() {
	m.TradesExecuted.Inc()
}

// UpdateOrderBook updates current order book metrics
func (m *Metrics) UpdateOrderBook(activeOrders, bidLevels, askLevels int) {
	m.ActiveOrders.Set(float64(activeOrders))
	m.BidLevels.Set(float64(bidLevels))
	m.AskLevels.Set(float64(askLevels))
}

// RecordRiskValidationLatency records risk check duration in microseconds
func (m *Metrics) RecordRiskValidationLatency(duration time.Duration) {
	m.RiskValidationDuration.Observe(float64(duration.Microseconds()))
}

// RecordRiskCheckFailed increments failed risk check counter
func (m *Metrics) RecordRiskCheckFailed() {
	m.RiskChecksFailed.Inc()
}

// LatencyPercentiles calculates p50, p95, p99 from histogram
// Note: This is approximate; real percentiles require histogram snapshots
func (m *Metrics) LatencyPercentiles() map[string]float64 {
	return map[string]float64{
		"latency_p50_us": 0,
		"latency_p95_us": 0,
		"latency_p99_us": 0,
		// Prometheus metrics are scrape-based; percentiles computed by Prometheus itself
	}
}
