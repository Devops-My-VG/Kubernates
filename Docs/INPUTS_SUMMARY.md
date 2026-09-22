# GitLab CI/CD Pipeline - Inputs Summary

**What needs to be provided?** → GitLab CI/CD Variables  
**How many?** → 20+ variables  
**What for?** → Deploy Ecommerce-App to ECS automatically  
**When?** → Before first pipeline execution

---

## 🎯 THE 4 TYPES OF INPUTS NEEDED

### 1️⃣ AWS CREDENTIALS (4 variables)
Used for authentication to your AWS account:
```
AWS_ACCESS_KEY_ID              ← Create IAM user, get access key
AWS_SECRET_ACCESS_KEY          ← Create IAM user, get secret key
AWS_ACCOUNT_ID                 ← 639140327478 (provided)
AWS_REGION                     ← us-east-1 (provided)
```

**How to get:**
```bash
# Create IAM user for deployment
aws iam create-user --user-name ecommerce-app-deployment
aws iam attach-user-policy --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess
aws iam create-access-key --user-name ecommerce-app-deployment
# Get AccessKeyId and SecretAccessKey from output
```

---

### 2️⃣ INFRASTRUCTURE DETAILS (10 variables)
Tells the pipeline WHERE to deploy:
```
ECS_CLUSTER_NAME               ← ecs-cluster-int (provided)
ECS_TASK_EXECUTION_ROLE_ARN    ← arn:aws:iam::639140327478:role/...
ECS_TASK_ROLE_ARN              ← arn:aws:iam::639140327478:role/...
VPC_ID                         ← vpc-0301d6ba38834d6aa (provided)
SUBNET_IDS                     ← subnet-05db..., subnet-03e6... (provided)
SECURITY_GROUP_ID              ← sg-04506e2e244ebc25a (provided)
BACKEND_ECR_REGISTRY           ← 639140327478.dkr.ecr.us-east-1.amazonaws.com
BACKEND_ECR_REPOSITORY         ← ecs-cluster-int/backend
FRONTEND_ECR_REGISTRY          ← 639140327478.dkr.ecr.us-east-1.amazonaws.com
FRONTEND_ECR_REPOSITORY        ← ecs-cluster-int/frontend
```

**How to get:**
```bash
# Get cluster name (provided)
echo "ecs-cluster-int"

# Get role ARNs
aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --query 'Role.Arn' --output text
aws iam get-role --role-name ecs-cluster-int-ecs-task-role --query 'Role.Arn' --output text

# Get VPC, subnets, security group (provided)
echo "vpc-0301d6ba38834d6aa"
echo "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2"
echo "sg-04506e2e244ebc25a"

# ECR values (calculated from account ID and region)
echo "639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/backend"
echo "639140327478.dkr.ecr.us-east-1.amazonaws.com/ecs-cluster-int/frontend"
```

---

### 3️⃣ DATABASE & CACHE CREDENTIALS (6 variables)
Connection details for your app to reach database and cache:
```
DB_HOST                        ← From Secrets Manager
DB_PORT                        ← 5432 (provided)
DB_NAME                        ← ecommercedb (provided)
DB_USERNAME                    ← postgres (provided)
DB_PASSWORD                    ← From Secrets Manager
REDIS_HOST                     ← From Secrets Manager
REDIS_PORT                     ← 6379 (provided)
REDIS_PASSWORD                 ← From Secrets Manager
```

**How to get (from AWS Secrets Manager):**
```bash
# Get RDS credentials
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/rds/master-password \
  --query SecretString --output text | jq .

# Output:
# {
#   "host": "ecs-cluster-int-postgres-db.c123abc.us-east-1.rds.amazonaws.com",
#   "password": "auto-generated-password",
#   "username": "postgres",
#   "port": 5432,
#   "dbname": "ecommercedb"
# }

# Get Redis credentials
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/redis/auth-token \
  --query SecretString --output text | jq .

# Output:
# {
#   "host": "ecs-cluster-int-redis.abc123.ng.0001.use1.cache.amazonaws.com",
#   "auth_token": "auto-generated-token",
#   "port": 6379,
#   "engine": "redis"
# }
```

---

### 4️⃣ APPLICATION CONFIGURATION (3+ variables)
Settings for your application:
```
ENVIRONMENT                    ← int (or: dev, staging, prod)
LOG_LEVEL                      ← info (or: debug, warn, error)
NODE_ENV                       ← production
JWT_SECRET                     ← Generate random string (32+ chars)

# Optional - Email
EMAIL_USERNAME                 ← your-email@gmail.com
EMAIL_PASSWORD                 ← Gmail app password
SMTP_HOST                      ← smtp.gmail.com
SMTP_PORT                      ← 587
EMAIL_FROM                     ← noreply@ecommerceapp.com

# Optional - Google OAuth
GOOGLE_CLIENT_ID               ← From Google Cloud Console
GOOGLE_CLIENT_SECRET           ← From Google Cloud Console
```

**How to generate:**
```bash
# Generate JWT_SECRET
openssl rand -base64 32
# Output: AbC+/D8EfGhI9jK0lMnOpQrStUvWxYzAbC+/D8EfGhI9jK= (use this)

# OR with Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## 📊 COMPLETE MAPPING

| Variable | Value | Protection | Where From |
|----------|-------|------------|-----------|
| **AWS_ACCESS_KEY_ID** | AKIA... | 🔐🔒 | Create IAM user |
| **AWS_SECRET_ACCESS_KEY** | xxxxxx | 🔐🔒 | Create IAM user |
| **AWS_ACCOUNT_ID** | 639140327478 | 🔐 | Given |
| **AWS_REGION** | us-east-1 | 🔐 | Given |
| **ECS_CLUSTER_NAME** | ecs-cluster-int | 🔐 | Given |
| **ECS_TASK_EXECUTION_ROLE_ARN** | arn:aws:iam::... | 🔐 | AWS CLI |
| **ECS_TASK_ROLE_ARN** | arn:aws:iam::... | 🔐 | AWS CLI |
| **VPC_ID** | vpc-0301d6ba38834d6aa | 🔐 | Given |
| **SUBNET_IDS** | subnet-..., subnet-... | 🔐 | Given |
| **SECURITY_GROUP_ID** | sg-04506e2e244ebc25a | 🔐 | Given |
| **BACKEND_ECR_REGISTRY** | 639140327478.dkr.ecr... | 🔐 | Calculated |
| **BACKEND_ECR_REPOSITORY** | ecs-cluster-int/backend | 🔐 | Given |
| **FRONTEND_ECR_REGISTRY** | 639140327478.dkr.ecr... | 🔐 | Calculated |
| **FRONTEND_ECR_REPOSITORY** | ecs-cluster-int/frontend | 🔐 | Given |
| **DB_HOST** | *.us-east-1.rds.amazonaws.com | 🔐 | Secrets Manager |
| **DB_PORT** | 5432 | 🔐 | Given |
| **DB_NAME** | ecommercedb | 🔐 | Given |
| **DB_USERNAME** | postgres | 🔐 | Given |
| **DB_PASSWORD** | xxxxxx | 🔐🔒 | Secrets Manager |
| **REDIS_HOST** | *.use1.cache.amazonaws.com | 🔐 | Secrets Manager |
| **REDIS_PORT** | 6379 | 🔐 | Given |
| **REDIS_PASSWORD** | xxxxxx | 🔐🔒 | Secrets Manager |
| **ENVIRONMENT** | int | 🔐 | User choice |
| **LOG_LEVEL** | info | 🔐 | User choice |
| **NODE_ENV** | production | 🔐 | User choice |
| **JWT_SECRET** | [random] | 🔐🔒 | Generate |

**Legend:** 🔐 = Protected, 🔒 = Masked

---

## 🚀 QUICK COLLECTION PROCESS

### Step 1: Run This Script (copies infrastructure details)

Save as `collect-inputs.sh`:
```bash
#!/bin/bash
PROFILE="$AWS_PROFILE"
REGION="us-east-1"

echo "=== PASTE THESE INTO GITLAB ==="
echo ""
echo "AWS_ACCOUNT_ID=639140327478"
echo "AWS_REGION=us-east-1"
echo "ECS_CLUSTER_NAME=ecs-cluster-int"
echo "VPC_ID=vpc-0301d6ba38834d6aa"
echo "SUBNET_IDS=subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2"
echo "SECURITY_GROUP_ID=sg-04506e2e244ebc25a"
echo "BACKEND_ECR_REGISTRY=639140327478.dkr.ecr.us-east-1.amazonaws.com"
echo "BACKEND_ECR_REPOSITORY=ecs-cluster-int/backend"
echo "FRONTEND_ECR_REGISTRY=639140327478.dkr.ecr.us-east-1.amazonaws.com"
echo "FRONTEND_ECR_REPOSITORY=ecs-cluster-int/frontend"
echo ""
echo "=== Get these from AWS ==="
echo "ECS_TASK_EXECUTION_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $PROFILE --query 'Role.Arn' --output text)"
echo "ECS_TASK_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $PROFILE --query 'Role.Arn' --output text)"
echo ""
echo "=== Database (from Secrets Manager) ==="
echo "DB_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.host')"
echo "DB_PORT=5432"
echo "DB_NAME=ecommercedb"
echo "DB_USERNAME=postgres"
echo "DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.password')"
echo ""
echo "=== Redis (from Secrets Manager) ==="
echo "REDIS_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.host')"
echo "REDIS_PORT=6379"
echo "REDIS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.auth_token')"
echo ""
echo "=== Generate these ==="
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "ENVIRONMENT=int"
echo "LOG_LEVEL=info"
echo "NODE_ENV=production"
```

Run it:
```bash
chmod +x collect-inputs.sh
./collect-inputs.sh
```

### Step 2: Create AWS IAM User (one-time)

```bash
# Create user
aws iam create-user --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Attach policies
aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess \
  --profile $AWS_PROFILE

aws iam attach-user-policy \
  --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess \
  --profile $AWS_PROFILE

# Generate access keys
aws iam create-access-key --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Copy: AccessKeyId → AWS_ACCESS_KEY_ID
# Copy: SecretAccessKey → AWS_SECRET_ACCESS_KEY
```

### Step 3: Open GitLab

1. Go to: **GitLab → Your Project → Settings → CI/CD → Variables**
2. Click **"Add Variable"** for each input
3. Fill in: **Key** and **Value**
4. Check: **Protected** (all), **Masked** (secrets only)
5. Click **"Add variable"**

### Step 4: Test

1. Push code to GitLab
2. Go to **CI/CD → Pipelines**
3. Monitor pipeline execution
4. Check logs for errors

---

## ✅ INPUTS CHECKLIST

- [ ] Create AWS IAM user
- [ ] Get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
- [ ] Run collection script
- [ ] Copy infrastructure details to GitLab
- [ ] Get database credentials from Secrets Manager
- [ ] Get Redis credentials from Secrets Manager
- [ ] Generate JWT_SECRET with: `openssl rand -base64 32`
- [ ] Open GitLab project settings
- [ ] Add 20+ variables to GitLab
- [ ] Mark sensitive vars as Protected and Masked
- [ ] Push code to trigger pipeline
- [ ] Monitor pipeline execution
- [ ] Verify application in ALB

---

## 📋 TOTAL INPUTS REQUIRED

```
Mandatory:   20 variables
Optional:    5 variables (email/OAuth)
───────────────────────────
Total:       25 variables

Setup time:  ~15 minutes
```

---

## 🎯 WHAT HAPPENS NEXT

```
You provide inputs → GitLab receives them
         ↓
GitLab runs pipeline:
  - Build: Compiles code
  - Test: Runs tests
  - Push: Builds Docker images
  - Deploy: Updates ECS service
  - Verify: Health checks
         ↓
Application automatically deployed ✅
Scales to 2-4 tasks
Load balancer distributes traffic
Logs in CloudWatch
         ↓
Your app is LIVE
```

Timeline: **5-10 minutes** from push to live

---

## 📚 DOCUMENTATION FILES

All details in the ecs-cluster repository:

1. **QUICK_START_INPUTS.txt** (this file)
   - Visual guide with all inputs
   - Automatic collection script
   - Step-by-step setup

2. **DEPLOYMENT_CHECKLIST.md**
   - Detailed checklist
   - Where to find each value
   - Verification commands

3. **APP_DEPLOYMENT_INPUTS.md**
   - Deep dive into each input
   - Full explanations
   - All commands

4. **INFRASTRUCTURE_GUIDE.md**
   - Infrastructure architecture
   - Resource details
   - Monitoring setup

---

## ✅ YOU ARE HERE

```
Infrastructure: ✅ Deployed (Complete)
Documentation: ✅ Written (Complete)
Inputs:        🟡 Pending (This is what you need to do now)
Pipeline:      ⏳ Waiting (Starts when you set variables)
Application:   ⏳ Waiting (Deploys when pipeline runs)
```

**Next Step:** Collect the 20+ inputs and add them to GitLab variables

---

**Questions?** Refer to the detailed documentation files listed above.

