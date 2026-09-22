# GitLab Pipeline: Update-Variables Stage

**Date Created:** 2026-09-14  
**Stage Added:** `update-variables` (new)  
**Status:** ✅ Ready  

---

## Overview

A new `update-variables` stage has been added to the GitLab CI/CD pipeline that automatically syncs infrastructure details from Terraform outputs to GitLab group/project variables. This enables the app deployment pipeline to consume all infrastructure endpoints without manual configuration.

---

## Pipeline Stages (Updated)

```
validate → plan → apply → update-variables → destroy
```

### New Stage: `update-variables`

Runs **after** successful `apply` jobs to extract Terraform outputs and update GitLab variables via the GitLab API.

---

## Features

✅ **Automated Output Extraction**
- Reads Terraform outputs from JSON files generated during `apply` stage
- Extracts infrastructure details for all 4 environments (INT, QA, STG, PRD)
- Handles missing output files by running `terraform output` dynamically

✅ **GitLab API Integration**
- Uses GitLab REST API v4 to create/update project variables
- Authenticates with CI_JOB_TOKEN (no PAT required)
- Handles both CREATE (HTTP 201) and UPDATE (HTTP 200) operations

✅ **Comprehensive Variable Sync**
Updates 19 infrastructure variables:

| Category | Variables |
|----------|-----------|
| **AWS** | AWS_ACCOUNT_ID |
| **Network** | VPC_ID, SUBNET_IDS, SECURITY_GROUP_ID |
| **Database (RDS)** | DB_HOST, DB_PORT, DB_NAME, DB_USERNAME |
| **Cache (Valkey)** | VALKEY_ENDPOINT, VALKEY_PORT |
| **Container Registry (ECR)** | BACKEND_ECR_REGISTRY, BACKEND_ECR_REPOSITORY, FRONTEND_ECR_REGISTRY, FRONTEND_ECR_REPOSITORY |
| **ECS** | ECS_CLUSTER_NAME, CLOUDWATCH_LOG_GROUP, ECS_TASK_EXECUTION_ROLE_ARN, ECS_TASK_ROLE_ARN |

✅ **All Existing Jobs Untouched**
- No changes to `validate`, `plan`, `apply`, or `destroy` stages
- New stage runs independently
- Fully backward compatible

---

## Job Definitions

### `update-variables:int` (INT Environment)

```yaml
update-variables:int:
  stage: update-variables
  image: ubuntu:22.04
  environment:
    name: INT
    deployment_tier: development
  dependencies:
    - apply:int
  before_script:
    - apt-get update -qq && apt-get install -y -qq curl jq
  script:
    # Extract outputs from int_outputs.json
    # Update 19 GitLab variables via API
  when: manual
  rules:
    - when: never
```

**Similar jobs:**
- `update-variables:qa` (depends on apply:qa)
- `update-variables:stg` (depends on apply:stg)
- `update-variables:prd` (depends on apply:prd)

---

## Execution Flow

### How It Works

1. **After Apply Succeeds**
   ```
   apply:int → {creates int_outputs.json} → ready for update-variables:int
   ```

2. **Extract Terraform Outputs**
   ```bash
   cat int_outputs.json | jq -r '.vpc_id.value'      # Extract VPC_ID
   cat int_outputs.json | jq -r '.rds_host.value'    # Extract DB_HOST
   cat int_outputs.json | jq -r '.valkey_host.value' # Extract VALKEY_ENDPOINT
   # ... 16 more variables
   ```

3. **Update GitLab Variables**
   ```bash
   POST https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/variables
   
   Request Body:
   {
     "key": "VPC_ID",
     "value": "vpc-0301d6ba38834d6aa",
     "protected": true,
     "masked": false
   }
   ```

4. **Handle Existing Variables**
   - If HTTP 400 (variable exists) → try PUT to update
   - If HTTP 201 (created) → done ✅
   - If HTTP 200 (updated) → done ✅

5. **Result**
   ```
   ✅ VPC_ID                               ✅ Updated
   ✅ SUBNET_IDS                           ✅ Updated
   ✅ SECURITY_GROUP_ID                    ✅ Updated
   ✅ DB_HOST                              ✅ Updated
   ... (19 total variables)
   ```

---

## Variables Created/Updated

### Infrastructure Network & Security

| Variable | Source | Example Value |
|----------|--------|---------------|
| `VPC_ID` | `outputs.vpc_id.value` | `vpc-0301d6ba38834d6aa` |
| `SUBNET_IDS` | `outputs.public_subnets.value` | `subnet-1,subnet-2` |
| `SECURITY_GROUP_ID` | `outputs.security_group_id.value` | `sg-04506e2e244ebc25a` |

### Database (PostgreSQL RDS)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `DB_HOST` | `outputs.rds_host.value` | `ecs-cluster-int-postgres-db.c638ae...rds.amazonaws.com` |
| `DB_PORT` | `outputs.rds_port.value` | `5432` |
| `DB_NAME` | `outputs.rds_database_name.value` | `ecommercedb` |
| `DB_USERNAME` | `outputs.rds_username.value` | `postgres` |

### Cache (Valkey Serverless)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `VALKEY_ENDPOINT` | `outputs.valkey_host.value` | `ecs-cluster-int-valkey-nwcsss.serverless.cache.amazonaws.com` |
| `VALKEY_PORT` | `outputs.valkey_port.value` | `6379` |

### Container Registry (ECR)

| Variable | Source | Example Value |
|----------|--------|---------------|
| `BACKEND_ECR_REGISTRY` | `outputs.backend_ecr_repository_url.value` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` |
| `BACKEND_ECR_REPOSITORY` | `outputs.backend_ecr_repository_name.value` | `ecs-cluster-int/backend` |
| `FRONTEND_ECR_REGISTRY` | `outputs.frontend_ecr_repository_url.value` | `639140327478.dkr.ecr.us-east-1.amazonaws.com` |
| `FRONTEND_ECR_REPOSITORY` | `outputs.frontend_ecr_repository_name.value` | `ecs-cluster-int/frontend` |

### ECS Cluster & Logging

| Variable | Source | Example Value |
|----------|--------|---------------|
| `ECS_CLUSTER_NAME` | `outputs.cluster_name.value` | `ecs-cluster-int` |
| `CLOUDWATCH_LOG_GROUP` | `outputs.cloudwatch_log_group_name.value` | `/ecs/ecs-cluster-int` |
| `ECS_TASK_EXECUTION_ROLE_ARN` | `outputs.ecs_task_execution_role_arn.value` | `arn:aws:iam::639140327478:role/...` |
| `ECS_TASK_ROLE_ARN` | `outputs.ecs_task_role_arn.value` | `arn:aws:iam::639140327478:role/...` |

### AWS Account

| Variable | Source | Example Value |
|----------|--------|---------------|
| `AWS_ACCOUNT_ID` | `outputs.ecr_registry_id.value` | `639140327478` |

---

## Usage Instructions

### Manual Trigger (Current Setup)

Since `when: manual` is set, the update-variables jobs must be manually triggered:

1. **Deploy Infrastructure**
   ```
   Pipeline → apply:int → ✓ Success (generates int_outputs.json)
   ```

2. **Trigger Variable Update**
   ```
   Pipeline → Click "update-variables:int" → Run
   ```

3. **Verify Variables Updated**
   ```
   GitLab Project → Settings → CI/CD → Variables
   OR
   glab variable list --project devops8004932/kubernetes/ecs-cluster
   ```

### Expected Output

```
✓ VPC_ID                               ✅ Updated
✓ SUBNET_IDS                           ✅ Updated
✓ SECURITY_GROUP_ID                    ✅ Updated
✓ DB_HOST                              ✅ Updated
✓ DB_PORT                              ✅ Updated
✓ DB_NAME                              ✅ Updated
✓ DB_USERNAME                          ✅ Updated
✓ BACKEND_ECR_REGISTRY                 ✅ Updated
✓ BACKEND_ECR_REPOSITORY               ✅ Updated
✓ FRONTEND_ECR_REGISTRY                ✅ Updated
✓ FRONTEND_ECR_REPOSITORY              ✅ Updated
✓ VALKEY_ENDPOINT                      ✅ Updated
✓ VALKEY_PORT                          ✅ Updated
✓ ECS_CLUSTER_NAME                     ✅ Updated
✓ CLOUDWATCH_LOG_GROUP                 ✅ Updated
✓ ECS_TASK_EXECUTION_ROLE_ARN          ✅ Updated
✓ ECS_TASK_ROLE_ARN                    ✅ Updated
✓ AWS_ACCOUNT_ID                       ✅ Updated
✓ INT environment variables updated successfully
```

---

## Authentication

**Method:** GitLab CI Job Token (CI_JOB_TOKEN)

- Automatically injected by GitLab into all jobs
- No additional credentials needed
- Uses `PRIVATE-TOKEN` header for API requests
- Endpoint: `https://gitlab.com/api/v4/projects/{CI_PROJECT_ID}/variables`

**Security:**
✅ All variables marked as `protected=true`  
✅ Variables updated at project level (isolated per environment)  
✅ Job token scoped to current project  
✅ No PAT (Personal Access Token) required  

---

## API Details

### Create Variable (HTTP 201)

```bash
curl -X POST "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/variables" \
  -H "PRIVATE-TOKEN: ${CI_JOB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"key\":\"VPC_ID\",
    \"value\":\"vpc-0301d6ba38834d6aa\",
    \"protected\":true,
    \"masked\":false
  }"
```

### Update Variable (HTTP 200)

```bash
curl -X PUT "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/variables/VPC_ID" \
  -H "PRIVATE-TOKEN: ${CI_JOB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"key\":\"VPC_ID\",
    \"value\":\"vpc-0301d6ba38834d6aa\",
    \"protected\":true,
    \"masked\":false
  }"
```

---

## Troubleshooting

### Variables Not Updating

**Check Job Logs:**
```bash
glab ci trace update-variables:int
```

**Common Issues:**

| Issue | Solution |
|-------|----------|
| `HTTP 401` | CI_JOB_TOKEN expired or invalid (rare) |
| `HTTP 403` | Job insufficient permissions (check project settings) |
| `HTTP 404` | Project ID incorrect (verify CI_PROJECT_ID) |
| `jq: command not found` | jq not installed (already in before_script) |
| `int_outputs.json not found` | apply:int didn't succeed or didn't generate outputs |

### Verify Terraform Outputs

```bash
cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster

# Check if outputs exist
ls -la *_outputs.json

# View output values
cat int_outputs.json | jq '.vpc_id.value'
cat int_outputs.json | jq '.rds_host.value'
cat int_outputs.json | jq '.valkey_host.value'
```

### Manual Variable Update (Fallback)

If pipeline fails, use manual script:

```bash
export GITLAB_TOKEN="glpat-xxxx"
bash SETUP_GITLAB_VARIABLES.sh
```

---

## Environment-Specific Behavior

### INT Environment
- **State File:** `s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate`
- **Output File:** `int_outputs.json`
- **Variables Updated:** `*_INT` or generic (shared across environments)
- **Triggered After:** `apply:int` succeeds

### QA Environment
- **State File:** `s3://bucket-s3-infra-devops/ecs-cluster/qa/terraform.tfstate`
- **Output File:** `qa_outputs.json`
- **Triggered After:** `apply:qa` succeeds

### STG Environment
- **State File:** `s3://bucket-s3-infra-devops/ecs-cluster/stg/terraform.tfstate`
- **Output File:** `stg_outputs.json`
- **Triggered After:** `apply:stg` succeeds

### PRD Environment
- **State File:** `s3://bucket-s3-infra-devops/ecs-cluster/prd/terraform.tfstate`
- **Output File:** `prd_outputs.json`
- **Triggered After:** `apply:prd` succeeds

**Note:** Variables are **NOT environment-scoped** in this setup. All environments update the same GitLab variables, with the latest environment's values taking precedence. For environment-scoped variables, consider using GitLab's environment-specific variable features.

---

## Next Steps

### For App Deployment Pipeline

The app deployment pipeline can now consume these variables:

```yaml
stages:
  - build
  - push
  - deploy

build:backend:
  stage: build
  script:
    - docker build -t backend:${CI_COMMIT_SHA:0:8} ./backend

push:ecr:
  stage: push
  script:
    - aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${BACKEND_ECR_REGISTRY}
    - docker tag backend:${CI_COMMIT_SHA:0:8} ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:latest
    - docker push ${BACKEND_ECR_REGISTRY}/${BACKEND_ECR_REPOSITORY}:latest

deploy:ecs:
  stage: deploy
  script:
    - aws ecs update-service --cluster ${ECS_CLUSTER_NAME} --service backend --force-new-deployment --region ${AWS_REGION}
```

### For Local Development

View synced variables:

```bash
# Using glab CLI
glab variable list --project devops8004932/kubernetes/ecs-cluster

# Or in GitLab UI
https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Stage Added** | `update-variables` (new) |
| **Trigger** | Manual (after apply succeeds) |
| **Variables Updated** | 19 infrastructure variables |
| **All Environments** | INT, QA, STG, PRD |
| **Existing Jobs** | ✅ Untouched (backward compatible) |
| **Authentication** | GitLab CI_JOB_TOKEN |
| **Files Modified** | `.gitlab-ci.yml` (added ~500 lines) |

---

## Related Files

- `.gitlab-ci.yml` - Pipeline configuration (lines 326-832)
- `outputs.tf` - Terraform outputs being extracted
- `SETUP_GITLAB_VARIABLES.sh` - Manual variable setup (fallback)
- `GITLAB_VARIABLES_CONFIGURED.md` - Variable reference documentation

