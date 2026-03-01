# Test Scripts

This folder contains PowerShell test scripts for validating API functionality.

## Available Tests

### test-api.ps1
Tests basic API functionality:
- Health check endpoint
- Order submission with limit orders
- Order book retrieval
- Market order execution
- Trade data persistence

**Usage:**
```powershell
.\test-api.ps1
```

### test-milestone2.ps1
Tests Milestone 2 event-driven architecture:
- Risk engine validation (rejecting invalid orders)
- Kafka event publishing (ORDER_SUBMITTED, TRADE_EXECUTED)
- Redis caching for order book snapshots
- Position tracking and risk monitoring
- Statistics endpoint

**Usage:**
```powershell
.\test-milestone2.ps1
```

## Prerequisites

### For API Tests
1. Start the API server:
   ```powershell
   go run ./cmd/api
   ```
   Server runs on `http://localhost:8080`

### For Milestone 2 Tests
Before running test-milestone2.ps1, you need the full stack:
```powershell
docker-compose up --build
```

This starts:
- Zookeeper (2181)
- Kafka (9092)
- Redis (6379)
- Postgres (5432)
- API Server (8080)

## Test Output

Both scripts provide:
- Request/response logging
- Timing information
- Status codes and results
- Error messages if tests fail

## Troubleshooting

- **Connection refused**: Make sure the API server is running
- **Kafka errors**: Run `docker-compose up` for full stack
- **Empty cache results**: Redis may not be running; errors gracefully fall back to live data
