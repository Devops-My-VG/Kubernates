# =========================================================
# ElastiCache Serverless Cache for Valkey
# =========================================================
# Migration from Redis to Valkey Serverless
# - 33% cheaper than Redis OSS Serverless
# - Auto-scaling compute and storage
# - No node management required
# =========================================================

# =========================================================
# SECURITY GROUP FOR VALKEY SERVERLESS
# =========================================================

resource "aws_security_group" "valkey_sg" {
  name        = "${var.cluster_name}-valkey-sg"
  description = "Security group for Valkey Serverless cache"
  vpc_id      = var.vpc_id

  # Allow Valkey access from ECS cluster
  ingress {
    description     = "Valkey from ECS instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # Allow Valkey from Lambda (if needed)
  ingress {
    description = "Valkey from Lambda/Applications"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-valkey-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Engine      = "Valkey-Serverless"
  }
}

# =========================================================
# AUTH TOKEN FOR VALKEY SERVERLESS
# =========================================================

resource "random_password" "valkey_auth_token" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "valkey_auth_token" {
  name                    = "${var.cluster_name}/valkey/auth-token"
  description             = "Auth token for Valkey Serverless cache"
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.cluster_name}-valkey-auth-token"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "valkey_auth_token" {
  secret_id      = aws_secretsmanager_secret.valkey_auth_token.id
  secret_string  = random_password.valkey_auth_token.result
  version_stages = ["AWSCURRENT"]
}

# =========================================================
# VALKEY SERVERLESS CACHE
# =========================================================

resource "aws_elasticache_serverless_cache" "valkey" {
  name                 = "${var.cluster_name}-valkey"
  engine               = "valkey"
  major_engine_version = split(".", var.valkey_engine_version)[0]

  # Serverless cache scaling configuration
  cache_usage_limits {
    data_storage {
      maximum = var.data_storage_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.ecpu_per_second
    }
  }

  # Security configuration
  security_group_ids = [aws_security_group.valkey_sg.id]
  subnet_ids         = var.cache_subnets

  # User management with AUTH
  user_group_id = aws_elasticache_user_group.valkey_default.id

  # Backup configuration for Serverless
  snapshot_retention_limit = var.snapshot_retention_limit
  daily_snapshot_time      = var.daily_snapshot_time

  tags = {
    Name        = "${var.cluster_name}-valkey"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Engine      = "Valkey-Serverless"
    CostCenter  = var.cost_center
  }

  depends_on = [aws_elasticache_user_group.valkey_default]
}

# =========================================================
# VALKEY USER AND USER GROUP
# =========================================================

resource "aws_elasticache_user" "valkey_default" {
  engine        = "valkey"
  user_id       = "${var.cluster_name}-default-user"
  user_name     = "default"
  access_string = "on ~* +@all"
  passwords     = [random_password.valkey_auth_token.result]

  tags = {
    Name        = "${var.cluster_name}-valkey-default-user"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_elasticache_user_group" "valkey_default" {
  engine        = "valkey"
  user_group_id = "${var.cluster_name}-default-group"
  user_ids      = [aws_elasticache_user.valkey_default.user_id]

  tags = {
    Name        = "${var.cluster_name}-valkey-default-group"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =========================================================
# SNS TOPIC FOR VALKEY ALERTS
# =========================================================

resource "aws_sns_topic" "valkey_notifications" {
  name              = "${var.cluster_name}-valkey-notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.cluster_name}-valkey-notifications"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =========================================================
# CLOUDWATCH ALARMS FOR VALKEY SERVERLESS
# =========================================================

resource "aws_cloudwatch_metric_alarm" "valkey_cpu_utilization" {
  alarm_name          = "${var.cluster_name}-valkey-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when Valkey CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.valkey_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = aws_elasticache_serverless_cache.valkey.id
  }

  tags = {
    Name        = "${var.cluster_name}-valkey-cpu-high"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "valkey_memory_utilization" {
  alarm_name          = "${var.cluster_name}-valkey-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Alert when Valkey memory exceeds 90%"
  alarm_actions       = [aws_sns_topic.valkey_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = aws_elasticache_serverless_cache.valkey.id
  }

  tags = {
    Name        = "${var.cluster_name}-valkey-memory-high"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "valkey_connection_count" {
  alarm_name          = "${var.cluster_name}-valkey-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "Alert when Valkey connections exceed 1000"
  alarm_actions       = [aws_sns_topic.valkey_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = aws_elasticache_serverless_cache.valkey.id
  }

  tags = {
    Name        = "${var.cluster_name}-valkey-connections-high"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "valkey_network_bytes_in" {
  alarm_name          = "${var.cluster_name}-valkey-network-in-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkBytesIn"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1048576" # 1 MB
  alarm_description   = "Alert when Valkey network traffic exceeds 1MB/sec"
  alarm_actions       = [aws_sns_topic.valkey_notifications.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = aws_elasticache_serverless_cache.valkey.id
  }

  tags = {
    Name        = "${var.cluster_name}-valkey-network-in-high"
    Environment = var.environment
  }
}

# =========================================================
# CLOUDWATCH LOG GROUP FOR VALKEY
# =========================================================

resource "aws_cloudwatch_log_group" "valkey_logs" {
  name              = "/aws/elasticache/valkey/${var.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.cluster_name}-valkey-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =========================================================
# CLOUDWATCH DASHBOARD FOR VALKEY
# =========================================================

resource "aws_cloudwatch_dashboard" "valkey" {
  dashboard_name = "${var.cluster_name}-valkey-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseMemoryUsagePercentage", { stat = "Average" }],
            [".", "NetworkBytesIn", { stat = "Sum" }],
            [".", "NetworkBytesOut", { stat = "Sum" }],
            [".", "CurrConnections", { stat = "Average" }],
            [".", "NewConnections", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Valkey Serverless Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CacheHits", { stat = "Sum" }],
            [".", "CacheMisses", { stat = "Sum" }],
            [".", "Evictions", { stat = "Sum" }],
            [".", "ReplicationLag", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Valkey Performance Metrics"
        }
      }
    ]
  })
}
