# ECS Cluster - PRD Environment Configuration
# AWS Account: $AWS_PROFILE (Separate Production Account)
# Used for: Production workloads
# Cache Engine: Valkey Serverless (33% cheaper than Redis OSS)

region                    = "us-east-1"
environment               = "prd"
cluster_name              = "ecs-cluster-prd"
instance_type             = "m5.large"
ami_id                    = "ami-0fa96a91a85e7d4a2"
min_size                  = 2
max_size                  = 4
desired_capacity          = 2
ecs_min_capacity          = 2
ecs_desired_capacity      = 2
ecs_max_capacity          = 4
log_retention_days        = 90
enable_container_insights = true
enable_private_subnets    = true
enable_nat_gateway        = true

# Valkey Serverless Configuration (PRD Environment)
# Cost Estimate: ~$0.30-0.35/hr (~$220-250/month)
# Note: Production sizing should be based on actual workload metrics
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 25   # 25GB for PRD (production workload)
valkey_ecpu_per_second          = 2000 # 2000 eCPUs/sec for PRD (peak traffic)
valkey_snapshot_retention_limit = 14   # 14-day retention for PRD (compliance)
valkey_snapshot_window          = "03:00-04:00"
valkey_daily_snapshot_time      = "03:00"
valkey_data_tiering_enabled     = true # Enable data tiering for PRD (cost optimization)

cost_center = "production"

tags = {
  Environment = "PRD"
  CostCenter  = "Production"
  ManagedBy   = "Terraform"
  Team        = "DevOps"
  Compliance  = "Required"
  Engine      = "Valkey-Serverless"
}
