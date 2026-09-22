# Quick Reference Guide - Infrastructure Artifact Export

## 🎯 One-Liner Overview

**Export infrastructure artifacts from ECS Cluster pipeline for consumption by ecommerce-app-v1 pipeline.**

---

## 📋 New Pipeline Stage

**Location**: `.gitlab-ci.yml`  
**Stage**: `export-artifacts`  
**Trigger**: Automatic (after `apply:int` succeeds)  
**Duration**: ~10-15 seconds  

---

## 📦 Artifacts Generated

| Format | File Name | Use Case | Retention |
|--------|-----------|----------|-----------|
| JSON | `terraform-outputs.json` | Programmatic access (jq parsing) | 30 days |
| Bash | `infra-config.env` | Source in shell scripts | 30 days |
| YAML | `infra-config.yaml` | K8s manifests, documentation | 30 days |
| Meta | `infra-manifest.json` | Metadata, versioning info | 30 days |

---

## 🔄 Consumption Methods

### Method 1: GitLab CI/CD Variables (Recommended)
```yaml
deploy:
  script:
    - echo "Cluster: $ECS_CLUSTER_NAME"
    - echo "RDS: $RDS_HOST"
```

### Method 2: Download from S3
```bash
aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/infra-config.env .
source infra-config.env
```

### Method 3: GitLab Artifacts API
```bash
curl -H "PRIVATE-TOKEN: $CI_JOB_TOKEN" \
  -o infra.zip \
  "https://gitlab.com/api/v4/projects/devops-trainsep%2FKubernetes%2Fecs-cluster/pipelines/latest/artifacts/download?job=export-artifacts:int"
unzip -o infra.zip && source infra-config.env
```

---

## 📊 Available Variables (20+)

```bash
# Network (3)
$VPC_ID
$PUBLIC_SUBNETS
$SECURITY_GROUP_ID

# ECS (3)
$ECS_CLUSTER_NAME
$ECS_CLUSTER_ARN
$CLOUDWATCH_LOG_GROUP

# Database (4)
$RDS_HOST
$RDS_PORT
$RDS_DATABASE_NAME
$RDS_USERNAME

# Cache (2)
$VALKEY_HOST
$VALKEY_PORT

# Registry (5)
$ECR_REGISTRY
$BACKEND_ECR_REPOSITORY
$FRONTEND_ECR_REPOSITORY
$BACKEND_ECR_REPOSITORY_URL
$FRONTEND_ECR_REPOSITORY_URL

# Security (2)
$ECS_TASK_EXECUTION_ROLE_ARN
$ECS_TASK_ROLE_ARN
```

---

## 🚀 Usage Examples

### Deploy to ECS
```bash
aws ecs update-service \
  --cluster $ECS_CLUSTER_NAME \
  --service my-app \
  --force-new-deployment
```

### Push to ECR
```bash
docker push $BACKEND_ECR_REPOSITORY_URL:latest
```

### Database Connection
```bash
DATABASE_URL="postgres://$RDS_USERNAME:$PASS@$RDS_HOST:$RDS_PORT/$RDS_DATABASE_NAME"
```

### Register Task Definition
```bash
aws ecs register-task-definition \
  --family my-app \
  --execution-role-arn $ECS_TASK_EXECUTION_ROLE_ARN \
  --task-role-arn $ECS_TASK_ROLE_ARN \
  --container-definitions "[{\"environment\":[{\"name\":\"RDS_HOST\",\"value\":\"$RDS_HOST\"}]}]"
```

---

## 📁 S3 Storage Structure

```
s3://bucket-s3-infra-devops/ecs-cluster/
├── int/
│   ├── terraform.tfstate          (Terraform state)
│   └── artifacts/
│       ├── current/               (Latest artifacts)
│       │   ├── terraform-outputs.json
│       │   ├── infra-config.env
│       │   ├── infra-config.yaml
│       │   └── infra-manifest.json
│       └── v2026-09-20-090600/    (Versioned)
│           ├── terraform-outputs.json
│           ├── infra-config.env
│           ├── infra-config.yaml
│           └── infra-manifest.json
└── qa/, stg/, prd/ (future environments)
```

---

## 🔐 Security Notes

- ✅ S3 artifacts encrypted (AES-256)
- ✅ GitLab variables protected & masked
- ✅ No credentials in artifacts
- ✅ Use IAM roles for AWS access
- ✅ RDS/Valkey passwords from Secrets Manager

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `INFRA_ARTIFACT_STRATEGY.md` | Complete architecture & design |
| `CONSUME_ARTIFACTS_GUIDE.md` | Integration guide for app teams |
| `QUICK_REFERENCE.md` | This guide - quick lookup |

---

## 🛠️ Helper Scripts

```bash
# Export artifacts locally
./scripts/export-infra-artifacts.sh INT

# Upload to S3
./scripts/upload-artifacts-to-s3.sh INT bucket-s3-infra-devops us-east-1 semalgo-01
```

---

## ❓ Troubleshooting

| Issue | Solution |
|-------|----------|
| Variables not available | Check if export-artifacts:int completed successfully |
| S3 download fails | Verify AWS credentials and S3 permissions |
| Missing values | Ensure infrastructure deployed (apply:int succeeded) |
| Artifact not found | Check GitLab artifacts have 30-day retention |

---

## 🔗 Related Links

- [INFRA_ARTIFACT_STRATEGY.md](./INFRA_ARTIFACT_STRATEGY.md)
- [CONSUME_ARTIFACTS_GUIDE.md](./CONSUME_ARTIFACTS_GUIDE.md)
- [.gitlab-ci.yml](./.gitlab-ci.yml)
- [outputs.tf](./outputs.tf)

---

## 📞 Quick Commands

```bash
# List S3 artifacts
aws s3 ls s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/ \
  --profile semalgo-01 --region us-east-1

# Download latest
aws s3 cp s3://bucket-s3-infra-devops/ecs-cluster/int/artifacts/current/ . \
  --recursive --profile semalgo-01 --region us-east-1

# View artifacts in GitLab
curl -H "PRIVATE-TOKEN: $CI_JOB_TOKEN" \
  "https://gitlab.com/api/v4/projects/devops-trainsep%2FKubernetes%2Fecs-cluster/pipelines/latest"
```

---

## ✅ Checklist for App Team

- [ ] Read CONSUME_ARTIFACTS_GUIDE.md
- [ ] Choose consumption method (Option 1 recommended)
- [ ] Update .gitlab-ci.yml to use variables
- [ ] Test in develop/test pipeline first
- [ ] Deploy to INT environment
- [ ] Verify application connects to RDS & Valkey
- [ ] Promote to QA/STG/PRD environments

---

**Last Updated**: September 20, 2026
