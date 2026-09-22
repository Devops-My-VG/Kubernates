################################################################################
# Terraform Backend Configuration
# Storage: AWS S3 (bucket-s3-infra-devops)
# Encryption: Enabled
# State Locking: Disabled (per requirements - no DynamoDB)
# Multi-Environment: Supported via -backend-config key argument
#
# Usage:
#   terraform init -backend-config="bucket=bucket-s3-infra-devops" \
#                  -backend-config="key=ecs-cluster/int/terraform.tfstate" \
#                  -backend-config="region=us-east-1"
#
# For each environment, use different key paths:
#   INT: ecs-cluster/int/terraform.tfstate
#   QA:  ecs-cluster/qa/terraform.tfstate
#   STG: ecs-cluster/stg/terraform.tfstate
#   PRD: ecs-cluster/prd/terraform.tfstate
################################################################################

terraform {
  backend "s3" {
    bucket         = "bucket-s3-infra-devops"
    encrypt        = true
    region         = "us-east-1"
    
    # Backend-specific optimizations
    skip_credentials_validation = false  # Validate AWS credentials
    skip_metadata_api_check     = false  # Validate IAM permissions
    
    # Note: 'key' is provided via -backend-config CLI argument
    # This allows same configuration for all environments
    # No DynamoDB table for state locking (per user requirement - S3 only)
  }
}
