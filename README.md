# AxiomX - High-Performance Order Matching Engine

A production-grade cryptocurrency exchange core built with Go, featuring in-memory matching, event streaming, risk management, and distributed caching.

## 🚀 Quick Start

### Prerequisites
- Go 1.23+
- Docker & Docker Compose
- PowerShell 5.1+ (for test scripts)

### Start the API Server
```powershell
# Build and run
go run ./cmd/api

# Server runs on http://localhost:8080
```

### Run Full Stack with Docker
```powershell
docker-compose up --build
```

This starts:
- **Zookeeper** (2181) - Kafka coordination
- **Kafka** (9092) - Event streaming
- **Redis** (6379) - Caching layer
- **Postgres** (5432) - Trade persistence
- **API Server** (8080) - HTTP endpoints

## 📁 Project Structure

```
AxiomX/
├── cmd/                          # Executables
│   ├── api/                       # REST API server
│   └── engine/                    # CLI matching demo
├── internal/                      # Core packages
│   ├── api/                       # REST handlers & routes
│   ├── engine/                    # Matching engine (types, processor, orderbook)
│   ├── events/                    # Kafka event publishing
│   ├── risk/                      # Risk engine & validation
│   ├── storage/                   # Postgres persistence
│   └── cache/                     # Redis caching
├── docs/                          # 📚 Documentation & Learning Guides
│   ├── README.md                  # Documentation index
│   ├── API_README.md              # REST API reference
│   ├── MILESTONE1_COMPLETE.md     # Milestone 1 summary
│   └── guides/                    # Step-by-step learning guides
│       ├── START_HERE.md
│       ├── PROJECT_PLAN.md
│       ├── TYPES_GUIDE.md
│       ├── PROCESSOR_GUIDE.md
│       ├── ORDERBOOK_GUIDE.md
│       └── MAIN_GUIDE.md
├── scripts/                       # 🧪 Test Scripts
│   ├── README.md                  # Test documentation
│   ├── test-api.ps1               # Basic API tests
│   └── test-milestone2.ps1        # Milestone 2 integration tests
├── docker-compose.yml             # Docker stack
├── Dockerfile                     # API server image
├── go.mod & go.sum                # Go dependencies
└── README.md                      # This file
```

## 🎯 Features

### Milestone 1: Core Matching Engine ✅
- **In-Memory Order Book**: Price-level aggregation with FIFO per level
- **Matching Algorithm**: Limit and market order support with price-time priority
- **REST API**: `/orders`, `/book`, `/health` endpoints
- **Persistence**: Postgres-backed trade history with in-memory fallback
- **Docker**: Multi-stage Dockerfile and docker-compose stack

### Milestone 2: Event-Driven Architecture ✅
- **Kafka Integration**: ORDER_SUBMITTED and TRADE_EXECUTED events
- **Risk Engine**: Position tracking, max size validation, price sanity checks
- **Redis Caching**: Order book snapshots with 10-second TTL
- **Enhanced API**: `/risk/position`, `/stats` endpoints
- **Position Tracking**: Per-user position management

### Milestone 3: Real-Time Market Feed & Observability ✅
- **WebSocket Broadcasting**: Real-time trades, orders, and book updates
- **Prometheus Metrics**: HTTP latency, matching latency, trade counters
- **Structured Logging**: JSON logs compatible with Loki aggregation
- **pprof Profiling**: CPU and memory profiling endpoints
- **Latency Tracking**: p50, p95, p99 percentiles across all critical paths
- **Dashboard Ready**: Pre-configured Grafana integration

### Milestone 4: Infrastructure & Kubernetes (Pending)
- Terraform infrastructure as code
- Ansible configuration management
- EKS cluster deployment

### Milestone 5: Testing & CI/CD (Pending)
- k6 load tests (1000s of orders/second)
- GitHub Actions CI/CD pipeline
- Automated integration tests

## 📖 Learning Guides

All learning materials are in [docs/guides/](docs/guides/):

1. **START_HERE.md** - Quick overview
2. **PROJECT_PLAN.md** - Full roadmap and architecture
3. **TYPES_GUIDE.md** - Go types and data structures
4. **PROCESSOR_GUIDE.md** - Goroutines and channels
5. **ORDERBOOK_GUIDE.md** - Matching algorithm walkthrough
6. **MAIN_GUIDE.md** - CLI demo explanation

## 🧪 Testing

### Run API Tests
```powershell
.\scripts\test-api.ps1
```

**Tests:**
- Health check
- Order submission
- Order book retrieval
- Trade execution
- Persistence verification

### Run Integration Tests (Milestone 2)
```powershell
docker-compose up --build

# In another terminal:
.\scripts\test-milestone2.ps1
```

**Tests:**
- Risk validation
- Kafka event publishing
- Redis caching
- Position tracking
- Statistics endpoint

## 🏗️ Architecture

### Matching Engine Flow
```
Order Request
    ↓
[Risk Validation] → Reject if limit exceeded
    ↓
[Matching Processor] → In-memory orderbook
    ↓
[Match Algorithm] → Find counterparty
    ↓
[Trade Execution] → Generate trades
    ↓
[Event Publishing] → Kafka stream
    ↓
[Persistence] → Postgres + Redis cache
```

### Data Structures
- **Order**: ID, Side (Buy/Sell), PriceTicks (int64), Qty (int64), Timestamp
- **Trade**: BuyOrderID, SellOrderID, PriceTicks, Qty, Timestamp
- **Position**: UserID, Symbol, Qty (cumulative)

### Technical Spec
- **Language**: Go 1.23
- **Message Queue**: Kafka (segmentio/kafka-go)
- **Cache**: Redis 7 (go-redis/v9)
- **Database**: Postgres 15 (lib/pq)
- **Concurrency**: Goroutines + channels, mutex-based order book locking
- **Matching**: Price-time priority, FIFO per level

## 📊 API Endpoints

### Health Check
```bash
GET /health
```

### Submit Order
```bash
POST /orders
{
  "order_id": "order-123",
  "user_id": "user-456",
  "side": "buy",           # or "sell"
  "order_type": "limit",   # or "market"
  "price_ticks": 3000000,  # $30,000.00 (for limit orders)
  "qty": 100000000         # 1.0 BTC (8 decimals)
}
```

### Get Order Book
```bash
GET /book
```
Response includes X-Cache header: `HIT` (Redis) or `MISS` (Live)

### Get User Position
```bash
GET /risk/position?user_id=user-456
```

### Get Stats
```bash
GET /stats
```

### WebSocket Real-Time Feed
```bash
GET ws://localhost:8080/ws
```
Streams: trades, orders, book updates, welcome messages

### Prometheus Metrics (Milestone 3)
```bash
GET /metrics
```
Returns Prometheus format metrics for: HTTP latency, matching latency, orders processed, trades executed, active orders

### CPU Profiling (Milestone 3)
```bash
GET /debug/pprof/
GET /debug/pprof/profile?seconds=30  # 30-second CPU profile
GET /debug/pprof/heap                # Memory allocations
GET /debug/pprof/goroutine           # Goroutine stack traces
```

## 🔧 Configuration

Environment variables (in `docker-compose.yml`):
- `KAFKA_BROKER`: Kafka bootstrap address
- `REDIS_ADDR`: Redis connection string
- `DATABASE_URL`: Postgres connection string

## 📚 Additional Resources

- **API Documentation**: See [docs/API_README.md](docs/API_README.md)
- **Project Plan**: See [docs/guides/PROJECT_PLAN.md](docs/guides/PROJECT_PLAN.md)
- **Learning Materials**: See [docs/guides/](docs/guides/)

## 🎓 Learning Objectives

This project teaches:
- **Go Fundamentals**: Goroutines, channels, interfaces, error handling
- **Concurrency Patterns**: Worker pools, synchronous APIs over async implementations
- **Trading Concepts**: Order types, matching algorithms, market microstructure
- **System Architecture**: Event-driven design, CQRS patterns, distributed systems
- **DevOps**: Docker, Kubernetes, infrastructure as code
- **Monitoring**: Prometheus metrics, log aggregation, performance tracking

## 📝 Notes

- **Memory Strategy**: 100M orders = 12-25GB RAM; production uses partitioning and active-only strategy
- **Graceful Degradation**: Without Kafka/Redis, system falls back to in-memory only
- **Latency**: Sub-millisecond matching with FIFO order fairness
- **Testing**: PowerShell scripts for Windows development; shell scripts for Linux/Mac

## 📄 License

Educational project - MIT License

---

**Status**: Milestone 3 Complete ✅ | Milestone 4 Pending

