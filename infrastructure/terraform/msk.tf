# MSK Security Group
resource "aws_security_group" "msk" {
  name        = "${var.cluster_name}-msk-sg"
  description = "Security group for MSK Kafka cluster"
  vpc_id      = aws_vpc.main.id

  # Allow Kafka broker communication from EKS nodes
  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "Kafka plaintext"
  }

  ingress {
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "Kafka TLS"
  }

  # Allow broker-to-broker communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-msk-sg"
  }
}

# MSK Subnet Group
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.cluster_name}-kafka"
  kafka_version          = "3.5.0"
  number_of_broker_nodes = var.kafka_broker_node_count

  broker_node_group_info {
    instance_type   = var.kafka_broker_instance_type
    client_subnets  = aws_subnet.private[*].id
    security_groups = [aws_security_group.msk.id]
    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }

    cloudwatch_logs_enabled = true
    cloudwatch_logs_log_group = aws_cloudwatch_log_group.msk.name

    log_delivery_info {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
      firehose {
        enabled = false
      }
      s3 {
        enabled = false
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = true
    }
    encryption_at_rest {
      enabled = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  tags = {
    Name = "${var.cluster_name}-kafka"
  }
}

# CloudWatch Log Group for MSK
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.cluster_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-msk-logs"
  }
}

# IAM Policy for MSK Access from EKS pods
resource "aws_iam_policy" "msk_access" {
  name        = "${var.cluster_name}-msk-access"
  description = "Policy for EKS pods to access MSK Kafka cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:*"
        ]
        Resource = aws_msk_cluster.main.arn
      }
    ]
  })
}
