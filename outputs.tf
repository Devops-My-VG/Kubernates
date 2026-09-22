output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ecs.asg_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "security_group_id" {
  description = "ID of the ECS security group"
  value       = module.vpc.security_group_id
}

output "ecs_instance_role_arn" {
  description = "ARN of the ECS instance role"
  value       = module.ecs.instance_role_arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.ecs.launch_template_id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = module.ecs.launch_template_latest_version
}

output "ecs_instances" {
  description = "List of ECS instance IPs and IDs"
  value = {
    instance_ids = try(data.aws_instances.ecs_instances.ids, [])
    private_ips  = try(data.aws_instances.ecs_instances.private_ips, [])
    public_ips   = try(data.aws_instances.ecs_instances.public_ips, [])
  }
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs_logs.arn
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.region
}


# ============================================
# RDS Database Outputs
# ============================================
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "rds_host" {
  description = "RDS database host"
  value       = module.rds.db_host
}

output "rds_port" {
  description = "RDS database port"
  value       = module.rds.db_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = var.db_master_username
  sensitive   = true
}

output "rds_password_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS password"
  value       = module.rds.db_password_secret_arn
}

output "rds_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_master_username}:PASSWORD@${module.rds.db_host}:${module.rds.db_port}/${module.rds.db_name}"
  sensitive   = true
}

output "rds_multi_az" {
  description = "Whether RDS is Multi-AZ"
  value       = module.rds.db_multi_az
}

# ============================================
# Valkey Serverless Cache Outputs (33% cost savings)
# ============================================
output "valkey_cache_id" {
  description = "ID of the Valkey Serverless cache"
  value       = module.valkey.valkey_cache_id
}

output "valkey_endpoint" {
  description = "Valkey Serverless cache endpoint (host:port)"
  value       = module.valkey.valkey_full_address
}

output "valkey_host" {
  description = "Valkey Serverless cache hostname"
  value       = module.valkey.valkey_host
}

output "valkey_port" {
  description = "Valkey Serverless cache port"
  value       = module.valkey.valkey_port
}

output "valkey_engine_version" {
  description = "Valkey engine version"
  value       = module.valkey.valkey_engine_version
}

output "valkey_data_storage_gb" {
  description = "Maximum data storage in GB for Valkey"
  value       = module.valkey.valkey_data_storage_gb
}

output "valkey_ecpu_per_second" {
  description = "Maximum eCPUs per second for Valkey"
  value       = module.valkey.valkey_ecpu_per_second
}

output "valkey_auth_token_secret_arn" {
  description = "ARN of Secrets Manager secret containing Valkey auth token"
  value       = module.valkey.valkey_auth_token_secret_arn
  sensitive   = true
}

output "valkey_auth_token_secret_name" {
  description = "Name of Secrets Manager secret containing Valkey auth token"
  value       = module.valkey.valkey_auth_token_secret_name
}

output "valkey_connection_string" {
  description = "Redis-compatible connection string for applications"
  value       = module.valkey.valkey_connection_string
  sensitive   = true
}

output "valkey_connection_string_template" {
  description = "Redis-compatible connection string template (add password from Secrets Manager)"
  value       = module.valkey.valkey_connection_string_without_password
}

output "valkey_security_group_id" {
  description = "Security group ID for Valkey Serverless"
  value       = module.valkey.valkey_security_group_id
}

output "valkey_snapshot_retention_limit" {
  description = "Number of days automatic snapshots are retained"
  value       = module.valkey.valkey_snapshot_retention_limit
}

output "valkey_cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard for Valkey monitoring"
  value       = module.valkey.valkey_dashboard_url
}

output "valkey_notification_topic_arn" {
  description = "SNS topic ARN for Valkey notifications"
  value       = module.valkey.valkey_notification_topic_arn
}

output "valkey_log_group_name" {
  description = "CloudWatch log group name for Valkey"
  value       = module.valkey.valkey_log_group_name
}

output "valkey_migration_summary" {
  description = "Summary of Valkey deployment for migration purposes"
  value       = module.valkey.valkey_migration_summary
}

# ============================================
# ECR Repositories Outputs
# ============================================
output "backend_ecr_repository_url" {
  description = "ECR repository URL for backend"
  value       = module.ecr.backend_repository_url
}

output "backend_ecr_repository_name" {
  description = "ECR repository name for backend"
  value       = module.ecr.backend_repository_name
}

output "frontend_ecr_repository_url" {
  description = "ECR repository URL for frontend"
  value       = module.ecr.frontend_repository_url
}

output "frontend_ecr_repository_name" {
  description = "ECR repository name for frontend"
  value       = module.ecr.frontend_repository_name
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = module.ecr.ecr_registry_id
}

# ============================================
# IAM Roles Outputs
# ============================================
output "ecs_task_execution_role_arn" {
  description = "ARN of ECS task execution role"
  value       = module.iam_tasks.ecs_task_execution_role_arn
}

output "ecs_task_execution_role_name" {
  description = "Name of ECS task execution role"
  value       = module.iam_tasks.ecs_task_execution_role_name
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = module.iam_tasks.ecs_task_role_arn
}

output "ecs_task_role_name" {
  description = "Name of ECS task role"
  value       = module.iam_tasks.ecs_task_role_name
}

# ============================================
# S3 Buckets Outputs
# ============================================
output "app_storage_bucket" {
  description = "S3 bucket for application storage"
  value       = module.s3.app_storage_bucket_name
}

output "app_storage_bucket_arn" {
  description = "ARN of S3 bucket for application storage"
  value       = module.s3.app_storage_bucket_arn
}

output "logs_bucket" {
  description = "S3 bucket for logs"
  value       = module.s3.logs_bucket_name
}

output "logs_bucket_arn" {
  description = "ARN of S3 bucket for logs"
  value       = module.s3.logs_bucket_arn
}
