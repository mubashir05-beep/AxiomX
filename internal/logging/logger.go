package logging

import (
	"encoding/json"
	"log"
	"time"
)

// LogLevel represents the severity of the log
type LogLevel string

const (
	DEBUG LogLevel = "DEBUG"
	INFO  LogLevel = "INFO"
	WARN  LogLevel = "WARN"
	ERROR LogLevel = "ERROR"
)

// Logger provides structured logging compatible with Loki
type Logger struct {
	serviceName string
	instanceID  string
}

// LogEntry represents a structured log entry for Loki
type LogEntry struct {
	Timestamp  int64             `json:"timestamp"`
	Level      LogLevel          `json:"level"`
	Service    string            `json:"service"`
	InstanceID string            `json:"instance_id"`
	Message    string            `json:"message"`
	Component  string            `json:"component"`
	RequestID  string            `json:"request_id,omitempty"`
	UserID     string            `json:"user_id,omitempty"`
	OrderID    string            `json:"order_id,omitempty"`
	TradeID    string            `json:"trade_id,omitempty"`
	Duration   float64           `json:"duration_ms,omitempty"`
	Error      string            `json:"error,omitempty"`
	StatusCode int               `json:"status_code,omitempty"`
	Metric     float64           `json:"metric,omitempty"`
	LatencyUS  int64             `json:"latency_us,omitempty"`
	Labels     map[string]string `json:"labels,omitempty"`
}

// NewLogger creates a new structured logger
func NewLogger(serviceName, instanceID string) *Logger {
	return &Logger{
		serviceName: serviceName,
		instanceID:  instanceID,
	}
}

// Info logs an info-level message
func (l *Logger) Info(component, message string, labels map[string]string) {
	l.log(INFO, component, message, labels)
}

// Debug logs a debug-level message
func (l *Logger) Debug(component, message string, labels map[string]string) {
	l.log(DEBUG, component, message, labels)
}

// Warn logs a warning-level message
func (l *Logger) Warn(component, message string, labels map[string]string) {
	l.log(WARN, component, message, labels)
}

// Error logs an error-level message
func (l *Logger) Error(component, message, err string, labels map[string]string) {
	if labels == nil {
		labels = make(map[string]string)
	}
	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      ERROR,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    message,
		Component:  component,
		Error:      err,
		Labels:     labels,
	}
	l.print(entry)
}

// HTTPRequest logs HTTP request details
func (l *Logger) HTTPRequest(method, path, requestID string, statusCode int, duration time.Duration) {
	labels := map[string]string{
		"method": method,
		"path":   path,
	}
	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      INFO,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    "HTTP request",
		Component:  "api",
		RequestID:  requestID,
		StatusCode: statusCode,
		Duration:   float64(duration.Milliseconds()),
		Labels:     labels,
	}
	l.print(entry)
}

// MatchingLatency logs matching engine latency
func (l *Logger) MatchingLatency(orderID string, latencyUS int64) {
	labels := map[string]string{
		"order_id": orderID,
	}
	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      DEBUG,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    "Matching executed",
		Component:  "engine",
		OrderID:    orderID,
		LatencyUS:  latencyUS,
		Labels:     labels,
	}
	l.print(entry)
}

// TradeExecuted logs a trade execution
func (l *Logger) TradeExecuted(buyOrderID, sellOrderID string, priceTicks, qty int64) {
	labels := map[string]string{
		"buy_order":  buyOrderID,
		"sell_order": sellOrderID,
		"price":      "ticks",
	}
	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      INFO,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    "Trade executed",
		Component:  "engine",
		Metric:     float64(qty),
		Labels:     labels,
	}
	l.print(entry)
}

// RiskCheck logs a risk validation
func (l *Logger) RiskCheck(userID, orderID string, approved bool, reason string) {
	labels := map[string]string{
		"user_id":   userID,
		"approved":  "true",
		"component": "risk",
	}
	if !approved {
		labels["approved"] = "false"
	}

	level := INFO
	if !approved {
		level = WARN
	}

	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      level,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    reason,
		Component:  "risk",
		UserID:     userID,
		OrderID:    orderID,
		Labels:     labels,
	}
	l.print(entry)
}

// log is the internal logging function
func (l *Logger) log(level LogLevel, component, message string, labels map[string]string) {
	entry := LogEntry{
		Timestamp:  time.Now().UnixMilli(),
		Level:      level,
		Service:    l.serviceName,
		InstanceID: l.instanceID,
		Message:    message,
		Component:  component,
		Labels:     labels,
	}
	l.print(entry)
}

// print outputs the log entry as JSON (compatible with Loki)
func (l *Logger) print(entry LogEntry) {
	data, _ := json.Marshal(entry)
	log.Println(string(data))
}
