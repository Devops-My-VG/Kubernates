# ECS Cluster - STG Environment Configuration
# AWS Account: $AWS_PROFILE
# Used for: Staging and pre-production testing
# Cache Engine: Valkey Serverless (33% cheaper than Redis OSS)

region                    = "us-east-1"
environment               = "stg"
cluster_name              = "ecs-cluster-stg"
instance_type             = "t3.medium"
ami_id                    = "ami-0fa96a91a85e7d4a2"
min_size                  = 2
max_size                  = 4
desired_capacity          = 2
ecs_min_capacity          = 2
ecs_desired_capacity      = 2
ecs_max_capacity          = 4
log_retention_days        = 30
enable_container_insights = true
enable_private_subnets    = true
enable_nat_gateway        = true

# Valkey Serverless Configuration (STG Environment)
# Cost Estimate: ~$0.20-0.25/hr (~$150-180/month)
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 15   # 15GB for STG
valkey_ecpu_per_second          = 1500 # 1500 eCPUs/sec for STG
valkey_snapshot_retention_limit = 7    # 7-day retention for STG
valkey_snapshot_window          = "03:00-04:00"
valkey_daily_snapshot_time      = "03:00"
valkey_data_tiering_enabled     = false

cost_center = "engineering"

tags = {
  Environment = "STG"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
  Team        = "DevOps"
  Engine      = "Valkey-Serverless"
}
