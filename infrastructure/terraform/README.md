# AxiomX Trading Engine - AWS Infrastructure Setup

This directory contains Terraform code to provision a complete AWS infrastructure for the AxiomX trading engine on EKS.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC                                │
│  10.0.0.0/16                                                   │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐   │
│  │    Public Subnets        │  │   Private Subnets        │   │
│  │    (3 AZs)               │  │   (3 AZs)                │   │
│  │  - NAT Gateways          │  │  - EKS Worker Nodes      │   │
│  │  - ALB (future)          │  │  - RDS Postgres          │   │
│  └──────────────────────────┘  │  - MSK Kafka             │   │
│                                │  - ElastiCache Redis     │   │
│                                └──────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │          EKS Cluster (Kubernetes 1.28)                  │  │
│  │  ┌────────────────────────────────────────────────┐    │  │
│  │  │  Node Group: 3 t3.medium instances (scalable)  │    │  │
│  │  │  - AxiomX trading engine pods                  │    │  │
│  │  │  - Prometheus, Grafana, Loki                   │    │  │
│  │  │  - Ingress Controller (NGINX)                  │    │  │
│  │  └────────────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ RDS Postgres │  │ MSK Kafka    │  │Redis Cache   │       │
│  │ Multi-AZ     │  │ 3 Brokers    │  │ Multi-AZ     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Terraform** >= 1.0
   ```bash
   terraform --version
   ```

2. **AWS CLI** configured with credentials
   ```bash
   aws configure
   # or set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY environment variables
   ```

3. **kubectl** for Kubernetes management
   ```bash
   kubectl version --client
   ```

4. **AWS Permissions**: Your IAM user needs permissions for:
   - EKS
   - EC2 (VPC, Security Groups, Subnets)
   - RDS
   - MSK
   - ElastiCache
   - IAM (Roles, Policies)
   - CloudWatch

## Variables

Create a `terraform.tfvars` file:

```hcl
# AWS Configuration
aws_region  = "us-east-1"
environment = "production"

# EKS Configuration
cluster_name       = "axiomx-trading"
cluster_version    = "1.28"
node_group_size    = 3
node_instance_type = "t3.medium"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# RDS Configuration
db_name     = "trading"
db_username = "axiomx"
db_password = "YOUR_SECURE_PASSWORD_HERE"  # Use AWS Secrets Manager in production

# Kafka Configuration
kafka_broker_node_count = 3
kafka_broker_instance_type = "kafka.t3.small"

# Redis Configuration
redis_node_type = "cache.t3.micro"
redis_num_cache_nodes = 3
```

**IMPORTANT**: Never commit secrets to version control. Use:
- Environment variables: `TF_VAR_db_password=value`
- AWS Secrets Manager
- Terraform Cloud/Enterprise
- `.tfvars` files excluded from git

## Deployment

### 1. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

This will:
- Download AWS provider
- Create `.terraform/` directory
- Initialize local state

### 2. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the output for all resources that will be created.

### 3. Apply Configuration

```bash
terraform apply tfplan
```

This will take ~15-20 minutes to complete:
- VPC and subnets: 2-3 minutes
- EKS cluster: 10-15 minutes
- RDS database: 5-10 minutes
- MSK Kafka: 10-15 minutes
- ElastiCache Redis: 3-5 minutes

### 4. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name axiomx-trading

# Verify connection
kubectl get nodes
```

## File Structure

```
terraform/
├── providers.tf          # AWS provider configuration
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── vpc.tf                # VPC, Subnets, NAT Gateway
├── eks.tf                # EKS cluster and worker nodes
├── rds.tf                # RDS Postgres database
├── msk.tf                # MSK Kafka cluster
├── elasticache.tf        # ElastiCache Redis cluster
├── terraform.tfvars      # (local) Variable values
├── README.md             # This file
└── .terraform/           # (local) Provider & state
```

## Outputs

After successful deployment, Terraform outputs:

```bash
terraform output
```

Key outputs:
- `eks_cluster_endpoint` - Kubernetes API endpoint
- `rds_endpoint` - Database connection string
- `msk_bootstrap_servers` - Kafka bootstrap servers
- `elasticache_endpoint` - Redis endpoint
- `kubeconfig_update_command` - Command to update local kubeconfig

## Kubernetes Deployment

After infrastructure is ready:

```bash
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f trading-engine-deployment.yaml
kubectl apply -f services.yaml
kubectl apply -f prometheus-deployment.yaml
```

## Helm Deployment (Alternative)

```bash
cd ../helm
helm repo add axiomx-trading ./trading-engine-chart
helm install axiomx-trading axiomx-trading/trading-engine \
  --namespace trading \
  --values values.yaml
```

## Security Best Practices

✅ **Implemented**:
- Multi-AZ deployment for high availability
- Encryption at rest (RDS, Redis, EBS)
- Encryption in transit (TLS for Kafka)
- Security groups restricting traffic
- Private subnets for databases
- IAM roles for EKS pods (IRSA)
- Secrets Manager for sensitive data
- RDS backup retention (7 days)

⚠️ **Additional Recommendations**:
- Enable VPC Flow Logs
- Use AWS WAF for ALB
- Enable GuardDuty for threat detection
- Use Secrets Manager for RDS password
- Enable audit logging for EKS
- Use ECR for container images with scanning
- Implement network policies in Kubernetes
- Use RBAC for Kubernetes access control

## Cost Optimization

Estimated monthly costs (US-East-1):
- EKS cluster: $73 (control plane)
- EC2 nodes (3×t3.medium): $60
- RDS (db.t3.medium, Multi-AZ): $180
- MSK (3×kafka.t3.small): $120
- ElastiCache (3×cache.t3.micro): $30
- Data transfer: $30-50

**Total**: ~$500-550/month

### Ways to Reduce Costs:
- Use Spot instances for worker nodes (50-70% savings)
- Reduce RDS instance size (t3.small)
- Use Kafka on EC2 instead of MSK
- Reduce Redis node count (single-node for dev)
- Use dev/staging smaller instances

## Troubleshooting

### EKS Cluster Creation Failing

```bash
# Check EKS service-linked role exists
aws iam list-roles | grep AWSServiceRoleForAmazonEKS

# Create if missing
aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
```

### Worker Nodes Not Ready

```bash
# Check node status
kubectl get nodes -o wide

# Get logs from node
aws ec2 describe-instances --region us-east-1 --filters Name=tag:Name,Values=axiomx-trading-nodes

# SSH to node (if public)
ssh -i ~/.ssh/aws-key.pem ec2-user@<NODE_IP>
```

### Database Connection Issues

```bash
# Test RDS connection
PGPASSWORD=<password> psql -h <rds-endpoint> -U axiomx -d trading

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### Kafka Connection Failed

```bash
# Get bootstrap servers
terraform output msk_bootstrap_servers

# Test connectivity from EKS node
kubectl run -it --rm debug --image=nicolaka/netcat --restart=Never -- bash
nc -zv <kafka-broker>:9092
```

## Cleanup

⚠️ **WARNING**: This will delete all resources!

```bash
terraform destroy
```

Terraform will ask for confirmation. Review what will be deleted.

Notes:
- RDS final snapshot will be created
- This takes 10-20 minutes
- Ensure no production data is lost

## Next Steps

1. **Deploy AxiomX Trading Engine**
   ```bash
   cd ../kubernetes
   # Deploy using kubectl or Helm
   ```

2. **Configure Monitoring**
   ```bash
   # Deploy Prometheus, Grafana, Loki
   kubectl apply -f monitoring/
   ```

3. **Setup CI/CD**
   - AWS CodePipeline for automated deployments
   - GitHub Actions integration
   - ArgoCD for GitOps

4. **Load Testing**
   ```bash
   # Use k6 to load test the trading engine
   k6 run load-test.js
   ```

## Support & Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

