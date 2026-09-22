# Ecommerce-App Deployment Pipeline - Required Inputs

**Last Updated:** September 13, 2026  
**Status:** ✅ Infrastructure Ready  
**Target:** GitLab CI/CD Pipeline for ECS Deployment

---

## 📋 TABLE OF CONTENTS

1. [Quick Reference](#quick-reference)
2. [AWS Account & Credentials](#aws-account--credentials)
3. [Infrastructure IDs & Endpoints](#infrastructure-ids--endpoints)
4. [Application Configuration](#application-configuration)
5. [Database & Cache Setup](#database--cache-setup)
6. [Docker Image Configuration](#docker-image-configuration)
7. [GitLab Variable Setup](#gitlab-variable-setup)
8. [Step-by-Step Setup Guide](#step-by-step-setup-guide)

---

## 🚀 QUICK REFERENCE

### **Minimum Required Inputs for Pipeline**

```yaml
# AWS Credentials (Required)
AWS_ACCESS_KEY_ID: "YOUR_AWS_ACCESS_KEY"
AWS_SECRET_ACCESS_KEY: "YOUR_AWS_SECRET_KEY"
AWS_ACCOUNT_ID: "639140327478"
AWS_REGION: "us-east-1"

# ECS Configuration (Required)
ECS_CLUSTER_NAME: "ecs-cluster-int"
ECS_TASK_EXECUTION_ROLE_ARN: "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role"
ECS_TASK_ROLE_ARN: "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role"

# Network Configuration (Required)
VPC_ID: "vpc-0301d6ba38834d6aa"
SUBNET_IDS: "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2"
SECURITY_GROUP_ID: "sg-04506e2e244ebc25a"

# Container Registry (Required)
BACKEND_ECR_REGISTRY: "639140327478.dkr.ecr.us-east-1.amazonaws.com"
BACKEND_ECR_REPOSITORY: "ecs-cluster-int/backend"
FRONTEND_ECR_REGISTRY: "639140327478.dkr.ecr.us-east-1.amazonaws.com"
FRONTEND_ECR_REPOSITORY: "ecs-cluster-int/frontend"

# Application Secrets (Required - from Secrets Manager)
DB_HOST: "ecs-cluster-int-postgres-db.XXXXX.us-east-1.rds.amazonaws.com"
DB_PORT: "5432"
DB_NAME: "ecommercedb"
DB_USERNAME: "postgres"
DB_PASSWORD: "****" # From Secrets Manager
REDIS_HOST: "ecs-cluster-int-redis.XXXXX.ng.0001.use1.cache.amazonaws.com"
REDIS_PORT: "6379"
REDIS_PASSWORD: "****" # From Secrets Manager
JWT_SECRET: "your-jwt-secret-key"
```

---

## 🔑 AWS ACCOUNT & CREDENTIALS

### Your AWS Account Details

```
AWS Account ID:         639140327478
Region:                 us-east-1
Profile Name:           $AWS_PROFILE
Environment:            INT (Development/Integration)
```

### AWS Credentials

You need to create an IAM user with ECS/ECR deployment permissions:

```bash
# Steps to create IAM user (one-time setup):
1. Go to AWS Console → IAM → Users → Create User
2. User name: ecommerce-app-deployment
3. Attach policies:
   - AmazonEC2ContainerServiceFullAccess
   - AmazonEC2ContainerRegistryFullAccess
   - SecretsManagerReadWrite
   - AmazonS3FullAccess
4. Generate Access Key ID and Secret Access Key
5. Save credentials securely (never commit to repo)
```

**GitLab Variable Names:**
```
AWS_ACCESS_KEY_ID              → Your IAM user access key
AWS_SECRET_ACCESS_KEY          → Your IAM user secret key
AWS_ACCOUNT_ID                 → 639140327478
AWS_REGION                     → us-east-1
```

**How to Get Credentials:**

```bash
# If you already have credentials configured locally:
aws configure --profile $AWS_PROFILE

# Verify credentials work:
aws sts get-caller-identity --profile $AWS_PROFILE

# Extract for GitLab:
aws configure get aws_access_key_id --profile $AWS_PROFILE
aws configure get aws_secret_access_key --profile $AWS_PROFILE
```

---

## 🏗️ INFRASTRUCTURE IDS & ENDPOINTS

### ECS Cluster Details

```
Cluster Name:                   ecs-cluster-int
Cluster ARN:                    arn:aws:ecs:us-east-1:639140327478:cluster/ecs-cluster-int

Auto Scaling Group:
  Name:                         ecs-cluster-int-asg
  Min Size:                     2
  Desired Capacity:             2
  Max Size:                     4
  Instance Type:                t3.micro

EC2 Instances:
  Instance 1 ID:                i-04aefede4e610ac7c
  Instance 1 IP:                3.84.248.69
  Instance 2 ID:                i-0c11696ebd07628ed
  Instance 2 IP:                100.54.138.49

Load Balancer:
  Name:                         ecs-cluster-int-alb
  DNS Name:                     ecs-cluster-int-alb-XXXXX.us-east-1.elb.amazonaws.com
  Listener Port:                80 (HTTP)
  Target Group:                 ecs-cluster-int-tg
```

**GitLab Variable Names:**
```
ECS_CLUSTER_NAME               → ecs-cluster-int
ECS_TASK_EXECUTION_ROLE_ARN    → arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role
ECS_TASK_ROLE_ARN              → arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role
```

**How to Get These:**

```bash
# Get Cluster Name
aws ecs list-clusters --region us-east-1 --profile $AWS_PROFILE

# Get Task Execution Role ARN
aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $AWS_PROFILE --query 'Role.Arn' --output text

# Get Task Role ARN
aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $AWS_PROFILE --query 'Role.Arn' --output text
```

### Network Configuration

```
VPC:
  VPC ID:                       vpc-0301d6ba38834d6aa
  CIDR Block:                   10.0.0.0/16
  Region:                       us-east-1

Public Subnets:
  Subnet 1 (us-east-1a):        subnet-05db786298e4e5df9 (10.0.0.0/24)
  Subnet 2 (us-east-1b):        subnet-03e658a1a4fac1ff2 (10.0.1.0/24)

Security Groups:
  ECS Security Group:           sg-04506e2e244ebc25a
  RDS Security Group:           sg-XXXXX (allows 5432 from ECS)
  Redis Security Group:         sg-XXXXX (allows 6379+16379 from ECS)
```

**GitLab Variable Names:**
```
VPC_ID                         → vpc-0301d6ba38834d6aa
SUBNET_IDS                     → subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2
SECURITY_GROUP_ID              → sg-04506e2e244ebc25a
```

**How to Get These:**

```bash
# Get VPC ID
aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.0.0.0/16" --region us-east-1 --profile $AWS_PROFILE --query 'Vpcs[0].VpcId' --output text

# Get Subnet IDs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0301d6ba38834d6aa" --region us-east-1 --profile $AWS_PROFILE --query 'Subnets[*].[SubnetId,AvailabilityZone]' --output text

# Get Security Group ID
aws ec2 describe-security-groups --filters "Name=group-name,Values=ecs_sg" --region us-east-1 --profile $AWS_PROFILE --query 'SecurityGroups[0].GroupId' --output text
```

---

## 🐳 CONTAINER REGISTRY (ECR)

### ECR Repository Details

```
AWS Account ID:                 639140327478
Region:                         us-east-1

Backend Repository:
  Repository Name:              ecs-cluster-int/backend
  Repository URI:               639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend
  Image Scanning:               Enabled
  Encryption:                   KMS

Frontend Repository:
  Repository Name:              ecs-cluster-int/frontend
  Repository URI:               639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend
  Image Scanning:               Enabled
  Encryption:                   KMS
```

**GitLab Variable Names:**
```
BACKEND_ECR_REGISTRY           → 639140327478.dkr.ecr.us-east-1.amazonaws.com
BACKEND_ECR_REPOSITORY         → ecs-cluster-int/backend
FRONTEND_ECR_REGISTRY          → 639140327478.dkr.ecr.us-east-1.amazonaws.com
FRONTEND_ECR_REPOSITORY        → ecs-cluster-int/frontend
```

**How to Get These:**

```bash
# List ECR repositories
aws ecr describe-repositories --region us-east-1 --profile $AWS_PROFILE --query 'repositories[*].[repositoryName,repositoryUri]' --output table
```

---

## 📊 APPLICATION CONFIGURATION

### Environment Variables

```yaml
# Basic Environment Settings
ENVIRONMENT: "int"
LOG_LEVEL: "info"
APP_PORT: "3000"
NODE_ENV: "production"

# API Configuration
API_BASE_URL: "http://ecs-cluster-int-alb-XXXXX.us-east-1.elb.amazonaws.com/api"
FRONTEND_URL: "http://ecs-cluster-int-alb-XXXXX.us-east-1.elb.amazonaws.com"

# JWT/Authentication
JWT_SECRET: "your-jwt-secret-key-here"
JWT_EXPIRES_IN: "7d"

# Email Configuration (Gmail/Office365/Custom)
EMAIL_USERNAME: "your-email@gmail.com"
EMAIL_PASSWORD: "your-app-password"
EMAIL_FROM: "noreply@ecommerceapp.com"
SMTP_HOST: "smtp.gmail.com"
SMTP_PORT: "587"

# Google OAuth (Optional)
GOOGLE_CLIENT_ID: "your-google-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET: "your-google-client-secret"
GOOGLE_CALLBACK_URL: "http://ecs-cluster-int-alb-XXXXX.us-east-1.elb.amazonaws.com/auth/google/callback"

# Monitoring
SENTRY_DSN: "https://your-sentry-key@sentry.io/project-id" (Optional)
NEW_RELIC_LICENSE_KEY: "your-newrelic-key" (Optional)
```

**Note:** Do NOT include actual secrets in environment variables. Use Secrets Manager instead (see below).

---

## 🗄️ DATABASE & CACHE SETUP

### RDS PostgreSQL Credentials

All credentials are stored in **AWS Secrets Manager**. The ECS task will automatically retrieve them.

```
Secret Name:                    ecs-cluster-int/rds/master-password

Database Details:
  Host:                         ecs-cluster-int-postgres-db.XXXXX.us-east-1.rds.amazonaws.com
  Port:                         5432
  Database Name:                ecommercedb
  Master Username:              postgres
  Master Password:              🔐 (auto-generated, in Secrets Manager)
  Multi-AZ:                     Enabled
  Backup Retention:             7 days
  Encryption:                   AES-256 (KMS)
```

**How to Retrieve Database Credentials:**

```bash
# Get full secret
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq .

# Extract just the password
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.password'

# Extract the host
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.host'
```

**Pipeline Variables (from Secrets Manager):**
```
DB_HOST                        → Retrieved from Secrets Manager
DB_PORT                        → 5432
DB_NAME                        → ecommercedb
DB_USERNAME                    → postgres
DB_PASSWORD                    → Retrieved from Secrets Manager

# Or as connection string:
DATABASE_URL: "postgresql://postgres:PASSWORD@HOST:5432/ecommercedb"
```

### Database Initialization

Before deploying the application, you need to run migrations:

```bash
# 1. Connect to RDS
export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.password')

export DB_HOST=$(aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.host')

# 2. Run migrations
psql -h $DB_HOST -U postgres -d ecommercedb -f migrations/001_init.sql

# 3. Verify
psql -h $DB_HOST -U postgres -d ecommercedb -c "\dt"
```

### ElastiCache Redis Credentials

All credentials are stored in **AWS Secrets Manager**.

```
Secret Name:                    ecs-cluster-int/redis/auth-token

Cache Details:
  Host:                         ecs-cluster-int-redis.XXXXX.ng.0001.use1.cache.amazonaws.com
  Port:                         6379
  Auth Token:                   🔐 (auto-generated, in Secrets Manager)
  Engine:                       Redis 7.0
  Node Type:                    cache.t3.micro
  Number of Nodes:              2 (Multi-AZ)
  Encryption at Rest:           Enabled
  Encryption in Transit:        Enabled
  Persistence:                  AOF (Append Only File)
```

**How to Retrieve Redis Credentials:**

```bash
# Get full secret
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/redis/auth-token \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq .

# Extract auth token
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/redis/auth-token \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.auth_token'

# Extract host
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/redis/auth-token \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq -r '.host'
```

**Pipeline Variables (from Secrets Manager):**
```
REDIS_HOST                     → Retrieved from Secrets Manager
REDIS_PORT                     → 6379
REDIS_PASSWORD                 → Retrieved from Secrets Manager

# Or as connection string:
REDIS_URL: "redis://:AUTH_TOKEN@HOST:6379/0"
```

---

## 🐳 DOCKER IMAGE CONFIGURATION

### Dockerfile Requirements

Your backend and frontend Dockerfiles should:

**Backend Dockerfile:**
```dockerfile
FROM node:18-alpine
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --production

# Copy application code
COPY . .

# Build TypeScript (if applicable)
RUN npm run build

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node healthcheck.js

# Start application
CMD ["npm", "start"]
```

**Frontend Dockerfile:**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Image Tagging Strategy

```
Development:  IMAGE:dev-[commit-sha]
              IMAGE:dev-latest

Staging:      IMAGE:staging-[commit-sha]
              IMAGE:staging-latest

Production:   IMAGE:v1.0.0
              IMAGE:latest
```

**GitLab CI/CD Example:**
```bash
# For INT (development)
IMAGE_TAG="${CI_COMMIT_SHORT_SHA}"
FULL_IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

# Tag as latest
docker tag ${FULL_IMAGE_NAME} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

# Push both
docker push ${FULL_IMAGE_NAME}
docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
```

---

## 📝 GITLAB VARIABLE SETUP

### Step 1: Create GitLab Variables

Go to **GitLab Project → Settings → CI/CD → Variables** and add:

#### AWS Credentials (Protected/Masked)
```
AWS_ACCESS_KEY_ID              [Protected] [Masked]
AWS_SECRET_ACCESS_KEY          [Protected] [Masked]
AWS_ACCOUNT_ID                 [Protected]
AWS_REGION                     [Protected]
```

#### ECS Configuration (Protected)
```
ECS_CLUSTER_NAME               [Protected]
ECS_TASK_EXECUTION_ROLE_ARN    [Protected]
ECS_TASK_ROLE_ARN              [Protected]
```

#### Network Configuration (Protected)
```
VPC_ID                         [Protected]
SUBNET_IDS                     [Protected]
SECURITY_GROUP_ID              [Protected]
```

#### ECR Configuration (Protected)
```
BACKEND_ECR_REGISTRY           [Protected]
BACKEND_ECR_REPOSITORY         [Protected]
FRONTEND_ECR_REGISTRY          [Protected]
FRONTEND_ECR_REPOSITORY        [Protected]
```

#### Application Configuration
```
ENVIRONMENT                    [Protected]
LOG_LEVEL                      [Protected]
APP_PORT                       [Protected]
NODE_ENV                       [Protected]
```

### Step 2: Create Script to Setup Variables

```bash
#!/bin/bash
# setup-gitlab-variables.sh

# Requires:
# - GitLab personal access token with api scope
# - jq installed

GITLAB_TOKEN="your-personal-access-token"
GITLAB_PROJECT_ID="12345"
GITLAB_URL="https://gitlab.com"

# Function to create variable
create_variable() {
  local key=$1
  local value=$2
  local protected=$3
  local masked=$4

  curl --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --form "key=$key" \
    --form "value=$value" \
    --form "protected=$protected" \
    --form "masked=$masked" \
    "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/variables"
}

# Create AWS credentials
create_variable "AWS_ACCESS_KEY_ID" "your-access-key" "true" "true"
create_variable "AWS_SECRET_ACCESS_KEY" "your-secret-key" "true" "true"
create_variable "AWS_ACCOUNT_ID" "639140327478" "true" "false"
create_variable "AWS_REGION" "us-east-1" "true" "false"

# Create ECS variables
create_variable "ECS_CLUSTER_NAME" "ecs-cluster-int" "true" "false"
create_variable "ECS_TASK_EXECUTION_ROLE_ARN" "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role" "true" "false"
create_variable "ECS_TASK_ROLE_ARN" "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role" "true" "false"

# ... etc for other variables
```

---

## 📋 STEP-BY-STEP SETUP GUIDE

### Phase 1: Prepare AWS Credentials

```bash
# Step 1: Create IAM user for ECS deployment
aws iam create-user --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Step 2: Attach required policies
aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess \
  --profile $AWS_PROFILE

aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess \
  --profile $AWS_PROFILE

# Step 3: Generate access keys
aws iam create-access-key --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Step 4: Save the output (you'll need AccessKeyId and SecretAccessKey)
```

### Phase 2: Retrieve Infrastructure Details

```bash
# Retrieve all infrastructure details at once
cat > get-infrastructure-details.sh << 'EOF'
#!/bin/bash

PROFILE="$AWS_PROFILE"
REGION="us-east-1"

echo "=== AWS ACCOUNT DETAILS ==="
aws sts get-caller-identity --profile $PROFILE

echo -e "\n=== ECS CLUSTER ==="
aws ecs list-clusters --region $REGION --profile $PROFILE --query 'clusterArns' --output text

echo -e "\n=== VPC AND SUBNETS ==="
aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.0.0.0/16" --region $REGION --profile $PROFILE --query 'Vpcs[0].VpcId' --output text

aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0301d6ba38834d6aa" --region $REGION --profile $PROFILE --query 'Subnets[*].[SubnetId,AvailabilityZone]' --output table

echo -e "\n=== SECURITY GROUPS ==="
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-0301d6ba38834d6aa" --region $REGION --profile $PROFILE --query 'SecurityGroups[*].[GroupId,GroupName]' --output table

echo -e "\n=== IAM ROLES ==="
aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $PROFILE --query 'Role.Arn' --output text

aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $PROFILE --query 'Role.Arn' --output text

echo -e "\n=== ECR REPOSITORIES ==="
aws ecr describe-repositories --region $REGION --profile $PROFILE --query 'repositories[*].[repositoryName,repositoryUri]' --output table

echo -e "\n=== RDS DATABASE ==="
aws rds describe-db-instances --db-instance-identifier ecs-cluster-int-postgres-db --region $REGION --profile $PROFILE --query 'DBInstances[0].[DBInstanceIdentifier,Endpoint.Address,DBName,MasterUsername]' --output table

echo -e "\n=== ELASTICACHE REDIS ==="
aws elasticache describe-cache-clusters --cache-cluster-id ecs-cluster-int-redis --show-cache-node-info --region $REGION --profile $PROFILE --query 'CacheClusters[0].[CacheClusterId,Engine,CacheNodeType,CacheNodes[0].Endpoint]' --output table

echo -e "\n=== SECRETS MANAGER ==="
aws secretsmanager list-secrets --region $REGION --profile $PROFILE --query 'SecretList[?contains(Name, `ecs-cluster-int`)].Name' --output table
EOF

chmod +x get-infrastructure-details.sh
./get-infrastructure-details.sh
```

### Phase 3: Set GitLab Variables

```bash
# Create GitLab variables from retrieved details
cat > setup-gitlab-vars.sh << 'EOF'
#!/bin/bash

# Fill in your GitLab token
GITLAB_TOKEN="your-gitlab-personal-access-token"
PROJECT_ID="your-gitlab-project-id"
GITLAB_URL="https://gitlab.com"

# Function to set variable
set_variable() {
  local key=$1
  local value=$2
  local protected=${3:-true}
  local masked=${4:-false}

  curl --request POST "$GITLAB_URL/api/v4/projects/$PROJECT_ID/variables" \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --form "key=$key" \
    --form "value=$value" \
    --form "protected=$protected" \
    --form "masked=$masked"
}

# Set all required variables
set_variable "AWS_ACCESS_KEY_ID" "YOUR_ACCESS_KEY" "true" "true"
set_variable "AWS_SECRET_ACCESS_KEY" "YOUR_SECRET_KEY" "true" "true"
set_variable "AWS_ACCOUNT_ID" "639140327478" "true" "false"
set_variable "AWS_REGION" "us-east-1" "true" "false"
set_variable "ECS_CLUSTER_NAME" "ecs-cluster-int" "true" "false"
set_variable "VPC_ID" "vpc-0301d6ba38834d6aa" "true" "false"
set_variable "SUBNET_IDS" "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2" "true" "false"
set_variable "SECURITY_GROUP_ID" "sg-04506e2e244ebc25a" "true" "false"
set_variable "BACKEND_ECR_REGISTRY" "639140327478.dkr.ecr.us-east-1.amazonaws.com" "true" "false"
set_variable "BACKEND_ECR_REPOSITORY" "ecs-cluster-int/backend" "true" "false"
set_variable "FRONTEND_ECR_REGISTRY" "639140327478.dkr.ecr.us-east-1.amazonaws.com" "true" "false"
set_variable "FRONTEND_ECR_REPOSITORY" "ecs-cluster-int/frontend" "true" "false"

echo "GitLab variables configured successfully!"
EOF

chmod +x setup-gitlab-vars.sh
```

### Phase 4: Verify Database & Cache Access

```bash
# Test RDS connection
psql -h $(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host') \
  -U postgres -d ecommercedb -c "SELECT version();"

# Test Redis connection
redis-cli -h $(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host') \
  -p 6379 \
  -a $(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.auth_token') \
  PING

# Test S3 access
aws s3 ls s3://ecs-cluster-int-app-storage-639140327478/ --region us-east-1 --profile $AWS_PROFILE
```

### Phase 5: Build & Push Initial Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 --profile $AWS_PROFILE | \
  docker login --username AWS --password-stdin 639140327478.dkr.ecr.us-east-1.amazonaws.com

# Build backend image
docker build -t 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend:latest ./backend

# Push backend image
docker push 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend:latest

# Build frontend image
docker build -t 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend:latest ./frontend

# Push frontend image
docker push 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend:latest

# Verify images in ECR
aws ecr describe-images \
  --repository-name ecs-cluster-int/backend \
  --region us-east-1 \
  --profile $AWS_PROFILE
```

---

## 📌 CHECKLIST FOR APP DEPLOYMENT

- [ ] AWS IAM user created with ECS/ECR permissions
- [ ] AWS Access Key ID and Secret Access Key saved securely
- [ ] GitLab variables configured (20+ variables)
- [ ] RDS database accessible from EC2 instances
- [ ] Redis cache accessible from EC2 instances
- [ ] S3 buckets verified and accessible
- [ ] Docker images built locally
- [ ] Initial backend image pushed to ECR
- [ ] Initial frontend image pushed to ECR
- [ ] Database migrations completed
- [ ] ECS task definition created with correct image references
- [ ] ECS service created and task deployed
- [ ] Health checks passing
- [ ] Application endpoint responding
- [ ] Logs visible in CloudWatch
- [ ] Monitoring alarms active

---

## 🔗 QUICK REFERENCE COMMANDS

```bash
# Verify infrastructure setup
terraform output -json > infrastructure_outputs.json

# Check ECS cluster
aws ecs describe-clusters --clusters ecs-cluster-int --region us-east-1 --profile $AWS_PROFILE

# View ECS logs
aws logs tail /ecs/ecs-cluster-int --follow --profile $AWS_PROFILE

# Get RDS endpoint
aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host'

# Get Redis endpoint
aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host'

# List ECR images
aws ecr list-images --repository-name ecs-cluster-int/backend --region us-east-1 --profile $AWS_PROFILE
```

---

## ✅ DEPLOYMENT READY

All inputs are documented and organized. Follow the step-by-step setup guide to prepare your GitLab CI/CD pipeline for application deployment.

**Next Steps:**
1. Create AWS IAM user and get credentials
2. Retrieve all infrastructure details using provided scripts
3. Configure GitLab variables
4. Test connectivity to all services
5. Build and push initial Docker images
6. Deploy ECS task definition and service
7. Monitor deployment and logs

---

**Infrastructure:** ✅ Deployed  
**Inputs:** ✅ Documented  
**Pipeline:** 🚀 Ready for deployment

