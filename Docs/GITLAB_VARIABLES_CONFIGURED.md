# GitLab Group Variables - Configured & Ready

**Date:** 2026-09-14  
**Group:** devops8004932 (Kubernetes)  
**Environment:** INT  
**Status:** ✅ **COMPLETE**

---

## Variables Configured

All infrastructure endpoints have been configured as GitLab group variables for the app deployment pipeline.

### AWS Account & Region

| Variable | Value | Usage |
|----------|-------|-------|
| `AWS_ACCOUNT_ID` | `639140327478` | AWS API calls, ECR login |
| `AWS_REGION` | `us-east-1` | All AWS service endpoints |

### Database (PostgreSQL/RDS)

| Variable | Value | Usage |
|----------|-------|-------|
| `DB_HOST` | `ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com` | Connection endpoint |
| `DB_PORT` | `5432` | Connection port |
| `DB_NAME` | `ecommercedb` | Database name |
| `DB_USERNAME` | `postgres` | RDS username |

**Connection String Construction:**
```bash
DATABASE_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
```

### Cache (Valkey Serverless)

| Variable | Value | Usage |
|----------|-------|-------|
| `VALKEY_ENDPOINT` | `ecs-cluster-int-valkey-nwcsss.serverless.use1.cache.amazonaws.com` | Cache endpoint |
| `VALKEY_PORT` | `6379` | Cache port |

**Connection String Construction:**
```bash
REDIS_URL="redis://${VALKEY_AUTH_TOKEN}@${VALKEY_ENDPOINT}:${VALKEY_PORT}"
```

### Container Registry (ECR)

| Variable | Value | Usage |
|----------|-------|-------|
| `BACKEND_ECR_REGISTRY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` | Registry URL |
| `BACKEND_ECR_REPOSITORY` | `ecs-cluster-int/backend` | Repository path |
| `FRONTEND_ECR_REGISTRY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` | Registry URL |
| `FRONTEND_ECR_REPOSITORY` | `ecs-cluster-int/frontend` | Repository path |

**Full ECR Repository URLs:**
```bash
BACKEND_IMAGE="${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}"
FRONTEND_IMAGE="${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}"
```

### ECS Cluster

| Variable | Value | Usage |
|----------|-------|-------|
| `ECS_CLUSTER_NAME` | `ecs-cluster-int` | Cluster name for deployments |

### Network & Logging

| Variable | Value | Usage |
|----------|-------|-------|
| `VPC_ID` | `vpc-0301d6ba38834d6aa` | Network reference |
| `CLOUDWATCH_LOG_GROUP` | `/ecs/ecs-cluster-int` | CloudWatch logs location |

---

## Complete .gitlab-ci.yml Example

```yaml
stages:
  - build
  - push
  - deploy
  - verify

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_BUILDKIT: 1

build:backend:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t backend:${CI_COMMIT_SHA:0:8} ./backend
  artifacts:
    reports:
      dotenv: build.env

build:frontend:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t frontend:${CI_COMMIT_SHA:0:8} ./frontend
  artifacts:
    reports:
      dotenv: build.env

push:ecr:
  stage: push
  image: amazon/aws-cli:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache docker
    - aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${BACKEND_ECR_REGISTRY}
  script:
    # Push backend
    - docker tag backend:${CI_COMMIT_SHA:0:8} ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
    - docker tag backend:${CI_COMMIT_SHA:0:8} ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:latest
    - docker push ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
    - docker push ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:latest
    
    # Push frontend
    - docker tag frontend:${CI_COMMIT_SHA:0:8} ${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
    - docker tag frontend:${CI_COMMIT_SHA:0:8} ${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:latest
    - docker push ${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
    - docker push ${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:latest
    
    # Export for next job
    - echo "BACKEND_IMAGE=${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}" >> deploy.env
    - echo "FRONTEND_IMAGE=${FRONTEND_ECR_REGISTRY}/${FRONTEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}" >> deploy.env
  artifacts:
    reports:
      dotenv: deploy.env

deploy:ecs:
  stage: deploy
  image: amazon/aws-cli:latest
  before_script:
    - apk add --no-cache jq
  script:
    # Get RDS password from Secrets Manager
    - |
      DB_PASSWORD=$(aws secretsmanager get-secret-value \
        --secret-id ecs-cluster-int/rds/master-password \
        --region ${AWS_REGION} \
        --query SecretString \
        --output text)
    
    # Get Valkey auth token from Secrets Manager
    - |
      VALKEY_AUTH_TOKEN=$(aws secretsmanager get-secret-value \
        --secret-id ecs-cluster-int/valkey/auth-token \
        --region ${AWS_REGION} \
        --query SecretString \
        --output text)
    
    # Create/Update task definition
    - |
      aws ecs register-task-definition \
        --family ${ECS_CLUSTER_NAME}-backend \
        --container-definitions "[{
          \"name\": \"backend\",
          \"image\": \"${BACKEND_IMAGE}\",
          \"essential\": true,
          \"portMappings\": [
            {\"containerPort\": 8000}
          ],
          \"environment\": [
            {\"name\": \"DATABASE_HOST\", \"value\": \"${DB_HOST}\"},
            {\"name\": \"DATABASE_PORT\", \"value\": \"${DB_PORT}\"},
            {\"name\": \"DATABASE_NAME\", \"value\": \"${DB_NAME}\"},
            {\"name\": \"DATABASE_USER\", \"value\": \"${DB_USERNAME}\"},
            {\"name\": \"REDIS_HOST\", \"value\": \"${VALKEY_ENDPOINT}\"},
            {\"name\": \"REDIS_PORT\", \"value\": \"${VALKEY_PORT}\"},
            {\"name\": \"AWS_REGION\", \"value\": \"${AWS_REGION}\"}
          ],
          \"secrets\": [
            {\"name\": \"DATABASE_PASSWORD\", \"valueFrom\": \"arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:ecs-cluster-int/rds/master-password\"},
            {\"name\": \"REDIS_PASSWORD\", \"valueFrom\": \"arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:ecs-cluster-int/valkey/auth-token\"}
          ],
          \"logConfiguration\": {
            \"logDriver\": \"awslogs\",
            \"options\": {
              \"awslogs-group\": \"${CLOUDWATCH_LOG_GROUP}\",
              \"awslogs-region\": \"${AWS_REGION}\",
              \"awslogs-stream-prefix\": \"backend\"
            }
          }
        }]" \
        --execution-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole" \
        --task-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskRole" \
        --network-mode awsvpc \
        --requires-compatibilities FARGATE \
        --cpu 256 \
        --memory 512 \
        --region ${AWS_REGION}
    
    # Update ECS service
    - |
      aws ecs update-service \
        --cluster ${ECS_CLUSTER_NAME} \
        --service backend \
        --force-new-deployment \
        --region ${AWS_REGION}

verify:deployment:
  stage: verify
  image: amazon/aws-cli:latest
  script:
    - |
      aws ecs describe-services \
        --cluster ${ECS_CLUSTER_NAME} \
        --services backend \
        --region ${AWS_REGION} \
        --query 'services[0].[serviceName,status,desiredCount,runningCount]' \
        --output table
    
    - |
      aws logs tail ${CLOUDWATCH_LOG_GROUP} --follow --region ${AWS_REGION} --since 5m
```

---

## Retrieving Sensitive Variables in Pipeline

### RDS Password

```bash
export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region ${AWS_REGION} \
  --query SecretString \
  --output text)
```

### Valkey Auth Token

```bash
export VALKEY_AUTH_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/valkey/auth-token \
  --region ${AWS_REGION} \
  --query SecretString \
  --output text)
```

---

## Testing Variables in Pipeline

Add this job to verify all variables are accessible:

```yaml
test:variables:
  stage: build
  image: amazon/aws-cli:latest
  script:
    - echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
    - echo "AWS_REGION: ${AWS_REGION}"
    - echo "DB_HOST: ${DB_HOST}"
    - echo "DB_PORT: ${DB_PORT}"
    - echo "DB_NAME: ${DB_NAME}"
    - echo "DB_USERNAME: ${DB_USERNAME}"
    - echo "VALKEY_ENDPOINT: ${VALKEY_ENDPOINT}"
    - echo "VALKEY_PORT: ${VALKEY_PORT}"
    - echo "BACKEND_ECR_REGISTRY: ${BACKEND_ECR_REGISTRY}"
    - echo "BACKEND_ECR_REPOSITORY: ${BACKEND_ECR_REPOSITORY}"
    - echo "FRONTEND_ECR_REGISTRY: ${FRONTEND_ECR_REGISTRY}"
    - echo "FRONTEND_ECR_REPOSITORY: ${FRONTEND_ECR_REPOSITORY}"
    - echo "ECS_CLUSTER_NAME: ${ECS_CLUSTER_NAME}"
    - echo "CLOUDWATCH_LOG_GROUP: ${CLOUDWATCH_LOG_GROUP}"
```

---

## Troubleshooting

### Variables Not Available in Pipeline

**Check:**
```bash
glab variable list -g devops8004932
```

**Verify in running pipeline:**
```bash
glab ci trace <job-id> | grep -A 20 "Secrets Manager"
```

### Cannot Access Secrets Manager

**Ensure IAM role has permissions:**
```bash
aws iam get-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-name SecretsManagerAccess \
  --region ${AWS_REGION}
```

### ECR Login Fails

**Verify registry is reachable:**
```bash
aws ecr describe-repositories \
  --region ${AWS_REGION} \
  --query 'repositories[].repositoryUri'
```

---

## Summary

✅ **All infrastructure endpoints configured and ready for app deployment pipeline**

The app pipeline can now:
- Connect to PostgreSQL RDS database
- Connect to Valkey Serverless cache
- Login to ECR and push container images
- Deploy to ECS cluster
- Stream logs to CloudWatch

**Next Step:** Use the provided `.gitlab-ci.yml` examples in your app deployment pipeline.
