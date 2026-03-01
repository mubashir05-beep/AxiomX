package main

import (
	"log"
	"net/http"

	"axiomx/internal/api"
	"axiomx/internal/cache"
	"axiomx/internal/engine"
	"axiomx/internal/events"
	"axiomx/internal/risk"
	"axiomx/internal/storage"
)

func main() {
	// Initialize matching processor
	processor := engine.NewMatchingProcessor("BTC-USD", 2048)
	defer processor.Stop()

	// Initialize trade storage (with optional Postgres)
	store := storage.NewTradeStore()
	defer store.Close()

	// Initialize event publisher (with optional Kafka)
	publisher := events.NewPublisher()
	defer publisher.Close()

	// Initialize risk engine
	riskEngine := risk.NewRiskEngine()

	// Initialize cache (with optional Redis)
	redisCache := cache.NewCache()
	defer redisCache.Close()

	// Create API server
	server := api.NewServer(processor, store, publisher, riskEngine, redisCache)

	// Start HTTP server
	log.Println("Starting API server on :8080")
	log.Println("Event-driven architecture enabled:")
	log.Println("  - Kafka: order/trade events")
	log.Println("  - Risk Engine: position limits and validation")
	log.Println("  - Redis: order book caching")
	if err := http.ListenAndServe(":8080", server.Router()); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
