output "redis_cluster_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.ecommerce.id
}

output "redis_cluster_address" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.ecommerce.primary_endpoint_address
}

output "redis_cluster_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.ecommerce.port
}

output "redis_endpoint" {
  description = "Redis endpoint (address:port)"
  value       = "${aws_elasticache_replication_group.ecommerce.primary_endpoint_address}:${aws_elasticache_replication_group.ecommerce.port}"
}

output "redis_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth_token.arn
}

output "redis_connection_string" {
  description = "Redis connection string for application"
  value       = "redis://:AUTH_TOKEN@${aws_elasticache_replication_group.ecommerce.primary_endpoint_address}:${aws_elasticache_replication_group.ecommerce.port}/0"
  sensitive   = true
}

output "redis_subnet_group_name" {
  description = "Cache subnet group name"
  value       = aws_elasticache_subnet_group.ecommerce.name
}

output "redis_security_group_id" {
  description = "Security group ID for cache"
  value       = var.cache_security_group_id
}

output "redis_engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_replication_group.ecommerce.engine_version
}

output "redis_node_type" {
  description = "Redis node type"
  value       = aws_elasticache_replication_group.ecommerce.node_type
}

output "redis_num_cache_nodes" {
  description = "Number of cache nodes"
  value       = aws_elasticache_replication_group.ecommerce.num_cache_clusters
}

output "redis_subnet_group_name_value" {
  description = "Redis subnet group name"
  value       = aws_elasticache_subnet_group.ecommerce.name
}
