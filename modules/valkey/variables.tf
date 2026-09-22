# =========================================================
# VALKEY SERVERLESS MODULE VARIABLES
# =========================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.cluster_name))
    error_message = "Cluster name must be 3-63 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "environment" {
  description = "Environment name (int, qa, stg, prd)"
  type        = string
  validation {
    condition     = contains(["int", "qa", "stg", "prd"], var.environment)
    error_message = "Environment must be one of: int, qa, stg, prd."
  }
}

variable "aws_region" {
  description = "AWS region for Valkey deployment"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., us-east-1)."
  }
}

# =========================================================
# NETWORK CONFIGURATION
# =========================================================

variable "vpc_id" {
  description = "VPC ID where Valkey will be deployed"
  type        = string
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

variable "cache_subnets" {
  description = "List of subnet IDs for Valkey Serverless cache"
  type        = list(string)
  validation {
    condition     = length(var.cache_subnets) >= 2
    error_message = "Valkey Serverless requires at least 2 subnets for high availability."
  }
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS cluster for ingress access"
  type        = string
  validation {
    condition     = can(regex("^sg-", var.ecs_security_group_id))
    error_message = "Security group ID must start with 'sg-'."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Valkey"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{1,2}$", cidr))])
    error_message = "All CIDR blocks must be in valid CIDR notation."
  }
}

# =========================================================
# VALKEY SERVERLESS CONFIGURATION
# =========================================================

variable "valkey_engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "7.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.valkey_engine_version))
    error_message = "Engine version must be in format X.Y (e.g., 7.2)."
  }
}

variable "data_storage_gb" {
  description = "Maximum data storage in GB for Valkey Serverless"
  type        = number
  default     = 10
  validation {
    condition     = var.data_storage_gb >= 1 && var.data_storage_gb <= 100
    error_message = "Data storage must be between 1 and 100 GB."
  }
}

variable "ecpu_per_second" {
  description = "Maximum eCPUs per second for Valkey Serverless"
  type        = number
  default     = 1000
  validation {
    condition     = var.ecpu_per_second >= 100 && var.ecpu_per_second <= 10000
    error_message = "eCPUs per second must be between 100 and 10000."
  }
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0 to disable)"
  type        = number
  default     = 7
  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "snapshot_window" {
  description = "Daily time window for automatic snapshots (HH:MM-HH:MM)"
  type        = string
  default     = "03:00-04:00"
  validation {
    condition     = can(regex("^\\d{2}:\\d{2}-\\d{2}:\\d{2}$", var.snapshot_window))
    error_message = "Snapshot window must be in format HH:MM-HH:MM."
  }
}

variable "daily_snapshot_time" {
  description = "Time of day to take daily snapshots (HH:MM)"
  type        = string
  default     = "03:00"
  validation {
    condition     = can(regex("^\\d{2}:\\d{2}$", var.daily_snapshot_time))
    error_message = "Daily snapshot time must be in format HH:MM."
  }
}

variable "data_tiering_enabled" {
  description = "Enable data tiering for Valkey Serverless (requires NVMe storage)"
  type        = bool
  default     = false
}

# =========================================================
# MONITORING AND LOGGING
# =========================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch value."
  }
}

# =========================================================
# TAGGING AND METADATA
# =========================================================

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "engineering"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
