<<<<<<< HEAD
# ECS-cluster



## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

## Add your files

* [Create](https://docs.gitlab.com/user/project/repository/web_editor/#create-a-file) or [upload](https://docs.gitlab.com/user/project/repository/web_editor/#upload-a-file) files
* [Add files using the command line](https://docs.gitlab.com/topics/git/add_files/#add-files-to-a-git-repository) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://gitlab.com/gitlablrn/kubernates/ecs-cluster.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

* [Set up project integrations](https://gitlab.com/gitlablrn/kubernates/ecs-cluster/-/settings/integrations)

## Collaborate with your team

* [Invite team members and collaborators](https://docs.gitlab.com/user/project/members/)
* [Create a new merge request](https://docs.gitlab.com/user/project/merge_requests/creating_merge_requests/)
* [Automatically close issues from merge requests](https://docs.gitlab.com/user/project/issues/managing_issues/#closing-issues-automatically)
* [Enable merge request approvals](https://docs.gitlab.com/user/project/merge_requests/approvals/)
* [Set auto-merge](https://docs.gitlab.com/user/project/merge_requests/auto_merge/)

## Test and Deploy

Use the built-in continuous integration in GitLab.

* [Get started with GitLab CI/CD](https://docs.gitlab.com/ci/quick_start/)
* [Analyze your code for known vulnerabilities with Static Application Security Testing (SAST)](https://docs.gitlab.com/user/application_security/sast/)
* [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/topics/autodevops/requirements/)
* [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/user/clusters/agent/)
* [Set up protected environments](https://docs.gitlab.com/ci/environments/protected_environments/)

***

# Editing this README

When you're ready to make this README your own, just edit this file and use the handy template below (or feel free to structure it however you want - this is just a starting point!). Thanks to [makeareadme.com](https://www.makeareadme.com/) for this template.

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
=======
# ECS Cluster Infrastructure - GitLab CI/CD Implementation

Professional Infrastructure-as-Code (IaC) repository for managing ECS cluster deployments across multiple environments using Terraform and GitLab CI/CD.

## 📋 Quick Links

- **[Full Implementation Guide](GITLAB_CICD_IMPLEMENTATION.md)** - Detailed markdown documentation
- **[HTML Documentation](GITLAB_CICD_IMPLEMENTATION.html)** - Professional styled documentation
- **[GitLab Runner Setup](GITLAB_RUNNER_SETUP.md)** - Runner installation & configuration
- **[CI/CD Pipeline Overview](CICD_PIPELINE.md)** - Pipeline architecture & execution

---

## 🎯 Overview

This repository contains Terraform infrastructure code for deploying and managing ECS clusters across four environments:

| Environment | Tier | Purpose | Instance Type | State File |
|------------|------|---------|---------------|-----------|
| **INT** | Development | Initial testing | t3.medium | `ecs-cluster/int/terraform.tfstate` |
| **QA** | Testing | Quality assurance | t3.medium | `ecs-cluster/qa/terraform.tfstate` |
| **STG** | Staging | Pre-production | t3.medium | `ecs-cluster/stg/terraform.tfstate` |
| **PRD** | Production | Production workload | t3.micro | `ecs-cluster/prd/terraform.tfstate` |

### Key Features

✅ **Multi-Environment Support** - INT, QA, STG, PRD with separate configurations  
✅ **4-Stage Pipeline** - Validate → Plan → Apply → Destroy  
✅ **Production Safety** - Manual approvals and separate PRD stage  
✅ **Centralized State** - S3 backend with Object Lock for consistency  
✅ **Dynamic Configuration** - Environment-specific tfvars  
✅ **Security First** - AWS credentials via CI/CD variables  
✅ **Infrastructure as Code** - Complete Terraform modules  

---

## 🏗️ Architecture

### Pipeline Structure

```
┌─────────────────────────────────────┐
│ GitLab Push to main branch          │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 1: VALIDATE (Automatic)       │
│ - Terraform format check            │
│ - Terraform validate                │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 2: PLAN (Automatic, Parallel) │
│ - plan:int   - plan:qa              │
│ - plan:stg   - plan:prd             │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 3: APPLY (Manual, Parallel)   │
│ - apply:int  - apply:qa             │
│ - apply:stg  - apply:prd            │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Stage 4: DESTROY (Manual, Parallel) │
│ - destroy:int - destroy:qa          │
│ - destroy:stg - destroy:prd         │
└─────────────────────────────────────┘
```

### Stages Definition

```yaml
stages:
  - validate    # Syntax validation and format checks
  - plan        # Terraform plan for all environments
  - apply       # Terraform apply (manual trigger)
  - destroy     # Terraform destroy (manual trigger)
```

---

## 🌍 Environments

### INT Environment (Development)
- **Terraform Variable**: `environment = "dev"`
- **Cluster Name**: `ecs-cluster-int`
- **Instance Type**: `t3.medium`
- **Min/Max Capacity**: 2-4 instances
- **Log Retention**: 7 days
- **Use**: Initial testing and development

**Configuration File**: `environments/int.tfvars`

### QA Environment (Testing)
- **Terraform Variable**: `environment = "staging"`
- **Cluster Name**: `ecs-cluster-qa`
- **Instance Type**: `t3.medium`
- **Min/Max Capacity**: 2-4 instances
- **Log Retention**: 14 days
- **Use**: Quality assurance and validation

**Configuration File**: `environments/qa.tfvars`

### STG Environment (Staging)
- **Terraform Variable**: `environment = "staging"`
- **Cluster Name**: `ecs-cluster-stg`
- **Instance Type**: `t3.medium`
- **Min/Max Capacity**: 2-4 instances
- **Log Retention**: 30 days
- **Use**: Pre-production testing

**Configuration File**: `environments/stg.tfvars`

### PRD Environment (Production)
- **Terraform Variable**: `environment = "prod"`
- **Cluster Name**: `ecs-cluster-prd`
- **Instance Type**: `t3.micro`
- **Min/Max Capacity**: 2-4 instances
- **Log Retention**: 90 days
- **Use**: Production workloads
- **Note**: Manual approval required for apply/destroy

**Configuration File**: `environments/prd.tfvars`

---

## 💾 Backend Configuration

### S3 Backend

All Terraform state files are stored in a centralized S3 bucket with security best practices:

**Bucket**: `bucket-s3-infra-devops`  
**Region**: `us-east-1`  
**Encryption**: AES-256 (Server-Side Encryption)  
**Versioning**: Enabled  
**Object Lock**: Enabled (use_lockfile=true)  

### State File Organization

```
s3://bucket-s3-infra-devops/
├── ecs-cluster/
│   ├── int/terraform.tfstate
│   ├── qa/terraform.tfstate
│   ├── stg/terraform.tfstate
│   └── prd/terraform.tfstate
└── ec2-infra-k8s/
    ├── int/terraform.tfstate
    ├── qa/terraform.tfstate
    ├── stg/terraform.tfstate
    └── prd/terraform.tfstate
```

### Backend Initialization

The pipeline dynamically initializes Terraform backend for each environment:

```bash
export TF_STATE_ENV="$(printf '%s' "${CI_ENVIRONMENT_NAME}" | tr '[:upper:]' '[:lower:]')"

terraform init \
  -backend-config="bucket=bucket-s3-infra-devops" \
  -backend-config="key=ecs-cluster/${TF_STATE_ENV}/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
```

---

## 🚀 Getting Started

### Prerequisites

- **Terraform** >= 1.16.2
- **AWS CLI** v2
- **Git**
- **Bash** shell
- **AWS Account** with appropriate permissions
- **GitLab Runner** (for CI/CD execution)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://gitlab.com/devops8004932/kubernetes/ecs-cluster.git
   cd ecs-cluster
   ```

2. **Verify configuration:**
   ```bash
   terraform fmt -check -recursive .
   terraform validate
   ```

3. **AWS Setup (One-time):**
   ```bash
   # Create S3 bucket
   aws s3api create-bucket \
     --bucket bucket-s3-infra-devops \
     --region us-east-1

   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket bucket-s3-infra-devops \
     --versioning-configuration Status=Enabled

   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket bucket-s3-infra-devops \
     --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
   ```

4. **Configure GitLab CI/CD Variables:**
   
   Go to: **GitLab → Project → Settings → CI/CD → Variables**
   
   Add the following variables:
   ```
   AWS_ACCESS_KEY_ID=AKIA...
   AWS_SECRET_ACCESS_KEY=wJal...
   AWS_DEFAULT_REGION=us-east-1
   ```

5. **Set Up GitLab Runner:**
   
   See [GITLAB_RUNNER_SETUP.md](GITLAB_RUNNER_SETUP.md) for detailed instructions.

---

## 📦 Repository Structure

```
ecs-cluster/
├── README.md                              # This file
├── GITLAB_CICD_IMPLEMENTATION.md          # Detailed implementation guide
├── GITLAB_CICD_IMPLEMENTATION.html        # HTML documentation
├── GITLAB_RUNNER_SETUP.md                 # Runner setup guide
├── CICD_PIPELINE.md                       # Pipeline overview
├── .gitlab-ci.yml                         # GitLab CI/CD pipeline configuration
├── .gitignore                             # Git ignore rules
├── backend.tf                             # Terraform backend configuration
├── main.tf                                # Main infrastructure code
├── outputs.tf                             # Output definitions
├── variables.tf                           # Variable definitions
├── environments/                          # Environment-specific variables
│   ├── int.tfvars                        # INT environment
│   ├── qa.tfvars                         # QA environment
│   ├── stg.tfvars                        # STG environment
│   └── prd.tfvars                        # PRD environment
└── modules/                               # Terraform modules
    ├── ecs/                              # ECS module
    ├── vpc/                              # VPC module
    ├── iam/                              # IAM module
    └── ...                               # Additional modules
```

---

## 🔄 Pipeline Execution

### Automatic Execution

The pipeline automatically triggers when code is pushed to the `main` branch:

1. **Validate Stage** - Automatic
   - Checks Terraform format
   - Validates syntax
   - Runs on all commits

2. **Plan Stage** - Automatic
   - Generates execution plans for all environments
   - Saves artifacts for apply stage
   - No infrastructure changes

### Manual Execution

Apply and destroy operations require manual approval:

3. **Apply Stage** - Manual (requires user click)
   - Executes Terraform changes
   - Creates/updates infrastructure
   - One environment at a time

4. **Destroy Stage** - Manual (requires explicit approval)
   - Tears down infrastructure
   - Typically used for INT environment cleanup
   - **Use with caution in PRD**

### Triggering Pipeline

#### Option 1: Push to main branch
```bash
git add .
git commit -m "Update infrastructure"
git push origin main
```

#### Option 2: Manual trigger in GitLab UI
1. Go to: **GitLab → Project → CI/CD → Pipelines**
2. Click: **"New Pipeline"**
3. Select Branch: **"main"**
4. Click: **"Create Pipeline"**

#### Option 3: Trigger specific job
1. Go to: **CI/CD → Pipelines → [Pipeline ID]**
2. Click: **"Play"** button next to job name
3. Confirm if prompted

### Monitoring Pipeline

**View pipeline status:**
- GitLab → Project → CI/CD → Pipelines
- Click pipeline to see all jobs
- Click job name to view logs
- Check artifacts in job details

---

## 🔐 Security

### Credentials Management

- AWS credentials stored in GitLab CI/CD Variables (encrypted)
- Never commit credentials to repository
- Rotate credentials regularly
- Use IAM users with least privilege

### State File Protection

- S3 backend with AES-256 encryption
- Object Lock enabled for consistency
- Versioning enabled for recovery
- Access logs available in S3

### Access Control

- Protected main branch (merge request reviews required)
- Only developers can trigger manual jobs
- Admin review for production changes
- All actions logged in GitLab and AWS

### Variables Validation

All Terraform variables include validation rules:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue 1: `CI_ENVIRONMENT_NAME is not set`

**Error:**
```
ERROR - CI_ENVIRONMENT_NAME is not set
```

**Cause:** Job doesn't have `environment:` block in `.gitlab-ci.yml`

**Solution:** Ensure job definition includes environment block:
```yaml
environment:
  name: INT
  deployment_tier: development
```

#### Issue 2: S3 State File Error (Double Slash)

**Error:**
```
Value must not contain "//"
```

**Cause:** Environment variable empty, resulting in `ecs-cluster//terraform.tfstate`

**Solution:** Check CI_ENVIRONMENT_NAME in job logs:
```bash
echo "CI_ENVIRONMENT_NAME=[$CI_ENVIRONMENT_NAME]"
echo "TF state key=[ecs-cluster/${TF_STATE_ENV}/terraform.tfstate]"
```

#### Issue 3: VPC Limit Exceeded

**Error:**
```
Error: creating EC2 VPC: operation error EC2: CreateVpc, ... VpcLimitExceeded
```

**Cause:** AWS account reached max VPCs (default 5 per region)

**Solution:**
1. Delete unused VPCs in AWS Console
2. Request AWS limit increase
3. Use Service Quotas console

#### Issue 4: Undeclared Variable Warning

**Error:**
```
Warning: Value for undeclared variable "aws_profile"
```

**Cause:** tfvars file has variable not declared in variables.tf

**Solution:** Remove from terraform.tfvars:
```diff
- aws_profile = "$AWS_PROFILE"
```

#### Issue 5: Terraform Lock Error

**Error:**
```
Error acquiring the state lock
```

**Cause:** Another pipeline/process has lock on state

**Solution:**
1. Wait for other job to complete
2. Or force unlock (use with caution):
   ```bash
   terraform force-unlock LOCK_ID
   ```

### Debugging Tips

1. **View detailed logs:**
   - GitLab → Pipeline → Click job → View logs
   - Look for `terraform init`, `terraform plan`, `terraform apply`

2. **Check S3 state files:**
   ```bash
   aws s3 ls s3://bucket-s3-infra-devops/ecs-cluster/
   ```

3. **Test locally:**
   ```bash
   terraform init -backend-config="bucket=bucket-s3-infra-devops" \
     -backend-config="key=ecs-cluster/int/terraform.tfstate" \
     -backend-config="region=us-east-1" \
     -backend-config="encrypt=true" \
     -backend-config="use_lockfile=true"
   terraform plan -var-file="environments/int.tfvars"
   ```

4. **Enable debug mode:**
   ```bash
   export TF_LOG=DEBUG
   terraform apply -var-file="environments/int.tfvars"
   ```

---

## ⭐ Best Practices

### Pipeline Management

- ✅ Protect main branch with merge request reviews
- ✅ Always progress through environments: INT → QA → STG → PRD
- ✅ Never skip environment stages
- ✅ Keep documentation updated
- ✅ Maintain deployment runbooks

### Terraform Development

- ✅ Format code: `terraform fmt -recursive .`
- ✅ Validate syntax: `terraform validate`
- ✅ Use descriptive variable names
- ✅ Add validation rules to variables
- ✅ Document all variables with descriptions

### State Management

- ✅ Never manually edit state files
- ✅ Always use remote state (S3)
- ✅ Keep state files encrypted
- ✅ Regular backups (S3 versioning)
- ✅ Lock state during apply operations

### Deployment Strategy

- ✅ Always run plan first and review output
- ✅ Test in INT environment before others
- ✅ Start with small changes to validate process
- ✅ Keep previous state versions for rollback
- ✅ Document all changes and decisions

### Team Workflow

- ✅ Require code review before merging
- ✅ Announce deployments to team
- ✅ Schedule maintenance windows
- ✅ Share lessons learned from issues
- ✅ Maintain knowledge base

---

## 📊 Job Configuration Details

### Validate Job

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

**Trigger:** Automatic on merge requests and main branch  
**Duration:** ~30-60 seconds  
**Purpose:** Syntax validation and format checks  

### Plan Jobs (INT, QA, STG, PRD)

**Trigger:** Automatic on main branch  
**Duration:** ~1-2 minutes per environment  
**Artifacts:** Plan files (expire in 7 days)  
**Purpose:** Generate execution plans without making changes  

### Apply Jobs (INT, QA, STG, PRD)

**Trigger:** Manual (requires user approval)  
**Duration:** ~2-5 minutes per environment  
**Dependencies:** Requires successful plan job  
**Purpose:** Execute Terraform changes  

### Destroy Jobs (INT, QA, STG, PRD)

**Trigger:** Manual (requires explicit approval)  
**Duration:** ~1-3 minutes per environment  
**Purpose:** Teardown infrastructure  
**Warning:** Use with extreme caution in PRD  

---

## 🔗 Related Repositories

- **[ec2-infra-k8s](https://gitlab.com/devops8004932/kubernetes/ec2-infra-k8s)** - EC2-based Kubernetes infrastructure

---

## 📚 Additional Resources

### Documentation
- [Full Implementation Guide](GITLAB_CICD_IMPLEMENTATION.md) - Comprehensive documentation
- [HTML Documentation](GITLAB_CICD_IMPLEMENTATION.html) - Styled HTML version
- [GitLab Runner Setup](GITLAB_RUNNER_SETUP.md) - Runner configuration
- [Pipeline Overview](CICD_PIPELINE.md) - Pipeline architecture

### External References
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

---

## 📝 Changelog

### Version 1.0 (2024-09-12)

**Initial Release:**
- ✅ 4-stage pipeline (validate, plan, apply, destroy)
- ✅ Multi-environment support (INT, QA, STG, PRD)
- ✅ S3 backend with Object Lock (use_lockfile=true)
- ✅ Dynamic state key generation (TF_STATE_ENV)
- ✅ Environment-specific tfvars
- ✅ AWS credentials via CI/CD variables
- ✅ Comprehensive documentation

**Recent Changes:**
- Fixed undeclared variable warning (removed aws_profile)
- Simplified pipeline structure (standard 4-stage pattern)
- Updated backend configuration (S3 Object Lock)
- Added complete documentation (Markdown + HTML)

---

## 👥 Support

For issues or questions:

1. Check [Troubleshooting](#-troubleshooting) section
2. Review [Full Implementation Guide](GITLAB_CICD_IMPLEMENTATION.md)
3. Check pipeline logs in GitLab
4. Contact DevOps team

---

## 📄 Document Metadata

| Property | Value |
|----------|-------|
| **Repository** | ecs-cluster |
| **Branch** | main |
| **Last Updated** | 2024-09-12 |
| **Terraform Version** | 1.16.2 |
| **AWS Region** | us-east-1 |
| **State Backend** | S3 (bucket-s3-infra-devops) |
| **Pipeline Stages** | 4 (validate, plan, apply, destroy) |
| **Environments** | 4 (INT, QA, STG, PRD) |
| **Maintainer** | DevOps Team |

---

## 📋 Release Notes

**Version 1.0** - September 12, 2024

This is the initial release of the ECS Cluster infrastructure repository with professional GitLab CI/CD pipeline implementation. The pipeline provides automated Terraform deployments across multiple environments with safety controls and best practices.

---

**Note:** This README is automatically updated whenever implementation changes occur. For detailed technical information, refer to [GITLAB_CICD_IMPLEMENTATION.md](GITLAB_CICD_IMPLEMENTATION.md).
>>>>>>> 1d1184e (adding code #1)
