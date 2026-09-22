# Infrastructure Artifact Export Strategy

## Overview

This document outlines the strategy to export Terraform-managed infrastructure resources from the ECS Cluster pipeline and make them consumable by the ecommerce-app-v1 deployment pipeline.

---

## 📋 Current Problem

**Gap**: Infrastructure resources created via Terraform in `ecs-cluster` pipeline are not easily accessible to the `ecommerce-app-v1` pipeline for application deployment.

**Need**: Seamless way to reference AWS infrastructure (VPC, ECS, RDS, ECR, etc.) in app deployment pipeline.

---

## 🎯 Proposed Solution: Multi-Layer Artifact Export

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ ECS Cluster Pipeline (Infrastructure)                           │
│  - validate → plan → apply → export-artifacts                   │
│                               ↓                                  │
│                    ┌──────────────────────┐                      │
│                    │ Artifact Repository  │                      │
│                    │ (GitLab Package)     │                      │
│                    └──────────────────────┘                      │
│                               ↑                                  │
└─────────────────────────────────────────────────────────────────┘
                                 │
                    ╔════════════╩════════════╗
                    ║                         ║
        ┌───────────────────┐     ┌───────────────────┐
        │ S3 Bucket         │     │ GitLab Variables  │
        │ (State Artifacts) │     │ (CI/CD Vars)      │
        │                   │     │                   │
        │ - outputs.json    │     │ - VPC_ID          │
        │ - env.tfvars      │     │ - ECR_REGISTRY    │
        │ - config.yml      │     │ - RDS_HOST        │
        │ - tfstate.backup  │     │ - VALKEY_HOST     │
        └───────────────────┘     └───────────────────┘
                    ↑                         ↑
        ╔═══════════╩═════════════════════════╩═══════════╗
        ║                                                 ║
        │ App Deployment Pipeline (ecommerce-app-v1)     │
        │  - Uses artifacts in build/deploy stages       │
        │  - Configures containers with resource info    │
        │  - Deploys to ECS cluster                       │
        └─────────────────────────────────────────────────┘
```

---

## 🔧 Implementation Approach

### Layer 1: Export-Artifacts Stage (New)

**Purpose**: Extract and package Terraform outputs into consumable artifacts

**When it runs**: After successful `apply:int` job

**What it does**:
1. Exports Terraform outputs as JSON
2. Creates environment variables file (.env format)
3. Generates deployment config (YAML)
4. Uploads to S3 bucket
5. Creates GitLab Package Registry artifact
6. Updates GitLab CI/CD variables

**Artifacts Generated**:
- `terraform-outputs.json` - Complete Terraform outputs
- `infra-config.env` - Environment variables format
- `infra-config.yaml` - YAML configuration
- `deployment-config.sh` - Shell script for sourcing
- `infra-manifest.json` - Metadata about infrastructure

### Layer 2: S3 Storage (Persistent)

**Purpose**: Central repository for infrastructure state artifacts

**Bucket**: `bucket-s3-infra-devops`

**Structure**:
```
s3://bucket-s3-infra-devops/
├── ecs-cluster/
│   ├── int/
│   │   ├── terraform.tfstate (existing)
│   │   ├── outputs.json (new)
│   │   ├── infra-config.yaml (new)
│   │   ├── infra-config.env (new)
│   │   └── infra-manifest.json (new)
│   └── qa/, stg/, prd/ (future)
└── exports/
    ├── latest/ → symlink to current version
    └── v1/, v2/, v3/ (versioned)
```

### Layer 3: GitLab CI/CD Variables

**Purpose**: Make infrastructure info available as environment variables in app pipeline

**Variables to Create**:
```
# Network
VPC_ID = vpc-xxxxx
PUBLIC_SUBNETS = subnet-1,subnet-2
SECURITY_GROUP_ID = sg-xxxxx

# ECS
ECS_CLUSTER_NAME = ecs-cluster-int
ECS_CLUSTER_ARN = arn:aws:ecs:...

# RDS Database
RDS_HOST = ecs-cluster-int-postgres-db.xxxxx.rds.amazonaws.com
RDS_PORT = 5432
RDS_DATABASE_NAME = ecommercedb
RDS_USERNAME = postgres

# Valkey Cache
VALKEY_HOST = ecs-cluster-int-valkey.xxxxx.cache.amazonaws.com
VALKEY_PORT = 6379

# ECR
ECR_REGISTRY = 639140327478.dkr.ecr.us-east-1.amazonaws.com
BACKEND_ECR_REPOSITORY = ecs-cluster-int/backend
FRONTEND_ECR_REPOSITORY = ecs-cluster-int/frontend

# ALB
ALB_DNS = ecs-cluster-int-alb-xxxxx.us-east-1.elb.amazonaws.com
ALB_ARN = arn:aws:elasticloadbalancing:...

# CloudWatch
CLOUDWATCH_LOG_GROUP = /ecs/ecs-cluster-int

# IAM Roles
ECS_TASK_EXECUTION_ROLE_ARN = arn:aws:iam::...
ECS_TASK_ROLE_ARN = arn:aws:iam::...
```

### Layer 4: GitLab Package Registry (Optional)

**Purpose**: Version-controlled artifact distribution

**Package Type**: Generic Package

**Usage**: 
```bash
# In app pipeline
curl --header "PRIVATE-TOKEN: $CI_JOB_TOKEN" \
  "https://gitlab.com/api/v4/projects/.../packages/generic/infra-artifacts/v1/infra-config.yaml"
```

---

## 📊 Pipeline Implementation

### New Stage: `export-artifacts`

**Add to `.gitlab-ci.yml`**:

```yaml
stages:
  - validate
  - plan
  - apply
  - export-artifacts    # NEW STAGE
  - destroy
```

**Jobs to add**:

1. **export-artifacts:int** (runs after apply:int succeeds)
2. **upload-to-s3:int** (upload to S3)
3. **update-variables:int** (update GitLab variables)
4. **publish-package:int** (optional - publish to package registry)

---

## 🔄 Integration with App Pipeline

### In ecommerce-app-v1 pipeline `.gitlab-ci.yml`

**Option 1: Source Environment Variables**
```yaml
deploy:
  stage: deploy
  script:
    # Get variables from parent project
    - aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/infra-config.env . --sse AES256
    - source infra-config.env
    - echo "VPC_ID=$VPC_ID"
    - echo "ECS_CLUSTER_NAME=$ECS_CLUSTER_NAME"
    # Deploy using these variables
```

**Option 2: Use GitLab CI/CD Variables**
```yaml
deploy:
  stage: deploy
  script:
    # Variables already available as $VPC_ID, $ECS_CLUSTER_NAME, etc.
    - aws ecs update-service --cluster $ECS_CLUSTER_NAME ...
```

**Option 3: Download JSON Config**
```yaml
deploy:
  stage: deploy
  script:
    - curl -H "Authorization: Bearer $CI_JOB_TOKEN" \
        -o infra-outputs.json \
        "https://gitlab.com/api/v4/projects/.../packages/generic/..."
    - VPC_ID=$(jq -r '.vpc_id.value' infra-outputs.json)
    - export VPC_ID
```

---

## 💾 Implementation Details

### Export Artifacts Job Script

```bash
#!/bin/bash

# 1. Export Terraform outputs
terraform output -json > terraform-outputs.json

# 2. Create environment variables file
cat > infra-config.env << 'EOF'
# ECS Cluster Infrastructure Configuration
# Generated: $(date)
# Environment: INT

export VPC_ID=$(jq -r '.vpc_id.value' terraform-outputs.json)
export PUBLIC_SUBNETS=$(jq -r '.public_subnets.value | join(",")' terraform-outputs.json)
export SECURITY_GROUP_ID=$(jq -r '.security_group_id.value' terraform-outputs.json)
export ECS_CLUSTER_NAME=$(jq -r '.cluster_name.value' terraform-outputs.json)
export RDS_HOST=$(jq -r '.rds_host.value' terraform-outputs.json)
export RDS_PORT=$(jq -r '.rds_port.value' terraform-outputs.json)
export RDS_DATABASE_NAME=$(jq -r '.rds_database_name.value' terraform-outputs.json)
export VALKEY_HOST=$(jq -r '.valkey_host.value' terraform-outputs.json)
export VALKEY_PORT=$(jq -r '.valkey_port.value' terraform-outputs.json)
export ECR_REGISTRY=$(jq -r '.ecr_registry_id.value' terraform-outputs.json)
export BACKEND_ECR_REPOSITORY=$(jq -r '.backend_ecr_repository_name.value' terraform-outputs.json)
export FRONTEND_ECR_REPOSITORY=$(jq -r '.frontend_ecr_repository_name.value' terraform-outputs.json)
export CLOUDWATCH_LOG_GROUP=$(jq -r '.cloudwatch_log_group_name.value' terraform-outputs.json)
EOF

# 3. Create YAML config
terraform output -json | jq '.' > infra-config.yaml

# 4. Create manifest
cat > infra-manifest.json << 'EOF'
{
  "version": "1.0",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "INT",
  "cluster_name": "ecs-cluster-int",
  "region": "us-east-1",
  "terraform_version": "1.16.2",
  "artifact_count": 4,
  "expiry": "$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# 5. Verify artifacts
echo "✅ Export artifacts created:"
ls -lh terraform-outputs.json infra-config.env infra-config.yaml infra-manifest.json
```

---

## 🔐 Security Considerations

### Access Control

1. **S3 Bucket**: Encrypt all artifacts (AES-256)
2. **GitLab Variables**: Mark as protected and masked (sensitive values)
3. **Package Registry**: Use project-level tokens with read-only access
4. **IAM**: Minimal permissions for artifact access

### Versioning & Rollback

- Keep last 10 versions in S3
- Tag exports with commit hash and timestamp
- Support rollback to previous infrastructure state

### Sensitive Data

- RDS password: Fetch from Secrets Manager (not in artifact)
- Valkey auth token: Fetch from Secrets Manager (not in artifact)
- AWS credentials: Use IAM roles, not stored in artifacts

---

## 📈 Benefits

| Benefit | Details |
|---------|---------|
| **Decoupling** | Infrastructure and app pipelines are independent |
| **Reusability** | Infrastructure info available to any pipeline |
| **Versioning** | Track infrastructure changes over time |
| **Reliability** | Single source of truth for resource info |
| **Automation** | No manual config passing between pipelines |
| **Auditability** | Track when resources were exported |
| **Rollback** | Restore to previous infrastructure state |

---

## 📋 Implementation Checklist

- [ ] Add `export-artifacts` stage to pipeline
- [ ] Create export script with jq processing
- [ ] Upload artifacts to S3 with versioning
- [ ] Update GitLab CI/CD variables via API
- [ ] Test artifact export in INT environment
- [ ] Document variable names in app pipeline
- [ ] Add package registry integration (optional)
- [ ] Create retrieval examples for app team
- [ ] Test app pipeline can consume artifacts
- [ ] Add error handling and retry logic
- [ ] Create rollback procedures
- [ ] Document in README

---

## 🚀 Next Steps

1. Implement `export-artifacts` stage in `.gitlab-ci.yml`
2. Add supporting shell scripts
3. Test with INT environment
4. Verify app pipeline can consume artifacts
5. Document for team

