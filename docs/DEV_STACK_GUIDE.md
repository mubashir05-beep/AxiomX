# Complete Development Stack Guide

This guide shows how **Devbox**, **Taskfile**, **Docker**, **Kubernetes**, and **Namespaces** work together.

---

## **Visual Overview**

```
┌─────────────────────────────────────────────────────┐
│ YOUR LAPTOP                                         │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ DEVBOX (Tool Isolation)                     │   │
│ │ Provides: Go, Terraform, kubectl, helm      │   │
│ │ Purpose: Consistent dev environment         │   │
│ └─────────────────────────────────────────────┘   │
│                    ↓ USES ↓                        │
│ ┌─────────────────────────────────────────────┐   │
│ │ TASKFILE (Command Automation)               │   │
│ │ Shortcut: "task deploy" instead of 5 cmds   │   │
│ │ Purpose: Developer productivity             │   │
│ └─────────────────────────────────────────────┘   │
│                    ↓ RUNS ↓                        │
│ ┌─────────────────────────────────────────────┐   │
│ │ DOCKER (Container Build)                    │   │
│ │ Creates: axiomx-trading-engine:latest       │   │
│ │ Purpose: Package app + dependencies         │   │
│ └─────────────────────────────────────────────┘   │
│                    ↓ DEPLOYS TO ↓                  │
└─────────────────────────────────────────────────────┘
                     ↓ ↓ ↓
┌─────────────────────────────────────────────────────┐
│ KUBERNETES CLUSTER (Local or AWS)                  │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ NAMESPACE: trading (Isolation)              │   │
│ │ ├─ Pod: trading-engine                      │   │
│ │ ├─ Pod: postgres                            │   │
│ │ └─ Pod: redis                               │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ NAMESPACE: monitoring                       │   │
│ │ ├─ Pod: prometheus                          │   │
│ │ └─ Pod: grafana                             │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## **Installation & Setup**

### **Step 1: Install Devbox**

**Windows:**
```powershell
# Using Scoop
scoop install devbox

# OR download from: https://www.jetify.com/devbox/docs/installing_devbox/
```

**Verify:**
```powershell
devbox version
```

### **Step 2: Install Taskfile**

**Windows:**
```powershell
# Using Chocolatey
choco install go-task

# OR using Scoop
scoop install task

# OR download from: https://taskfile.dev/installation/
```

**Verify:**
```powershell
task --version
```

### **Step 3: Activate Devbox Environment**

```powershell
cd C:\Users\Mubashir\Documents\GitHub\AxiomX

# Enter isolated environment (activates devbox.json)
devbox shell

# You'll see:
# 🚀 AxiomX Development Environment Activated!
# Now all tools are available: go, terraform, kubectl, helm

# Verify tools
go version          # Go 1.23.5 (from devbox, not global!)
terraform version   # Terraform 1.7.4
kubectl version     # kubectl 1.28.0
helm version        # Helm 3.14.0
```

---

## **Daily Workflow Examples**

### **Example 1: Start Local Development**

**❌ WITHOUT Taskfile (manual):**
```powershell
docker-compose up -d postgres redis kafka
sleep 5
$env:DATABASE_URL = "postgres://..."
$env:KAFKA_BROKERS = "kafka:9092"
$env:REDIS_ADDR = "redis:6379"
go run cmd/api/main.go
```

**✅ WITH Taskfile (automated):**
```powershell
task dev
```

That's it! One command does everything.

---

### **Example 2: Deploy to Local Kubernetes**

**❌ WITHOUT Taskfile:**
```powershell
# 1. Create cluster
kind create cluster --name axiomx-local --config infrastructure/local/kind-config.yaml

# 2. Build image
docker build -t axiomx-trading-engine:latest .

# 3. Load into Kind
kind load docker-image axiomx-trading-engine:latest --name axiomx-local

# 4. Create namespace
kubectl create namespace trading

# 5. Deploy dependencies
kubectl apply -f infrastructure/local/dependencies.yaml

# 6. Wait for ready
sleep 30

# 7. Deploy app
kubectl apply -f infrastructure/local/trading-engine-local.yaml

# 8. Check status
kubectl get pods -n trading
```

**✅ WITH Taskfile:**
```powershell
task local-start
```

One command replaces 8 steps!

---

### **Example 3: Test Helm Version Control**

**Deploy v1:**
```powershell
task helm-install
# Output: ✅ Installed as revision 1
```

**Upgrade to v2:**
```powershell
# Edit infrastructure/helm/values-local.yaml first
# Change: replicaCount: 2 → 3

task helm-upgrade
# Output: ✅ Upgraded to revision 2
```

**Rollback to v1:**
```powershell
task helm-rollback
# Output: ⏪ Rolled back to revision 1
```

**View history:**
```powershell
task helm-history
# Output:
# REVISION  UPDATED                   STATUS      CHART
# 1         Wed Mar 05 10:00:00 2026  SUPERSEDED  trading-engine-1.0.0
# 2         Wed Mar 05 10:15:00 2026  SUPERSEDED  trading-engine-1.0.0
# 3         Wed Mar 05 10:20:00 2026  DEPLOYED    trading-engine-1.0.0
```

---

### **Example 4: Deploy to AWS Production**

**Complete workflow:**
```powershell
# 1. Initialize infrastructure (first time only)
task infra-init

# 2. Plan changes (preview)
task infra-plan

# 3. Apply infrastructure (creates EKS, RDS, etc.)
task infra-apply

# 4. Connect kubectl to AWS
task infra-connect

# 5. Deploy application
task deploy-aws

# 6. Check status
task aws-status

# 7. View logs
task aws-logs
```

All automated with Taskfile!

---

## **Isolation Comparison**

### **Scenario: You work on 3 projects**

```
WITHOUT Devbox:
Your Laptop:
├─ Global Go 1.20 (old project needs this)
├─ Global Terraform 0.12 (old)
├─ Try to install Go 1.23 → BREAKS OLD PROJECT!
└─ Manual env var juggling

WITH Devbox:
Your Laptop:
├─ Project A/
│  └─ devbox shell → Go 1.20, Terraform 0.12
├─ Project B/
│  └─ devbox shell → Go 1.21, Terraform 1.5
└─ AxiomX/
   └─ devbox shell → Go 1.23, Terraform 1.7

No conflicts! Each project isolated!
```

### **Scenario: Multiple environments in Kubernetes**

```
WITHOUT Namespaces:
All pods mixed in default namespace:
├─ trading-engine-dev (dev version)
├─ trading-engine-prod (prod version)
├─ postgres-dev (conflicts with prod?)
└─ postgres-prod (same name error!)

WITH Namespaces:
├─ Namespace: dev
│  ├─ trading-engine
│  └─ postgres
├─ Namespace: staging
│  ├─ trading-engine
│  └─ postgres
└─ Namespace: prod
   ├─ trading-engine
   └─ postgres

No conflicts! Same names in different namespaces!
```

---

## **Common Commands Reference**

```powershell
# ===== DEVBOX =====
devbox shell                    # Enter isolated environment
devbox run setup                # Run setup script
devbox add package-name         # Add new tool
devbox rm package-name          # Remove tool

# ===== TASKFILE =====
task --list                     # Show all tasks
task dev                        # Start development
task test                       # Run tests
task local-start                # Start local K8s
task local-stop                 # Stop local K8s
task helm-install               # Deploy with Helm
task helm-upgrade               # Upgrade deployment
task helm-rollback              # Rollback deployment
task deploy-aws                 # Deploy to AWS

# ===== KUBERNETES NAMESPACES =====
kubectl get namespaces          # List all namespaces
kubectl get pods -n trading     # Get pods in 'trading' namespace
kubectl logs -n trading pod-name # View logs
kubectl exec -it -n trading pod-name -- /bin/sh  # SSH into pod
kubectl delete namespace trading # Delete namespace (and all resources!)

# ===== SWITCHING CONTEXTS =====
# Local cluster
kubectl config use-context kind-axiomx-local

# AWS cluster
kubectl config use-context arn:aws:eks:us-east-1:123456789012:cluster/axiomx-prod
```

---

## **Quick Start Workflow**

```powershell
# 1. Enter isolated dev environment
cd C:\Users\Mubashir\Documents\GitHub\AxiomX
devbox shell

# 2. See available tasks
task --list

# 3. Start local Kubernetes
task local-start

# 4. Check status
task local-status

# 5. View logs
task local-logs

# 6. Access app
task local-port-forward
# Visit: http://localhost:8080/health

# 7. Make changes, test Helm upgrade
# Edit: infrastructure/helm/values-local.yaml
task helm-upgrade

# 8. Rollback if broken
task helm-rollback

# 9. Cleanup
task local-stop
```

---

## **Key Differences Summary**

| Tool | Layer | Purpose | Scope |
|------|-------|---------|-------|
| **Devbox** | Local laptop | Tool version management | Your dev tools (Go, kubectl, etc.) |
| **Taskfile** | Local laptop | Command automation | Your workflow shortcuts |
| **Docker** | Containerization | Application packaging | Your app + its runtime deps |
| **K8s Namespace** | Orchestration | Resource isolation | Running apps in cluster |
| **Helm** | Orchestration | Deployment versioning | K8s manifest management |

**They all work together:**
1. **Devbox** gives you the tools
2. **Taskfile** automates using those tools
3. **Docker** packages your app
4. **Kubernetes** runs the containers
5. **Namespaces** keep things organized
6. **Helm** manages versions

---

## **Next Steps**

Try it yourself:
```powershell
# 1. Install Devbox & Taskfile (see above)

# 2. Activate environment
devbox shell

# 3. Start local cluster
task local-start

# 4. Experiment with Helm
task helm-install
task helm-history
task helm-upgrade
task helm-rollback
```

You now have a **complete production-grade workflow** for local development!
