variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (leave empty to use latest ECS-optimized AMI)"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS service tasks"
  type        = number
  default     = 1
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS service tasks"
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS service tasks"
  type        = number
  default     = 4
}

