variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (int, qa, stg, prd)"
  type        = string
  default     = "int"

  validation {
    condition     = contains(["int", "qa", "stg", "prd"], var.environment)
    error_message = "Environment must be one of: int, qa, stg, prd."
  }
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 255
    error_message = "Cluster name must be between 1 and 255 characters."
  }
}

variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type (e.g., t3.medium)."
  }
}

variable "ami_id" {
  description = "AMI ID for ECS-optimized EC2 instances (leave empty to use latest)"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be at least 1."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1
    error_message = "Desired capacity must be at least 1."
  }
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
  default     = null
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS service tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.ecs_min_capacity >= 1
    error_message = "ECS minimum capacity must be at least 1."
  }
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS service tasks"
  type        = number
  default     = 2

  validation {
    condition     = var.ecs_desired_capacity >= 1
    error_message = "ECS desired capacity must be at least 1."
  }
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS service tasks"
  type        = number
  default     = 4

  validation {
    condition     = var.ecs_max_capacity >= 1
    error_message = "ECS maximum capacity must be at least 1."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch value."
  }
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = false
}

variable "enable_private_subnets" {
  description = "Enable private subnets for Valkey cache and RDS database"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# ============================================
# RDS PostgreSQL Variables
# ============================================
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20

  validation {
    condition     = var.rds_allocated_storage >= 20
    error_message = "RDS allocated storage must be at least 20GB."
  }
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.7"
}

variable "db_master_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "ecommercedb"
}

variable "database_port" {
  description = "PostgreSQL database port"
  type        = number
  default     = 5432
}

variable "backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

# ============================================
# Valkey Serverless Cache Variables (33% cheaper than Redis)
# ============================================
variable "valkey_engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "7.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.valkey_engine_version))
    error_message = "Engine version must be in format X.Y (e.g., 7.2)."
  }
}

variable "valkey_data_storage_gb" {
  description = "Maximum data storage in GB for Valkey Serverless (1-100 GB)"
  type        = number
  default     = 10
  validation {
    condition     = var.valkey_data_storage_gb >= 1 && var.valkey_data_storage_gb <= 100
    error_message = "Data storage must be between 1 and 100 GB."
  }
}

variable "valkey_ecpu_per_second" {
  description = "Maximum eCPUs per second for Valkey Serverless (1000-15000000)"
  type        = number
  default     = 1000
  validation {
    condition     = var.valkey_ecpu_per_second >= 1000 && var.valkey_ecpu_per_second <= 15000000
    error_message = "eCPUs per second must be between 1000 and 15000000."
  }
}

variable "valkey_snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots for Valkey (0-35 days)"
  type        = number
  default     = 0
  validation {
    condition     = var.valkey_snapshot_retention_limit >= 0 && var.valkey_snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "valkey_snapshot_window" {
  description = "Daily time window for automatic snapshots (HH:MM-HH:MM)"
  type        = string
  default     = "03:00-04:00"
  validation {
    condition     = can(regex("^\\d{2}:\\d{2}-\\d{2}:\\d{2}$", var.valkey_snapshot_window))
    error_message = "Snapshot window must be in format HH:MM-HH:MM (e.g., 03:00-04:00)."
  }
}

variable "valkey_daily_snapshot_time" {
  description = "Time of day to take daily snapshots for Valkey (HH:MM)"
  type        = string
  default     = "03:00"
  validation {
    condition     = can(regex("^\\d{2}:\\d{2}$", var.valkey_daily_snapshot_time))
    error_message = "Daily snapshot time must be in format HH:MM (e.g., 03:00)."
  }
}

variable "valkey_data_tiering_enabled" {
  description = "Enable data tiering for Valkey Serverless (requires NVMe storage)"
  type        = bool
  default     = false
}

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "engineering"
}
