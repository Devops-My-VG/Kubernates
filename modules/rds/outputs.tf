output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.ecommerce.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.ecommerce.arn
}

output "db_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.ecommerce.endpoint
}

output "db_host" {
  description = "RDS instance hostname"
  value       = aws_db_instance.ecommerce.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.ecommerce.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.ecommerce.db_name
}

output "db_username" {
  description = "Database master username"
  value       = var.master_username
  sensitive   = true
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_connection_string" {
  description = "PostgreSQL connection string for application"
  value       = "postgresql://${var.master_username}:PASSWORD@${aws_db_instance.ecommerce.address}:${aws_db_instance.ecommerce.port}/${aws_db_instance.ecommerce.db_name}"
  sensitive   = true
}

output "db_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.ecommerce.resource_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.ecommerce.name
}

output "db_security_group_id" {
  description = "Security group ID for database"
  value       = var.db_security_group_id
}

output "db_backup_retention_days" {
  description = "Backup retention period in days"
  value       = aws_db_instance.ecommerce.backup_retention_period
}

output "db_multi_az" {
  description = "Whether the database is multi-AZ"
  value       = aws_db_instance.ecommerce.multi_az
}

output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.id
}

output "kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds.arn
}
