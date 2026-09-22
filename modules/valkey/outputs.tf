# =========================================================
# VALKEY SERVERLESS MODULE OUTPUTS
# =========================================================

# Valkey Serverless Cache Endpoints
output "valkey_cache_id" {
  description = "ID of the Valkey Serverless cache"
  value       = aws_elasticache_serverless_cache.valkey.id
}

output "valkey_endpoint" {
  description = "Endpoint of the Valkey Serverless cache (host:port)"
  value       = aws_elasticache_serverless_cache.valkey.endpoint[0].address
  sensitive   = false
}

output "valkey_host" {
  description = "Hostname of the Valkey Serverless cache"
  value       = split(":", aws_elasticache_serverless_cache.valkey.endpoint[0].address)[0]
}

output "valkey_port" {
  description = "Port of the Valkey Serverless cache"
  value       = aws_elasticache_serverless_cache.valkey.endpoint[0].port
}

output "valkey_full_address" {
  description = "Full address and port for application connections"
  value       = "${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:${aws_elasticache_serverless_cache.valkey.endpoint[0].port}"
  sensitive   = false
}

# Security and Access
output "valkey_security_group_id" {
  description = "Security group ID for Valkey Serverless"
  value       = aws_security_group.valkey_sg.id
}

output "valkey_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the auth token"
  value       = aws_secretsmanager_secret.valkey_auth_token.arn
  sensitive   = true
}

output "valkey_auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing the auth token"
  value       = aws_secretsmanager_secret.valkey_auth_token.name
}

# Configuration Details
output "valkey_engine" {
  description = "Cache engine type (Valkey)"
  value       = "valkey"
}

output "valkey_engine_version" {
  description = "Valkey engine version"
  value       = var.valkey_engine_version
}

output "valkey_cache_nodes" {
  description = "Number of cache nodes"
  value       = "Auto-scaling (Serverless)"
}

# Resource Configuration
output "valkey_data_storage_gb" {
  description = "Maximum data storage in GB"
  value       = var.data_storage_gb
}

output "valkey_ecpu_per_second" {
  description = "Maximum eCPUs per second"
  value       = var.ecpu_per_second
}

# Backup and Recovery
output "valkey_snapshot_retention_limit" {
  description = "Number of days automatic snapshots are retained"
  value       = var.snapshot_retention_limit
}

output "valkey_snapshot_window" {
  description = "Daily time window for automatic snapshots"
  value       = var.snapshot_window
}

# Monitoring and Alarms
output "valkey_notification_topic_arn" {
  description = "SNS topic ARN for Valkey notifications"
  value       = aws_sns_topic.valkey_notifications.arn
}

output "valkey_cloudwatch_alarms" {
  description = "CloudWatch alarms for Valkey monitoring"
  value = {
    cpu_alarm              = aws_cloudwatch_metric_alarm.valkey_cpu_utilization.arn
    memory_alarm           = aws_cloudwatch_metric_alarm.valkey_memory_utilization.arn
    connection_alarm       = aws_cloudwatch_metric_alarm.valkey_connection_count.arn
    network_bytes_in_alarm = aws_cloudwatch_metric_alarm.valkey_network_bytes_in.arn
  }
}

output "valkey_log_group_name" {
  description = "CloudWatch log group name for Valkey"
  value       = aws_cloudwatch_log_group.valkey_logs.name
}

output "valkey_dashboard_url" {
  description = "URL to CloudWatch dashboard for Valkey monitoring"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.valkey.dashboard_name}"
}

# Connection String for Applications
output "valkey_connection_string" {
  description = "Redis-compatible connection string for applications"
  value       = "redis://default:${random_password.valkey_auth_token.result}@${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:${aws_elasticache_serverless_cache.valkey.endpoint[0].port}/0"
  sensitive   = true
}

output "valkey_connection_string_without_password" {
  description = "Redis-compatible connection string template (add password from Secrets Manager)"
  value       = "redis://default:<PASSWORD>@${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:${aws_elasticache_serverless_cache.valkey.endpoint[0].port}/0"
  sensitive   = false
}

# Migration Summary
output "valkey_migration_summary" {
  description = "Summary of Valkey deployment for migration purposes"
  value = {
    engine                      = "Valkey Serverless"
    version                     = var.valkey_engine_version
    region                      = var.aws_region
    environment                 = var.environment
    cluster_name                = var.cluster_name
    endpoint                    = aws_elasticache_serverless_cache.valkey.endpoint[0].address
    port                        = aws_elasticache_serverless_cache.valkey.endpoint[0].port
    data_storage_gb             = var.data_storage_gb
    ecpu_per_second             = var.ecpu_per_second
    data_tiering_enabled        = var.data_tiering_enabled
    snapshot_retention_limit    = var.snapshot_retention_limit
    cost_monthly_estimate       = "~$${var.data_storage_gb * 0.084 * 730 / 1000 + var.ecpu_per_second * 0.0023 / 1000}"
    savings_vs_redis_serverless = "33% cost savings"
    deployment_timestamp        = timestamp()
  }
}
