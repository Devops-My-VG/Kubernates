# Backend Configuration Documentation
#
# This file is for reference only.
# Backend is configured via CLI arguments in .gitlab-ci.yml before_script.
#
# S3 Backend with State Locking:
#
#   terraform init \
#     -backend-config="bucket=bucket-s3-infra-devops" \
#     -backend-config="key=ecs-cluster/{int|qa|stg|prd}/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="encrypt=true" \
#     -backend-config="use_lockfile=true"
#
# State Files Per Environment:
#   • INT:  s3://bucket-s3-infra-devops/ecs-cluster/int/terraform.tfstate
#   • QA:   s3://bucket-s3-infra-devops/ecs-cluster/qa/terraform.tfstate
#   • STG:  s3://bucket-s3-infra-devops/ecs-cluster/stg/terraform.tfstate
#   • PRD:  s3://bucket-s3-infra-devops/ecs-cluster/prd/terraform.tfstate
#
# Backend Features:
#   • Encryption:    AES-256 (encrypt=true)
#   • State Locking: S3 Object Lock (use_lockfile=true)
#   • Versioning:    Recommended (enable in S3 bucket settings)



