# Valkey Serverless Deployment Checklist

**Project:** ECS Cluster Infrastructure Migration  
**Target:** Migrate from ElastiCache Redis to Valkey Serverless  
**Environments:** INT → QA → STG → PRD (sequential deployment)

---

## Pre-Deployment Phase

### Prerequisites Verification

- [ ] **AWS Credentials Configured**
  - AWS_ACCESS_KEY_ID set
  - AWS_SECRET_ACCESS_KEY set
  - Correct AWS account selected ($AWS_PROFILE)

- [ ] **Terraform Setup**
  - Terraform version 1.16.2+ installed
  - `terraform init` executed in ecs-cluster directory
  - `.terraform.lock.hcl` present

- [ ] **GitLab Configuration**
  - GitLab runner available and healthy
  - CI/CD pipeline variables set at group level:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - `AWS_DEFAULT_REGION=us-east-1`
  - Project webhook for main branch pushes enabled

- [ ] **Network Prerequisites**
  - VPC and subnets exist in us-east-1
  - ECS cluster running (if upgrading existing)
  - Security groups properly configured
  - NAT gateway for private subnet outbound access

- [ ] **Documentation Review**
  - Read `VALKEY_MIGRATION_GUIDE.md`
  - Understand cost differences vs Redis
  - Review security group changes
  - Plan rollback strategy

---

## Code Review & Validation Phase

### Repository Changes

- [ ] **Review All Modified Files**
  ```
  - modules/valkey/main.tf ✓ Created
  - modules/valkey/variables.tf ✓ Created
  - modules/valkey/outputs.tf ✓ Created
  - main.tf ✓ Updated (ElastiCache → Valkey)
  - variables.tf ✓ Updated (Redis vars → Valkey vars)
  - outputs.tf ✓ Updated (Redis outputs → Valkey outputs)
  - environments/int.tfvars ✓ Updated
  - environments/qa.tfvars ✓ Updated
  - environments/stg.tfvars ✓ Updated
  - environments/prd.tfvars ✓ Updated
  - .gitlab-ci.yml ✓ Updated (Valkey stages)
  ```

- [ ] **Terraform Format Validation**
  ```bash
  terraform fmt -check -recursive .
  # Must return 0 (no formatting issues)
  ```

- [ ] **Terraform Syntax Validation**
  ```bash
  terraform validate
  # Must return: "Success! The configuration is valid."
  ```

- [ ] **Module Dependencies**
  - Valkey module correctly depends on VPC module
  - VPC security group accessible to Valkey module
  - RDS module unchanged and compatible

- [ ] **Git Commit & Push**
  ```bash
  git add -A
  git commit -m "chore: migrate ElastiCache Redis to Valkey Serverless

  - Add new Valkey Serverless module
  - Update root main.tf to use Valkey
  - Replace Redis variables with Valkey parameters
  - Update all environment tfvars
  - Update GitLab CI/CD pipeline with Valkey stages
  - Add comprehensive migration documentation

  Benefits:
  - 33% cost savings ($722/year)
  - Serverless auto-scaling
  - Redis API compatible (no app code changes)
  - Improved cost efficiency"
  
  git push origin main
  ```

---

## GitLab Pipeline Phase (Automated)

### INT Environment (Development)

- [ ] **Stage: validate**
  - [ ] Check GitLab Pipelines dashboard
  - [ ] Wait for `validate` job to complete
  - [ ] Job output should show: "✓ All Terraform files validated successfully"

- [ ] **Stage: plan**
  - [ ] `plan:int` job starts automatically
  - [ ] Download `plan_output_int.txt` artifact
  - [ ] Review plan changes:
    ```
    Terraform will perform these actions:
    
    + aws_elasticache_serverless_cache.valkey
    + aws_security_group.valkey_sg
    + aws_secretsmanager_secret.valkey_auth_token
    + aws_cloudwatch_metric_alarm.* (4 alarms)
    + aws_cloudwatch_log_group.valkey_logs
    + aws_cloudwatch_dashboard.valkey
    - aws_elasticache_replication_group.* (OLD - if exists)
    - aws_security_group.redis_sg (OLD - if exists)
    ```
  - [ ] Verify no unexpected resource deletions
  - [ ] Check cost estimate in plan output

- [ ] **Stage: apply**
  - [ ] Click `apply:int` job
  - [ ] Click "Manual trigger" button (⏱️ with play icon)
  - [ ] Monitor job output for:
    ```
    Applying INT environment configuration with Valkey Serverless...
    module.valkey.aws_elasticache_serverless_cache.valkey: Creating...
    module.valkey.aws_elasticache_serverless_cache.valkey: Still creating... [30s elapsed]
    module.valkey.aws_elasticache_serverless_cache.valkey: Creation complete after 45s
    ✓ INT environment deployed successfully
    ```
  - [ ] Expected runtime: 2-3 minutes
  - [ ] Download `int_outputs.json` artifact

- [ ] **Verification**
  - [ ] Parse outputs to verify deployment:
    ```bash
    jq '.valkey_endpoint.value' int_outputs.json
    # Output: valkey-serverless-prd.xxxxx.xxxxxx.ng.0001.use1.cache.amazonaws.com:6379
    ```
  - [ ] Verify auth token secret created:
    ```bash
    aws secretsmanager describe-secret \
      --secret-id ecs-cluster-int/valkey/auth-token \
      --region us-east-1
    ```
  - [ ] Check CloudWatch dashboard:
    ```bash
    aws cloudwatch get-dashboard \
      --dashboard-name ecs-cluster-int-valkey-dashboard
    ```
  - [ ] Verify security group:
    ```bash
    aws ec2 describe-security-groups \
      --group-names ecs-cluster-int-valkey-sg
    ```

---

### QA Environment (Testing)

- [ ] Follow same steps as INT for `plan:qa` and `apply:qa`
- [ ] Verify Valkey Serverless deployment with 10GB storage, 1000 eCPUs/sec
- [ ] Test connection from QA ECS instances:
  ```bash
  nc -zv <VALKEY_ENDPOINT> 6379
  # Output: Connection to ... port 6379 [tcp/*] succeeded!
  ```

---

### STG Environment (Staging)

- [ ] Follow same steps as INT for `plan:stg` and `apply:stg`
- [ ] Verify Valkey Serverless deployment with 15GB storage, 1500 eCPUs/sec
- [ ] Run application smoke tests against STG Valkey
  - [ ] Cache write test: `SET test-key "test-value"`
  - [ ] Cache read test: `GET test-key`
  - [ ] TTL test: `EXPIRE test-key 60` → `TTL test-key`

---

### PRD Environment (Production)

- [ ] **Pre-Deployment Notification**
  - [ ] Notify team of planned PRD deployment
  - [ ] Schedule during low-traffic window
  - [ ] Have rollback plan ready

- [ ] Follow same steps as INT for `plan:prd` and `apply:prd`
- [ ] Verify Valkey Serverless deployment with 25GB storage, 2000 eCPUs/sec, data tiering enabled
- [ ] Monitor CloudWatch alarms during/after deployment:
  - [ ] No CPU spikes
  - [ ] No memory alerts
  - [ ] No connection errors
- [ ] Verify RDS connectivity unaffected
- [ ] Run application health checks:
  - [ ] Service endpoints responding
  - [ ] Cache operations working
  - [ ] Database queries normal latency

---

## Post-Deployment Phase

### Immediate Verification (First 30 Minutes)

- [ ] **CloudWatch Metrics**
  - [ ] CPU Utilization < 20%
  - [ ] Memory Usage < 50%
  - [ ] Network In < 100KB/s
  - [ ] No alarm triggers

- [ ] **Application Health**
  - [ ] ECS task logs show successful Valkey connections
  - [ ] No cache-related errors in logs
  - [ ] API response times normal
  - [ ] Database transactions proceeding normally

- [ ] **Security Verification**
  - [ ] Only ECS cluster can connect to Valkey
  - [ ] AUTH token in use (test: `AUTH <token>`)
  - [ ] No unauthorized connection attempts in logs

### Extended Monitoring (First 24 Hours)

- [ ] **Cost Validation**
  - [ ] AWS Cost Explorer shows Valkey charges (not Redis)
  - [ ] No duplicate charges for old Redis cluster
  - [ ] Estimated monthly cost matches projections

- [ ] **Performance Comparison**
  - [ ] Cache hit ratio maintained or improved
  - [ ] Query latencies < 10ms (p95)
  - [ ] No increase in database load
  - [ ] Memory efficiency better than Redis

- [ ] **Backup/Snapshot Verification**
  - [ ] First automatic snapshot created
  - [ ] Snapshot size reasonable (< 2GB for 10GB data)
  - [ ] Can restore from snapshot if needed

### Ongoing Monitoring (Weekly)

- [ ] **CloudWatch Dashboard Review**
  - [ ] No sustained high CPU (> 70%)
  - [ ] No memory pressure (> 85%)
  - [ ] Connection counts stable
  - [ ] Network patterns expected

- [ ] **Cost Tracking**
  - [ ] Weekly cost review in AWS Cost Explorer
  - [ ] Validate savings vs Redis baseline
  - [ ] Identify any optimization opportunities
  - [ ] Compare vs. projections

- [ ] **Application Metrics**
  - [ ] Cache hit ratio stable
  - [ ] Eviction rate < 5%
  - [ ] No slowlog entries with timeouts
  - [ ] ECS service health: 100% tasks running

---

## Rollback Checklist (If Needed)

### Minor Issues (< 1 hour downtime acceptable)

- [ ] **Step 1: Notify Team**
  - [ ] Post in #devops-incidents channel
  - [ ] Document issue encountered
  - [ ] Estimated rollback time: 15-20 minutes

- [ ] **Step 2: Destroy Valkey Only**
  ```bash
  cd /path/to/ecs-cluster
  terraform destroy -var-file="environments/int.tfvars" \
    -target=module.valkey \
    -auto-approve
  ```
  - [ ] Verify Valkey resources deleted
  - [ ] Verify RDS still running
  - [ ] ECS cluster unaffected

- [ ] **Step 3: Restore from Snapshot**
  ```bash
  # If using old Redis cluster backup
  aws elasticache restore-cache-cluster \
    --replication-group-id ecs-cluster-int-redis \
    --snapshot-name ecs-cluster-int-redis-TIMESTAMP
  ```

- [ ] **Step 4: Update Application**
  - [ ] Point applications back to old Redis endpoint
  - [ ] Verify cache operations working
  - [ ] Confirm no error logs

- [ ] **Step 5: Post-Incident**
  - [ ] Document root cause
  - [ ] Update this checklist if needed
  - [ ] Plan improvements for next attempt

### Critical Issues (Service down, data loss)

- [ ] **Immediate Actions**
  - [ ] Page on-call DBA and DevOps
  - [ ] Declare SEV-1 incident
  - [ ] Notify stakeholders of downtime

- [ ] **Emergency Rollback**
  - [ ] Full revert of commit
  - [ ] Redeploy previous working configuration
  - [ ] Verify all services operational

---

## Sign-Off & Documentation

- [ ] **Deployment Completed**
  - [ ] All environments deployed (INT → QA → STG → PRD)
  - [ ] All verifications passed
  - [ ] No critical issues identified

- [ ] **Documentation Updated**
  - [ ] This checklist marked complete
  - [ ] Any deviations documented
  - [ ] Lessons learned captured
  - [ ] Cost savings verified and documented

- [ ] **Team Notification**
  - [ ] Deployment completion announced
  - [ ] Performance metrics shared
  - [ ] Cost savings quantified
  - [ ] Team training scheduled (optional)

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| DevOps Lead | _________________ | ___/___/___ | _________________ |
| SRE/On-Call | _________________ | ___/___/___ | _________________ |
| Engineering Manager | _________________ | ___/___/___ | _________________ |

---

**Deployment Status:** ⏳ Pending  
**Started:** _____________  
**Completed:** _____________  
**Total Duration:** _____________ (estimated: 2-3 hours)  
**Incidents:** 0 / 0 (none)  

---

## Quick Reference

### Useful Commands

```bash
# View current Valkey status
terraform state show module.valkey

# Get Valkey endpoint
terraform output valkey_endpoint

# Get auth token
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/valkey/auth-token \
  --query 'SecretString' --output text

# Test Valkey connectivity
redis-cli -h <ENDPOINT> -p 6379 -a <PASSWORD> PING

# Monitor CloudWatch logs
aws logs tail /aws/elasticache/valkey/ecs-cluster-int --follow

# View alarms
aws cloudwatch describe-alarms \
  --alarm-names "ecs-cluster-int-valkey-cpu-high"
```

### Contact & Escalation

- **DevOps Team:** #devops-team  
- **On-Call:** Check PagerDuty schedule  
- **AWS Support:** Premium support case (if deployed in production)

---

**Version:** 1.0  
**Last Updated:** September 12, 2026  
**Review Period:** After each deployment phase
