# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name        = "${var.cluster_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-elasticache-sg"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.cluster_name}-cache-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.cluster_name}-cache-subnet"
  }
}

# ElastiCache Redis Cluster (Multi-AZ with automatic failover)
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.cluster_name}-cache"
  engine               = "redis"
  node_type           = var.redis_node_type
  num_cache_nodes     = var.redis_num_cache_nodes
  parameter_group_name = "default.redis7"
  engine_version      = "7.0"
  port                = 6379

  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]
  automatic_failover_enabled = true
  multi_az_enabled          = true

  # Enable encryption at rest and in transit
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                = random_password.redis_token.result

  # Enable automatic backups
  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"

  # Enable automatic software updates
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:04:00-sun:05:00"

  # Enable CloudWatch logs
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Name = "${var.cluster_name}-cache"
  }
}

# CloudWatch Log Group for ElastiCache
resource "aws_cloudwatch_log_group" "elasticache" {
  name              = "/aws/elasticache/${var.cluster_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-elasticache-logs"
  }
}

# Generate random token for Redis AUTH
resource "random_password" "redis_token" {
  length  = 32
  special = true
}

# Store Redis auth token in Secrets Manager
resource "aws_secretsmanager_secret" "redis_token" {
  name                    = "${var.cluster_name}/redis/auth-token"
  description             = "ElastiCache Redis authentication token"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.cluster_name}-redis-token"
  }
}

resource "aws_secretsmanager_secret_version" "redis_token" {
  secret_id     = aws_secretsmanager_secret.redis_token.id
  secret_string = random_password.redis_token.result
}
