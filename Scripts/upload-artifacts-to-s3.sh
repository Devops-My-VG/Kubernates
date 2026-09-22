#!/bin/bash

# ============================================================================
# Upload Artifacts to S3 Script
# Purpose: Upload infrastructure artifacts to S3 for distribution
# Usage: ./scripts/upload-artifacts-to-s3.sh [environment] [s3-bucket]
# ============================================================================

set -e

# Configuration
ENVIRONMENT="${1:-INT}"
S3_BUCKET="${2:-bucket-s3-infra-devops}"
AWS_REGION="${3:-us-east-1}"
AWS_PROFILE="${4:-semalgo-01}"
ARTIFACTS_DIR="${5:-./artifacts}"
TIMESTAMP=$(date -u +%Y-%m-%d-%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "Upload Artifacts to S3"
echo "==========================================${NC}"
echo ""
echo "Environment: ${ENVIRONMENT}"
echo "S3 Bucket: ${S3_BUCKET}"
echo "AWS Region: ${AWS_REGION}"
echo "AWS Profile: ${AWS_PROFILE}"
echo "Artifacts Directory: ${ARTIFACTS_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Verify artifacts exist
if [ ! -d "${ARTIFACTS_DIR}" ]; then
  echo -e "${RED}❌ Artifacts directory not found: ${ARTIFACTS_DIR}${NC}"
  exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity --profile ${AWS_PROFILE} --region ${AWS_REGION} > /dev/null 2>&1; then
  echo -e "${RED}❌ AWS credentials failed. Check profile: ${AWS_PROFILE}${NC}"
  exit 1
fi

echo -e "${YELLOW}✓ AWS credentials verified${NC}"
echo ""

# S3 paths
S3_BASE_PATH="s3://${S3_BUCKET}/ecs-cluster/$(echo ${ENVIRONMENT} | tr '[:upper:]' '[:lower:]')"
S3_CURRENT_PATH="${S3_BASE_PATH}/artifacts/current"
S3_VERSIONED_PATH="${S3_BASE_PATH}/artifacts/v${TIMESTAMP}"

echo -e "${YELLOW}Uploading to S3 paths:${NC}"
echo "  Current: ${S3_CURRENT_PATH}"
echo "  Versioned: ${S3_VERSIONED_PATH}"
echo ""

# Step 1: Upload to versioned path
echo -e "${YELLOW}[1/3] Uploading to versioned path...${NC}"

for file in "${ARTIFACTS_DIR}"/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "  → Uploading: ${filename}"
    aws s3 cp "$file" "${S3_VERSIONED_PATH}/${filename}" \
      --profile ${AWS_PROFILE} \
      --region ${AWS_REGION} \
      --sse AES256 \
      --metadata "Environment=${ENVIRONMENT},Timestamp=${TIMESTAMP}" \
      --quiet
  fi
done

echo -e "${GREEN}✓ Versioned artifacts uploaded${NC}"
echo ""

# Step 2: Upload to current path (latest)
echo -e "${YELLOW}[2/3] Uploading to current path (latest)...${NC}"

for file in "${ARTIFACTS_DIR}"/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    echo "  → Uploading: ${filename}"
    aws s3 cp "$file" "${S3_CURRENT_PATH}/${filename}" \
      --profile ${AWS_PROFILE} \
      --region ${AWS_REGION} \
      --sse AES256 \
      --metadata "Environment=${ENVIRONMENT},Timestamp=${TIMESTAMP},Latest=true" \
      --quiet
  fi
done

echo -e "${GREEN}✓ Current artifacts uploaded${NC}"
echo ""

# Step 3: Verify uploads
echo -e "${YELLOW}[3/3] Verifying uploads...${NC}"

echo -e "${YELLOW}Versioned artifacts:${NC}"
aws s3 ls "${S3_VERSIONED_PATH}/" \
  --profile ${AWS_PROFILE} \
  --region ${AWS_REGION} \
  --human-readable \
  --summarize

echo ""
echo -e "${YELLOW}Current artifacts:${NC}"
aws s3 ls "${S3_CURRENT_PATH}/" \
  --profile ${AWS_PROFILE} \
  --region ${AWS_REGION} \
  --human-readable \
  --summarize

echo ""
echo -e "${GREEN}✅ All artifacts uploaded successfully!${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  Versioned Path: ${S3_VERSIONED_PATH}"
echo "  Current Path: ${S3_CURRENT_PATH}"
echo "  Access URL (current): https://s3.console.aws.amazon.com/s3/buckets/${S3_BUCKET}?prefix=${S3_CURRENT_PATH#s3://*//}"
echo ""
