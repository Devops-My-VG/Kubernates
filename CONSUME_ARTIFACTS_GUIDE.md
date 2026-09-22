# How to Consume Infrastructure Artifacts in App Pipeline

## Overview

This guide explains how to consume infrastructure artifacts exported from the ECS Cluster pipeline in your application deployment pipeline (ecommerce-app-v1).

---

## 📋 Available Artifacts

After the `export-artifacts:int` job completes successfully, four artifacts are available:

### 1. **terraform-outputs.json**
Complete Terraform outputs as JSON. Use for programmatic access to all infrastructure details.

```json
{
  "vpc_id": {
    "value": "vpc-xxxxx",
    "type": "string"
  },
  "cluster_name": {
    "value": "ecs-cluster-int",
    "type": "string"
  },
  ...
}
```

### 2. **infra-config.env**
Environment variables in bash format. Source this file to get all infrastructure variables.

```bash
export VPC_ID=vpc-xxxxx
export ECS_CLUSTER_NAME=ecs-cluster-int
export RDS_HOST=ecs-cluster-int-postgres.xxxxx.rds.amazonaws.com
...
```

### 3. **infra-config.yaml**
YAML format configuration. Use for Kubernetes manifests, Docker Compose, or documentation.

```yaml
infrastructure:
  cluster_name: ecs-cluster-int
  environment: INT

network:
  vpc_id: vpc-xxxxx
  public_subnets: subnet-1, subnet-2
...
```

### 4. **infra-manifest.json**
Metadata about the artifacts (version, timestamp, expiry, etc.)

---

## 🔄 Option 1: Use GitLab CI/CD Variables (Recommended)

The infrastructure variables are automatically available in your app pipeline as GitLab CI/CD variables.

### In ecommerce-app-v1 `.gitlab-ci.yml`

```yaml
deploy:
  stage: deploy
  image: ubuntu:22.04
  script:
    - echo "VPC_ID=$VPC_ID"
    - echo "ECS_CLUSTER_NAME=$ECS_CLUSTER_NAME"
    - echo "RDS_HOST=$RDS_HOST"
    - echo "VALKEY_HOST=$VALKEY_HOST"
    - echo "ECR_REGISTRY=$ECR_REGISTRY"
    
    # Deploy application
    - aws ecs update-service \
        --cluster $ECS_CLUSTER_NAME \
        --service my-app-service \
        --force-new-deployment \
        --region $AWS_REGION
```

### Available Variables

```bash
# Network
VPC_ID
PUBLIC_SUBNETS
SECURITY_GROUP_ID

# ECS
ECS_CLUSTER_NAME
ECS_CLUSTER_ARN
CLOUDWATCH_LOG_GROUP

# RDS Database
RDS_HOST
RDS_PORT
RDS_DATABASE_NAME
RDS_USERNAME

# Valkey Cache
VALKEY_HOST
VALKEY_PORT

# ECR Registry
ECR_REGISTRY
BACKEND_ECR_REPOSITORY
FRONTEND_ECR_REPOSITORY
BACKEND_ECR_REPOSITORY_URL
FRONTEND_ECR_REPOSITORY_URL

# IAM Roles
ECS_TASK_EXECUTION_ROLE_ARN
ECS_TASK_ROLE_ARN
```

---

## 🔄 Option 2: Download from S3

Download artifacts directly from S3 in your app pipeline.

### In ecommerce-app-v1 `.gitlab-ci.yml`

```yaml
deploy:
  stage: deploy
  image: aws/aws-cli:latest
  script:
    # Download artifacts from S3
    - aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/infra-config.env . \
        --region us-east-1
    
    # Source environment variables
    - source infra-config.env
    
    # Use variables in deployment
    - echo "Deploying to cluster: $ECS_CLUSTER_NAME"
    - aws ecs update-service \
        --cluster $ECS_CLUSTER_NAME \
        --service my-app-service \
        --force-new-deployment
```

### Benefits
- ✅ Works cross-project/cross-group
- ✅ Access latest artifacts anytime
- ✅ No need to wait for variable sync
- ✅ Independent of GitLab variable updates

### With AWS Profile
```yaml
deploy:
  stage: deploy
  image: aws/aws-cli:latest
  before_script:
    - aws configure set profile.${AWS_PROFILE}.aws_access_key_id $AWS_ACCESS_KEY_ID
    - aws configure set profile.${AWS_PROFILE}.aws_secret_access_key $AWS_SECRET_ACCESS_KEY
  script:
    - aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/infra-config.env . \
        --region us-east-1 \
        --profile ${AWS_PROFILE}
    - source infra-config.env
```

---

## 🔄 Option 3: Download from GitLab Artifacts

Access artifacts from the successful `export-artifacts:int` job.

### In ecommerce-app-v1 `.gitlab-ci.yml`

```yaml
deploy:
  stage: deploy
  image: ubuntu:22.04
  script:
    # Note: This requires accessing the infrastructure project
    # Use GitLab API to download artifacts from export-artifacts:int job
    - |
      curl --header "PRIVATE-TOKEN: $CI_JOB_TOKEN" \
        -L -o infra-config.env \
        "https://gitlab.com/api/v4/projects/devops-trainsep%2FKubernetes%2Fecs-cluster/pipelines/latest/artifacts/download?job=export-artifacts:int&file_format=zip"
    
    - unzip -o infra-config.env
    - source infra-config.env
```

### Benefits
- ✅ Uses GitLab authentication
- ✅ No AWS credentials needed in app pipeline
- ✅ Direct access to specific job artifacts

---

## 💻 Usage Examples

### Example 1: Deploy ECS Service with Infrastructure Details

```yaml
deploy_ecs_service:
  stage: deploy
  image: aws/aws-cli:latest
  script:
    # Get infrastructure config
    - source infra-config.env
    
    # Register ECS task definition
    - |
      aws ecs register-task-definition \
        --family my-app \
        --network-mode awsvpc \
        --requires-compatibilities FARGATE \
        --cpu 256 \
        --memory 512 \
        --execution-role-arn $ECS_TASK_EXECUTION_ROLE_ARN \
        --task-role-arn $ECS_TASK_ROLE_ARN \
        --container-definitions "[
          {
            \"name\": \"app\",
            \"image\": \"$BACKEND_ECR_REPOSITORY_URL:latest\",
            \"environment\": [
              {
                \"name\": \"RDS_HOST\",
                \"value\": \"$RDS_HOST\"
              },
              {
                \"name\": \"VALKEY_HOST\",
                \"value\": \"$VALKEY_HOST\"
              }
            ],
            \"logConfiguration\": {
              \"logDriver\": \"awslogs\",
              \"options\": {
                \"awslogs-group\": \"$CLOUDWATCH_LOG_GROUP\",
                \"awslogs-region\": \"us-east-1\",
                \"awslogs-stream-prefix\": \"ecs\"
              }
            }
          }
        ]"
    
    # Create or update service
    - |
      aws ecs update-service \
        --cluster $ECS_CLUSTER_NAME \
        --service my-app \
        --task-definition my-app \
        --force-new-deployment \
        --region us-east-1
```

### Example 2: Configure Application Environment

```yaml
configure_app:
  stage: deploy
  image: ubuntu:22.04
  script:
    # Get infrastructure details
    - aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/terraform-outputs.json .
    
    # Extract specific values
    - export RDS_ENDPOINT=$(jq -r '.rds_host.value' terraform-outputs.json)
    - export VALKEY_ENDPOINT=$(jq -r '.valkey_host.value' terraform-outputs.json)
    - export ECR_REGISTRY=$(jq -r '.ecr_registry_id.value' terraform-outputs.json)
    
    # Use in deployment
    - kubectl set env deployment/my-app \
        --record \
        DATABASE_URL="postgres://user:pass@${RDS_ENDPOINT}:5432/ecommercedb" \
        REDIS_URL="redis://${VALKEY_ENDPOINT}:6379"
```

### Example 3: Push Docker Image to ECR

```yaml
push_to_ecr:
  stage: build
  image: aws/aws-cli:latest
  before_script:
    - apk add --no-cache docker
    - source infra-config.env
  script:
    # Login to ECR
    - aws ecr get-login-password --region us-east-1 | \
        docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Build and push
    - docker build -t $BACKEND_ECR_REPOSITORY_URL:$CI_COMMIT_SHA .
    - docker push $BACKEND_ECR_REPOSITORY_URL:$CI_COMMIT_SHA
    - docker tag $BACKEND_ECR_REPOSITORY_URL:$CI_COMMIT_SHA $BACKEND_ECR_REPOSITORY_URL:latest
    - docker push $BACKEND_ECR_REPOSITORY_URL:latest
```

---

## 🔐 Best Practices

### 1. **Security**
- ✅ Never hardcode infrastructure details in code
- ✅ Use AWS IAM roles instead of credentials
- ✅ Mask sensitive values in logs
- ✅ Encrypt artifacts in transit and at rest

### 2. **Versioning**
- ✅ Keep infrastructure artifacts versioned
- ✅ Support rollback to previous infrastructure state
- ✅ Track artifact changes in CI/CD logs

### 3. **Documentation**
- ✅ Document which pipeline exports which artifacts
- ✅ Keep artifact schema updated
- ✅ Provide examples for common use cases

### 4. **Error Handling**
```yaml
deploy:
  script:
    - |
      if ! source infra-config.env; then
        echo "Failed to load infrastructure configuration"
        exit 1
      fi
    
    - |
      if [ -z "$ECS_CLUSTER_NAME" ]; then
        echo "ECS_CLUSTER_NAME not set"
        exit 1
      fi
```

### 5. **Validation**
```bash
# Validate configuration before use
check_infra_config() {
  required_vars=(VPC_ID ECS_CLUSTER_NAME RDS_HOST VALKEY_HOST ECR_REGISTRY)
  
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      echo "Error: $var not set"
      return 1
    fi
  done
  
  echo "✅ All required infrastructure variables are set"
}
```

---

## 📊 Artifact Workflow Diagram

```
ECS Cluster Pipeline                    App Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. validate
2. plan
3. apply → Creates infrastructure
          ↓
4. export-artifacts:int
   • terraform-outputs.json
   • infra-config.env
   • infra-config.yaml
   • infra-manifest.json
          ↓
   ┌──────────────────────┐
   │ Store Artifacts      │
   │ • S3 (current/)      │
   │ • S3 (v-timestamp/)  │
   │ • GitLab variables   │
   └──────────────────────┘
          ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            Consume Artifacts
                  ↓
          ┌───────┴───────┐
          ↓               ↓
      Option 1        Option 2
      CI/CD Vars      Download S3
          ↓               ↓
      Deploy ←────────────┘
          ↓
   Application running
   on ECS cluster with
   database & cache
```

---

## 🚀 Quick Start

### For App Pipeline Team

1. **Option A - Use GitLab Variables** (Easiest)
   ```yaml
   deploy:
     script:
       - echo "Cluster: $ECS_CLUSTER_NAME"
       - echo "RDS Host: $RDS_HOST"
   ```

2. **Option B - Download from S3**
   ```yaml
   deploy:
     script:
       - aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/infra-config.env .
       - source infra-config.env
   ```

---

## 📞 Troubleshooting

### Variables Not Available
- ✅ Check if `export-artifacts:int` job completed successfully
- ✅ Verify GitLab variables are marked as protected
- ✅ Check CI/CD variable scope (group/project level)

### S3 Download Fails
- ✅ Verify AWS credentials in app pipeline
- ✅ Check S3 bucket permissions
- ✅ Ensure artifact exists: `aws s3 ls s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/`

### Missing Infrastructure Details
- ✅ Verify all Terraform outputs are exported
- ✅ Check `terraform output -json` shows expected values
- ✅ Review `infra-manifest.json` for artifact completeness

---

## 📚 Related Documentation

- [INFRA_ARTIFACT_STRATEGY.md](./INFRA_ARTIFACT_STRATEGY.md) - Architecture and design
- [.gitlab-ci.yml](./.gitlab-ci.yml) - Pipeline definition
- [Terraform Outputs](./outputs.tf) - Available infrastructure outputs

