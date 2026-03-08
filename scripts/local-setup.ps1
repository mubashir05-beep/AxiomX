# Quick Start Script for Local Kubernetes Development
# Run this to set up everything automatically

Write-Host "`n=== AxiomX Local Kubernetes Setup ===" -ForegroundColor Cyan
Write-Host "This script will set up a local Kubernetes cluster for development`n" -ForegroundColor Gray

# Step 1: Check prerequisites
Write-Host "[1/7] Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Docker installed" -ForegroundColor Green
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    Write-Host "  [OK] Docker is running" -ForegroundColor Green
} else {
    Write-Host "  [X] Docker not found. Install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Check kubectl
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] kubectl installed" -ForegroundColor Green
} else {
    Write-Host "  [X] kubectl not found. Installing..." -ForegroundColor Yellow
    choco install kubernetes-cli -y
}

# Check Kind
if (Get-Command kind -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Kind installed" -ForegroundColor Green
} else {
    Write-Host "  [X] Kind not found." -ForegroundColor Red
    Write-Host "`nKind is required to create a local Kubernetes cluster." -ForegroundColor Yellow
    Write-Host "`nTo install Kind, run this command in a NEW PowerShell window:" -ForegroundColor Cyan
    Write-Host "  .\install-tools.ps1" -ForegroundColor White
    Write-Host "`nThen close that window, open a new PowerShell, and run:" -ForegroundColor Cyan
    Write-Host "  .\local-setup.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Check Helm
if (Get-Command helm -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] Helm installed" -ForegroundColor Green
} else {
    Write-Host "  [!] Helm not found (optional)" -ForegroundColor Yellow
    Write-Host "    Run .\install-tools.ps1 to install Helm" -ForegroundColor Gray
}

# Step 2: Build Docker image
Write-Host "`n[2/7] Building Trading Engine Docker image..." -ForegroundColor Yellow
docker build -t axiomx-trading-engine:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Docker image built successfully" -ForegroundColor Green

# Step 3: Create Kind cluster
Write-Host "`n[3/7] Creating local Kubernetes cluster..." -ForegroundColor Yellow
kind get clusters 2>&1 | Select-String "axiomx-local" | Out-Null
if ($?) {
    Write-Host "  [!] Cluster 'axiomx-local' already exists" -ForegroundColor Yellow
    $recreate = Read-Host "  Delete and recreate? (y/n)"
    if ($recreate -eq "y") {
        kind delete cluster --name axiomx-local
        kind create cluster --name axiomx-local --config infrastructure/local/kind-config.yaml
    }
} else {
    kind create cluster --name axiomx-local --config infrastructure/local/kind-config.yaml
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [X] Failed to create cluster" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Cluster created successfully" -ForegroundColor Green

# Step 4: Load Docker image into Kind
Write-Host "`n[4/7] Loading Docker image into Kind cluster..." -ForegroundColor Yellow
kind load docker-image axiomx-trading-engine:latest --name axiomx-local
Write-Host "  [OK] Image loaded into cluster" -ForegroundColor Green

# Step 5: Create namespace
Write-Host "`n[5/7] Creating 'trading' namespace..." -ForegroundColor Yellow
kubectl create namespace trading 2>$null
Write-Host "  [OK] Namespace ready" -ForegroundColor Green

# Step 6: Deploy dependencies (PostgreSQL, Redis, Kafka)
Write-Host "`n[6/7] Deploying dependencies (PostgreSQL, Redis, Kafka)..." -ForegroundColor Yellow
kubectl apply -f infrastructure/local/dependencies.yaml
Write-Host "  [WAIT] Waiting for dependencies to be ready (this may take 1-2 minutes)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Wait for pods to be ready
$maxWait = 120
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $notReady = kubectl get pods -n trading --no-headers | Where-Object { $_ -notmatch "Running|Completed" }
    if (-not $notReady) {
        break
    }
    Write-Host "  [WAIT] Still waiting... ($elapsed / $maxWait seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    $elapsed += 10
}

kubectl get pods -n trading
Write-Host "  [OK] Dependencies deployed" -ForegroundColor Green

# Step 7: Deploy trading engine
Write-Host "`n[7/7] Deploying Trading Engine..." -ForegroundColor Yellow
kubectl apply -f infrastructure/local/trading-engine-local.yaml

Write-Host "`n  [WAIT] Waiting for trading engine to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 5
kubectl wait --for=condition=ready pod -l app=trading-engine -n trading --timeout=120s

Write-Host "`n[SUCCESS] Setup complete!" -ForegroundColor Green

# Display status
Write-Host "`n=== Cluster Status ===" -ForegroundColor Cyan
kubectl get pods -n trading

Write-Host "`n=== Access Instructions ===" -ForegroundColor Cyan
Write-Host "1. View logs:" -ForegroundColor White
Write-Host "   kubectl logs -n trading -l app=trading-engine --follow" -ForegroundColor Gray

Write-Host "`n2. Port forward to access locally:" -ForegroundColor White
Write-Host "   kubectl port-forward -n trading svc/trading-engine 8080:8080" -ForegroundColor Gray
Write-Host "   Then visit: http://localhost:8080/health" -ForegroundColor Gray

Write-Host "`n3. SSH into pod:" -ForegroundColor White
Write-Host "   kubectl exec -it -n trading deployment/trading-engine -- /bin/sh" -ForegroundColor Gray

Write-Host "`n4. View all resources:" -ForegroundColor White
Write-Host "   kubectl get all -n trading" -ForegroundColor Gray

Write-Host "`n5. Delete everything:" -ForegroundColor White
Write-Host "   kind delete cluster --name axiomx-local" -ForegroundColor Gray

Write-Host "`nSee local-k8s-setup.md for detailed instructions`n" -ForegroundColor Yellow
