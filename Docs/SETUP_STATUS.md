# GitLab Variables Setup Status

**Date:** September 13, 2026  
**Project:** devops8004932/kubernetes/ecs-cluster  
**Task:** Set 20 required GitLab CI/CD variables

---

## Current Status

### ❌ API-Based Setup Failed
- **Reason:** Current GitLab PAT token has insufficient scopes
- **Missing Scopes:** `Variable: Create`, `Project: Read`
- **Error:** `403 Access Denied - insufficient_granular_scope`

### ✅ Solution Provided
Three options available to complete setup:

---

## Options for Setup

### Option 1: Manual UI Setup (Recommended - 5 minutes)
**Easiest and fastest**

1. Go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd
2. Click "Add Variable" for each of these 20 variables:

```
AWS_ACCOUNT_ID = 639140327478
AWS_REGION = us-east-1
VPC_ID = vpc-0301d6ba38834d6aa
SUBNET_IDS = subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2
SECURITY_GROUP_ID = sg-04506e2e244ebc25a
DB_PASSWORD = 8pzPwmSuuA8XDlXVqfhh3yDBXgFLkV0g [MASKED]
JWT_SECRET = e8Z3fZnRz/nm0qPRBmNWbIYY5RA6KaZAYEuSSvpWrEg= [MASKED]
BACKEND_ECR_REGISTRY = 639140327478.dkr.ecr.us-east-1.amazonaws.com
BACKEND_ECR_REPOSITORY = ecs-cluster-int/backend
FRONTEND_ECR_REGISTRY = 639140327478.dkr.ecr.us-east-1.amazonaws.com
FRONTEND_ECR_REPOSITORY = ecs-cluster-int/frontend
DB_HOST = ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com
DB_PORT = 5432
DB_NAME = ecommercedb
DB_USERNAME = postgres
ECS_TASK_EXECUTION_ROLE_ARN = arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role
ECS_TASK_ROLE_ARN = arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role
ENVIRONMENT = int
LOG_LEVEL = info
NODE_ENV = production
```

**For each variable:**
- ✅ Check "Protected"
- ✅ Check "Masked" (only for DB_PASSWORD and JWT_SECRET)

---

### Option 2: Automated Setup with New Token (10 minutes)

1. **Regenerate PAT with broader scope:**
   - Go to: https://gitlab.com/-/user_settings/personal_access_tokens
   - Create new token with scopes: `api`, `read_user`, `read_repository`, `write_repository`
   - Copy new token

2. **Update local token file:**
   ```bash
   echo "glpat-YOUR_NEW_TOKEN" > ~/export/DevOps/AWS-DevOps/gitlab-token
   ```

3. **Run automated setup script:**
   ```bash
   cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster
   export GITLAB_TOKEN="glpat-YOUR_NEW_TOKEN"
   bash SETUP_GITLAB_VARIABLES.sh
   ```

---

### Option 3: Use GitLab CLI (Alternative to Option 2)

1. **Regenerate PAT** (same as Option 2, step 1)

2. **Configure glab:**
   ```bash
   export GITLAB_TOKEN="glpat-YOUR_NEW_TOKEN"
   glab auth login --token "$GITLAB_TOKEN"
   ```

3. **Set variables via glab:**
   ```bash
   glab variable set AWS_ACCOUNT_ID "639140327478" --protected
   glab variable set AWS_REGION "us-east-1" --protected
   glab variable set VPC_ID "vpc-0301d6ba38834d6aa" --protected
   glab variable set SUBNET_IDS "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2" --protected
   glab variable set SECURITY_GROUP_ID "sg-04506e2e244ebc25a" --protected
   glab variable set DB_PASSWORD "8pzPwmSuuA8XDlXVqfhh3yDBXgFLkV0g" --protected --masked
   glab variable set JWT_SECRET "e8Z3fZnRz/nm0qPRBmNWbIYY5RA6KaZAYEuSSvpWrEg=" --protected --masked
   glab variable set BACKEND_ECR_REGISTRY "639140327478.dkr.ecr.us-east-1.amazonaws.com" --protected
   glab variable set BACKEND_ECR_REPOSITORY "ecs-cluster-int/backend" --protected
   glab variable set FRONTEND_ECR_REGISTRY "639140327478.dkr.ecr.us-east-1.amazonaws.com" --protected
   glab variable set FRONTEND_ECR_REPOSITORY "ecs-cluster-int/frontend" --protected
   glab variable set DB_HOST "ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com" --protected
   glab variable set DB_PORT "5432" --protected
   glab variable set DB_NAME "ecommercedb" --protected
   glab variable set DB_USERNAME "postgres" --protected
   glab variable set ECS_TASK_EXECUTION_ROLE_ARN "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role" --protected
   glab variable set ECS_TASK_ROLE_ARN "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role" --protected
   glab variable set ENVIRONMENT "int" --protected
   glab variable set LOG_LEVEL "info" --protected
   glab variable set NODE_ENV "production" --protected
   ```

---

## After Setup Complete

1. **Verify all variables are set:**
   - Go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd
   - Should see all 20 variables with 🔒 Protected badges

2. **Trigger pipeline:**
   ```bash
   cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster
   git push origin main
   ```

3. **Monitor deployment:**
   - Go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/pipelines
   - Stages will run: validate → plan → apply (manual)

---

## Files Created

1. **GITLAB_VARIABLES_ALL.txt** - Complete variable reference with descriptions
2. **GITLAB_VARIABLES.json** - Structured JSON format
3. **MANUAL_GITLAB_SETUP.md** - Detailed setup guide with all options
4. **SETUP_GITLAB_VARIABLES.sh** - Automated script (requires new token with `api` scope)
5. **SETUP_STATUS.md** - This file

---

## Recommendation

**Start with Option 1 (Manual UI)** - Takes only 5 minutes and doesn't require token regeneration. You can do it right now.

If you prefer automation for future use, regenerate the PAT and save the script.

---

## Support

- GitLab Variables: https://docs.gitlab.com/ee/ci/variables/
- Personal Access Tokens: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
- GitLab CI/CD: https://docs.gitlab.com/ee/ci/
