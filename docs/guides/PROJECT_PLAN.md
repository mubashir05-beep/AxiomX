# High-Performance Order Matching Engine (Mini Exchange)

## Project Overview

This project aims to build a realistic crypto exchange core, focusing on high performance, reliability, and modern infrastructure. It is designed to showcase your skills in trading infrastructure, distributed systems, and DevOps.

### Why Build This?
- **Recruiter Appeal:** Demonstrates experience with matching engines, Kafka, Kubernetes, latency metrics, and infrastructure-as-code.
- **Learning Opportunity:** Deepens understanding of trading systems, order matching, and scalable cloud-native architectures.
- **Real-World Relevance:** Crypto exchanges are complex, high-throughput systems with strict reliability and latency requirements.

## Exchange Core Concepts

- **Order Book:** In-memory data structure holding limit and market orders.
- **Matching Engine:** Matches buy/sell orders based on price/time priority.
- **Order Types:** Supports limit and market orders.
- **Trade Execution:** Executes matched trades and updates order book.
- **Risk Checks:** Ensures orders/trades comply with risk rules.
- **Market Feed:** Real-time updates via WebSocket.
- **Persistence:** Trades stored in Postgres; order book snapshots cached in Redis.
- **Event Bus:** Kafka for decoupled, scalable event-driven architecture.

## What Makes This Project Different?
- **Performance Focus:** Lock-free or optimized mutex order book, goroutines for concurrency, latency tracking (p50, p95, p99).
- **Modern Infra:** Uses Kubernetes (EKS), Terraform, Ansible, Helm, Prometheus, Grafana, Loki, GitHub Actions.
- **Scalability:** Microservices, event-driven, cloud-native.
- **Observability:** Metrics, logging, profiling, load testing.

## Technologies & Learning Path

### Core Services
- **Go:** Main language for all services.
- **Kafka:** Event bus for order/trade events.
- **Postgres:** Trade persistence.
- **Redis:** Caching order book snapshots.

### Infrastructure & DevOps
- **Docker:** Containerization (already familiar).
- **Kubernetes (EKS):** Container orchestration, scaling, service management.
- **Terraform:** Infrastructure-as-code for AWS resources.
- **Ansible:** Server provisioning and configuration.
- **Helm:** Kubernetes package management (optional, recommended for production).
- **Prometheus/Grafana/Loki:** Monitoring, metrics, logging.
- **GitHub Actions:** CI/CD pipelines.

### AWS Services
- **EC2:** Compute (already familiar).
- **S3:** Storage (already familiar).
- **RDS:** Managed Postgres.
- **MSK:** Managed Kafka.
- **ElastiCache:** Managed Redis.
- **ALB:** Load balancing.
- **IAM:** Access management.
- **VPC/Subnets/Security Groups:** Networking and security.

## Suggested Learning Resources

- **Kubernetes:**
  - [Kubernetes Official Docs](https://kubernetes.io/docs/)
  - [EKS Workshop](https://www.eksworkshop.com/)
- **Terraform:**
  - [Terraform Official Docs](https://developer.hashicorp.com/terraform/docs)
  - [AWS Terraform Modules](https://registry.terraform.io/namespaces/terraform-aws-modules)
- **Ansible:**
  - [Ansible Official Docs](https://docs.ansible.com/)
- **Helm:**
  - [Helm Docs](https://helm.sh/docs/)
- **Prometheus/Grafana/Loki:**
  - [Prometheus Docs](https://prometheus.io/docs/)
  - [Grafana Docs](https://grafana.com/docs/)
  - [Loki Docs](https://grafana.com/docs/loki/latest/)

## Project Milestones & Phases


## Milestone Breakdown

### Milestone 1: Core Matching Engine & API ✅ COMPLETE
- [x] Design in-memory order book (Go)
- [x] Implement matching logic
- [x] REST API for order placement
- [x] Trade execution logic
- [x] Persist trades to Postgres
- [x] Dockerize services

### Milestone 2: Event-Driven Architecture & Risk ✅ COMPLETE
- [x] Integrate Kafka for order/trade events
- [x] Implement risk checks (separate service)
- [x] Add Redis for order book snapshot caching

### Milestone 3: Real-Time Market Feed & Observability ✅ COMPLETE
- [x] WebSocket broadcaster for market data
- [x] Integrate Prometheus, Grafana, Loki
- [x] Latency tracking and profiling (pprof)

### Milestone 4: Infrastructure & Scaling
- [ ] Write Terraform scripts for AWS (VPC, EKS, RDS, MSK, ElastiCache)
- [ ] Use Ansible for EC2 provisioning and logging agent setup
- [ ] Deploy services to EKS (Kubernetes)
- [ ] (Optional) Use Helm for Kubernetes deployments

### Milestone 5: CI/CD & Load Testing
- [ ] Set up GitHub Actions for CI/CD
- [ ] Write k6 load tests
- [ ] Optimize for latency
- [ ] Document architecture, setup, and usage

---

## How I Will Help You Learn

- Break down each milestone into actionable tasks and track progress
- Provide code scaffolding, explanations, and best practices for each technology
- Suggest resources and exercises for unfamiliar tools (K8s, Terraform, Ansible, Helm)
- Review your code and offer feedback
- Help debug issues and optimize performance
- Guide you through infrastructure setup and deployment
- Answer conceptual questions and explain trading/infra principles
- Keep a running todo list for visibility and accountability

## Next Steps
1. Review and understand the core exchange concepts.
2. Begin with Phase 1: design and implement the matching engine and REST API (you do NOT need to learn Kubernetes, Terraform, Ansible, or Helm first).
3. Progress through each milestone, building and deploying incrementally.
4. Learn infrastructure tools (Kubernetes, Terraform, Ansible, Helm) when you reach the deployment and scaling milestones. This way, you build core features first and expand your skills as needed.

---

**This file will guide your learning and project execution. Update it as you progress!**

---

## FAQ & Deep Dive

### Will this be a low latency system?
Yes. The architecture is designed for low latency by using:
- In-memory order book and matching engine (Go, goroutines)
- Optimized locking or lock-free data structures
- Event-driven communication (Kafka)
- Real-time feeds (WebSocket)
- Latency tracking (p50, p95, p99)

### Why "Mini Exchange"?
"Mini Exchange" means a simplified, focused version of a real-world trading engine. It covers all core concepts (matching, risk, persistence, infra) without the full complexity of a production exchange. This makes it achievable, educational, and demonstrable for recruiters.

### How can I maximize learning?
- Build each component from scratch, understanding its role
- Learn new infra tools (K8s, Terraform, Ansible, Helm)
- Profile and optimize for latency
- Deploy and monitor in cloud
- Document design decisions and trade-offs

### What is the minimum response time to target?
- Aim for sub-10ms matching engine response under load (p50)
- Track p95 and p99 latency; strive for <50ms for most requests
- Real-world exchanges target microseconds, but for learning, sub-10ms is excellent

### What database concepts will be used?
- ACID transactions for trade persistence (Postgres)
- Indexing for fast queries
- Event sourcing (Kafka topics)
- Caching (Redis) for order book snapshots
- Data partitioning and scaling (Postgres, Kafka)

### Is this approach scalable?
Yes. Microservices, event-driven architecture, and cloud-native infra (K8s, Kafka, Redis, Postgres) allow horizontal scaling. Each service can be scaled independently, and stateless components (API, matching engine) are easy to replicate. Kafka and Redis support high throughput and low latency.

---

## Core Trading Flows (No-Finance-Jargon Version)

These are exactly the right concepts to understand first. Yes, this is what we are building.

### Seller Flow (I want to sell BTC)

```text
Seller decides to sell BTC
  |
  v
Chooses order type?
  |
  +----------------------+
  |                      |
  v                      v
   LIMIT SELL              MARKET SELL
("only at my price")     ("sell immediately")
  |                      |
  v                      v
Is there a buyer           Find best buyer
willing to pay             right now
my price or more?               |
  |                      v
   +----+----+             Trade executes
   |         |             immediately
  YES       NO                  |
   |         |                  v
   v         v             BTC sold
Trade       Order waits      Money received
executes    in order book
   |
   v
BTC sold
Money received
```

### Buyer Flow (I want to buy BTC)

```text
Buyer decides to buy BTC
  |
  v
Chooses order type?
  |
  +----------------------+
  |                      |
  v                      v
   LIMIT BUY               MARKET BUY
("only at my price")     ("buy immediately")
  |                      |
  v                      v
Is there a seller         Find cheapest seller
selling at my             right now
price or cheaper?              |
  |                      v
   +----+----+             Trade executes
   |         |             immediately
  YES       NO                  |
   |         |                  v
   v         v             BTC received
Trade       Order waits      Money paid
executes    in order book
   |
   v
BTC received
Money paid
```

### Exchange Engine Logic (Behind the scenes)

```text
Receive order
   |
   v
Check opposite side of book
   |
   v
If prices overlap -> trade
Else -> store order
```

### Mental Shortcut

> Market orders want speed. Limit orders want control.

If this is clear, you understand the core behavior your matching engine must implement.

### How this maps to your milestones

- Milestone 1 implements these exact rules in Go (order book + matching + REST).
- Milestone 2 adds risk checks and event flow around this core.
- Milestone 3+ adds market feed, observability, and production-grade infrastructure.

---

## Performance Reality Check: Can we keep 100M orders in RAM?

Short answer: **possible in large systems, but not ideal as a naive single-book design**.

### Rough memory math (why this matters)

- If one in-memory order object costs ~120 to ~250 bytes in Go (struct + pointers + map/slice overhead), then:
  - 100M orders can consume roughly **12 GB to 25+ GB** just for order objects.
  - Real usage is higher after indexes, GC overhead, queues, and service runtime.
- So a single process holding all raw orders is risky and can degrade latency due to GC pressure.

### Better production pattern

- Keep only **active/open orders** in memory (not all historical requests).
- Persist events/trades/orders in Postgres/Kafka for durability and replay.
- Partition by **symbol** (or symbol shard) so each matching worker owns a smaller book.
- Use **one goroutine per symbol/shard** for deterministic sequencing and reduced lock contention.
- Store compact numeric fields (ticks, qty as int64), avoid heavy object graphs.

### For your project target

- Start with one symbol book in memory and prove matching correctness.
- Then add symbol partitioning and measure p50/p95/p99 under load (k6).
- Aim for stable low-latency at realistic open-order counts, then scale horizontally.

### Practical conclusion

Yes, the approach is scalable if you architect for:
- in-memory active state,
- persistent event log,
- partitioned matching,
- and horizontal scale.

This is exactly how real exchange-like systems stay fast.
