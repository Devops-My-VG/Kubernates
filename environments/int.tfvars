# ECS Cluster - INT Environment Configuration
# AWS Account: $AWS_PROFILE
# Used for: Development and initial testing
# Cache Engine: Valkey Serverless (33% cheaper than Redis OSS)

region                    = "us-east-1"
environment               = "int"
cluster_name              = "ecs-cluster-int"
instance_type             = "t3.micro"
ami_id                    = "ami-0fa96a91a85e7d4a2"
min_size                  = 2
max_size                  = 4
desired_capacity          = 2
ecs_min_capacity          = 2
ecs_desired_capacity      = 2
ecs_max_capacity          = 4
log_retention_days        = 7
enable_container_insights = false
enable_private_subnets    = true
enable_nat_gateway        = true

# RDS Configuration
postgres_version = "15.7"

# Valkey Serverless Configuration (INT Environment)
# Cost Estimate: ~$0.08-0.10/hr (~$60-70/month)
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 5    # 5GB for INT (development)
valkey_ecpu_per_second          = 1000 # 1000 eCPUs/sec minimum for INT
valkey_snapshot_retention_limit = 3    # 3-day retention for INT
valkey_snapshot_window          = "03:00-04:00"
valkey_daily_snapshot_time      = "03:00"
valkey_data_tiering_enabled     = false

cost_center = "engineering"

tags = {
  Environment = "INT"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
  Team        = "DevOps"
  Engine      = "Valkey-Serverless"
}
