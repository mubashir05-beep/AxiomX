# AxiomX Matching Engine API

REST API for the high-performance order matching engine.

## Quick Start

### Local Development (Without Docker)

```bash
# Download dependencies
go mod download

# Run the API server
go run ./cmd/api
```

Server starts on http://localhost:8080

### With Docker Compose (Recommended)

```bash
# Build and start services (API + Postgres)
docker-compose up --build

# Stop services
docker-compose down
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Submit Order
```bash
POST /orders
Content-Type: application/json

{
  "order_id": "order123",
  "side": "buy",           # or "sell"
  "order_type": "limit",   # or "market"
  "price_ticks": 3000000,  # for limit orders (e.g., $30,000.00)
  "qty": 100000000         # e.g., 1.0 BTC with 8 decimals
}
```

Response:
```json
{
  "success": true,
  "trades": [
    {
      "ID": "t1",
      "PriceTicks": 3000000,
      "Qty": 100000000,
      "MakerOrderID": "order456",
      "TakerOrderID": "order123",
      "TsNano": 1234567890123456789
    }
  ]
}
```

### Get Order Book Snapshot
```bash
GET /book
```

Response:
```json
{
  "symbol": "BTC-USD",
  "bid_levels": 5,
  "ask_levels": 3
}
```

## Example Usage

### Place a limit buy order
```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "buy1",
    "side": "buy",
    "order_type": "limit",
    "price_ticks": 3000000,
    "qty": 100000000
  }'
```

### Place a limit sell order
```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "sell1",
    "side": "sell",
    "order_type": "limit",
    "price_ticks": 3010000,
    "qty": 100000000
  }'
```

### Place a market buy order
```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "market1",
    "side": "buy",
    "order_type": "market",
    "qty": 50000000
  }'
```

### Check order book
```bash
curl http://localhost:8080/book
```

## Database

Trades are persisted to Postgres when `DATABASE_URL` is set. If not available, trades are cached in memory.

**Connection string format:**
```
DATABASE_URL=postgres://user:password@host:port/database?sslmode=disable
```

## Architecture

- **cmd/api** - HTTP server entrypoint
- **internal/api** - REST endpoints
- **internal/engine** - Matching engine (orderbook, processor)
- **internal/storage** - Trade persistence layer
- **Dockerfile** - Container build
- **docker-compose.yml** - Local stack (API + Postgres)

## Next Steps

- Add authentication/authorization
- Add WebSocket for real-time market data
- Integrate Kafka for event streaming
- Add Prometheus metrics
- Deploy to Kubernetes
