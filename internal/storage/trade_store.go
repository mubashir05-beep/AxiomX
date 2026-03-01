package storage

import (
	"database/sql"
	"fmt"
	"os"
	"sync"

	"axiomx/internal/engine"

	_ "github.com/lib/pq"
)

type TradeStore struct {
	db    *sql.DB
	mu    sync.Mutex
	cache []engine.Trade
}

func NewTradeStore() *TradeStore {
	store := &TradeStore{
		cache: make([]engine.Trade, 0),
	}

	// Try to connect to Postgres if DATABASE_URL is set
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL != "" {
		db, err := sql.Open("postgres", dbURL)
		if err == nil && db.Ping() == nil {
			store.db = db
			store.initDB()
			fmt.Println("Connected to Postgres")
		} else {
			fmt.Println("Postgres not available, using in-memory cache")
		}
	} else {
		fmt.Println("DATABASE_URL not set, using in-memory cache")
	}

	return store
}

func (ts *TradeStore) initDB() error {
	query := `
	CREATE TABLE IF NOT EXISTS trades (
		id TEXT PRIMARY KEY,
		price_ticks BIGINT NOT NULL,
		qty BIGINT NOT NULL,
		maker_order_id TEXT NOT NULL,
		taker_order_id TEXT NOT NULL,
		ts_nano BIGINT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`
	_, err := ts.db.Exec(query)
	return err
}

func (ts *TradeStore) SaveTrade(trade engine.Trade) error {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	// Always cache in memory
	ts.cache = append(ts.cache, trade)

	// Persist to Postgres if available
	if ts.db != nil {
		query := `
		INSERT INTO trades (id, price_ticks, qty, maker_order_id, taker_order_id, ts_nano)
		VALUES ($1, $2, $3, $4, $5, $6)`
		_, err := ts.db.Exec(query, trade.ID, trade.PriceTicks, trade.Qty,
			trade.MakerOrderID, trade.TakerOrderID, trade.TsNano)
		return err
	}

	return nil
}

func (ts *TradeStore) GetTrades(limit int) []engine.Trade {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	if limit <= 0 || limit > len(ts.cache) {
		limit = len(ts.cache)
	}

	result := make([]engine.Trade, limit)
	copy(result, ts.cache[len(ts.cache)-limit:])
	return result
}

func (ts *TradeStore) Close() error {
	if ts.db != nil {
		return ts.db.Close()
	}
	return nil
}
