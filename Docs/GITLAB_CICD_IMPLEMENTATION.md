# GitLab CI/CD Pipeline Implementation - ECS Cluster Infrastructure

## Overview

This document provides a comprehensive guide to the professional GitLab CI/CD pipeline implementation for the ECS cluster infrastructure repository. The pipeline automates Terraform deployments across multiple environments (INT, QA, STG, PRD) with strict controls and best practices.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Pipeline Structure](#pipeline-structure)
3. [Environments](#environments)
4. [Backend Configuration](#backend-configuration)
5. [Prerequisites](#prerequisites)
6. [Setup Instructions](#setup-instructions)
7. [Pipeline Execution](#pipeline-execution)
8. [Security Considerations](#security-considerations)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Architecture

### Design Philosophy

- **Multi-Environment**: Supports INT (development), QA (testing), STG (staging), and PRD (production)
- **Standard 4-Stage Pipeline**: validate → plan → apply → destroy
- **Separation of Concerns**: All environments use same stages but with different tfvars
- **Production Safety**: PRD jobs defined at END of pipeline with manual approval
- **State Management**: Centralized S3 backend with Object Lock for consistency

### High-Level Flow

```
┌─────────────────────────────────────┐
│ GitLab Push to main branch          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 1: VALIDATE                   │
│ - Terraform format check            │
│ - Terraform validate                │
│ - Automatic trigger (all branches)  │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 2: PLAN (Parallel)            │
│ - plan:int   (INT environment)      │
│ - plan:qa    (QA environment)       │
│ - plan:stg   (STG environment)      │
│ - plan:prd   (PRD environment)      │
│ - Automatic trigger                 │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 3: APPLY (Parallel)           │
│ - apply:int  (INT environment)      │
│ - apply:qa   (QA environment)       │
│ - apply:stg  (STG environment)      │
│ - apply:prd  (PRD environment)      │
│ - MANUAL trigger (requires approval)│
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 4: DESTROY (Parallel)         │
│ - destroy:int (INT environment)     │
│ - destroy:qa  (QA environment)      │
│ - destroy:stg (STG environment)     │
│ - destroy:prd (PRD environment)     │
│ - MANUAL trigger (requires approval)│
└─────────────────────────────────────┘
```

---

## Pipeline Structure

### Stages Definition

```yaml
stages:
  - validate    # Syntax validation and format checks
  - plan        # Terraform plan for all environments
  - apply       # Terraform apply (manual trigger)
  - destroy     # Terraform destroy (manual trigger)
```

### Jobs Configuration

#### Validate Stage
```yaml
validate:
  stage: validate
  image: ubuntu:22.04
  script:
    - ./terraform fmt -check -recursive .
    - ./terraform validate
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'
```

**Purpose**: Ensures Terraform configuration is properly formatted and syntactically valid
**Trigger**: Automatic on merge requests and main branch commits
**Duration**: ~30-60 seconds

#### Plan Jobs (INT, QA, STG, PRD)
```yaml
plan:int:
  stage: plan
  image: ubuntu:22.04
  environment:
    name: INT
    deployment_tier: development
  script:
    - ./terraform plan -var-file="environments/int.tfvars" -out=tfplan.int
    - ./terraform show -no-color tfplan.int > plan_output_int.txt
  artifacts:
    paths:
      - tfplan.int
      - plan_output_int.txt
      - .terraform.lock.hcl
    expire_in: 7 days
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

**Purpose**: Generate execution plans for each environment
**Trigger**: Automatic on main branch
**Artifacts**: Saved plan files used in apply stage
**Duration**: ~1-2 minutes per environment

#### Apply Jobs (INT, QA, STG, PRD)
```yaml
apply:int:
  stage: apply
  image: ubuntu:22.04
  environment:
    name: INT
    deployment_tier: development
  dependencies:
    - plan:int
  script:
    - ./terraform apply -auto-approve tfplan.int
    - ./terraform output -json > int_outputs.json
  artifacts:
    paths:
      - int_outputs.json
    expire_in: 30 days
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual
```

**Purpose**: Execute Terraform changes to create/update infrastructure
**Trigger**: Manual (requires user approval in GitLab UI)
**Dependencies**: Requires successful plan job
**Duration**: ~2-5 minutes per environment

#### Destroy Jobs (INT, QA, STG, PRD)
```yaml
destroy:int:
  stage: destroy
  image: ubuntu:22.04
  environment:
    name: INT
    deployment_tier: development
  script:
    - ./terraform destroy -var-file="environments/int.tfvars" -auto-approve
  when: manual
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual
```

**Purpose**: Teardown infrastructure (development/testing purposes)
**Trigger**: Manual (requires explicit user approval)
**Duration**: ~1-3 minutes per environment

---

## Environments

### Environment Configuration

| Environment | Tier | Purpose | Instance Type | Min Size | Max Size | State File |
|-------------|------|---------|---------------|----------|----------|-----------|
| INT | Development | Initial testing | t3.micro | 2 | 4 | `ecs-cluster/int/terraform.tfstate` |
| QA | Testing | Quality assurance | t3.micro | 2 | 4 | `ecs-cluster/qa/terraform.tfstate` |
| STG | Staging | Pre-production | t3.micro | 2 | 4 | `ecs-cluster/stg/terraform.tfstate` |
| PRD | Production | Production workload | t3.micro | 2 | 4 | `ecs-cluster/prd/terraform.tfstate` |

### Environment Variables

**INT Environment** (`environments/int.tfvars`):
```hcl
region                    = "us-east-1"
environment               = "dev"
cluster_name              = "ecs-cluster-int"
instance_type             = "t3.medium"
min_size                  = 2
max_size                  = 4
desired_capacity          = 2
ecs_min_capacity          = 2
ecs_desired_capacity      = 2
ecs_max_capacity          = 4
log_retention_days        = 7
enable_container_insights = false
```

**QA Environment** (`environments/qa.tfvars`):
```hcl
environment               = "staging"
cluster_name              = "ecs-cluster-qa"
log_retention_days        = 14
```

**STG Environment** (`environments/stg.tfvars`):
```hcl
environment               = "staging"
cluster_name              = "ecs-cluster-stg"
log_retention_days        = 30
```

**PRD Environment** (`environments/prd.tfvars`):
```hcl
environment               = "prod"
cluster_name              = "ecs-cluster-prd"
instance_type             = "t3.micro"
log_retention_days        = 90
```

---

## Backend Configuration

### S3 Backend Setup

**Bucket**: `bucket-s3-infra-devops`
**Region**: `us-east-1`
**Encryption**: AES-256
**Versioning**: Enabled
**Object Lock**: Enabled (use_lockfile=true)

### State File Organization

```
s3://bucket-s3-infra-devops/
├── ecs-cluster/
│   ├── int/
│   │   └── terraform.tfstate
│   ├── qa/
│   │   └── terraform.tfstate
│   ├── stg/
│   │   └── terraform.tfstate
│   └── prd/
│       └── terraform.tfstate
└── ec2-infra-k8s/
    ├── int/
    │   └── terraform.tfstate
    ├── qa/
    │   └── terraform.tfstate
    ├── stg/
    │   └── terraform.tfstate
    └── prd/
        └── terraform.tfstate
```

### Backend Initialization (before_script)

```bash
#!/bin/bash

cd ${TF_ROOT}

# Install Terraform
apt-get update -qq && apt-get install -y -qq curl unzip ca-certificates
curl -fsSLo terraform.zip "https://releases.hashicorp.com/terraform/1.16.2/terraform_1.16.2_linux_amd64.zip"
unzip -q terraform.zip && rm -f terraform.zip && chmod +x terraform

# Verify Terraform version
./terraform version

# Validate environment name is set
: "${CI_ENVIRONMENT_NAME:?ERROR - CI_ENVIRONMENT_NAME is not set}"

# Convert environment name to lowercase (INT → int, PRD → prd)
export TF_STATE_ENV="$(printf '%s' "${CI_ENVIRONMENT_NAME}" | tr '[:upper:]' '[:lower:]')"

# Initialize backend with dynamic state key
./terraform init \
  -backend-config="bucket=bucket-s3-infra-devops" \
  -backend-config="key=ecs-cluster/${TF_STATE_ENV}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
```

### Dynamic State Key Generation

The pipeline uses environment name to construct unique state keys:

```
CI_ENVIRONMENT_NAME = "INT"
↓ (convert to lowercase)
TF_STATE_ENV = "int"
↓ (construct key)
key = ecs-cluster/int/terraform.tfstate
↓ (full S3 path)
s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate
```

---

## Prerequisites

### AWS Account Setup

1. **S3 Bucket**: Create bucket `bucket-s3-infra-devops`
   ```bash
   aws s3api create-bucket \
     --bucket bucket-s3-infra-devops \
     --region us-east-1 \
     --create-bucket-configuration LocationConstraint=us-east-1
   ```

2. **Enable Versioning**:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket bucket-s3-infra-devops \
     --versioning-configuration Status=Enabled
   ```

3. **Enable Server-Side Encryption**:
   ```bash
   aws s3api put-bucket-encryption \
     --bucket bucket-s3-infra-devops \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

4. **Enable Object Lock** (optional but recommended):
   ```bash
   aws s3api put-object-lock-legal-hold \
     --bucket bucket-s3-infra-devops \
     --key ecs-cluster/int/terraform.tfstate \
     --legal-hold-status ON
   ```

5. **IAM User for GitLab CI/CD**:
   - Create IAM user: `gitlab-cicd-deployer`
   - Attach policy for S3 access and EC2 operations
   - Generate AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

### GitLab Setup

1. **GitLab Runner**: Install and register runner
2. **CI/CD Variables**: Add to GitLab group or project
3. **Repository Access**: Ensure runner can access repository

### Local System Requirements

- Terraform >= 1.16.2
- AWS CLI v2
- Git
- Bash shell

---

## Setup Instructions

### Step 1: AWS Credentials Configuration

Add credentials to GitLab CI/CD variables (Group or Project level):

**Go to**: GitLab → Group/Project → Settings → CI/CD → Variables

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJal...
AWS_DEFAULT_REGION=us-east-1
```

### Step 2: Clone Repository

```bash
git clone https://gitlab.com/devops8004932/kubernetes/ecs-cluster.git
cd ecs-cluster
```

### Step 3: Verify Configuration

```bash
# Check backend configuration
cat backend.tf

# Verify environment files exist
ls -la environments/

# Check Terraform syntax
terraform fmt -check -recursive .
terraform validate
```

### Step 4: Set Up GitLab Runner

Refer to `GITLAB_RUNNER_SETUP.md` for detailed setup instructions.

### Step 5: Trigger Pipeline

Push changes to main branch:

```bash
git add .
git commit -m "Initial infrastructure setup"
git push origin main
```

Monitor pipeline in GitLab UI:
- GitLab → Project → CI/CD → Pipelines

---

## Pipeline Execution

### Manual Pipeline Trigger

1. **Go to**: GitLab → Project → CI/CD → Pipelines
2. **Click**: "New Pipeline"
3. **Select Branch**: `main`
4. **Click**: "Create Pipeline"

### Triggering Individual Jobs

1. **Validation** (Automatic):
   - Runs automatically when push to main
   - No manual action needed

2. **Plan** (Automatic):
   - Runs after validation passes
   - Generates plan files for each environment

3. **Apply** (Manual):
   - Click "Play" button next to apply:int job
   - Confirm deployment
   - Repeats for apply:qa, apply:stg, apply:prd

4. **Destroy** (Manual):
   - Only run for development/testing
   - Use for cleanup (typically INT environment)

### Example Execution Flow

```
Commit to main
    ↓
validate job starts (automatic)
    ↓
validate passes?
    ├─ YES → plan jobs start (automatic, parallel)
    │         plan:int
    │         plan:qa
    │         plan:stg
    │         plan:prd
    │         ↓
    │     plan jobs complete
    │         ↓
    │     apply jobs ready (manual, waiting for approval)
    │
    └─ NO → Pipeline failed, check logs
```

### Monitoring Pipeline Status

**In GitLab UI**:
1. Pipeline view shows all stages and jobs
2. Each job shows:
   - Status (running, passed, failed, manual)
   - Duration
   - Logs (click to view)
   - Artifacts (if any)

**Via GitLab API**:
```bash
curl --header "PRIVATE-TOKEN: <token>" \
  https://gitlab.com/api/v4/projects/PROJECT_ID/pipelines
```

---

## Security Considerations

### Secrets Management

1. **AWS Credentials**:
   - Stored in GitLab CI/CD Variables (encrypted)
   - Never committed to repository
   - Rotated regularly

2. **SSH Keys**:
   - Generated per environment
   - Stored in Terraform state (encrypted in S3)
   - Never exposed in logs

3. **Terraform State**:
   - S3 backend with encryption
   - Object Lock enabled for consistency
   - Versioning enabled for recovery

### Access Control

1. **GitLab Permissions**:
   - Repository: Protected main branch
   - CI/CD: Only developers can trigger manual jobs
   - Admin review required for production

2. **AWS IAM**:
   - Least privilege principle
   - Service-specific policies
   - Regular audit of permissions

### Audit Trail

- All pipeline executions logged in GitLab
- Terraform state changes tracked (with versioning)
- S3 access logs available
- CloudTrail for AWS API calls

---

## Troubleshooting

### Common Issues

#### 1. CI_ENVIRONMENT_NAME Not Set

**Error**:
```
ERROR - CI_ENVIRONMENT_NAME is not set
```

**Cause**: Job doesn't have `environment:` block

**Solution**: Ensure job definition includes:
```yaml
environment:
  name: INT
  deployment_tier: development
```

#### 2. S3 State File Error (Double Slash)

**Error**:
```
Value must not contain "//"
```

**Cause**: Environment variable empty, resulting in `ecs-cluster//terraform.tfstate`

**Solution**: Verify CI_ENVIRONMENT_NAME is set properly in job output:
```bash
echo "CI_ENVIRONMENT_NAME=[$CI_ENVIRONMENT_NAME]"
echo "TF state key=[ecs-cluster/${TF_STATE_ENV}/terraform.tfstate]"
```

#### 3. VPC Limit Exceeded

**Error**:
```
Error: creating EC2 VPC: operation error EC2: CreateVpc, ... VpcLimitExceeded
```

**Cause**: AWS account reached max VPCs (default 5 per region)

**Solution**:
1. Delete unused VPCs in AWS Console
2. Request AWS limit increase
3. Use Service Quotas console

#### 4. Undeclared Variable Warning

**Error**:
```
Warning: Value for undeclared variable
The root module does not declare a variable named "aws_profile"
```

**Cause**: tfvars file has variable not declared in variables.tf

**Solution**: Remove from terraform.tfvars:
```diff
- aws_profile = "$AWS_PROFILE"
```

#### 5. Terraform Lock Error

**Error**:
```
Error acquiring the state lock
```

**Cause**: Another pipeline/process has lock on state

**Solution**:
1. Wait for other job to complete
2. Or force unlock (use with caution):
   ```bash
   terraform force-unlock LOCK_ID
   ```

### Debugging Tips

1. **View Job Logs**:
   - GitLab → Pipeline → Click job → View logs
   - Look for `terraform init` output

2. **Check State File**:
   ```bash
   aws s3 ls s3://bucket-s3-infra-devops/ecs-cluster/
   ```

3. **Local Testing**:
   ```bash
   terraform init -backend-config="bucket=bucket-s3-infra-devops" \
     -backend-config="key=ecs-cluster/int/terraform.tfstate" \
     -backend-config="region=us-east-1" \
     -backend-config="encrypt=true" \
     -backend-config="use_lockfile=true"
   terraform plan -var-file="environments/int.tfvars"
   ```

4. **Enable Debug Mode**:
   ```bash
   export TF_LOG=DEBUG
   terraform apply -var-file="environments/int.tfvars"
   ```

---

## Best Practices

### Pipeline Management

1. **Protect Main Branch**:
   - Require merge request reviews
   - Require successful CI pipeline
   - Restrict push access to admins

2. **Environment Progression**:
   - Always start with INT
   - Test in QA before STG
   - Never skip to PRD directly
   - Use consistent configuration

3. **Documentation**:
   - Keep terraform.tfvars comments updated
   - Document variable changes
   - Maintain deployment runbooks

### Terraform Best Practices

1. **Code Quality**:
   ```bash
   # Format code
   terraform fmt -recursive .
   
   # Validate syntax
   terraform validate
   
   # Security scan
   terraform scan -json
   ```

2. **State Management**:
   - Never manually edit state
   - Always use remote state
   - Regular backups (S3 versioning)
   - Lock state during apply

3. **Variable Organization**:
   - Use descriptive variable names
   - Add validation rules
   - Document all variables
   - Group related variables

### Deployment Strategy

1. **Testing**:
   - Always run plan first
   - Review plan output before apply
   - Test in INT environment first
   - Validate with small changes

2. **Rollback Procedure**:
   - Keep previous state versions
   - Document rollback steps
   - Test rollback process
   - Communicate changes to team

3. **Monitoring**:
   - Watch CloudWatch metrics
   - Monitor cost implications
   - Track resource utilization
   - Alert on anomalies

### Team Workflow

1. **Code Review**:
   - Require PR reviews
   - Check Terraform changes
   - Verify security implications
   - Document reasoning

2. **Communication**:
   - Announce deployments
   - Schedule maintenance windows
   - Document changes
   - Debrief after issues

3. **Knowledge Sharing**:
   - Maintain runbooks
   - Document procedures
   - Record troubleshooting steps
   - Share lessons learned

---

## Additional Resources

### Documentation Files
- `GITLAB_RUNNER_SETUP.md` - GitLab Runner setup guide
- `CICD_PIPELINE.md` - Pipeline overview
- `README.md` - Main repository documentation

### External References
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Support

For issues or questions:
1. Check `TROUBLESHOOTING.md`
2. Review pipeline logs in GitLab
3. Contact DevOps team
4. Refer to team runbooks

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-09-12 | Initial implementation |
| | | 4-stage pipeline (validate, plan, apply, destroy) |
| | | All environments (INT, QA, STG, PRD) |
| | | S3 backend with Object Lock |
| | | Dynamic state key generation |

---

## Document Metadata

- **Repository**: ecs-cluster
- **Branch**: main
- **Last Updated**: 2024-09-12
- **Terraform Version**: 1.16.2
- **AWS Region**: us-east-1
- **State Backend**: S3 (bucket-s3-infra-devops)

---

## Conclusion

This GitLab CI/CD pipeline implementation provides a robust, scalable, and secure way to manage infrastructure as code across multiple environments. By following the guidelines in this document, your team can deploy infrastructure changes confidently while maintaining compliance and best practices.

For questions or contributions, please contact the DevOps team.
