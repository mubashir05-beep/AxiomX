#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-axiomx-prod}"
NAMESPACE="${NAMESPACE:-trading}"
ENVIRONMENT="${ENVIRONMENT:-production}"
TERRAFORM_DIR="infrastructure/terraform"
KUBE_DIR="infrastructure/kubernetes"
HELM_DIR="infrastructure/helm"

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Install from: https://aws.amazon.com/cli/"
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Install from: https://www.terraform.io/downloads"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Install from: https://kubernetes.io/docs/tasks/tools/"
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        log_error "Helm not found. Install from: https://helm.sh/docs/intro/install/"
    fi
    
    log_success "All prerequisites installed"
}

# Configure AWS credentials
configure_aws() {
    log_info "Configuring AWS..."
    
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        log_warn "AWS credentials not set. Running 'aws configure'..."
        aws configure
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_success "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Phase 1: Provision infrastructure with Terraform
phase_1_terraform() {
    log_info "Phase 1: Provisioning AWS Infrastructure with Terraform"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform.tfvars ]; then
        log_warn "terraform.tfvars not found. Creating with defaults..."
        cat > terraform.tfvars << EOF
aws_region          = "$AWS_REGION"
environment         = "$ENVIRONMENT"
cluster_name        = "$CLUSTER_NAME"
instance_class      = "t3.medium"
db_instance_class   = "db.t3.medium"
db_username         = "axiomadmin"
db_password         = "$(openssl rand -base64 32)"
kafka_broker_count  = 3
redis_node_type     = "cache.t3.micro"
EOF
        log_success "Created terraform.tfvars"
    fi
    
    # Plan
    log_info "Planning infrastructure changes..."
    terraform plan -out=tfplan
    
    # Apply
    log_info "Applying infrastructure changes (this may take 15-20 minutes)..."
    terraform apply tfplan
    
    # Capture outputs
    log_success "Infrastructure provisioned successfully"
    terraform output > outputs.txt
    
    cd - > /dev/null
}

# Phase 2: Configure Kubernetes
phase_2_kubernetes_config() {
    log_info "Phase 2: Configuring Kubernetes Access"
    
    # Update kubeconfig
    log_info "Updating kubeconfig..."
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
    
    # Verify cluster connectivity
    log_info "Verifying cluster connectivity..."
    kubectl cluster-info
    
    # Check node status
    log_info "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready node --all --timeout=300s || log_warn "Nodes not fully ready yet"
    
    kubectl get nodes
    log_success "Kubernetes cluster configured"
}

# Phase 3: Create namespace and secrets
phase_3_namespace_secrets() {
    log_info "Phase 3: Creating Namespace and Secrets"
    
    # Read Terraform outputs
    cd "$TERRAFORM_DIR"
    
    DB_ENDPOINT=$(terraform output -raw rds_address 2>/dev/null)
    DB_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "5432")
    DB_USER="axiomadmin"
    DB_PASSWORD=$(terraform output -raw rds_password 2>/dev/null)
    
    MSK_BOOTSTRAP=$(terraform output -raw msk_bootstrap_servers 2>/dev/null)
    
    REDIS_ENDPOINT=$(terraform output -raw elasticache_endpoint 2>/dev/null)
    REDIS_PORT=$(terraform output -raw elasticache_port 2>/dev/null || echo "6379")
    REDIS_PASSWORD=$(terraform output -raw elasticache_auth_token 2>/dev/null)
    
    cd - > /dev/null
    
    # Create namespace
    log_info "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets
    log_info "Creating secrets..."
    
    DATABASE_URL="postgres://$DB_USER:$DB_PASSWORD@$DB_ENDPOINT:$DB_PORT/trading?sslmode=require"
    
    kubectl create secret generic trading-secrets \
        --from-literal=DATABASE_URL="$DATABASE_URL" \
        --from-literal=KAFKA_BROKERS="$MSK_BOOTSTRAP" \
        --from-literal=REDIS_ADDR="$REDIS_ENDPOINT:$REDIS_PORT" \
        --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD" \
        --namespace "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Namespace and secrets created"
}

# Phase 4: Deploy application
phase_4_deploy_application() {
    log_info "Phase 4: Deploying Application"
    
    # Option to use Helm or kubectl
    echo -e "${YELLOW}Choose deployment method:${NC}"
    echo "1) Helm (recommended)"
    echo "2) kubectl apply"
    read -p "Enter choice (1 or 2): " deployment_choice
    
    if [ "$deployment_choice" = "1" ]; then
        log_info "Deploying with Helm..."
        
        # Lint chart
        log_info "Linting Helm chart..."
        helm lint "$HELM_DIR"
        
        # Install/upgrade
        log_info "Installing/upgrading Helm release..."
        helm upgrade --install axiomx-trading "$HELM_DIR" \
            --namespace "$NAMESPACE" \
            --values "$HELM_DIR/values.yaml" \
            --wait \
            --timeout=10m
        
        # Show status
        helm status axiomx-trading -n "$NAMESPACE"
        
    else
        log_info "Deploying with kubectl..."
        
        # Apply ConfigMap
        kubectl apply -f "$KUBE_DIR/secrets-configmap.yaml" --namespace "$NAMESPACE"
        
        # Apply deployment
        kubectl apply -f "$KUBE_DIR/trading-engine-deployment.yaml" --namespace "$NAMESPACE"
        
        # Apply services & HPA
        kubectl apply -f "$KUBE_DIR/services-hpa.yaml" --namespace "$NAMESPACE"
    fi
    
    # Wait for deployment
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/trading-engine -n "$NAMESPACE" --timeout=10m
    
    log_success "Application deployed successfully"
}

# Phase 5: Verification
phase_5_verification() {
    log_info "Phase 5: Verifying Deployment"
    
    # Check pods
    log_info "Checking pods..."
    kubectl get pods -n "$NAMESPACE" -o wide
    
    # Check services
    log_info "Checking services..."
    kubectl get svc -n "$NAMESPACE"
    
    # Check HPA
    log_info "Checking HPA..."
    kubectl get hpa -n "$NAMESPACE"
    
    # Check metrics
    log_info "Waiting for metrics (may take 1-2 minutes)..."
    sleep 30
    kubectl get hpa -n "$NAMESPACE"
    
    log_success "Deployment verification complete"
}

# Phase 6: Post-deployment
phase_6_post_deployment() {
    log_info "Phase 6: Post-Deployment Configuration"
    
    echo ""
    echo -e "${GREEN}========== Deployment Complete ==========${NC}"
    echo ""
    echo "Use the following commands to interact with your cluster:"
    echo ""
    echo -e "${BLUE}# Forward API port:${NC}"
    echo "kubectl port-forward -n $NAMESPACE svc/trading-engine 8080:8080"
    echo ""
    echo -e "${BLUE}# View logs:${NC}"
    echo "kubectl logs -n $NAMESPACE -l app=trading-engine -f"
    echo ""
    echo -e "${BLUE}# Check metrics:${NC}"
    echo "kubectl get hpa -n $NAMESPACE -w"
    echo ""
    echo -e "${BLUE}# Scale deployment:${NC}"
    echo "kubectl scale deployment trading-engine -n $NAMESPACE --replicas=5"
    echo ""
    echo -e "${BLUE}# Test API health:${NC}"
    echo "curl http://localhost:8080/health"
    echo ""
    echo -e "${GREEN}==========================================${NC}"
}

# Main execution
main() {
    log_info "AxiomX Trading Engine Cluster Deployment"
    log_info "Region: $AWS_REGION, Cluster: $CLUSTER_NAME, Namespace: $NAMESPACE"
    
    # Run phases
    check_prerequisites
    configure_aws
    
    phase_1_terraform
    phase_2_kubernetes_config
    phase_3_namespace_secrets
    phase_4_deploy_application
    phase_5_verification
    phase_6_post_deployment
    
    log_success "Full deployment completed!"
}

# Show menu if interactive
if [ $# -eq 0 ]; then
    echo -e "${BLUE}AxiomX Cluster Deployment Script${NC}"
    echo ""
    echo "This script will deploy the trading engine to AWS EKS."
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION=$AWS_REGION"
    echo "  CLUSTER_NAME=$CLUSTER_NAME"
    echo "  NAMESPACE=$NAMESPACE"
    echo "  ENVIRONMENT=$ENVIRONMENT"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

main
