output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "eks_cluster_auth_token" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "eks_node_group_id" {
  description = "EKS worker node group ID"
  value       = aws_eks_node_group.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS database address (without port)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.main.arn
}

output "msk_bootstrap_servers" {
  description = "MSK Kafka bootstrap servers for plaintext connection"
  value       = aws_msk_cluster.main.bootstrap_servers
}

output "msk_bootstrap_servers_tls" {
  description = "MSK Kafka bootstrap servers for TLS connection"
  value       = aws_msk_cluster.main.bootstrap_servers_tls
}

output "msk_cluster_id" {
  description = "MSK cluster ID"
  value       = aws_msk_cluster.main.cluster_id
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis cluster endpoint address"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "elasticache_port" {
  description = "ElastiCache Redis cluster port"
  value       = aws_elasticache_cluster.main.port
}

output "elasticache_auth_token_secret" {
  description = "Secrets Manager secret containing Redis auth token"
  value       = aws_secretsmanager_secret.redis_token.name
}

output "kubeconfig_update_command" {
  description = "Command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
