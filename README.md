# ECS Cluster Infrastructure

> **Project:** Multi-environment ECS cluster deployment using Terraform + GitLab CI/CD  
> **Branch:** main | **Maintainer:** DevOps Team  
> **Last Updated:** 2026-09-23

---

## 📋 What This Project Does

This repository deploys and manages Amazon ECS clusters across **4 environments** (INT, QA, STG, PRD) using **Terraform** and **GitLab CI/CD**. It creates an ECS cluster backed by EC2 instances running Amazon Linux 2023 ECS-optimized AMIs, with Auto Scaling Groups, VPC networking, IAM roles, ECR repositories, RDS PostgreSQL, S3 storage, Valkey cache, CloudWatch logging, and Application Auto Scaling for ECS services.

---

## 🔑 AWS Keywords / Services Used

| Service | Usage in Project |
|---------|------------------|
| **Amazon ECS** | Cluster, services, task definitions, container orchestration |
| **EC2** | Container instances running the ECS-optimized AMI |
| **Auto Scaling (ASG)** | `aws_autoscaling_group` — scales EC2 instances based on CPU |
| **Launch Template** | `aws_launch_template` — defines EC2 instance config for ASG |
| **VPC** | `aws_vpc`, subnets (public/private), security groups, NAT Gateway |
| **IAM** | Instance roles, task execution roles, instance profiles, policies |
| **ECR** | Docker image repositories for app containers |
| **RDS (PostgreSQL)** | Managed relational database for the app |
| **S3** | Application storage bucket |
| **Valkey (Serverless Cache)** | Replaces ElastiCache Redis for caching layer |
| **CloudWatch** | Log groups (`/ecs/{cluster}`), CPU alarms, metrics |
| **Application Auto Scaling** | ECS service scaling (`DesiredCount`) based on CPU |
| **ELB / Target Group** | Load balancer for ECS service (via `aws_autoscaling_attachment`) |
| **Route 53 / DNS** | Not explicitly defined in modules (check VPC module) |
| **AWS CLI / SDK** | Used in pipeline for state verification |

---

## 🏗️ How It Works (Architecture)

### 1. ECS Cluster → EC2 Communication
- The **ECS Cluster** (`aws_ecs_cluster.main`) is created with a name like `ecs-cluster-int`.
- **EC2 instances** are launched via an **Auto Scaling Group (ASG)** using an **AWS Launch Template** (`aws_launch_template.ecs_lt`).
- The Launch Template uses an **Amazon Linux 2023 ECS-optimized AMI** (`amzn2-ami-ecs-hvm-*-x86_64-ebs`).
- **User Data** (`base64encode`) writes `ECS_CLUSTER={name}` to `/etc/ecs/ecs.config` so the instance joins the correct ECS cluster on boot.
- The instance also installs packages (`httpd`, `stress`, `git`, `telnet`, etc.) and enables EPEL.
- The instance is assigned an **IAM Instance Profile** (`ecs_instance_profile`) with the `AmazonEC2ContainerServiceforEC2Role` policy.

### 2. Auto Scaling Group (ASG) — Yes, Created
- **Resource:** `aws_autoscaling_group.ecs_asg`
- **Name:** `{cluster_name}-asg` (e.g., `ecs-cluster-int-asg`)
- **Config:** Uses the Launch Template (`$Latest` version) and deploys into `public_subnets`.
- **Min/Max/Desired:** Defined by variables (`min_size`, `max_size`, `desired_capacity`) — defaults from `modules/ecs/variables.tf`.
- **Tags:** Propagated at launch (`Name = {cluster_name}-ecs-asg`).
- **Scaling Policies:**
  - `scale_up` (SimpleScaling, +1 instance, cooldown 300s)
  - `scale_down` (SimpleScaling, -1 instance, cooldown 300s)
- **CloudWatch Alarms:**
  - `cpu_high` (threshold 60%, period 30s) → triggers scale up
  - `cpu_low` (threshold 10%, period 60s, 5 eval periods) → triggers scale down

### 3. ECS Service Auto Scaling (Application Auto Scaling)
- **Resource:** `aws_appautoscaling_target.ecs_service` (namespace `ecs`)
- **Target:** ECS service `httpd_service` within the cluster
- **Dimension:** `ecs:service:DesiredCount`
- **Scale-up policy:** StepScaling, +2 tasks when CPU > 80% (2 eval periods, 60s)
- **Scale-down policy:** StepScaling, -1 task when CPU < 30%
- **Min/Max:** Set by `ecs_min_capacity` / `ecs_max_capacity` variables

### 4. VPC & Networking
- **Module:** `modules/vpc`
- Creates VPC, public/private subnets, Internet Gateway, NAT Gateway (optional), route tables, security groups.
- The ECS ASG uses `public_subnets`; Valkey and RDS can use `private_subnets`.

### 5. IAM & Security
- **Instance Role:** `ecs_instance_role` — assumed by `ec2.amazonaws.com` and `ecs-tasks.amazonaws.com`
- **Task Execution Role:** Created in `modules/iam_tasks` for ECS tasks to pull from ECR
- **Instance Profile:** Links role to EC2 instances
- **Key Pair:** `aws_key_pair` for SSH access (optional)

### 6. Additional Resources Created
- **ECR:** `modules/ecr` — Docker registry for application images
- **RDS PostgreSQL:** `modules/rds` — managed DB with configurable class/storage/version
- **S3:** `modules/s3` — application storage bucket
- **Valkey:** `modules/valkey` — serverless cache (replaces Redis/ElastiCache)
- **CloudWatch Log Group:** `/ecs/{cluster_name}` with retention (7/14/30/90 days per env)

---

## 📁 Repository Structure (Updated)

```
ecs-cluster/
├── README.md                    # This file
├── .github/workflows/           # GitHub Actions (terraform.yml, etc.)
├── .gitlab-ci.yml               # GitLab CI/CD pipeline (4 stages)
├── main.tf                      # Root module: vpc + ecs + iam + ecr + rds + s3 + valkey + cloudwatch
├── variables.tf                 # All input variables with validation rules
├── outputs.tf                   # Outputs from root
├── backend.tf / backend-config.hcl # S3 backend config
├── provider.tf                  # AWS provider
├── environments/
│   ├── int.tfvars               # INT (dev) — t3.medium, 2-4 instances, 7-day logs
│   ├── qa.tfvars                # QA (staging) — t3.medium, 2-4 instances, 14-day logs
│   ├── stg.tfvars               # STG (staging) — t3.medium, 2-4 instances, 30-day logs
│   └── prd.tfvars               # PRD (prod) — t3.micro, 2-4 instances, 90-day logs
├── modules/
│   ├── ecs/                     # ECS cluster, ASG, Launch Template, IAM, scaling, CloudWatch
│   ├── vpc/                     # VPC, subnets, security groups, gateways
│   ├── iam/ / iam_tasks/        # IAM roles and policies
│   ├── ecr/                     # ECR repositories
│   ├── rds/                     # PostgreSQL database
│   ├── s3/                      # Storage bucket
│   ├── valkey/                  # Serverless cache
│   └── ...
└── Scripts/
    └── terraform / etc.
```

---

## ⚙️ Prerequisites (Before You Start)

1. **Terraform** >= 1.16.2 installed locally
2. **AWS CLI** v2 configured with credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION=us-east-1`)
3. **Git** + **Bash** shell
4. **AWS Account** with IAM user/role that can create VPCs, ECS, EC2, RDS, S3, ECR, IAM, CloudWatch
5. **S3 Bucket** `bucket-s3-infra-devops` (created, versioned, AES-256 encrypted, Object Lock enabled) — for remote state
6. **GitLab Runner** configured (if using GitLab CI) — see `GITLAB_RUNNER_SETUP.md`
7. **Amazon Linux 2023 ECS-optimized AMI** available (auto-discovered by `data.aws_ami.al2023_ecs_optimized`)
8. **SSH Key Pair** (optional, for `key_name`) — create via AWS EC2 console or `aws ec2 create-key-pair`

---

## 🚀 Pipeline / CI/CD (What Is Happening)

- **GitHub Actions** (`.github/workflows/terraform.yml`) and **GitLab CI** (`.gitlab-ci.yml`) run a 4-stage pipeline:
  1. **Validate** — `terraform fmt -check`, `terraform validate`
  2. **Plan** — Parallel plans for INT, QA, STG, PRD (auto)
  3. **Apply** — Manual approval, executes `terraform apply` (auto for INT/QA/STG, manual for PRD)
  4. **Destroy** — Manual, tears down resources (use cautiously in PRD)
- **State:** Stored in `s3://bucket-s3-infra-devops/ecs-cluster/{env}/terraform.tfstate` with `use_lockfile=true`
- **Backend Init:** Dynamic in pipeline using `CI_ENVIRONMENT_NAME`

---

## 🌍 Environments

| Env | Cluster Name | Instance | Min/Max | Log Retention | Tier |
|-----|-------------|----------|---------|---------------|------|
| INT | `ecs-cluster-int` | t3.medium | 2-4 | 7 days | Dev |
| QA | `ecs-cluster-qa` | t3.medium | 2-4 | 14 days | Testing |
| STG | `ecs-cluster-stg` | t3.medium | 2-4 | 30 days | Pre-prod |
| PRD | `ecs-cluster-prd` | t3.micro | 2-4 | 90 days | Production |

Note: `desired_capacity` is set per environment; ASG scales between `min_size` and `max_size`. ECS service scales between `ecs_min_capacity` and `ecs_max_capacity`.

---

## 🔒 Security Notes

- AWS secrets stored in **GitLab CI/CD Variables** or **GitHub Secrets** (never in repo)
- S3 backend uses AES-256 + versioning + Object Lock
- Main branch protected (merge requests required)
- Production apply requires manual approval
- IAM uses least-privilege policies and instance profiles

---

## 📄 Key AWS Resources Created (Summary)

- `aws_ecs_cluster.main`
- `aws_autoscaling_group.ecs_asg` (ASG with Launch Template)
- `aws_launch_template.ecs_lt`
- `aws_ecs_service.httpd_service`
- `aws_iam_role.ecs_instance_role`
- `aws_iam_instance_profile.ecs_instance_profile`
- `aws_cloudwatch_log_group.ecs_logs`
- `aws_appautoscaling_target.ecs_service`
- `aws_appautoscaling_policy.scale_up / scale_down`
- `aws_cloudwatch_metric_alarm.ecs_cpu_high / ecs_cpu_low`
- `aws_autoscaling_policy.scale_up / scale_down` (EC2 ASG)
- `aws_cloudwatch_metric_alarm.cpu_high / cpu_low` (EC2)
- VPC, Subnets, Security Groups, NAT Gateway (optional)
- ECR repo, RDS instance, S3 bucket, Valkey cluster

