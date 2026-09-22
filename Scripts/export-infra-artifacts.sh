#!/bin/bash

# ============================================================================
# Export Infrastructure Artifacts Script
# Purpose: Export Terraform outputs for consumption by app pipelines
# Usage: ./scripts/export-infra-artifacts.sh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-INT}"
TERRAFORM_ROOT="${2:-.}"
ARTIFACTS_DIR="${TERRAFORM_ROOT}/artifacts"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Create artifacts directory
mkdir -p "${ARTIFACTS_DIR}"

echo -e "${BLUE}=========================================="
echo "Export Infrastructure Artifacts"
echo "==========================================${NC}"
echo ""
echo "Environment: ${ENVIRONMENT}"
echo "Timestamp: ${TIMESTAMP}"
echo "Artifacts Dir: ${ARTIFACTS_DIR}"
echo ""

# Step 1: Export Terraform outputs
echo -e "${YELLOW}[1/4] Exporting Terraform outputs...${NC}"
cd "${TERRAFORM_ROOT}"

if ! ./terraform output -json > "${ARTIFACTS_DIR}/terraform-outputs.json"; then
  echo -e "${RED}❌ Failed to export Terraform outputs${NC}"
  exit 1
fi
echo -e "${GREEN}✓ terraform-outputs.json created${NC}"

# Step 2: Create environment variables file
echo -e "${YELLOW}[2/4] Creating environment variables file...${NC}"

cat > "${ARTIFACTS_DIR}/infra-config.env" << 'ENVEOF'
# ECS Cluster Infrastructure Configuration
# Environment: INT
# Cluster: ecs-cluster-int

# Network Configuration
export VPC_ID=$(jq -r '.vpc_id.value' terraform-outputs.json)
export PUBLIC_SUBNETS=$(jq -r '.public_subnets.value | join(",")' terraform-outputs.json)
export SECURITY_GROUP_ID=$(jq -r '.security_group_id.value' terraform-outputs.json)

# ECS Cluster
export ECS_CLUSTER_NAME=$(jq -r '.cluster_name.value' terraform-outputs.json)
export ECS_CLUSTER_ARN=$(jq -r '.cluster_arn.value' terraform-outputs.json)
export CLOUDWATCH_LOG_GROUP=$(jq -r '.cloudwatch_log_group_name.value' terraform-outputs.json)

# RDS PostgreSQL Database
export RDS_HOST=$(jq -r '.rds_host.value' terraform-outputs.json)
export RDS_PORT=$(jq -r '.rds_port.value' terraform-outputs.json)
export RDS_DATABASE_NAME=$(jq -r '.rds_database_name.value' terraform-outputs.json)
export RDS_USERNAME=$(jq -r '.rds_username.value' terraform-outputs.json)

# Valkey Serverless Cache
export VALKEY_HOST=$(jq -r '.valkey_host.value' terraform-outputs.json)
export VALKEY_PORT=$(jq -r '.valkey_port.value' terraform-outputs.json)

# ECR Container Registry
export ECR_REGISTRY=$(jq -r '.ecr_registry_id.value' terraform-outputs.json)
export BACKEND_ECR_REPOSITORY=$(jq -r '.backend_ecr_repository_name.value' terraform-outputs.json)
export FRONTEND_ECR_REPOSITORY=$(jq -r '.frontend_ecr_repository_name.value' terraform-outputs.json)
export BACKEND_ECR_REPOSITORY_URL=$(jq -r '.backend_ecr_repository_url.value' terraform-outputs.json)
export FRONTEND_ECR_REPOSITORY_URL=$(jq -r '.frontend_ecr_repository_url.value' terraform-outputs.json)

# IAM Roles
export ECS_TASK_EXECUTION_ROLE_ARN=$(jq -r '.ecs_task_execution_role_arn.value' terraform-outputs.json)
export ECS_TASK_ROLE_ARN=$(jq -r '.ecs_task_role_arn.value' terraform-outputs.json)
ENVEOF

echo -e "${GREEN}✓ infra-config.env created${NC}"

# Step 3: Create YAML configuration
echo -e "${YELLOW}[3/4] Creating YAML configuration...${NC}"

cat > "${ARTIFACTS_DIR}/infra-config.yaml" << 'YAMLEOF'
# ECS Cluster Infrastructure Configuration (YAML)

infrastructure:
  cluster_name: ecs-cluster-int
  environment: INT
  region: us-east-1

network:
  vpc_id: $(jq -r '.vpc_id.value' terraform-outputs.json)
  public_subnets: $(jq -r '.public_subnets.value | join(", ")' terraform-outputs.json)
  security_group_id: $(jq -r '.security_group_id.value' terraform-outputs.json)

ecs:
  cluster_name: $(jq -r '.cluster_name.value' terraform-outputs.json)
  cluster_arn: $(jq -r '.cluster_arn.value' terraform-outputs.json)
  cloudwatch_log_group: $(jq -r '.cloudwatch_log_group_name.value' terraform-outputs.json)

database:
  type: PostgreSQL
  host: $(jq -r '.rds_host.value' terraform-outputs.json)
  port: $(jq -r '.rds_port.value' terraform-outputs.json)
  database_name: $(jq -r '.rds_database_name.value' terraform-outputs.json)
  username: $(jq -r '.rds_username.value' terraform-outputs.json)

cache:
  type: Valkey Serverless
  host: $(jq -r '.valkey_host.value' terraform-outputs.json)
  port: $(jq -r '.valkey_port.value' terraform-outputs.json)

registry:
  registry_id: $(jq -r '.ecr_registry_id.value' terraform-outputs.json)
  backend_repository: $(jq -r '.backend_ecr_repository_name.value' terraform-outputs.json)
  backend_repository_url: $(jq -r '.backend_ecr_repository_url.value' terraform-outputs.json)
  frontend_repository: $(jq -r '.frontend_ecr_repository_name.value' terraform-outputs.json)
  frontend_repository_url: $(jq -r '.frontend_ecr_repository_url.value' terraform-outputs.json)

iam:
  task_execution_role_arn: $(jq -r '.ecs_task_execution_role_arn.value' terraform-outputs.json)
  task_role_arn: $(jq -r '.ecs_task_role_arn.value' terraform-outputs.json)
YAMLEOF

echo -e "${GREEN}✓ infra-config.yaml created${NC}"

# Step 4: Create manifest
echo -e "${YELLOW}[4/4] Creating infrastructure manifest...${NC}"

cat > "${ARTIFACTS_DIR}/infra-manifest.json" << MANIFESTEOF
{
  "version": "1.0",
  "generated_at": "${TIMESTAMP}",
  "environment": "${ENVIRONMENT}",
  "cluster_name": "ecs-cluster-int",
  "region": "us-east-1",
  "terraform_version": "1.16.2",
  "artifacts": {
    "terraform_outputs": "terraform-outputs.json",
    "env_config": "infra-config.env",
    "yaml_config": "infra-config.yaml",
    "manifest": "infra-manifest.json"
  },
  "expiry_days": 30
}
MANIFESTEOF

echo -e "${GREEN}✓ infra-manifest.json created${NC}"

# Summary
echo ""
echo -e "${BLUE}=========================================="
echo "Artifact Export Summary"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}Files created:${NC}"
ls -lh "${ARTIFACTS_DIR}"/*.json "${ARTIFACTS_DIR}"/*.env "${ARTIFACTS_DIR}"/*.yaml 2>/dev/null || true
echo ""

# Display some key values
echo -e "${BLUE}Configuration Preview:${NC}"
echo "  VPC ID: $(jq -r '.vpc_id.value' "${ARTIFACTS_DIR}/terraform-outputs.json")"
echo "  Cluster: $(jq -r '.cluster_name.value' "${ARTIFACTS_DIR}/terraform-outputs.json")"
echo "  RDS Host: $(jq -r '.rds_host.value' "${ARTIFACTS_DIR}/terraform-outputs.json")"
echo "  Valkey Host: $(jq -r '.valkey_host.value' "${ARTIFACTS_DIR}/terraform-outputs.json")"
echo "  ECR Registry: $(jq -r '.ecr_registry_id.value' "${ARTIFACTS_DIR}/terraform-outputs.json")"
echo ""
echo -e "${GREEN}✅ All artifacts exported successfully!${NC}"
echo ""
