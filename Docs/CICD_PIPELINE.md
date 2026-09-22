# ECS Cluster - GitLab CI/CD Pipeline Documentation

## Overview

This document describes the professional GitLab CI/CD pipeline for Terraform infrastructure deployment across multiple environments:
- **INT** - Integration/Development ($AWS_PROFILE account)
- **QA** - Quality Assurance ($AWS_PROFILE account)
- **STG** - Staging ($AWS_PROFILE account)
- **PRD** - Production ($AWS_PROFILE account - separate AWS account)

## Pipeline Stages

### 1. Validate Stage (Automatic)
- Triggered on merge requests and commits to main branch
- Performs Terraform format check (`terraform fmt`)
- Validates Terraform configuration (`terraform validate`)
- No infrastructure changes applied

### 2. Plan Stages (Per Environment)
- **plan:int** - Plans infrastructure for INT environment
- **plan:qa** - Plans infrastructure for QA environment
- **plan:stg** - Plans infrastructure for STG environment
- **plan:prd** - Plans infrastructure for PRD environment ($AWS_PROFILE)

Each plan stage:
- Uses environment-specific tfvars file
- Generates binary plan file (tfplan.binary)
- Displays plan summary
- Artifacts retained for 7 days

### 3. Apply Stages (Manual - Per Environment)
- **apply:int** - Applies infrastructure for INT environment
- **apply:qa** - Applies infrastructure for QA environment
- **apply:stg** - Applies infrastructure for STG environment
- **apply:prd** - Applies infrastructure for PRD environment ($AWS_PROFILE)

Each apply stage:
- Requires manual trigger (when: manual)
- Uses binary plan from corresponding plan stage
- Generates outputs in JSON format
- Artifacts retained for 7 days

### 4. Destroy Stages (Manual - Per Environment)
- **destroy:int** - Destroys infrastructure for INT environment
- **destroy:qa** - Destroys infrastructure for QA environment
- **destroy:stg** - Destroys infrastructure for STG environment
- **destroy:prd** - Destroys infrastructure for PRD environment ($AWS_PROFILE)

Each destroy stage:
- Requires manual trigger (when: manual)
- Automatically approved (-auto-approve flag)
- Uses environment-specific tfvars file

## Environment Configuration

### INT Environment
- **Profile**: $AWS_PROFILE
- **Instance Type**: t3.medium
- **Cluster Name**: ecs-cluster-int
- **Min/Desired/Max Capacity**: 2/2/4
- **Log Retention**: 7 days
- **Container Insights**: Disabled

### QA Environment
- **Profile**: $AWS_PROFILE
- **Instance Type**: t3.medium
- **Cluster Name**: ecs-cluster-qa
- **Min/Desired/Max Capacity**: 2/2/4
- **Log Retention**: 14 days
- **Container Insights**: Enabled

### STG Environment
- **Profile**: $AWS_PROFILE
- **Instance Type**: t3.medium
- **Cluster Name**: ecs-cluster-stg
- **Min/Desired/Max Capacity**: 2/2/4
- **Log Retention**: 30 days
- **Container Insights**: Enabled

### PRD Environment
- **Profile**: $AWS_PROFILE (Different AWS Account)
- **Instance Type**: m5.large (Production-grade)
- **Cluster Name**: ecs-cluster-prd
- **Min/Desired/Max Capacity**: 2/2/4
- **Log Retention**: 90 days
- **Container Insights**: Enabled

## How to Use

### 1. Trigger Validation
- Make a merge request to main branch
- Pipeline automatically validates code

### 2. Deploy to INT
1. Push changes to main branch
2. Wait for plan:int to complete
3. Click "play" button on apply:int job
4. Monitor the deployment

### 3. Deploy to QA/STG/PRD
- Follow same process as INT
- Each environment has its own manual apply/destroy buttons

### 4. Destroy Infrastructure
- Click "play" button on destroy:env job
- Infrastructure will be destroyed with auto-approval

## Before Script Execution

Before each job executes:
1. Downloads Terraform version 1.6.0
2. Initializes Terraform with S3 backend
3. Backend state stored at: `s3://terraform-state-infra-aws/{ENV}/terraform.tfstate`
4. Uses DynamoDB for state locking: `terraform-locks`

## AWS Profile Configuration

Profiles must be configured in GitLab CI/CD variables or AWS credentials:

```
[$AWS_PROFILE]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
region = us-east-1

[$AWS_PROFILE]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
region = us-east-1
```

## State Management

### Backend Configuration
- **Backend Type**: S3
- **Bucket**: `terraform-state-infra-aws`
- **Encryption**: Enabled
- **DynamoDB Lock Table**: `terraform-locks`
- **Region**: us-east-1

### State Files Location
```
s3://terraform-state-infra-aws/INT/terraform.tfstate
s3://terraform-state-infra-aws/QA/terraform.tfstate
s3://terraform-state-infra-aws/STG/terraform.tfstate
s3://terraform-state-infra-aws/PRD/terraform.tfstate
```

## Troubleshooting

### Plan Fails
1. Check AWS credentials for selected profile
2. Verify tfvars file contains valid configuration
3. Check Terraform validate stage for syntax errors

### Apply Fails
1. Review plan output from previous stage
2. Check AWS permissions for the profile
3. Ensure no concurrent applies to same environment
4. Check DynamoDB lock table for stale locks

### State Lock Issues
1. DynamoDB table: `terraform-locks`
2. To remove stale lock: `terraform force-unlock <LOCK_ID>`

## GitLab CI/CD Variables Required

Set the following variables in GitLab project settings:

```
AWS_PROFILE=$AWS_PROFILE  (for INT, QA, STG)
AWS_PROFILE=$AWS_PROFILE  (for PRD)
AWS_DEFAULT_REGION=us-east-1
```

Or configure in `.gitlab-ci.yml` (currently done)

## Security Best Practices

1. **State File Encryption**: S3 encryption enabled
2. **DynamoDB Locking**: Prevents concurrent modifications
3. **AWS Profile Separation**: Different profiles for different environments
4. **Production Account**: Separate AWS account ($AWS_PROFILE)
5. **Manual Approvals**: Apply and Destroy require manual trigger
6. **Artifact Retention**: Plans kept for 7 days for audit trail

## Maintenance

### Upgrading Terraform Version
1. Update `TF_VERSION` in `.gitlab-ci.yml`
2. Commit and push changes
3. Re-run validation stage
4. Proceed with deployment as normal

### Adding New Environment
1. Create new tfvars file: `environments/new_env.tfvars`
2. Add plan/apply/destroy stages in `.gitlab-ci.yml`
3. Update AWS profiles as needed
4. Document configuration in this file

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Terraform State Management](https://www.terraform.io/language/state)
- [AWS S3 Backend](https://www.terraform.io/language/settings/backends/s3)
