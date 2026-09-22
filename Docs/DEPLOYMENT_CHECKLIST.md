# GitLab CI/CD Pipeline - Deployment Input Checklist

**Purpose:** Quick reference for all inputs needed to deploy Ecommerce-App via GitLab pipeline  
**Target:** Deployment Engineer  
**Status:** ✅ Ready for Input

---

## 🎯 WHAT THE PIPELINE DOES

```
Your Input (GitLab Variables)
         ↓
GitLab CI/CD Pipeline Receives Variables
         ↓
Pipeline Stage 1: Build
  - Compile backend/frontend code
  - Run tests
         ↓
Pipeline Stage 2: Push to ECR
  - Build Docker images
  - Push to AWS ECR repositories
         ↓
Pipeline Stage 3: Deploy to ECS
  - Update ECS task definition with new image
  - Deploy to ECS cluster
  - Auto-scales to 2-4 tasks
         ↓
Pipeline Stage 4: Verify
  - Health checks
  - Verify logs in CloudWatch
         ↓
Application Running ✅
```

---

## 📋 COMPLETE INPUT CHECKLIST

### SECTION 1: AWS ACCOUNT & CREDENTIALS

**What to provide:**
```
✓ AWS_ACCESS_KEY_ID
  └─ Format: AKIA... (20 characters)
  └─ Source: AWS IAM → Create new user → Generate Access Key
  └─ Note: Keep this secret! Mark as [Protected] [Masked] in GitLab

✓ AWS_SECRET_ACCESS_KEY
  └─ Format: Long random string (40 characters)
  └─ Source: AWS IAM → Generate with Access Key ID
  └─ Note: Keep this secret! Mark as [Protected] [Masked] in GitLab

✓ AWS_ACCOUNT_ID
  └─ Value: 639140327478 (already provided)
  └─ Description: Your AWS account number

✓ AWS_REGION
  └─ Value: us-east-1 (already provided)
  └─ Description: AWS region for all resources
```

**Where to find/create:**
```bash
# Create AWS IAM user for deployment
aws iam create-user --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Attach policies
aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess

aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

# Generate access keys
aws iam create-access-key --user-name ecommerce-app-deployment

# Output will show:
# AccessKeyId: AKIA... ← USE THIS FOR AWS_ACCESS_KEY_ID
# SecretAccessKey: ... ← USE THIS FOR AWS_SECRET_ACCESS_KEY
```

---

### SECTION 2: ECS CLUSTER CONFIGURATION

**What to provide:**
```
✓ ECS_CLUSTER_NAME
  └─ Value: ecs-cluster-int
  └─ Description: Name of your ECS cluster

✓ ECS_TASK_EXECUTION_ROLE_ARN
  └─ Format: arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role
  └─ Description: IAM role for pulling images and logs

✓ ECS_TASK_ROLE_ARN
  └─ Format: arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role
  └─ Description: IAM role for application to access S3, Secrets, CloudWatch

✓ DESIRED_TASK_COUNT
  └─ Value: 2 (minimum recommended)
  └─ Description: Number of tasks to run initially
  └─ Auto-scales: 2-4 based on CPU

✓ TASK_CPU
  └─ Value: 256 (0.25 vCPU)
  └─ Description: CPU per task

✓ TASK_MEMORY
  └─ Value: 512 (512 MB)
  └─ Description: Memory per task
```

**Where to find:**
```bash
# Get cluster name
aws ecs list-clusters --region us-east-1 --profile $AWS_PROFILE --query 'clusterArns' --output text
# Output: arn:aws:ecs:us-east-1:639140327478:cluster/ecs-cluster-int
# Extract: ecs-cluster-int

# Get task execution role ARN
aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $AWS_PROFILE --query 'Role.Arn' --output text
# Output: arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role

# Get task role ARN
aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $AWS_PROFILE --query 'Role.Arn' --output text
# Output: arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role
```

---

### SECTION 3: NETWORK CONFIGURATION

**What to provide:**
```
✓ VPC_ID
  └─ Value: vpc-0301d6ba38834d6aa
  └─ Description: Your VPC where ECS runs

✓ SUBNET_IDS
  └─ Value: subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2
  └─ Format: Comma-separated, no spaces
  └─ Description: Public subnets for ECS tasks (2 for HA)

✓ SECURITY_GROUP_ID
  └─ Value: sg-04506e2e244ebc25a
  └─ Description: Security group for ECS tasks
  └─ Allows: Inbound on port 80 (from ALB)
```

**Where to find:**
```bash
# Get VPC ID
aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.0.0.0/16" --region us-east-1 --profile $AWS_PROFILE --query 'Vpcs[0].VpcId' --output text

# Get subnet IDs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0301d6ba38834d6aa" --region us-east-1 --profile $AWS_PROFILE --query 'Subnets[*].SubnetId' --output text | tr '\t' ','

# Get security group ID
aws ec2 describe-security-groups --filters "Name=group-name,Values=ecs_sg" --region us-east-1 --profile $AWS_PROFILE --query 'SecurityGroups[0].GroupId' --output text
```

---

### SECTION 4: CONTAINER REGISTRY (ECR)

**What to provide:**
```
✓ BACKEND_ECR_REGISTRY
  └─ Value: 639140327478.dkr.ecr.us-east-1.amazonaws.com
  └─ Format: ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com

✓ BACKEND_ECR_REPOSITORY
  └─ Value: ecs-cluster-int/backend
  └─ Description: ECR repository name for backend

✓ FRONTEND_ECR_REGISTRY
  └─ Value: 639140327478.dkr.ecr.us-east-1.amazonaws.com
  └─ Format: Same as backend registry

✓ FRONTEND_ECR_REPOSITORY
  └─ Value: ecs-cluster-int/frontend
  └─ Description: ECR repository name for frontend
```

**Where to find:**
```bash
# List ECR repositories
aws ecr describe-repositories --region us-east-1 --profile $AWS_PROFILE --query 'repositories[*].[repositoryName,repositoryUri]' --output table

# Output will show:
# | ecs-cluster-int/backend | 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend |
# | ecs-cluster-int/frontend | 639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend |
```

---

### SECTION 5: DATABASE CONFIGURATION

**What to provide:**
```
✓ DB_HOST
  └─ Value: ecs-cluster-int-postgres-db.XXXXX.us-east-1.rds.amazonaws.com
  └─ Description: RDS endpoint
  └─ Get from: Secrets Manager

✓ DB_PORT
  └─ Value: 5432
  └─ Description: PostgreSQL default port

✓ DB_NAME
  └─ Value: ecommercedb
  └─ Description: Database name

✓ DB_USERNAME
  └─ Value: postgres
  └─ Description: Master username

✓ DB_PASSWORD
  └─ Value: From Secrets Manager
  └─ Description: Master password
  └─ Note: Secrets Manager auto-generated this

✓ DATABASE_URL (alternative)
  └─ Format: postgresql://postgres:PASSWORD@HOST:5432/ecommercedb
  └─ Description: Full connection string
```

**Where to find:**
```bash
# Get from Secrets Manager (auto-generated, stored securely)
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq .

# Output example:
# {
#   "username": "postgres",
#   "password": "auto-generated-password",
#   "engine": "postgres",
#   "host": "ecs-cluster-int-postgres-db.c123abc.us-east-1.rds.amazonaws.com",
#   "port": 5432,
#   "dbname": "ecommercedb"
# }

# Extract individual values:
export DB_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host')
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.password')
```

---

### SECTION 6: CACHE CONFIGURATION

**What to provide:**
```
✓ REDIS_HOST
  └─ Value: ecs-cluster-int-redis.XXXXX.ng.0001.use1.cache.amazonaws.com
  └─ Description: Redis endpoint
  └─ Get from: Secrets Manager

✓ REDIS_PORT
  └─ Value: 6379
  └─ Description: Redis default port

✓ REDIS_PASSWORD
  └─ Value: From Secrets Manager
  └─ Description: AUTH token
  └─ Note: Secrets Manager auto-generated this

✓ REDIS_URL (alternative)
  └─ Format: redis://:AUTH_TOKEN@HOST:6379/0
  └─ Description: Full connection string
```

**Where to find:**
```bash
# Get from Secrets Manager (auto-generated, stored securely)
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/redis/auth-token \
  --region us-east-1 \
  --profile $AWS_PROFILE \
  --query SecretString --output text | jq .

# Output example:
# {
#   "auth_token": "auto-generated-token",
#   "host": "ecs-cluster-int-redis.abc123.ng.0001.use1.cache.amazonaws.com",
#   "port": 6379,
#   "engine": "redis"
# }

# Extract individual values:
export REDIS_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.host')
export REDIS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region us-east-1 --profile $AWS_PROFILE --query SecretString --output text | jq -r '.auth_token')
```

---

### SECTION 7: APPLICATION CONFIGURATION

**What to provide:**
```
✓ ENVIRONMENT
  └─ Value: int (or: dev, staging, prod)
  └─ Description: Deployment environment

✓ LOG_LEVEL
  └─ Value: info (or: debug, warn, error)
  └─ Description: Logging level

✓ NODE_ENV
  └─ Value: production
  └─ Description: Node.js environment

✓ APP_PORT
  └─ Value: 3000 (backend), 80 (frontend in container)
  └─ Description: Application port inside container

✓ JWT_SECRET
  └─ Value: Generate random string (min 32 characters)
  └─ Description: JWT signing key
  └─ Command to generate: openssl rand -base64 32
```

**Where to generate:**
```bash
# Generate JWT_SECRET
openssl rand -base64 32
# Output: AbC+/D8EfGhI9jK0lMnOpQrStUvWxYzAbC+/D8EfGhI9jK= (copy this)

# OR use Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# These are randomly generated - create new values for your deployment
```

---

### SECTION 8: OPTIONAL - EMAIL CONFIGURATION

**What to provide (if sending emails):**
```
✓ EMAIL_USERNAME
  └─ Value: your-email@gmail.com
  └─ Description: Email account for sending

✓ EMAIL_PASSWORD
  └─ Value: app-specific-password (NOT your regular password)
  └─ Description: Gmail app password
  └─ Generate from: Gmail → Settings → Security → App Passwords

✓ SMTP_HOST
  └─ Value: smtp.gmail.com
  └─ Description: SMTP server

✓ SMTP_PORT
  └─ Value: 587
  └─ Description: SMTP port (TLS)

✓ EMAIL_FROM
  └─ Value: noreply@ecommerceapp.com
  └─ Description: From address in emails
```

---

### SECTION 9: OPTIONAL - GOOGLE OAUTH

**What to provide (if using Google login):**
```
✓ GOOGLE_CLIENT_ID
  └─ Value: Your Google OAuth client ID
  └─ Get from: Google Cloud Console → OAuth 2.0 Credentials
  └─ Format: XXX...XXX.apps.googleusercontent.com

✓ GOOGLE_CLIENT_SECRET
  └─ Value: Your Google OAuth client secret
  └─ Get from: Google Cloud Console
  └─ Keep this secret!

✓ GOOGLE_CALLBACK_URL
  └─ Value: http://ecs-cluster-int-alb-XXXXX.us-east-1.elb.amazonaws.com/auth/google/callback
  └─ Description: Redirect URL registered in Google Cloud Console
```

---

## 📊 FULL GITLAB VARIABLES TEMPLATE

```yaml
# AWS Credentials
AWS_ACCESS_KEY_ID: "AKIA..."                                    # [Protected] [Masked]
AWS_SECRET_ACCESS_KEY: "..."                                    # [Protected] [Masked]
AWS_ACCOUNT_ID: "639140327478"                                  # [Protected]
AWS_REGION: "us-east-1"                                         # [Protected]

# ECS Configuration
ECS_CLUSTER_NAME: "ecs-cluster-int"                            # [Protected]
ECS_TASK_EXECUTION_ROLE_ARN: "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role"  # [Protected]
ECS_TASK_ROLE_ARN: "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role"  # [Protected]
DESIRED_TASK_COUNT: "2"                                         # [Protected]
TASK_CPU: "256"                                                 # [Protected]
TASK_MEMORY: "512"                                              # [Protected]

# Network Configuration
VPC_ID: "vpc-0301d6ba38834d6aa"                                # [Protected]
SUBNET_IDS: "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2" # [Protected]
SECURITY_GROUP_ID: "sg-04506e2e244ebc25a"                      # [Protected]

# ECR Configuration
BACKEND_ECR_REGISTRY: "639140327478.dkr.ecr.us-east-1.amazonaws.com"  # [Protected]
BACKEND_ECR_REPOSITORY: "ecs-cluster-int/backend"              # [Protected]
FRONTEND_ECR_REGISTRY: "639140327478.dkr.ecr.us-east-1.amazonaws.com" # [Protected]
FRONTEND_ECR_REPOSITORY: "ecs-cluster-int/frontend"            # [Protected]

# Database Configuration
DB_HOST: "ecs-cluster-int-postgres-db.XXXXX.us-east-1.rds.amazonaws.com"  # [Protected]
DB_PORT: "5432"                                                 # [Protected]
DB_NAME: "ecommercedb"                                          # [Protected]
DB_USERNAME: "postgres"                                         # [Protected]
DB_PASSWORD: "auto-generated"                                   # [Protected] [Masked]

# Cache Configuration
REDIS_HOST: "ecs-cluster-int-redis.XXXXX.ng.0001.use1.cache.amazonaws.com"  # [Protected]
REDIS_PORT: "6379"                                              # [Protected]
REDIS_PASSWORD: "auto-generated"                                # [Protected] [Masked]

# Application Configuration
ENVIRONMENT: "int"                                              # [Protected]
LOG_LEVEL: "info"                                               # [Protected]
NODE_ENV: "production"                                          # [Protected]
APP_PORT: "3000"                                                # [Protected]
JWT_SECRET: "your-random-32-char-secret"                       # [Protected] [Masked]

# Optional - Email
EMAIL_USERNAME: "your-email@gmail.com"                         # [Protected] [Masked]
EMAIL_PASSWORD: "app-specific-password"                        # [Protected] [Masked]
SMTP_HOST: "smtp.gmail.com"                                    # [Protected]
SMTP_PORT: "587"                                               # [Protected]
EMAIL_FROM: "noreply@ecommerceapp.com"                         # [Protected]

# Optional - Google OAuth
GOOGLE_CLIENT_ID: "your-client-id.apps.googleusercontent.com"  # [Protected]
GOOGLE_CLIENT_SECRET: "your-client-secret"                     # [Protected] [Masked]
```

---

## ✅ STEP-BY-STEP INPUT PROCESS

### Step 1: Gather All Information
```bash
# Run script to collect infrastructure details
cat > collect-inputs.sh << 'EOF'
#!/bin/bash
PROFILE="$AWS_PROFILE"
REGION="us-east-1"

echo "AWS_ACCOUNT_ID=639140327478"
echo "AWS_REGION=us-east-1"
echo "ECS_CLUSTER_NAME=ecs-cluster-int"
echo "VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.0.0.0/16" --region $REGION --profile $PROFILE --query 'Vpcs[0].VpcId' --output text)"
echo "SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0301d6ba38834d6aa" --region $REGION --profile $PROFILE --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')"
echo "SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecs_sg" --region $REGION --profile $PROFILE --query 'SecurityGroups[0].GroupId' --output text)"
echo "ECS_TASK_EXECUTION_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $PROFILE --query 'Role.Arn' --output text)"
echo "ECS_TASK_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $PROFILE --query 'Role.Arn' --output text)"
echo "BACKEND_ECR_REGISTRY=639140327478.dkr.ecr.us-east-1.amazonaws.com"
echo "BACKEND_ECR_REPOSITORY=ecs-cluster-int/backend"
echo "FRONTEND_ECR_REGISTRY=639140327478.dkr.ecr.us-east-1.amazonaws.com"
echo "FRONTEND_ECR_REPOSITORY=ecs-cluster-int/frontend"
echo ""
echo "# Get database credentials from Secrets Manager:"
echo "aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region $REGION --profile $PROFILE --query SecretString --output text | jq ."
echo ""
echo "# Get Redis credentials from Secrets Manager:"
echo "aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region $REGION --profile $PROFILE --query SecretString --output text | jq ."
EOF

chmod +x collect-inputs.sh
./collect-inputs.sh
```

### Step 2: Copy to Document
```
Create a document with all values collected above
```

### Step 3: Login to GitLab
```
Go to GitLab → Your Project → Settings → CI/CD → Variables
```

### Step 4: Add Each Variable
```
For each variable in the template:
1. Click "Add Variable"
2. Enter Key (e.g., "AWS_ACCESS_KEY_ID")
3. Enter Value
4. Check [Protected] for sensitive values
5. Check [Masked] for secrets
6. Click "Add variable"
```

### Step 5: Verify Variables
```
Go to CI/CD → Pipelines
Push code to trigger pipeline
Monitor pipeline execution
```

---

## 🎯 QUICK SUMMARY TABLE

| Variable | Value | Where to Get | Protected | Masked |
|----------|-------|--------------|-----------|--------|
| AWS_ACCESS_KEY_ID | AKIA... | IAM Create User | ✅ | ✅ |
| AWS_SECRET_ACCESS_KEY | xxxxxx | IAM Create User | ✅ | ✅ |
| AWS_ACCOUNT_ID | 639140327478 | Given | ✅ | ❌ |
| AWS_REGION | us-east-1 | Given | ✅ | ❌ |
| ECS_CLUSTER_NAME | ecs-cluster-int | Given | ✅ | ❌ |
| VPC_ID | vpc-0301... | AWS CLI | ✅ | ❌ |
| SUBNET_IDS | subnet-..., subnet-... | AWS CLI | ✅ | ❌ |
| SECURITY_GROUP_ID | sg-... | AWS CLI | ✅ | ❌ |
| ECS_TASK_EXECUTION_ROLE_ARN | arn:aws:iam::... | AWS CLI | ✅ | ❌ |
| ECS_TASK_ROLE_ARN | arn:aws:iam::... | AWS CLI | ✅ | ❌ |
| BACKEND_ECR_REGISTRY | 639140327478.dkr.ecr... | Given | ✅ | ❌ |
| BACKEND_ECR_REPOSITORY | ecs-cluster-int/backend | Given | ✅ | ❌ |
| FRONTEND_ECR_REGISTRY | 639140327478.dkr.ecr... | Given | ✅ | ❌ |
| FRONTEND_ECR_REPOSITORY | ecs-cluster-int/frontend | Given | ✅ | ❌ |
| DB_HOST | *.rds.amazonaws.com | Secrets Manager | ✅ | ❌ |
| DB_PORT | 5432 | Given | ✅ | ❌ |
| DB_NAME | ecommercedb | Given | ✅ | ❌ |
| DB_USERNAME | postgres | Given | ✅ | ❌ |
| DB_PASSWORD | xxxxxx | Secrets Manager | ✅ | ✅ |
| REDIS_HOST | *.cache.amazonaws.com | Secrets Manager | ✅ | ❌ |
| REDIS_PORT | 6379 | Given | ✅ | ❌ |
| REDIS_PASSWORD | xxxxxx | Secrets Manager | ✅ | ✅ |
| ENVIRONMENT | int | User Choice | ✅ | ❌ |
| LOG_LEVEL | info | User Choice | ✅ | ❌ |
| NODE_ENV | production | User Choice | ✅ | ❌ |
| JWT_SECRET | random... | Generate | ✅ | ✅ |

---

## ✅ READY FOR DEPLOYMENT

Once all GitLab variables are set, your pipeline will:

1. **Build Stage:** Compile & test your code
2. **Push Stage:** Build Docker images & push to ECR
3. **Deploy Stage:** Deploy to ECS automatically
4. **Verify Stage:** Run health checks

**Timeline:** ~5-10 minutes from push to deployment

---

**Status:** ✅ All inputs documented  
**Next Action:** Set GitLab variables and push code

