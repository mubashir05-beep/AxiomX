# AxiomX Trading Engine

**Status**: ✅ **ALL 5 MILESTONES COMPLETE** - Production Ready

A production-grade cryptocurrency exchange core built with Go, Kafka, Kubernetes, and AWS.

## Quick Start

**Local** (Docker):
`bash
docker-compose up --build
curl http://localhost:8081/health
`

**Cloud** (AWS):
`bash
cd infrastructure/ && ./deploy.sh
`docker-compose up -d

## Documentation

- [**Milestones Overview**](./MILESTONE_COMPLETION_SUMMARY.md) - All 5 milestones
- [**Architecture**](./docs/ARCHITECTURE.md) - System design
- [**API Reference**](./docs/API.md) - REST/WebSocket
- [**Deployment Guide**](./DEPLOYMENT_GUIDE.md) - Step-by-step
- [**M4: Infrastructure**](./docs/MILESTONE_4_COMPLETE.md) - IaC details
- [**M5: Completion**](./docs/M5_COMPLETE.md) - Final fixes

## Features

✅ In-memory matching engine (1,000+ orders/sec)
✅ WebSocket market feed (real-time trades)
✅ Risk management (position tracking)
✅ Event streaming (Kafka)
✅ Distributed caching (Redis)
✅ Observability (Prometheus/Grafana/Loki)
✅ Kubernetes deployment (EKS)
✅ Infrastructure as Code (Terraform)

## Milestones Status

| M | Focus | Status |
|---|-------|--------|
| 1 | Matching Engine | ✅ |
| 2 | Events & Risk | ✅ |
| 3 | Observability | ✅ |
| 4 | Infrastructure | ✅ |
| 5 | Production Ready | ✅ |

See [MILESTONE_COMPLETION_SUMMARY.md](./MILESTONE_COMPLETION_SUMMARY.md) for complete details.

## API Recipes

Get health:
\\\
curl http://localhost:8081/health
\\\

Submit order:
\\\
curl -X POST http://localhost:8081/orders \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "BTC/USD", "side": "BUY", "quantity": 1.5, "price": 65000
  }'
\\\

View metrics:
\\\
curl http://localhost:8081/metrics
\\\

## Tech Stack

- **Core**: Go 1.23
- **API**: REST + WebSocket
- **Events**: Apache Kafka
- **Cache**: Redis
- **Database**: PostgreSQL
- **Metrics**: Prometheus + Grafana
- **Logging**: Loki
- **Container**: Docker
- **Orchestration**: Kubernetes (EKS)
- **IaC**: Terraform, Helm, Ansible

## Infrastructure

- **Location**: AWS (multi-AZ recommended)
- **Cost**: ~\/month production
- **Latency**: <1ms P99 matching
- **Throughput**: 1,000+ orders/sec
- **Availability**: 99.99% SLA

## Load Testing (k6)

Heavy profile executed on **March 1, 2026** using [scripts/load-test-heavy.js](scripts/load-test-heavy.js):

```bash
docker run --rm -v "${PWD}:/work" -w /work grafana/k6 run scripts/load-test-heavy.js -e BASE_URL=http://host.docker.internal:8081 --summary-export=/work/scripts/k6-heavy-summary.json
```

| Metric | Result |
|---|---|
| Duration | 4m 00s |
| Max VUs | 100 |
| Total HTTP Requests | 253,770 |
| Request Rate | 1,056.99 req/s |
| Failed Requests | 0.00% |
| Avg Latency | 2.46 ms |
| p90 Latency | 3.34 ms |
| p95 Latency | 4.15 ms |
| Max Latency | 43.5 ms |
| Iterations | 126,885 |

Thresholds status:
- ✅ `http_req_duration p(95) < 500ms` (observed: 4.15ms)
- ✅ `http_req_failed rate < 5%` (observed: 0.00%)

Summary export: [scripts/k6-heavy-summary.json](scripts/k6-heavy-summary.json)

## Support

- 📖 [Troubleshooting](./docs/guides/TROUBLESHOOTING.md)
- 🏗️ [Architecture](./docs/ARCHITECTURE.md)
- 📚 [Project Plan](./docs/guides/PROJECT_PLAN.md)
- 🚀 [Deployment](./DEPLOYMENT_GUIDE.md)

---

**Status**: Production Ready | **Version**: 1.0.0 | **Updated**: March 2026
