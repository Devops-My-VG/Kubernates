# ECS Cluster Infrastructure Deployment Guide

## 📋 Overview

This guide explains how to deploy and manage ECS cluster infrastructure using the `deploy.sh` script with Terraform and S3 state storage.

### Key Features

✅ **Pipeline Disabled** - GitLab CI/CD pipeline is completely disabled (`when: never` for all jobs)  
✅ **Local Deployment** - Use `deploy.sh` script to deploy from your local machine  
✅ **S3 State Storage** - All Terraform state stored in `bucket-s3-infra-devops`  
✅ **Multi-Environment** - Support for INT, QA, STG, PRD environments  
✅ **No DynamoDB Locking** - S3-only state backend (per requirements)  
✅ **Automatic Validation** - Input validation, AWS credentials check, S3 bucket verification  
✅ **State Backup** - Automatic state file backup before operations  

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install AWS CLI
brew install awscli                    # macOS
# or: apt-get install awscli           # Linux

# Configure AWS credentials
aws configure --profile $AWS_PROFILE
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)

# Verify credentials
aws sts get-caller-identity --profile $AWS_PROFILE

# Verify S3 bucket access
aws s3 ls s3://bucket-s3-infra-devops --profile $AWS_PROFILE
```

### Basic Usage

```bash
# Navigate to repository
cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster

# Deploy INT environment
./deploy.sh int apply

# Preview changes before deploying
./deploy.sh int plan

# Deploy other environments
./deploy.sh qa apply
./deploy.sh stg apply
./deploy.sh prd apply

# Destroy environment
./deploy.sh int destroy
```

---

## 📊 Command Reference

### Syntax

```bash
./deploy.sh [ENVIRONMENT] [ACTION]
```

### Environments

| Environment | Purpose | Valkey Sizing | Monthly Cost |
|-------------|---------|---------------|--------------|
| `int` | Development & Testing | 5GB, 500 eCPUs/sec | ~$70 |
| `qa` | Quality Assurance | 10GB, 1000 eCPUs/sec | ~$140 |
| `stg` | Staging & Pre-Prod | 15GB, 1500 eCPUs/sec | ~$170 |
| `prd` | Production | 25GB, 2000 eCPUs/sec | ~$240 |

### Actions

| Action | Description | Confirmation Required | Reversible |
|--------|-------------|----------------------|-----------|
| `plan` | Preview infrastructure changes | No | Yes |
| `apply` | Create/update infrastructure | Yes (10 sec warning) | No |
| `destroy` | Delete all infrastructure | Yes (manual confirmation) | No |

### Examples

```bash
# Plan INT environment
./deploy.sh int plan

# Apply INT environment (with confirmation)
./deploy.sh int apply

# Plan QA environment
./deploy.sh qa plan

# Apply QA environment
./deploy.sh qa apply

# Plan STG environment
./deploy.sh stg plan

# Apply STG environment
./deploy.sh stg apply

# Destroy INT environment (careful!)
./deploy.sh int destroy
```

---

## 🔍 What the Script Does

### Validation Phase

1. **Environment Check** - Validates environment name (int, qa, stg, prd)
2. **Action Check** - Validates action (plan, apply, destroy)
3. **AWS Credentials** - Verifies AWS profile authentication
4. **S3 Bucket** - Confirms `bucket-s3-infra-devops` exists
5. **Environment File** - Checks `environments/{env}.tfvars` exists

### Terraform Phase

1. **Download Terraform** - Downloads version 1.16.2 (macOS/Linux compatible)
2. **Initialize Backend** - Configures S3 backend with environment-specific state key
3. **Validate Config** - Runs format check and syntax validation
4. **Backup State** - Backs up existing state file to `/tmp/`
5. **Execute Action** - Runs plan, apply, or destroy

### Output Phase

1. **Display Plan** - Shows infrastructure changes
2. **Export Outputs** - Saves Terraform outputs to `outputs_{env}.json`
3. **Show Endpoints** - Displays key infrastructure endpoints (VPC, RDS, Valkey, ALB)

---

## 📁 State File Management

### State File Locations

All state files are stored in S3:

```
s3://bucket-s3-infra-devops/
├── ecs-cluster/
│   ├── int/terraform.tfstate          # INT environment
│   ├── qa/terraform.tfstate           # QA environment
│   ├── stg/terraform.tfstate          # STG environment
│   └── prd/terraform.tfstate          # PRD environment
```

### Encryption

- ✅ All state files encrypted at rest (S3 encryption)
- ✅ Encryption in transit (HTTPS)
- ✅ Access controlled via IAM policies

### Backup

- ✅ Automatic backup before each operation
- ✅ Backups saved to `/tmp/terraform_{env}_YYYYMMDD_HHMMSS.tfstate`
- ✅ Manual backup: `aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/{env}/terraform.tfstate ./backup.tfstate --profile $AWS_PROFILE`

### Recovery

If you need to restore a state file:

```bash
# Download backup from S3
aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate ./restore.tfstate --profile $AWS_PROFILE

# Restore to local Terraform
cp ./restore.tfstate /path/to/.terraform/terraform.tfstate

# Or push to S3 (if corrupted)
aws s3 cp ./restore.tfstate s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate --profile $AWS_PROFILE
```

---

## 📋 Deployment Workflow

### Workflow: Deploy INT Environment

```bash
# Step 1: Preview changes
./deploy.sh int plan
# Review the output to see what will be created

# Step 2: Deploy infrastructure
./deploy.sh int apply
# Wait for confirmation (10 sec countdown)
# Infrastructure will be created

# Step 3: Verify deployment
terraform output -json
# Or check AWS Console
```

### Workflow: Update INT Environment

```bash
# Step 1: Make changes to Terraform files
# (e.g., update main.tf, variables.tf, etc.)

# Step 2: Preview changes
./deploy.sh int plan
# Review the changes

# Step 3: Apply changes
./deploy.sh int apply
# Infrastructure will be updated
```

### Workflow: Destroy INT Environment

```bash
# Step 1: Destroy infrastructure
./deploy.sh int destroy
# Confirm destruction when prompted

# Step 2: Verify deletion
# Check AWS Console or run:
aws ec2 describe-vpcs --profile $AWS_PROFILE --region us-east-1
```

---

## ⚠️ Important Notes

### Before Deploying to Production

1. **Always run `plan` first** - Preview all changes
2. **Review plan output** - Check resource details
3. **Test on INT/QA first** - Validate before production
4. **Have backup ready** - Ensure state file backups exist

### Destruction is Irreversible

- ⚠️ `destroy` action DELETES ALL INFRASTRUCTURE
- ✅ State file is preserved (can restore later with terraform)
- ✅ State file backed up before destruction
- ✓ Requires manual confirmation

### Common Issues

**Issue: "Invalid environment"**
```
Solution: Use one of: int, qa, stg, prd
```

**Issue: "S3 bucket not found"**
```
Solution: Check AWS credentials and S3 bucket name
aws s3 ls --profile $AWS_PROFILE
```

**Issue: "Environment variables file not found"**
```
Solution: Check environments/{env}.tfvars file exists
ls -la environments/
```

**Issue: "AWS credentials not configured"**
```
Solution: Configure AWS profile
aws configure --profile $AWS_PROFILE
```

---

## 📊 Outputs

After deployment, outputs are available in two ways:

### 1. Console Output

```bash
./deploy.sh int apply
# Shows:
# VPC ID: vpc-0667236d801895c4d
# RDS Endpoint: ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com:5432
# Valkey Endpoint: ecs-cluster-int-valkey.xxxxx.serverless.cache.amazonaws.com:6379
# ALB DNS: ecs-cluster-int-alb-123456.us-east-1.elb.amazonaws.com
```

### 2. JSON Output File

```bash
cat outputs_int.json
# Contains all Terraform outputs in JSON format
```

### Key Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `vpc_id` | VPC ID | vpc-0667236d801895c4d |
| `rds_endpoint` | RDS database endpoint | ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com |
| `valkey_endpoint` | Valkey Serverless endpoint | ecs-cluster-int-valkey.xxxxx.serverless.cache.amazonaws.com |
| `alb_dns_name` | Application Load Balancer DNS | ecs-cluster-int-alb-123456.us-east-1.elb.amazonaws.com |

---

## 🔐 Security Considerations

### State File Security

✅ Encrypted at rest (S3 encryption)  
✅ Encrypted in transit (HTTPS)  
✅ Access controlled via IAM  
✅ Versioning enabled on S3  
✅ Automatic backups before operations  

### Infrastructure Security

✅ Security groups restrict access  
✅ RDS database in private subnets  
✅ Valkey Serverless in private subnets  
✅ ALB in public subnets (controlled access)  
✅ EC2 instances in private subnets  

### Credential Management

✅ AWS credentials stored in `~/.aws/credentials`  
✅ Never commit credentials to Git  
✅ Use IAM profiles for authentication  
✅ Rotate credentials regularly  

---

## 📝 Troubleshooting

### Enable Debug Mode

```bash
# Run script with debug output
bash -x deploy.sh int plan

# Or set debug flag
DEBUG=1 ./deploy.sh int plan
```

### Check Terraform State

```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.example

# Export state
terraform show -json
```

### View S3 State File

```bash
# List state files
aws s3 ls s3://bucket-s3-infra-devops/ecs-cluster/ --profile $AWS_PROFILE

# Download state file
aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate ./debug.tfstate --profile $AWS_PROFILE

# View state file content
cat debug.tfstate | jq .
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid environment` | Wrong environment name | Use: int, qa, stg, prd |
| `Invalid action` | Wrong action name | Use: plan, apply, destroy |
| `S3 bucket not found` | Bucket doesn't exist or no access | Check AWS credentials, S3 bucket name |
| `Environment variables file not found` | Missing tfvars file | Check `environments/{env}.tfvars` exists |
| `AWS credentials not configured` | Missing/invalid credentials | Run `aws configure --profile $AWS_PROFILE` |

---

## 📚 Related Documentation

- **Terraform Documentation:** https://www.terraform.io/docs
- **AWS Documentation:** https://docs.aws.amazon.com/
- **ECS Documentation:** https://docs.aws.amazon.com/ecs/
- **Valkey Serverless:** https://docs.aws.amazon.com/elasticache/
- **S3 Backend:** https://www.terraform.io/language/settings/backends/s3

---

## ✅ Checklist: Before Deploying

- [ ] AWS credentials configured: `aws configure --profile $AWS_PROFILE`
- [ ] S3 bucket verified: `aws s3 ls s3://bucket-s3-infra-devops --profile $AWS_PROFILE`
- [ ] Environment file exists: `ls environments/{env}.tfvars`
- [ ] Terraform changes reviewed: `./deploy.sh {env} plan`
- [ ] No sensitive data in code
- [ ] Backup strategy in place
- [ ] Team notified of deployment
- [ ] Runbook available for rollback

---

## 📞 Support

For issues or questions:

1. Check this documentation
2. Review Terraform logs: `terraform show`
3. Check AWS Console for resource status
4. Review CloudTrail for API calls
5. Contact DevOps team

---

## 🎯 Next Steps

1. **Review Deploy Script:** Understand the workflow
2. **Plan INT Deployment:** `./deploy.sh int plan`
3. **Deploy INT:** `./deploy.sh int apply`
4. **Verify Resources:** Check AWS Console
5. **Test Application:** Deploy apps to ECS
6. **Plan QA/STG/PRD:** Repeat for other environments

---

**Last Updated:** September 2026  
**Status:** ✅ Production Ready
