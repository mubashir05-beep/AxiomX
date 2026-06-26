-- Initialize AxiomX database
-- Matches trade_store.go schema

CREATE TABLE IF NOT EXISTS trades (
    id TEXT PRIMARY KEY,
    price_ticks BIGINT NOT NULL,
    qty BIGINT NOT NULL,
    maker_order_id TEXT NOT NULL,
    taker_order_id TEXT NOT NULL,
    ts_nano BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    symbol VARCHAR(12) NOT NULL,
    side VARCHAR(4) NOT NULL,
    order_type VARCHAR(10) NOT NULL,
    price_ticks BIGINT,
    qty BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    user_id VARCHAR(50) NOT NULL DEFAULT 'default_user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_trades_maker ON trades(maker_order_id);
CREATE INDEX IF NOT EXISTS idx_trades_taker ON trades(taker_order_id);
CREATE INDEX IF NOT EXISTS idx_trades_ts ON trades(ts_nano);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
