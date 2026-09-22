variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 2
}

variable "redis_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_major_version" {
  description = "Redis major version for parameter group (e.g., '7', '6.x')"
  type        = string
  default     = "7"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}

variable "cache_subnets" {
  description = "List of subnet IDs for cache"
  type        = list(string)
}

variable "cache_security_group_id" {
  description = "Security group ID for cache"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
