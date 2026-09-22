# ElastiCache Redis Module for Ecommerce Application

# Cache Subnet Group
resource "aws_elasticache_subnet_group" "ecommerce" {
  name       = "${var.cluster_name}-cache-subnet-group"
  subnet_ids = var.cache_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cache-subnet-group"
    }
  )
}

# ElastiCache Redis Replication Group (supports multi-AZ and failover)
resource "aws_elasticache_replication_group" "ecommerce" {
  replication_group_id       = "${var.cluster_name}-redis"
  description                = "Redis cluster for ${var.cluster_name}"
  engine                     = "redis"
  engine_version             = var.redis_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  parameter_group_name       = aws_elasticache_parameter_group.ecommerce.name
  port                       = var.redis_port
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.ecommerce.name
  security_group_ids = [var.cache_security_group_id]

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  # Backup configuration
  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = "03:00-05:00"

  # Maintenance
  maintenance_window = "sun:04:00-sun:05:00"

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis"
    }
  )

  depends_on = [
    aws_elasticache_parameter_group.ecommerce,
    aws_cloudwatch_log_group.redis_slow_log,
    aws_cloudwatch_log_group.redis_engine_log
  ]
}

# Parameter Group for Redis
resource "aws_elasticache_parameter_group" "ecommerce" {
  name   = "${var.cluster_name}-redis-params"
  family = "redis${var.redis_major_version}"

  # Optimize for web sessions and caching
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-params"
    }
  )
}

# SNS Topic for notifications
resource "aws_sns_topic" "elasticache_notifications" {
  name = "${var.cluster_name}-elasticache-notifications"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-elasticache-notifications"
    }
  )
}

# Random auth token for Redis
resource "random_password" "redis_auth_token" {
  length      = 32
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
}

# Store auth token in Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth_token" {
  name                    = "${var.cluster_name}/redis/auth-token"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-auth-token"
    }
  )
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
    host       = aws_elasticache_replication_group.ecommerce.primary_endpoint_address
    port       = var.redis_port
    engine     = "redis"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.cluster_name}/slow-log"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-slow-log"
    }
  )
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.cluster_name}/engine-log"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-engine-log"
    }
  )
}

# CloudWatch Alarms for Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.cluster_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Redis CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-cpu-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.cluster_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Alert when Redis memory usage exceeds 90%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-memory-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  alarm_name          = "${var.cluster_name}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Alert when Redis evictions exceed 1000"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-evictions-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "redis_connection_count" {
  alarm_name          = "${var.cluster_name}-redis-connection-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrentConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 500
  alarm_description   = "Alert when Redis connection count exceeds 500"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-redis-connections-alarm"
    }
  )
}
