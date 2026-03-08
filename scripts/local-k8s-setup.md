# Local Kubernetes Setup (No AWS Required)

## Prerequisites Checklist

- ✅ Docker installed and running
- ✅ kubectl installed
- ⬜ Kind (Kubernetes in Docker) - we'll install this
- ⬜ Helm - we'll install this

---

## Step 1: Install Kind (Local Kubernetes)

**Kind** = Kubernetes in Docker (runs K8s cluster on your laptop)

```powershell
# Install Kind using Chocolatey
choco install kind

# OR manually download:
# https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager

# Verify installation
kind version
```

---

## Step 2: Install Helm

```powershell
# Install Helm using Chocolatey
choco install kubernetes-helm

# OR manually download:
# https://github.com/helm/helm/releases

# Verify installation
helm version
```

---

## Step 3: Create Local Kubernetes Cluster

```powershell
# Create a local cluster named "axiomx-local"
kind create cluster --name axiomx-local --config infrastructure/local/kind-config.yaml

# This creates:
# - Local Kubernetes cluster running in Docker
# - Automatically sets up kubeconfig
# - Takes ~2 minutes

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

---

## Step 4: Deploy Trading Engine Locally

```powershell
# Create namespace
kubectl create namespace trading

# Start dependencies first (PostgreSQL, Redis, Kafka)
kubectl apply -f infrastructure/local/dependencies.yaml

# Wait for dependencies to be ready (~30 seconds)
kubectl wait --for=condition=ready pod -l app=postgres -n trading --timeout=120s

# Deploy trading engine
kubectl apply -f infrastructure/local/trading-engine-local.yaml

# Check status
kubectl get pods -n trading
```

---

## Step 5: Access Your Application

```powershell
# Port forward to access locally
kubectl port-forward -n trading svc/trading-engine 8080:8080

# Open browser or curl: http://localhost:8080/health
# Should return: {"status":"ok"}
```

---

## Step 6: View Logs & Debug

```powershell
# See all pods
kubectl get pods -n trading

# View trading engine logs
kubectl logs -n trading -l app=trading-engine --follow

# SSH into pod
kubectl exec -it -n trading $(kubectl get pod -n trading -l app=trading-engine -o jsonpath='{.items[0].metadata.name}') -- /bin/sh
```

---

## Step 7: Test Helm Locally

```powershell
# Install using Helm chart
cd infrastructure/helm

helm install axiomx-trading . \
  --namespace trading \
  --values values-local.yaml

# Upgrade
helm upgrade axiomx-trading . --namespace trading

# Rollback
helm rollback axiomx-trading 1

# Check history
helm history axiomx-trading --namespace trading
```

---

## Cleanup

```powershell
# Delete namespace
kubectl delete namespace trading

# Delete cluster
kind delete cluster --name axiomx-local
```

---

## Differences: Local vs AWS

| Feature | Local (Kind) | AWS (EKS) |
|---------|-------------|-----------|
| **Cost** | FREE | ~$150/month |
| **Speed** | 2 minutes setup | 30 minutes setup |
| **Resources** | Your laptop RAM/CPU | AWS EC2 instances |
| **Database** | SQLite or local Postgres | RDS Multi-AZ |
| **Kafka** | Single broker in Docker | MSK 3-broker cluster |
| **Persistence** | Deleted when cluster stops | Permanent storage |
| **Use Case** | Development & testing | Production |

---

## Next: Choose Your Path

**Path A: Keep Testing Locally**
- Edit `infrastructure/local/trading-engine-local.yaml`
- Run `kubectl apply -f ...` to update
- Fast iteration, no costs

**Path B: Move to AWS**
- Follow main DEPLOYMENT_GUIDE.md
- Run `terraform apply` to create real infrastructure
- Get production-ready setup
