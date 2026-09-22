# Quick Reference Card

## ✅ Status: Infrastructure 95% Ready

---

## AWS Endpoints

| Resource | Endpoint/ID |
|----------|---------|
| **AWS Account** | 639140327478 |
| **Region** | us-east-1 |
| **VPC** | vpc-0301d6ba38834d6aa |
| **ECS Cluster** | ecs-cluster-int |
| **RDS PostgreSQL** | ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com:5432 |
| **Redis** | Creating (~5-10 min) |
| **ECR Registry** | 639140327478.dkr.ecr.us-east-1.amazonaws.com |
| **S3 Storage** | ecs-cluster-int-app-storage-639140327478 |
| **S3 Logs** | ecs-cluster-int-logs-639140327478 |

---

## Database Credentials

| Field | Value |
|-------|-------|
| **Host** | ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com |
| **Port** | 5432 |
| **Database** | ecommercedb |
| **Username** | postgres |
| **Password** | In Secrets Manager: ecs-cluster-int/rds/master-password |

---

## GitLab CI/CD Variables

| Category | Count | Status |
|----------|-------|--------|
| AWS Config | 2 | ✅ Set |
| VPC/Network | 3 | ✅ Set |
| ECR | 4 | ✅ Set |
| Database | 5 | ✅ Set |
| IAM Roles | 2 | ✅ Set |
| App Config | 3 | ✅ Set |
| Secrets | 1 | ✅ Set |
| **Total** | **20** | **✅ All Set** |

📍 View: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd

---

## Useful Commands

### Check Infrastructure
```bash
# ECS Status
aws ecs describe-clusters --clusters ecs-cluster-int --region us-east-1 --profile $AWS_PROFILE

# RDS Status
aws rds describe-db-instances --db-instance-identifier ecs-cluster-int-postgres-db --region us-east-1 --profile $AWS_PROFILE

# Redis Status
aws elasticache describe-replication-groups --replication-group-id ecs-cluster-int-redis --region us-east-1 --profile $AWS_PROFILE
```

### Test Database
```bash
psql -h ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com \
  -U postgres -d ecommercedb -c "SELECT version();"
```

### Deploy (Manual)
```bash
cd /Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster
export AWS_PROFILE=$AWS_PROFILE
terraform apply -var-file="environments/int.tfvars"
```

### Deploy (GitLab Pipeline)
```bash
git push origin main
# Then go to: https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/pipelines
```

---

## Pending (Next 5-10 min)

- ⏳ Redis creation completing
- ⏳ Get REDIS_HOST and REDIS_PASSWORD from Secrets Manager
- ⏳ (Optional) Set REDIS_HOST and REDIS_PASSWORD variables in GitLab

---

## What's Ready

✅ ECS Cluster (running)  
✅ RDS PostgreSQL (available)  
✅ ECR Repositories (ready)  
✅ IAM Roles (configured)  
✅ S3 Storage (ready)  
✅ Security Groups (configured)  
✅ GitLab Variables (all 20 set)  
✅ Terraform Code (validated)  
✅ Git Repository (pushed to main)  

---

## Important Links

| Link | Purpose |
|------|---------|
| https://gitlab.com/devops8004932/kubernetes/ecs-cluster | GitLab Project |
| https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/settings/ci_cd | CI/CD Variables |
| https://gitlab.com/devops8004932/kubernetes/ecs-cluster/-/pipelines | Pipeline Status |
| https://console.aws.amazon.com/ | AWS Console |

---

## File Locations

```
/Users/sankarapple/export/DevOps/AWS-DevOps/Kubernetes/ecs-cluster/
├── DEPLOYMENT_SUMMARY.md              ← Full overview
├── QUICK_REFERENCE.md                 ← This file
├── GITLAB_VARIABLES_ALL.txt           ← All variable details
├── GITLAB_VARIABLES.json              ← JSON format
├── VARIABLES_SETUP_COMPLETE.md        ← Setup verification
├── main.tf                            ← Main infrastructure
├── variables.tf                       ← Input variables
├── outputs.tf                         ← Output values
├── environments/
│   ├── int.tfvars                     ← INT environment config
│   ├── qa.tfvars
│   ├── stg.tfvars
│   └── prd.tfvars
└── modules/
    ├── vpc/
    ├── ecr/
    ├── rds/
    ├── elasticache/
    ├── iam_tasks/
    └── s3/
```

---

**Last Updated:** September 13, 2026  
**Status:** Infrastructure Ready ✅
