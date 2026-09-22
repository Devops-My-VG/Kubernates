# Manual GitLab Variables Setup Guide

**Status:** Token has insufficient scopes for API-based setup
**Alternative:** Manual UI setup OR regenerate PAT with broader permissions

## Option 1: Manual Setup via GitLab UI (5 minutes)

### Step 1: Navigate to Project Variables
```
https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd
```

### Step 2: Add Each Variable
Click "Add Variable" for each of the following:

| Variable | Value | Protected | Masked |
|----------|-------|-----------|--------|
| AWS_ACCOUNT_ID | 639140327478 | ✅ | ❌ |
| AWS_REGION | us-east-1 | ✅ | ❌ |
| VPC_ID | vpc-0301d6ba38834d6aa | ✅ | ❌ |
| SUBNET_IDS | subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2 | ✅ | ❌ |
| SECURITY_GROUP_ID | sg-04506e2e244ebc25a | ✅ | ❌ |
| DB_PASSWORD | 8pzPwmSuuA8XDlXVqfhh3yDBXgFLkV0g | ✅ | ✅ |
| JWT_SECRET | e8Z3fZnRz/nm0qPRBmNWbIYY5RA6KaZAYEuSSvpWrEg= | ✅ | ✅ |
| BACKEND_ECR_REGISTRY | 639140327478.dkr.ecr.us-east-1.amazonaws.com | ✅ | ❌ |
| BACKEND_ECR_REPOSITORY | ecs-cluster-int/backend | ✅ | ❌ |
| FRONTEND_ECR_REGISTRY | 639140327478.dkr.ecr.us-east-1.amazonaws.com | ✅ | ❌ |
| FRONTEND_ECR_REPOSITORY | ecs-cluster-int/frontend | ✅ | ❌ |
| DB_HOST | ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com | ✅ | ❌ |
| DB_PORT | 5432 | ✅ | ❌ |
| DB_NAME | ecommercedb | ✅ | ❌ |
| DB_USERNAME | postgres | ✅ | ❌ |
| ECS_TASK_EXECUTION_ROLE_ARN | arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role | ✅ | ❌ |
| ECS_TASK_ROLE_ARN | arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role | ✅ | ❌ |
| ENVIRONMENT | int | ✅ | ❌ |
| LOG_LEVEL | info | ✅ | ❌ |
| NODE_ENV | production | ✅ | ❌ |

---

## Option 2: Regenerate PAT with Broader Scope

Your current token lacks permissions for API variable management.

### Step 1: Create New PAT
1. Go to: https://gitlab.com/-/user_settings/personal_access_tokens
2. Click "Add new token"
3. Name: "GitLab API - Infra Setup"
4. Scopes needed:
   - ✅ api
   - ✅ read_user
   - ✅ read_repository
   - ✅ write_repository
5. Expiration: 90 days (or longer)
6. Click "Create personal access token"
7. Copy the new token

### Step 2: Update Local Token
```bash
echo "glpat-YOUR_NEW_TOKEN_HERE" > ~/export/DevOps/AWS-DevOps/gitlab-token
```

### Step 3: Run Automated Setup
```bash
cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster
bash SETUP_GITLAB_VARIABLES.sh
```

---

## Option 3: Use GitLab CLI with New Token

### Step 1: Regenerate PAT (see Option 2, Step 1-2)

### Step 2: Configure glab
```bash
export GITLAB_TOKEN="glpat-YOUR_NEW_TOKEN_HERE"
glab auth login --token "$GITLAB_TOKEN"
```

### Step 3: Set Variables via glab
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

## Verification

### Check Variables in UI
Go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd

You should see all 20 variables listed with:
- 🔒 Protected badge
- 🔐 Masked badge (for secrets only)

### Verify via API (after setting)
```bash
curl -s "https://gitlab.com/api/v4/projects/devops8004932%2Fkubernetes%2Fecs-cluster/variables" \
  -H "PRIVATE-TOKEN: YOUR_TOKEN" | jq '.[] | {key, protected, masked}'
```

---

## Troubleshooting

### "404 Not Found"
- Project path is: `devops8004932/kubernetes/ecs-cluster` (not `ecommerce-app-v1`)
- URL-encoded: `devops8004932%2Fkubernetes%2Fecs-cluster`

### "403 Access Denied - insufficient_granular_scope"
- Your PAT doesn't have enough permissions
- Regenerate PAT with `api` scope (see Option 2)

### "422 Unprocessable Entity"
- Variable key might already exist
- Try updating instead of creating
- Or delete and recreate

---

## Next Steps

1. **Choose Setup Method:**
   - Quick: Option 1 (manual UI) - 5 minutes
   - Automated: Option 2 + 3 (new PAT + glab)

2. **After Variables are Set:**
   ```bash
   cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster
   git push origin main
   ```

3. **Monitor Pipeline:**
   - Go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/pipelines
   - Pipeline will start automatically on push
   - Stages: validate → plan → apply (manual trigger)

---

## References

- GitLab CI/CD Variables Docs: https://docs.gitlab.com/ee/ci/variables/
- Personal Access Tokens: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
- glab Documentation: https://gitlab.com/gitlab-org/cli/-/docs
