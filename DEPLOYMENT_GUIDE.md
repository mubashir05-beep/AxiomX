# AxiomX Deployment & Operations Guide

## Quick Start (5 minutes)

```bash
# 1. Clone repository and navigate
cd infrastructure/

# 2. Set environment variables
export AWS_REGION=us-east-1
export CLUSTER_NAME=axiomx-prod
export NAMESPACE=trading

# 3. Run deployment script
chmod +x deploy.sh
./deploy.sh

# The script will guide you through all phases automatically
```

**Result**: Production Kubernetes cluster with AxiomX trading engine running across 3 AWS availability zones.

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│   AWS Region (us-east-1)                │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  EKS Cluster (3 AZs)             │   │
│  │  ├─ Node 1 (t3.medium)           │   │
│  │  ├─ Node 2 (t3.medium)           │   │
│  │  ├─ Node 3 (t3.medium)           │   │
│  │  │                               │   │
│  │  └─ Trading Engine Pods (3-10)   │   │
│  │     ├─ HPA: Scales 3-10 replicas │   │
│  │     ├─ Health checks (3 probes)  │   │
│  │     └─ Prometheus metrics        │   │
│  └──────────────────────────────────┘   │
│                                         │
│  Managed Services:                      │
│  ├─ RDS: Postgres Multi-AZ             │
│  ├─ MSK: Kafka 3 brokers               │
│  ├─ ElastiCache: Redis Multi-AZ        │
│  └─ CloudWatch: Monitoring/Logging     │
│                                         │
└─────────────────────────────────────────┘
```

---

## Deployment Workflow

### Step-by-Step Manual Deployment

**Phase 1: Infrastructure (Terraform) - ~20 minutes**

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Create variables file
cat > terraform.tfvars << 'EOF'
aws_region = "us-east-1"
cluster_name = "axiomx-prod"
db_password = "YourSecurePassword123!@#"
environment = "production"
EOF

# Plan and review
terraform plan -out=tfplan

# Deploy infrastructure
terraform apply tfplan

# Save outputs
terraform output > outputs.txt
cat outputs.txt
```

**What Gets Created**:
- ✅ VPC (10.0.0.0/16) with 6 subnets across 3 AZs
- ✅ EKS cluster (Kubernetes 1.28) with 3 worker nodes
- ✅ RDS Postgres Multi-AZ (20GB, encrypted, 7-day backups)
- ✅ MSK Kafka cluster (3 brokers with TLS)
- ✅ ElastiCache Redis (3 nodes with automatic failover)
- ✅ Security groups, IAM roles, NAT gateways

**Phase 2: Kubernetes Setup - ~5 minutes**

```bash
# Update kubeconfig
aws eks update-kubeconfig --name axiomx-prod --region us-east-1

# Verify access
kubectl cluster-info
kubectl get nodes
```

**Phase 3: Secrets Configuration - ~2 minutes**

```bash
# Create namespace
kubectl create namespace trading

# Create secret with database credentials
# (Replace with actual values from terraform outputs)
kubectl create secret generic trading-secrets \
  --from-literal=DATABASE_URL='postgres://axiomadmin:PASSWORD@RDS-ENDPOINT:5432/trading?sslmode=require' \
  --from-literal=KAFKA_BROKERS='MSK-BOOTSTRAP-SERVERS' \
  --from-literal=REDIS_ADDR='REDIS-ENDPOINT:6379' \
  --from-literal=REDIS_PASSWORD='XXXXXXXXXXXX' \
  --namespace trading
```

**Phase 4: Deploy Application - ~3 minutes**

```bash
cd infrastructure

# Option A: Using Helm (Recommended)
helm install axiomx-trading helm/ \
  --namespace trading \
  --values helm/values.yaml \
  --wait

# Option B: Using kubectl
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets-configmap.yaml
kubectl apply -f kubernetes/trading-engine-deployment.yaml
kubectl apply -f kubernetes/services-hpa.yaml
```

**Phase 5: Verify - ~2 minutes**

```bash
# Check pods
kubectl get pods -n trading -w

# Port forward to test
kubectl port-forward -n trading svc/trading-engine 8080:8080

# Test API in another terminal
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

---

## Accessing the Application

### Port Forwarding (Development/Testing)

```bash
# Forward API endpoint
kubectl port-forward -n trading svc/trading-engine 8080:8080

# Access in browser/curl
curl http://localhost:8080/health
```

### Direct Access (Load Balancer)

To expose externally, add Ingress/LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trading-engine-lb
  namespace: trading
spec:
  type: LoadBalancer  # or: type: NodePort
  selector:
    app: trading-engine
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
```

Then apply:
```bash
kubectl apply -f service-lb.yaml
kubectl get svc -n trading trading-engine-lb
# Get external IP/hostname from EXTERNAL-IP column
```

---

## Monitoring & Observability

### Prometheus Metrics

Engine exports 9 metrics at `/metrics`:

```promql
# Example: View P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Example: View error rate
rate(http_requests_total{status=~"5.."}[5m])

# Example: View active connections
trading_engine_active_orders

# Example: View trade throughput
rate(trading_engine_trades_total[1m])
```

### CloudWatch Logs

```bash
# View logs from CLI
aws logs tail /axiomx/trading-engine --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /axiomx/trading-engine \
  --filter-pattern "ERROR"
```

### Pod Metrics

```bash
# CPU/Memory usage
kubectl top pods -n trading

# Node utilization
kubectl top nodes

# Watch HPA scaling decisions
kubectl get hpa -n trading -w
```

---

## Scaling

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment trading-engine -n trading --replicas=5

# Verify
kubectl get replicas -n trading
```

### Automatic Scaling (HPA)

Configured by default to scale 3-10 replicas based on:
- CPU > 70%
- Memory > 80%

View HPA status:
```bash
kubectl describe hpa -n trading trading-engine

# Watch scaling in action
kubectl get hpa -n trading -w
```

### Node Scaling

EKS auto-scaling group configured (3-6 nodes):
```bash
# View node pool
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names axiomx-prod-nodes

# Scale nodes
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name axiomx-prod-nodes \
  --desired-capacity 5
```

---

## Updating & Rollback

### Update Application (New Version)

```bash
# Update image tag
kubectl set image deployment/trading-engine \
  trading-engine=axiomx:v1.2.3 \
  -n trading

# Or with Helm
helm upgrade axiomx-trading helm/ \
  --namespace trading \
  --set image.tag=v1.2.3

# Monitor rollout
kubectl rollout status deployment/trading-engine -n trading
```

### Rollback to Previous Version

```bash
# View rollout history
kubectl rollout history deployment/trading-engine -n trading

# Rollback to previous
kubectl rollout undo deployment/trading-engine -n trading

# Or with Helm
helm rollout history axiomx-trading -n trading
helm rollout undo axiomx-trading -n trading

# Verify
kubectl get pods -n trading
```

---

## Cost Optimization

### Current Monthly Cost: ~$550

| Component | Cost | Optimization |
|-----------|------|--------------|
| EKS | $73 | ✅ Already amortized (shared control plane) |
| EC2 Nodes (3×t3.medium) | $90 | Use Spot (-70%) or Reserved (-30%) |
| RDS (db.t3.medium) | $150 | Use db.t3.micro for dev (-50%) |
| MSK (3×kafka.t3.small) | $120 | Use Single-AZ for dev (-30%) |
| ElastiCache (3×cache.t3.micro) | $50 | Use cache.t3.nano (-40%) |
| NAT Gateways (3) | $45 | Use Single-AZ (-60%) |
| **Total** | **$548** | ~$250 with optimizations |

### Cost Reduction Steps

```bash
# 1. Use Spot Instances
aws ec2 request-spot-instances --launch-specification file://spot-config.json

# 2. Reserved Instances (1-year)
aws ec2 purchase-reserved-instances --reserved-instances-offering-ids xxxxx

# 3. Scale down non-prod
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name axiomx-dev-nodes \
  --desired-capacity 1

# 4. Use CloudWatch cost monitoring
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31
```

---

## Troubleshooting

### Pod Crashes

```bash
# Check pod events
kubectl describe pod <pod-name> -n trading

# View logs
kubectl logs <pod-name> -n trading --previous

# Check health endpoint
kubectl exec -it <pod-name> -n trading -- curl localhost:8080/health
```

### Database Connection Issues

```bash
# Test connectivity
kubectl run -it --rm psql --image=postgres --restart=Never -- \
  psql "postgresql://user:pass@rds-endpoint:5432/trading?sslmode=require"

# Check RDS security group
aws ec2 describe-security-groups --filters "Name=group-name,Values=axiomx-rds-sg"
```

### Kafka Connection Issues

```bash
# List Kafka topics
kubectl run -it --rm kafka --image=library/kafka --restart=Never -- \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server msk-endpoint:9092 \
  --list

# Test producer
kubectl run -it --rm kafka --image=library/kafka --restart=Never -- \
  /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server msk-endpoint:9092 \
  --topic orders
```

### Node Issues

```bash
# Check node status
kubectl get nodes -o wide

# Describe problematic node
kubectl describe node <node-name>

# SSH to node (EC2 Systems Manager)
aws ssm start-session --target i-xxxxxxxxx

# Drain node (prepare for replacement)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Cordon node (prevent new pods)
kubectl cordon <node-name>
```

---

## Backup & Disaster Recovery

### RDS Backup

```bash
# View automated backups
aws rds describe-db-instances \
  --db-instance-identifier axiomx-db \
  --query 'DBInstances[0].DBInstanceStatus'

# Create manual backup
aws rds create-db-snapshot \
  --db-instance-identifier axiomx-db \
  --db-snapshot-identifier axiomx-backup-$(date +%s)

# Restore from backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier axiomx-db-restore \
  --db-snapshot-identifier axiomx-backup-1234567890
```

### Kubernetes Resources

```bash
# Backup all resources to YAML
kubectl get all -n trading -o yaml > trading-backup.yaml

# Restore from backup
kubectl apply -f trading-backup.yaml
```

### Helm Release Backup

```bash
# Get release values
helm get values axiomx-trading -n trading > values-backup.yaml

# Get full manifest
helm get manifest axiomx-trading -n trading > manifest-backup.yaml
```

---

## Security Best Practices

### 1. Network Security
✅ Private subnets for databases
✅ Security groups restrict access
✅ NAT Gateways for outbound

### 2. Encryption
✅ RDS encrypted at rest (AES-256)
✅ ElastiCache encrypted at rest + in-transit
✅ EBS volumes encrypted
✅ Secrets Manager for credentials

### 3. Access Control
✅ IAM RBAC for Kubernetes
✅ Pod-level IAM roles (IRSA)
✅ Network policies (optional)
✅ Non-root containers

### 4. Auditing
✅ CloudTrail for AWS API calls
✅ CloudWatch Logs for application logs
✅ Prometheus metrics for operational metrics

---

## Maintenance Schedule

### Daily
- [ ] Monitor pod CPU/memory
- [ ] Review application logs for errors
- [ ] Check HPA scaling decisions

### Weekly
- [ ] Review RDS backup status
- [ ] Check Kafka consumer lag
- [ ] Verify Redis replication

### Monthly
- [ ] Review infrastructure drift (`terraform plan`)
- [ ] Analyze costs and optimize
- [ ] Test disaster recovery

### Quarterly
- [ ] Upgrade Kubernetes
- [ ] Update dependencies (Kafka, Redis, Postgres)
- [ ] Load test with synthetic traffic
- [ ] Review security policies

---

## Resource Limits & Quotas

| Resource | Limit | Current | % Used |
|----------|-------|---------|---------|
| EKS Nodes | 6 | 3 | 50% |
| VPC Subnets | 20 | 6 | 30% |
| Security Groups | 500 | 8 | 1.6% |
| RDS Instances | 40 | 1 | 2.5% |
| NAT Gateways | 5 | 3 | 60% |
| Elastic IPs | 5 | 3 | 60% |

To increase quotas:
```bash
aws service-quotas request-service-quota-increase \
  --service-code eks \
  --quota-code arn:aws:eks:region:account:nodegroup/cluster-nodegroup-limit \
  --desired-value 20
```

---

## Cleanup & Destruction

⚠️ **WARNING: This will delete all resources and associated data**

```bash
# 1. Delete Kubernetes resources
helm uninstall axiomx-trading -n trading
kubectl delete namespace trading

# 2. Delete RDS backup (optional, keep for safety)
aws rds delete-db-instance \
  --db-instance-identifier axiomx-db \
  --skip-final-snapshot

# 3. Destroy Terraform infrastructure
cd infrastructure/terraform
terraform destroy
# Type 'yes' to confirm
```

## Support

For issues or questions:
1. Check logs: `kubectl logs -n trading -l app=trading-engine`
2. Review docs: `infrastructure/terraform/README.md`, `infrastructure/helm/README.md`
3. Check health: `curl http://localhost:8080/health`
4. View metrics: Port-forward Prometheus and check

---

**Last Updated**: 2024  
**Maintained By**: AxiomX Team  
**Version**: 1.0.0
