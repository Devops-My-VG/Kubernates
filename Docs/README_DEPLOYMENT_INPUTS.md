# GitLab CI/CD Pipeline - Deployment Inputs Guide

**What:** Complete reference for all inputs needed to deploy Ecommerce-App via GitLab pipeline  
**When:** Before running first deployment  
**Status:** ✅ Infrastructure deployed, documentation complete, **awaiting your inputs**

---

## 🎯 THE SIMPLE ANSWER

**What needs to be given as a prompt/input to the app deployment pipeline?**

### **Answer: 20-25 GitLab CI/CD Variables**

These variables tell the pipeline:
- **Who** → AWS credentials to access your account
- **Where** → ECS cluster, VPC, subnets, security groups  
- **What** → ECR repositories, database, cache endpoints
- **How** → Application configuration (environment, logging, secrets)

---

## 📊 THE 4 GROUPS OF INPUTS

### Group 1: AWS Credentials (4 variables)
```
✓ AWS_ACCESS_KEY_ID           ← From IAM user
✓ AWS_SECRET_ACCESS_KEY       ← From IAM user
✓ AWS_ACCOUNT_ID              ← 639140327478 (given)
✓ AWS_REGION                  ← us-east-1 (given)
```

### Group 2: Infrastructure Details (10 variables)
```
✓ ECS_CLUSTER_NAME            ← ecs-cluster-int
✓ ECS_TASK_EXECUTION_ROLE_ARN ← IAM role ARN
✓ ECS_TASK_ROLE_ARN           ← IAM role ARN
✓ VPC_ID                      ← vpc-0301d6ba38834d6aa
✓ SUBNET_IDS                  ← subnet-..., subnet-...
✓ SECURITY_GROUP_ID           ← sg-04506e2e244ebc25a
✓ BACKEND_ECR_REGISTRY        ← 639140327478.dkr.ecr...
✓ BACKEND_ECR_REPOSITORY      ← ecs-cluster-int/backend
✓ FRONTEND_ECR_REGISTRY       ← 639140327478.dkr.ecr...
✓ FRONTEND_ECR_REPOSITORY     ← ecs-cluster-int/frontend
```

### Group 3: Database & Cache (8 variables)
```
✓ DB_HOST                     ← From Secrets Manager
✓ DB_PORT                     ← 5432 (given)
✓ DB_NAME                     ← ecommercedb (given)
✓ DB_USERNAME                 ← postgres (given)
✓ DB_PASSWORD                 ← From Secrets Manager
✓ REDIS_HOST                  ← From Secrets Manager
✓ REDIS_PORT                  ← 6379 (given)
✓ REDIS_PASSWORD              ← From Secrets Manager
```

### Group 4: Application Config (3+ variables)
```
✓ ENVIRONMENT                 ← int (your choice)
✓ LOG_LEVEL                   ← info (your choice)
✓ NODE_ENV                    ← production (fixed)
✓ JWT_SECRET                  ← Generate randomly
```

**Optional:**
```
✓ EMAIL_USERNAME, EMAIL_PASSWORD, SMTP_HOST, SMTP_PORT, EMAIL_FROM
✓ GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
```

---

## 🚀 QUICK START

### 1. Create AWS IAM User (One-time, 5 minutes)
```bash
aws iam create-user --user-name ecommerce-app-deployment --profile $AWS_PROFILE
aws iam attach-user-policy --user-name ecommerce-app-deployment \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess
aws iam create-access-key --user-name ecommerce-app-deployment --profile $AWS_PROFILE

# Save the AccessKeyId and SecretAccessKey
```

### 2. Run Collection Script (Automatic, 1 minute)
```bash
# Create and run this script
cat > collect-gitlab-inputs.sh << 'EOF'
#!/bin/bash
PROFILE="$AWS_PROFILE"
REGION="us-east-1"

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

# Get role ARNs
echo "ECS_TASK_EXECUTION_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-execution-role --profile $PROFILE --query 'Role.Arn' --output text)"
echo "ECS_TASK_ROLE_ARN=$(aws iam get-role --role-name ecs-cluster-int-ecs-task-role --profile $PROFILE --query 'Role.Arn' --output text)"

# Get database credentials
echo "DB_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.host')"
echo "DB_PORT=5432"
echo "DB_NAME=ecommercedb"
echo "DB_USERNAME=postgres"
echo "DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/rds/master-password --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.password')"

# Get Redis credentials
echo "REDIS_HOST=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.host')"
echo "REDIS_PORT=6379"
echo "REDIS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ecs-cluster-int/redis/auth-token --region $REGION --profile $PROFILE --query SecretString --output text | jq -r '.auth_token')"

# Generate secrets
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "ENVIRONMENT=int"
echo "LOG_LEVEL=info"
echo "NODE_ENV=production"
EOF

chmod +x collect-gitlab-inputs.sh
./collect-gitlab-inputs.sh
```

### 3. Add Variables to GitLab (Manual, 10 minutes)
```
1. Go to: GitLab → Your Project → Settings → CI/CD → Variables
2. Click "Add Variable" for each variable
3. Set: Key and Value
4. Check: Protected (all), Masked (for secrets)
5. Click: "Add variable"
```

### 4. Deploy (Automatic, 10 minutes)
```
1. Push code to GitLab
2. Watch pipeline execute
3. Application deployed ✅
```

---

## 📚 DETAILED DOCUMENTATION

| Document | Purpose | Audience |
|----------|---------|----------|
| **QUICK_START_INPUTS.txt** | Visual guide with all inputs organized | Quick reference |
| **DEPLOYMENT_CHECKLIST.md** | Detailed step-by-step checklist | Implementation |
| **APP_DEPLOYMENT_INPUTS.md** | Deep dive into each input | Detailed learning |
| **INPUTS_SUMMARY.md** | High-level overview | Quick understanding |
| **PIPELINE_INPUTS_FLOW.txt** | Visual flow diagrams | Visual learners |
| **INFRASTRUCTURE_GUIDE.md** | Infrastructure architecture | Operators |
| **This file** | Summary of inputs needed | Quick answer |

---

## ⏱️ TIME BREAKDOWN

| Task | Duration | Type |
|------|----------|------|
| Create IAM user | 5 min | Manual |
| Run collection script | 1 min | Automatic |
| Get database/cache creds | 1 min | Manual |
| Generate JWT_SECRET | 1 min | Manual |
| Add variables to GitLab | 10 min | Manual |
| Push code to trigger | 1 min | Manual |
| **Pipeline builds & deploys** | **~10 min** | **Automatic** |
| **TOTAL** | **~29 minutes** | Mixed |

---

## ✅ INPUTS CHECKLIST

**Before you start:**
- [ ] AWS CLI installed (`aws --version`)
- [ ] jq installed (`jq --version`)
- [ ] OpenSSL installed (`openssl version`)
- [ ] Access to AWS account ($AWS_PROFILE profile)
- [ ] Access to GitLab project

**Collect inputs:**
- [ ] IAM user created
- [ ] AWS_ACCESS_KEY_ID obtained
- [ ] AWS_SECRET_ACCESS_KEY obtained
- [ ] Collection script executed
- [ ] Database credentials from Secrets Manager
- [ ] Redis credentials from Secrets Manager
- [ ] JWT_SECRET generated

**Add to GitLab:**
- [ ] 20+ variables added to GitLab
- [ ] All marked as [Protected]
- [ ] Secrets marked as [Masked]
- [ ] Variables verified

**Deploy:**
- [ ] Code pushed to GitLab
- [ ] Pipeline executed
- [ ] Application deployed ✅

---

## 🎯 NEXT STEPS

### Immediate (Right now)
1. Read this file completely
2. Open **QUICK_START_INPUTS.txt** for visual reference
3. Open **DEPLOYMENT_CHECKLIST.md** for detailed steps

### Within 30 minutes
1. Create IAM user with access keys
2. Run collection script
3. Add all variables to GitLab

### Automatic (After you push)
1. GitLab pipeline starts
2. Builds Docker images
3. Pushes to ECR
4. Deploys to ECS
5. Application live ✅

---

## 📊 INPUTS AT A GLANCE

```
┌──────────────────────────────────────────────────┐
│ 25 TOTAL INPUTS NEEDED                           │
├──────────────────────────────────────────────────┤
│ 4  AWS Credentials                               │
│ 10 Infrastructure Details                        │
│ 8  Database & Cache Credentials                  │
│ 3  Application Configuration                     │
│ 5  Optional (Email/OAuth)                        │
├──────────────────────────────────────────────────┤
│ 20 MANDATORY for deployment                      │
│ 5  OPTIONAL for email/OAuth features             │
├──────────────────────────────────────────────────┤
│ Effort: ~20 minutes to collect & input            │
│ Result: Automated CI/CD pipeline ready            │
└──────────────────────────────────────────────────┘
```

---

## 🔐 SECURITY NOTES

- **Never commit credentials to Git**
- All credentials stored in GitLab's protected variables
- Mark all secrets as [Masked] in GitLab
- AWS IAM user is for CI/CD only, not personal use
- Database/Redis passwords auto-generated and stored in Secrets Manager
- JWT_SECRET generated randomly for application security

---

## 🆘 COMMON QUESTIONS

**Q: Where do I get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY?**  
A: Create an IAM user named `ecommerce-app-deployment` and generate access keys

**Q: What if I don't know my VPC ID or subnet IDs?**  
A: They're already provided (vpc-0301..., subnet-05db..., subnet-03e6...)

**Q: Where do I get database and Redis credentials?**  
A: Automatically generated in AWS Secrets Manager (use `aws secretsmanager get-secret-value` commands)

**Q: What if I lose the JWT_SECRET?**  
A: You can regenerate it with `openssl rand -base64 32`

**Q: What if I make a mistake adding variables to GitLab?**  
A: Edit or delete the variable in GitLab and re-add it

**Q: How long does deployment take after I set variables?**  
A: ~10 minutes from code push to application live

---

## ✨ WHAT HAPPENS WHEN YOU PROVIDE INPUTS

```
Your inputs (20+ variables)
        ↓
GitLab receives variables & unlocks secrets
        ↓
Pipeline Stage 1: Build
  ├─ Compile backend code
  ├─ Compile frontend code
  ├─ Run tests
        ↓
Pipeline Stage 2: Push
  ├─ Build backend Docker image
  ├─ Build frontend Docker image
  ├─ Push images to ECR
  ├─ Scan for vulnerabilities
        ↓
Pipeline Stage 3: Deploy
  ├─ Create/update ECS task definition
  ├─ Deploy backend service to ECS
  ├─ Deploy frontend service to ECS
  ├─ Auto-scale to 2-4 tasks
        ↓
Pipeline Stage 4: Verify
  ├─ Check task health
  ├─ Check logs in CloudWatch
  ├─ Verify ALB responding
        ↓
Your Application LIVE ✅
  ├─ Database connected
  ├─ Cache working
  ├─ Logs flowing to CloudWatch
  ├─ Auto-scaling enabled
  └─ Load balancer distributing traffic
```

---

## 🎓 DOCUMENTATION HIERARCHY

```
New to this? Start here:
  1. This file (README_DEPLOYMENT_INPUTS.md) ← You are here
  2. QUICK_START_INPUTS.txt
  3. DEPLOYMENT_CHECKLIST.md

Need details?
  → APP_DEPLOYMENT_INPUTS.md
  → INFRASTRUCTURE_GUIDE.md

Visual learner?
  → PIPELINE_INPUTS_FLOW.txt

Quick reference?
  → INPUTS_SUMMARY.md
```

---

## ✅ SUMMARY

**You need to provide:** 20+ GitLab CI/CD variables  
**Time to collect:** ~20 minutes  
**Time for automatic deployment:** ~10 minutes  
**Result:** Fully deployed Ecommerce-App on ECS with CI/CD pipeline  

**Infrastructure is ready.** Documentation is complete. **Now it's your turn to provide the inputs.**

---

## 📞 WHERE TO GET HELP

- **Infrastructure details?** → See INFRASTRUCTURE_GUIDE.md
- **Step-by-step guide?** → See DEPLOYMENT_CHECKLIST.md
- **Visual flow?** → See PIPELINE_INPUTS_FLOW.txt
- **All variables explained?** → See APP_DEPLOYMENT_INPUTS.md
- **Quick reference?** → See QUICK_START_INPUTS.txt
- **High-level overview?** → See INPUTS_SUMMARY.md

---

**Status:** ✅ Ready for your inputs  
**Next Action:** Collect infrastructure details and add GitLab variables

