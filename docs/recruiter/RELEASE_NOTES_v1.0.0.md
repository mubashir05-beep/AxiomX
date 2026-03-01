# AxiomX v1.0.0 - Production Ready

High-performance cryptocurrency matching engine handling 1,000+ orders/second with sub-5ms P95 latency.

## Quick Start

```bash
docker-compose up -d
```

Then visit:
- API: http://localhost:8081/health
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

## Performance (Verified)

Load tested with k6 on March 1, 2026:

| Metric | Result |
|--------|--------|
| Throughput | 1,056 req/s |
| Total Requests | 253,770 (4 min) |
| P95 Latency | 4.15ms |
| Error Rate | 0.00% |

Full metrics: [k6-heavy-summary.json](scripts/k6-heavy-summary.json)

## What's Included

- Matching Engine: In-memory order book with price-time priority
- Event Streaming: Kafka for reliable event distribution
- Observability: Prometheus + Grafana + Loki
- Persistence: PostgreSQL with optimized schema
- Caching: Redis for sub-ms lookups
- Infrastructure: Kubernetes (Helm) + Terraform + Ansible
- Load Tests: k6 scripts with verified results

## For Recruiters

See [RECRUITER_GUIDE.md](../../RECRUITER_GUIDE.md) for technical highlights and Q&A.

## Tech Stack

Backend: Go 1.23 | Streaming: Apache Kafka 7.5 | Database: PostgreSQL 15, Redis 7  
Observability: Prometheus, Grafana, Loki | Infrastructure: Kubernetes, Docker, Terraform

## Documentation

- [README](../../README.md) - Project overview
- [RECRUITER_GUIDE](../../RECRUITER_GUIDE.md) - Technical guide
- [DEPLOYMENT_GUIDE](../../DEPLOYMENT_GUIDE.md) - Deployment options

## License

MIT License - see [LICENSE](LICENSE)
