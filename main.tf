module "vpc" {
  source                 = "./modules/vpc"
  cluster_name           = var.cluster_name
  environment            = var.environment
  enable_private_subnets = var.enable_private_subnets
  enable_nat_gateway     = var.enable_nat_gateway
}

module "ecs" {
  source                = "./modules/ecs"
  vpc_id                = module.vpc.vpc_id
  ami_id                = var.ami_id
  subnets               = module.vpc.public_subnets
  vpc_security_group_id = module.vpc.security_group_id
  cluster_name          = var.cluster_name
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  key_name              = var.key_name
  environment           = var.environment
}

# Wait for instances to be fully initialized
resource "null_resource" "wait_for_instances" {
  provisioner "local-exec" {
    command = "echo 'Waiting for ECS instances to initialize...' && sleep 120"
  }

  depends_on = [module.ecs]
}

# Fetch running ECS instances after initialization
data "aws_instances" "ecs_instances" {
  depends_on = [null_resource.wait_for_instances]

  instance_tags = {
    "Name" = "${var.cluster_name}-ecs-asg"
  }

  instance_state_names = ["running"]
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

# ============================================
# IAM Roles for ECS Tasks
# ============================================
module "iam_tasks" {
  source = "./modules/iam_tasks"

  cluster_name   = var.cluster_name
  region         = var.region
  aws_account_id = data.aws_caller_identity.current.account_id
  app_s3_bucket  = module.s3.app_storage_bucket_name

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

# ============================================
# ECR Repositories
# ============================================
module "ecr" {
  source = "./modules/ecr"

  cluster_name                = var.cluster_name
  ecs_task_execution_role_arn = module.iam_tasks.ecs_task_execution_role_arn

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

# ============================================
# RDS PostgreSQL Database
# ============================================
module "rds" {
  source = "./modules/rds"

  cluster_name          = var.cluster_name
  database_subnets      = module.vpc.public_subnets
  db_security_group_id  = module.vpc.rds_security_group_id
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  postgres_version      = var.postgres_version
  master_username       = var.db_master_username
  database_name         = var.database_name
  database_port         = var.database_port
  backup_retention_days = var.backup_retention_days

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

# ============================================
# Valkey Serverless Cache (Replaces ElastiCache Redis)
# ============================================
module "valkey" {
  source = "./modules/valkey"

  cluster_name          = var.cluster_name
  environment           = var.environment
  aws_region            = var.region
  vpc_id                = module.vpc.vpc_id
  cache_subnets         = module.vpc.private_subnets
  ecs_security_group_id = module.vpc.security_group_id

  valkey_engine_version    = var.valkey_engine_version
  data_storage_gb          = var.valkey_data_storage_gb
  ecpu_per_second          = var.valkey_ecpu_per_second
  snapshot_retention_limit = var.valkey_snapshot_retention_limit
  snapshot_window          = var.valkey_snapshot_window
  daily_snapshot_time      = var.valkey_daily_snapshot_time
  data_tiering_enabled     = var.valkey_data_tiering_enabled
  log_retention_days       = var.log_retention_days
  cost_center              = var.cost_center

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }

  depends_on = [module.vpc]
}

# ============================================
# S3 Buckets for Application Storage
# ============================================
module "s3" {
  source = "./modules/s3"

  cluster_name      = var.cluster_name
  ecs_task_role_arn = module.iam_tasks.ecs_task_role_arn

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}

# ============================================
# Data Sources
# ============================================
data "aws_caller_identity" "current" {}
