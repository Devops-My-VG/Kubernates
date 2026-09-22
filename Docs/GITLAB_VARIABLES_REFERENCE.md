# GitLab Group Variables - Infrastructure Endpoints

**Group:** devops8004932 (kubernetes)  
**Environment:** INT  
**Cluster:** ecs-cluster-int  
**Region:** us-east-1  
**AWS Account:** 639140327478  
**Last Updated:** 2026-09-14

---

## Configured Variables for App Pipeline

### Database (PostgreSQL/RDS)

| Variable | Value |
|----------|-------|
| `DB_HOST` | `ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | `5432` |
| `DB_NAME` | `ecommercedb` |
| `DB_USERNAME` | `postgres` |

### Cache (Valkey Serverless)

| Variable | Value |
|----------|-------|
| `VALKEY_ENDPOINT` | `ecs-cluster-int-valkey-nwcsss.serverless.use1.cache.amazonaws.com` |
| `VALKEY_PORT` | `6379` |

### Container Registry (ECR)

| Variable | Value |
|----------|-------|
| `BACKEND_ECR_REGISTRY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` |
| `BACKEND_ECR_REPOSITORY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend` |
| `FRONTEND_ECR_REGISTRY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` |
| `FRONTEND_ECR_REPOSITORY` | `639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend` |

### ECS Cluster

| Variable | Value |
|----------|-------|
| `ECS_CLUSTER_NAME` | `ecs-cluster-int` |
| `ECS_CLUSTER_ARN` | `arn:aws:ecs:us-east-1:639140327478:cluster/ecs-cluster-int` |
| `ECS_TASK_EXECUTION_ROLE_ARN` | *(already configured)* |
| `ECS_TASK_ROLE_ARN` | *(already configured)* |

### Network & Logging

| Variable | Value |
|----------|-------|
| `AWS_REGION` | `us-east-1` |
| `AWS_ACCOUNT_ID` | `639140327478` |
| `VPC_ID` | `vpc-0667236d801895c4d` |
| `CLOUDWATCH_LOG_GROUP` | `/ecs/ecs-cluster-int` |

---

## How to Use in App Pipeline

### Example: Database Connection

```bash
export DATABASE_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
```

### Example: Valkey Cache Connection

```bash
export REDIS_URL="redis://${VALKEY_ENDPOINT}:${VALKEY_PORT}"
```

### Example: ECR Login & Push

```bash
# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${BACKEND_ECR_REGISTRY}

# Build and push image
docker build -t ${BACKEND_ECR_REPOSITORY}:latest .
docker push ${BACKEND_ECR_REPOSITORY}:latest
```

### Example: ECS Deployment

```bash
aws ecs update-service \
  --cluster ${ECS_CLUSTER_NAME} \
  --service backend \
  --force-new-deployment \
  --region ${AWS_REGION}
```

### Example: CloudWatch Logs

```bash
aws logs tail ${CLOUDWATCH_LOG_GROUP} --follow --region ${AWS_REGION}
```

---

## Sensitive Variables (Set in Secrets Manager)

These variables should NOT be set as GitLab variables. Instead, retrieve them from AWS Secrets Manager:

| Secret | Location | Usage |
|--------|----------|-------|
| `DB_PASSWORD` | `ecs-cluster-int/rds/master-password` | PostgreSQL authentication |
| `VALKEY_AUTH_TOKEN` | `ecs-cluster-int/valkey/auth-token` | Valkey authentication |
| `AWS_ACCESS_KEY_ID` | GitLab Group Variables (masked) | AWS CLI authentication |
| `AWS_SECRET_ACCESS_KEY` | GitLab Group Variables (masked) | AWS CLI authentication |

### Retrieve Secrets in Pipeline

```bash
# Get RDS password
export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region ${AWS_REGION} \
  --query SecretString \
  --output text)

# Get Valkey auth token
export VALKEY_AUTH_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/valkey/auth-token \
  --region ${AWS_REGION} \
  --query SecretString \
  --output text)
```

---

## Complete .gitlab-ci.yml Example

```yaml
variables:
  # Import from group variables (GitLab will auto-inject)
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: "639140327478"

deploy_app:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache aws-cli
    - aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${BACKEND_ECR_REGISTRY}
  script:
    # Get secrets from Secrets Manager
    - export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region ${AWS_REGION} --query SecretString --output text)
    - export VALKEY_AUTH_TOKEN=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/valkey/auth-token --region ${AWS_REGION} --query SecretString --output text)
    
    # Build Docker image
    - docker build 
        --build-arg DB_HOST=${DB_HOST}
        --build-arg DB_PORT=${DB_PORT}
        --build-arg DB_NAME=${DB_NAME}
        --build-arg DB_USERNAME=${DB_USERNAME}
        --build-arg DB_PASSWORD=${DB_PASSWORD}
        --build-arg VALKEY_ENDPOINT=${VALKEY_ENDPOINT}
        --build-arg VALKEY_PORT=${VALKEY_PORT}
        --build-arg VALKEY_AUTH_TOKEN=${VALKEY_AUTH_TOKEN}
        -t ${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
        -t ${BACKEND_ECR_REPOSITORY}:latest
        .
    
    # Push to ECR
    - docker push ${BACKEND_ECR_REPOSITORY}:${CI_COMMIT_SHA:0:8}
    - docker push ${BACKEND_ECR_REPOSITORY}:latest
    
    # Update ECS service
    - aws ecs update-service 
        --cluster ${ECS_CLUSTER_NAME}
        --service backend
        --force-new-deployment
        --region ${AWS_REGION}
    
    # Check deployment status
    - aws ecs describe-services
        --cluster ${ECS_CLUSTER_NAME}
        --services backend
        --region ${AWS_REGION}
```

---

## Testing Connectivity

### Test RDS Connection

```bash
# In CI pipeline
apt-get install -y postgresql-client
psql -h ${DB_HOST} -U ${DB_USERNAME} -d ${DB_NAME} -c "SELECT version();"
```

### Test Valkey Connection

```bash
# Using redis-cli
redis-cli -h ${VALKEY_ENDPOINT} -p ${VALKEY_PORT} PING
```

### Test ECR Access

```bash
aws ecr describe-repositories --region ${AWS_REGION}
```

### Test ECS Cluster Access

```bash
aws ecs describe-clusters --clusters ${ECS_CLUSTER_NAME} --region ${AWS_REGION}
```

---

## Troubleshooting

### Cannot connect to RDS

- Verify security groups allow ingress from ECS instances
- Check RDS endpoint is reachable from CI runner
- Ensure `DB_PASSWORD` is correctly retrieved from Secrets Manager

### Cannot connect to Valkey

- Verify security groups allow port 6379 from ECS instances
- Check Valkey endpoint is reachable
- Ensure `VALKEY_AUTH_TOKEN` is provided for authentication

### Cannot push to ECR

- Verify AWS credentials are configured
- Check ECR repository exists: `aws ecr describe-repositories --region ${AWS_REGION}`
- Ensure CI role has `ecr:*` permissions

### ECS Deployment Fails

- Check task definition exists
- Verify service exists in cluster
- Review CloudWatch logs: `aws logs tail ${CLOUDWATCH_LOG_GROUP} --follow`

---

## Related Documentation

- [ECS Infrastructure Implementation](./README_VALKEY.md)
- [Valkey Migration Guide](./VALKEY_MIGRATION_GUIDE.md)
- [Infrastructure Cost Analysis](./ECS_INFRASTRUCTURE_COST_ANALYSIS.html)
- [Deployment Checklist](./VALKEY_DEPLOYMENT_CHECKLIST.md)
