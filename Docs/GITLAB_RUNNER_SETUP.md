# GitLab Runner Setup Guide

## Issue: "no runners for the protected branch" or "no runners that match tags"

This guide explains how to set up GitLab Runner to execute the CI/CD pipeline.

## Overview

The CI/CD pipelines are configured to use standard **Ubuntu 22.04** Docker images without requiring specific tags. The pipeline handles all Terraform operations including downloading the Terraform binary.

## Prerequisites

1. GitLab project with admin access
2. Server or VM with Docker installed (optional, can use system GitLab Runner)
3. Network access to GitHub (to download Terraform binary)
4. AWS credentials configured locally

## Installation Options

### Option 1: Docker-based GitLab Runner (Recommended)

#### Step 1: Install GitLab Runner

```bash
# Install on Ubuntu/Debian
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Or install with Docker
docker run -d --name gitlab-runner --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest
```

#### Step 2: Register the Runner

```bash
# Register with GitLab
sudo gitlab-runner register \
  --url https://gitlab.com/ \
  --registration-token <YOUR_REGISTRATION_TOKEN> \
  --executor docker \
  --docker-image ubuntu:22.04 \
  --description "Terraform Runner" \
  --tag-list terraform,aws \
  --run-untagged true
```

**Key parameters:**
- `--executor docker`: Use Docker for job execution
- `--docker-image ubuntu:22.04`: Use Ubuntu 22.04 (includes curl, unzip)
- `--run-untagged true`: Run jobs without tags (important!)
- `--tag-list`: Optional tags for job filtering

#### Step 3: Verify Runner Registration

Go to **Project → Settings → CI/CD → Runners**

You should see your runner with a green checkmark.

### Option 2: System GitLab Runner (Alternative)

If running locally without Docker:

```bash
# Install system-wide
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Register
sudo gitlab-runner register \
  --url https://gitlab.com/ \
  --registration-token <YOUR_REGISTRATION_TOKEN> \
  --executor shell \
  --description "Terraform Runner Shell"
```

**Requirements for shell executor:**
- Terraform binary in PATH
- AWS CLI installed
- curl and unzip available

## Configuration Details

### runner-config.toml (Docker Executor)

Example configuration saved at `/etc/gitlab-runner/config.toml`:

```toml
[[runners]]
  name = "Terraform Runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker"
  run_untagged = true
  
  [runners.docker]
    image = "ubuntu:22.04"
    privileged = false
    volumes = ["/cache"]
    allowed_pull_policies = ["always", "if-not-present"]
```

### Debugging Runner Issues

```bash
# Check runner status
sudo gitlab-runner verify

# Start runner in debug mode
sudo gitlab-runner run --debug

# View runner logs
sudo systemctl status gitlab-runner
sudo journalctl -u gitlab-runner -f

# For Docker runner
docker logs -f gitlab-runner
```

## AWS Credentials Configuration

### Method 1: AWS Credentials File (Recommended)

In the job environment, AWS credentials must be accessible:

**On the runner host:**

```bash
# Create ~/.aws/credentials
[$AWS_PROFILE]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

[$AWS_PROFILE]
aws_access_key_id = AKIA...
aws_secret_access_key = ...

# Create ~/.aws/config
[profile $AWS_PROFILE]
region = us-east-1

[profile $AWS_PROFILE]
region = us-east-1
```

### Method 2: GitLab CI/CD Variables

In **Project → Settings → CI/CD → Variables**, set:

```
AWS_ACCESS_KEY_ID_INT = AKIA...
AWS_SECRET_ACCESS_KEY_INT = ...
AWS_ACCESS_KEY_ID_PRD = AKIA...
AWS_SECRET_ACCESS_KEY_PRD = ...
```

Then in `.gitlab-ci.yml`, export them:

```yaml
script:
  - export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_INT}
  - export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_INT}
```

## Troubleshooting

### Problem: "No runners for protected branch"

**Solution:**
1. Go to **Project → Settings → CI/CD → Runners**
2. Ensure runner has "Run untagged jobs" enabled
3. Ensure runner is NOT locked to specific branches

```bash
sudo gitlab-runner verify --delete  # Verify and reconfigure
```

### Problem: "Executor docker not found"

**Solution:**
- Ensure Docker is running: `docker ps`
- Verify runner configuration has `executor = docker`
- Reinstall runner: `sudo apt-get install --reinstall gitlab-runner`

### Problem: "Connection refused to Docker daemon"

**Solution:**
```bash
# Add gitlab-runner user to docker group
sudo usermod -aG docker gitlab-runner

# Restart runner
sudo systemctl restart gitlab-runner
```

### Problem: "Pipeline timeout"

**Solution:**
- Increase timeout in runner configuration
- Optimize Terraform operations
- Check network connectivity for downloading Terraform binary

### Problem: "terraform command not found"

**Solution:**
Pipeline automatically downloads Terraform in `before_script`. Ensure:
- curl is installed
- unzip is installed  
- Internet access available to releases.hashicorp.com
- Using Ubuntu 22.04 or compatible image

## Viewing Pipeline Status

1. Go to **Project → CI/CD → Pipelines**
2. Click on pipeline to see stages
3. Click on individual jobs to see logs
4. Each environment (INT, QA, STG, PRD) shows separately

## Manual Job Triggers

After plan completes successfully:

1. Navigate to pipeline
2. Find desired environment's `apply:env` job
3. Click play button (▶) to trigger
4. Monitor logs in real-time

## Security Best Practices

1. **Runner Isolation:**
   - Use separate runners for production
   - Run production jobs on dedicated hardware

2. **AWS Credentials:**
   - Use IAM roles when possible
   - Rotate credentials regularly
   - Don't commit credentials to repository

3. **State File Access:**
   - S3 bucket encryption enabled
   - DynamoDB locking prevents concurrent modifications
   - Versioning enabled for rollback capability

4. **CI/CD Variables:**
   - Mark sensitive variables as "Protected"
   - Mark as "Masked" to hide in logs

## Advanced: Multiple Runners

For large deployments, use multiple runners:

```bash
# Runner 1: Development
gitlab-runner register --executor docker --tag-list dev

# Runner 2: Production
gitlab-runner register --executor docker --tag-list prd
```

Then update `.gitlab-ci.yml`:

```yaml
plan:dev:
  tags:
    - dev

plan:prd:
  tags:
    - prd
```

## Maintenance

### Update GitLab Runner

```bash
sudo apt-get update
sudo apt-get upgrade gitlab-runner
sudo systemctl restart gitlab-runner
```

### View Runner Logs

```bash
# Docker based
docker logs gitlab-runner

# System based
sudo journalctl -u gitlab-runner -f
```

### Clean Up Old Jobs

```bash
sudo gitlab-runner cleanup
```

## Getting Help

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- Check runner logs: `gitlab-runner verify --debug`
