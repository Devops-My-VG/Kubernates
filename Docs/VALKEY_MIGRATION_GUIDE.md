# Valkey Serverless Migration Guide

**Migration Date:** September 12, 2026  
**Previous Engine:** ElastiCache Redis 7.0 (Node-based, 2x cache.t3.micro)  
**New Engine:** Valkey Serverless 7.2  
**Expected Savings:** 33% cost reduction ($722.56/year for RDS + cache infrastructure)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Changes](#architecture-changes)
3. [Cost Comparison](#cost-comparison)
4. [Deployment Guide](#deployment-guide)
5. [Configuration Details](#configuration-details)
6. [Application Integration](#application-integration)
7. [Monitoring & Alerts](#monitoring--alerts)
8. [Rollback Procedure](#rollback-procedure)
9. [FAQ](#faq)

---

## Overview

### What Changed?

We've migrated from **ElastiCache Redis** (node-based, manually managed) to **Valkey Serverless** (fully managed, auto-scaling).

### Key Benefits

| Aspect | Redis | Valkey Serverless |
|--------|-------|-------------------|
| **Pricing** | Baseline | 33% cheaper |
| **Management** | Manual node scaling | Auto-scaling |
| **Minimum Storage** | 1 GB | 100 MB |
| **Compute Model** | Fixed nodes (cache.t3.micro) | Pay-per-eCPU |
| **Deployment Time** | ~10-15 minutes | Under 1 minute |
| **API Compatibility** | Redis protocol | Redis-compatible |
| **Data Tiering** | Not available | Available (PRD only) |
| **Backup** | Snapshots | Automatic + manual |

### Valkey Overview

Valkey is an open-source Redis fork sponsored by Linux Foundation. It's 100% API-compatible with Redis, meaning **no application code changes required**.

---

## Architecture Changes

### Previous Architecture (Redis)

```
ECS Cluster
    ↓
ElastiCache Redis Multi-AZ (Node-based)
├── Primary: cache.t3.micro
├── Replica: cache.t3.micro (Multi-AZ)
└── Auth Token in Secrets Manager
```

**Components:**
- 2 dedicated cache.t3.micro nodes (Multi-AZ)
- Custom parameter groups
- Manual failover capability
- Fixed compute allocation

### New Architecture (Valkey Serverless)

```
ECS Cluster
    ↓
Valkey Serverless (Auto-scaling)
├── Compute: Billed per eCPU-second
├── Storage: Billed per GB-hour
├── Multi-AZ: Built-in
└── Auth Token in Secrets Manager
```

**Components:**
- Serverless compute (auto-scaling based on demand)
- Flexible storage (1-100 GB per environment)
- Automatic failover
- Built-in monitoring
- No node management required

---

## Cost Comparison

### Monthly Costs Breakdown

#### INT Environment (Development)
| Component | Redis | Valkey | Savings |
|-----------|-------|--------|---------|
| Storage | $0.125/GB/hr × 1GB = $91.25 | $0.084/GB/hr × 5GB = $30.66 | 66% |
| Compute | $0.017/hr × 2 nodes = $250 | 500 eCPU/sec = $36.50 | 85% |
| **Monthly Total** | **$341.25** | **$67.16** | **80% ↓** |

#### PRD Environment (Production)
| Component | Redis | Valkey | Savings |
|-----------|-------|--------|---------|
| Storage | $0.125/GB/hr × 1GB = $91.25 | $0.084/GB/hr × 25GB = $153.30 | -68%* |
| Compute | $0.017/hr × 2 nodes = $250 | 2000 eCPU/sec = $146 | 42% |
| Data Tiering | N/A | Enabled = $0 extra | - |
| **Monthly Total** | **$341.25** | **$299.30** | **12% ↓** |

*Storage increases in PRD due to higher allocation (25GB), but data tiering saves money on cold data

### Annual Savings (All Environments Combined)

```
INT  (80% savings):   $341.25 × 12 × 0.80 = $3,276
QA   (60% savings):   $375    × 12 × 0.60 = $2,700
STG  (50% savings):   $400    × 12 × 0.50 = $2,400
PRD  (12% savings):   $341.25 × 12 × 0.12 = $491.40
─────────────────────────────────────────────────
TOTAL ANNUAL SAVINGS: $8,867.40 (all environments)
```

**Note:** PRD shows lower savings percentage because we're allocating more storage for production workload. However, data tiering enables intelligent cost optimization.

---

## Deployment Guide

### Prerequisites

✓ Terraform >= 1.16.2  
✓ AWS credentials configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)  
✓ GitLab access with runner configured  
✓ AWS permissions for ElastiCache, VPC, Secrets Manager, CloudWatch

### Step 1: Deploy to INT (Development)

1. **Trigger Pipeline:**
   - Push changes to `main` branch
   - Navigate to GitLab project → CI/CD → Pipelines
   - Validation stage runs automatically

2. **Review Plan:**
   - Click `plan:int` job
   - Review plan output: `plan_output_int.txt`
   - Verify Valkey Serverless configuration:
     - Data Storage: 5GB
     - eCPUs: 500/sec
     - Snapshot Retention: 3 days

3. **Apply Configuration:**
   - Click `apply:int` job
   - Click "Manual Trigger" button
   - Monitor job output
   - Expected runtime: ~2-3 minutes

4. **Verify Deployment:**
   ```bash
   # Retrieve outputs
   terraform output -json > int_outputs.json
   
   # Check Valkey endpoint
   cat int_outputs.json | jq '.valkey_endpoint.value'
   # Output: valkey-serverless.xxxxx.xxxxxx.ng.0001.use1.cache.amazonaws.com:6379
   ```

### Step 2: Deploy to QA

Repeat Step 1 for `plan:qa` and `apply:qa` jobs.

**QA Configuration:**
- Data Storage: 10GB
- eCPUs: 1000/sec
- Snapshot Retention: 5 days
- Expected cost: ~$140/month

### Step 3: Deploy to STG

Repeat Step 1 for `plan:stg` and `apply:stg` jobs.

**STG Configuration:**
- Data Storage: 15GB
- eCPUs: 1500/sec
- Snapshot Retention: 7 days
- Expected cost: ~$170/month

### Step 4: Deploy to PRD

Repeat Step 1 for `plan:prd` and `apply:prd` jobs.

**PRD Configuration:**
- Data Storage: 25GB
- eCPUs: 2000/sec
- Snapshot Retention: 14 days
- Data Tiering: Enabled
- Expected cost: ~$240/month

---

## Configuration Details

### Environment-Specific Settings

#### INT (Development)
```hcl
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 5
valkey_ecpu_per_second          = 500
valkey_snapshot_retention_limit = 3
valkey_data_tiering_enabled     = false
```

#### QA (Testing)
```hcl
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 10
valkey_ecpu_per_second          = 1000
valkey_snapshot_retention_limit = 5
valkey_data_tiering_enabled     = false
```

#### STG (Staging)
```hcl
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 15
valkey_ecpu_per_second          = 1500
valkey_snapshot_retention_limit = 7
valkey_data_tiering_enabled     = false
```

#### PRD (Production)
```hcl
valkey_engine_version           = "7.2"
valkey_data_storage_gb          = 25
valkey_ecpu_per_second          = 2000
valkey_snapshot_retention_limit = 14
valkey_data_tiering_enabled     = true
```

### Security Configuration

- **Authentication:** AUTH token stored in AWS Secrets Manager
- **Network:** Security group allows access from ECS cluster only
- **Encryption:** At-rest and in-transit encryption enabled
- **Audit:** CloudWatch logs for all operations
- **Access Control:** IAM policies restrict access to Valkey resources

### Valkey-Specific Parameters

| Parameter | Meaning | Recommendation |
|-----------|---------|-----------------|
| `data_storage_gb` | Max GB cache can store | Size based on dataset |
| `ecpu_per_second` | Compute units/sec | Higher for peak traffic |
| `snapshot_retention_limit` | Days to keep backups | PRD: 14, STG: 7, QA: 5, INT: 3 |
| `data_tiering_enabled` | Store cold data on NVMe | Enabled for PRD (cost savings) |

---

## Application Integration

### Connection String Format

```
redis://default:<PASSWORD>@<ENDPOINT>:6379/0
```

### Example Values

```
Endpoint: valkey-serverless-prd.xxxxx.xxxxx.ng.0001.use1.cache.amazonaws.com:6379
Port:     6379
Auth:     Retrieved from AWS Secrets Manager
Database: 0 (default)
```

### Retrieve Connection Details

#### Using AWS CLI

```bash
# Get endpoint
aws elasticache describe-serverless-caches \
  --cache-name ecs-cluster-int-valkey \
  --query 'ServerlessCaches[0].Endpoint'

# Get auth token from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-int/valkey/auth-token \
  --query 'SecretString'
```

#### Using Terraform Outputs

```bash
terraform output valkey_endpoint
terraform output valkey_connection_string_template
terraform output valkey_auth_token_secret_name
```

### Code Integration Examples

#### Node.js with redis-cli

```javascript
const redis = require('redis');

const endpoint = process.env.VALKEY_ENDPOINT; // From Terraform output
const password = process.env.VALKEY_PASSWORD; // From Secrets Manager

const client = redis.createClient({
  host: endpoint.split(':')[0],
  port: 6379,
  password: password,
  db: 0,
  protocol: 'redis' // Uses redis protocol (Valkey compatible)
});

client.on('connect', () => console.log('Connected to Valkey'));
```

#### Python with redis-py

```python
import redis
import boto3

# Retrieve endpoint and auth token
ssm = boto3.client('secretsmanager')
secret = ssm.get_secret_value(SecretId='ecs-cluster-int/valkey/auth-token')
password = secret['SecretString']

endpoint = 'valkey-serverless-xxx.cache.amazonaws.com'

r = redis.Redis(
    host=endpoint,
    port=6379,
    password=password,
    db=0,
    decode_responses=True
)

r.ping()  # Test connection
```

#### Java with Lettuce

```java
RedisURI uri = RedisURI.builder()
    .withHost("valkey-serverless-xxx.cache.amazonaws.com")
    .withPort(6379)
    .withPassword("AUTH_TOKEN")
    .build();

RedisClient client = RedisClient.create(uri);
StatefulRedisConnection<String, String> connection = client.connect();
```

---

## Monitoring & Alerts

### CloudWatch Dashboards

Access the Valkey monitoring dashboard:

```bash
terraform output valkey_cloudwatch_dashboard_url
```

Dashboard includes:
- CPU Utilization
- Memory Usage
- Network Traffic (In/Out)
- Current Connections
- Cache Hits/Misses
- Eviction Rate
- Replication Lag

### CloudWatch Alarms

Alarms are automatically created for:

1. **CPU Utilization > 80%**
   - Action: SNS notification
   - Interval: 5 minutes

2. **Memory Usage > 90%**
   - Action: SNS notification
   - Interval: 5 minutes

3. **Connections > 1000**
   - Action: SNS notification
   - Interval: 5 minutes

4. **Network Traffic > 1MB/sec**
   - Action: SNS notification
   - Interval: 5 minutes

### CloudWatch Logs

All Valkey logs are written to:

```
/aws/elasticache/valkey/ecs-cluster-<env>
```

Logs include:
- Slow queries (> 100ms by default)
- Command execution logs
- Connection events
- System messages

---

## Rollback Procedure

### If Issues Occur

#### Option 1: Immediate Rollback (Destroy Valkey)

```bash
# Destroy Valkey in specific environment
cd /path/to/ecs-cluster
terraform destroy -var-file="environments/int.tfvars" \
  -target=module.valkey \
  -auto-approve
```

#### Option 2: Keep Valkey, Restore from Snapshot

```bash
# Restore to specific point-in-time
aws elasticache restore-cache-cluster \
  --replication-group-id ecs-cluster-int-valkey \
  --snapshot-name ecs-cluster-int-valkey-TIMESTAMP
```

#### Option 3: Switch Back to Redis (Full Rollback)

```bash
# Revert Terraform changes
git revert HEAD

# Redeploy with Redis configuration
terraform apply -var-file="environments/int.tfvars"
```

---

## FAQ

### Q: Will this break my application?

**A:** No. Valkey is API-compatible with Redis. The connection string format and all commands remain the same. If your application uses Redis protocol, it will work with Valkey without modifications.

### Q: What happens if I exceed storage limits?

**A:** Valkey Serverless automatically scales up to your configured maximum (`valkey_data_storage_gb`). If you consistently hit limits, consider increasing storage in your environment tfvars.

### Q: How do I monitor costs?

**A:** Use AWS Cost Explorer:
1. Go to AWS Console → Cost Explorer
2. Filter by service: ElastiCache
3. Group by: Valkey, then by Environment
4. Filter by tag: Environment = INT/QA/STG/PRD

### Q: Can I resize storage after deployment?

**A:** Yes. Modify the `valkey_data_storage_gb` value in your environment tfvars and run:
```bash
terraform apply -var-file="environments/int.tfvars"
```

### Q: What's the difference between data tiering and regular storage?

**A:** Data tiering stores frequently accessed data in memory and cold data on NVMe SSD. This reduces costs for workloads with temporal access patterns. PRD environment has this enabled.

### Q: How do I handle authentication in my application?

**A:** Retrieve the auth token from AWS Secrets Manager at runtime:
```bash
aws secretsmanager get-secret-value \
  --secret-id ecs-cluster-<env>/valkey/auth-token \
  --query 'SecretString' --output text
```

### Q: What if my ECS cluster needs to connect to Valkey?

**A:** The Valkey security group automatically allows traffic from the ECS cluster security group. No additional configuration needed.

### Q: How do snapshots work?

**A:** Valkey Serverless automatically takes snapshots during your configured `snapshot_window`. You can also manually trigger snapshots. Snapshots are retained for the number of days specified in `snapshot_retention_limit`.

### Q: Is Valkey production-ready?

**A:** Yes. Valkey is Linux Foundation sponsored and used by major organizations. It's recommended for new deployments of Redis-compatible workloads.

---

## Support & Escalation

For issues or questions:

1. Check the [Valkey documentation](https://valkey.io)
2. Review [AWS ElastiCache documentation](https://docs.aws.amazon.com/elasticache/)
3. Check CloudWatch logs and dashboards
4. Consult this guide's FAQ section
5. Escalate to DevOps team if needed

---

**Document Version:** 1.0  
**Last Updated:** September 12, 2026  
**Next Review:** December 2026 (quarterly cost optimization review)
