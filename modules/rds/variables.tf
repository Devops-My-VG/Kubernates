variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "ecommercedb"
}

variable "master_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.7"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "database_subnets" {
  description = "List of subnet IDs for database"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for database"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
