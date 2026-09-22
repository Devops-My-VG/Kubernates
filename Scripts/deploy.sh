#!/bin/bash

################################################################################
# ECS Cluster Infrastructure Deployment Script
# Purpose: Create/update ECS infrastructure with Valkey Serverless & S3 state
# Usage: ./deploy.sh [aws_profile] [environment] [action]
#        ./deploy.sh default int apply     # Deploy INT with default profile
#        ./deploy.sh prod int plan         # Preview INT changes with prod profile
#        ./deploy.sh staging int destroy   # Destroy INT with staging profile
# Parameters:
#   aws_profile: AWS profile to use (default: uses AWS_PROFILE env var or 'default')
#   environment: int, qa, stg, prd
#   action: plan, apply, destroy
# Examples:
#   ./deploy.sh                                  # Uses AWS_PROFILE env var, int env, apply action
#   ./deploy.sh myprofile                        # Uses myprofile, int env, apply action
#   ./deploy.sh myprofile qa                     # Uses myprofile, qa env, apply action
#   ./deploy.sh myprofile qa plan                # Uses myprofile, qa env, plan action
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# AWS Configuration
# Parse parameters: $1 = aws_profile, $2 = environment, $3 = action
AWS_PROFILE="${1:-${AWS_PROFILE:-default}}"
ENVIRONMENT="${2:-int}"
ACTION="${3:-apply}"

AWS_REGION="${AWS_REGION:-us-east-1}"
S3_BUCKET="bucket-s3-infra-devops"
STATE_KEY="${AWS_REGION:-ecs-cluster}"
PROJECT_NAME="ecs-cluster"

# Terraform Configuration
TF_VERSION="1.16.2"
TERRAFORM_DIR="${SCRIPT_DIR}"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ============================================================================
# VALIDATION
# ============================================================================

validate_inputs() {
    log_info "Validating inputs..."
    
    # Validate environment
    case "$ENVIRONMENT" in
        int|qa|stg|prd)
            log_success "Environment: $ENVIRONMENT"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            log_info "Valid environments: int, qa, stg, prd"
            exit 1
            ;;
    esac
    
    # Validate action
    case "$ACTION" in
        plan|apply|destroy)
            log_success "Action: $ACTION"
            ;;
        *)
            log_error "Invalid action: $ACTION"
            log_info "Valid actions: plan, apply, destroy"
            exit 1
            ;;
    esac
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
        log_error "AWS credentials not configured for profile: $AWS_PROFILE"
        exit 1
    fi
    log_success "AWS credentials verified"
    
    # Check S3 bucket exists
    if ! aws s3 ls "s3://$S3_BUCKET" --profile "$AWS_PROFILE" &>/dev/null; then
        log_error "S3 bucket not found: $S3_BUCKET"
        exit 1
    fi
    log_success "S3 bucket verified: $S3_BUCKET"
    
    # Check terraform variables file exists
    if [ ! -f "environments/${ENVIRONMENT}.tfvars" ]; then
        log_error "Environment variables file not found: environments/${ENVIRONMENT}.tfvars"
        exit 1
    fi
    log_success "Environment variables file found: environments/${ENVIRONMENT}.tfvars"
}

# ============================================================================
# TERRAFORM SETUP
# ============================================================================

setup_terraform() {
    log_info "Setting up Terraform..."
    
    # Detect OS and architecture
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    if [ "$OS" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then
            TF_OS="darwin_arm64"
        else
            TF_OS="darwin_amd64"
        fi
    else
        TF_OS="linux_amd64"
    fi
    
    log_info "Detected OS: $OS, Architecture: $ARCH"
    
    # Download Terraform if not exists
    if [ ! -f "terraform" ]; then
        log_info "Downloading Terraform ${TF_VERSION} for ${TF_OS}..."
        curl -fsSLo terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${TF_OS}.zip"
        unzip -q terraform.zip
        rm -f terraform.zip
        chmod +x terraform
        log_success "Terraform downloaded"
    fi
    
    # Verify Terraform version
    if INSTALLED_VERSION=$(terraform version | head -1 | sed 's/.*Terraform v//'); then
        log_info "Terraform version: $INSTALLED_VERSION"
    else
        log_info "Terraform installed"
    fi
}

# ============================================================================
# TERRAFORM INITIALIZATION WITH S3 BACKEND
# ============================================================================

init_terraform() {
    log_info "Initializing Terraform with S3 backend..."
    
    # Convert environment name to lowercase for state file path
    STATE_KEY="${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate"
    
    log_info "Backend configuration:"
    log_info "  S3 Bucket: $S3_BUCKET"
    log_info "  State Key: $STATE_KEY"
    log_info "  Region: $AWS_REGION"
    
    # Initialize with S3 backend
    terraform init \
        -backend-config="bucket=$S3_BUCKET" \
        -backend-config="key=$STATE_KEY" \
        -backend-config="region=$AWS_REGION" \
        -backend-config="encrypt=true" \
        -backend-config="skip_credentials_validation=false" \
        -backend-config="skip_metadata_api_check=false" \
        -backend=true \
        -upgrade
    
    log_success "Terraform initialized with S3 backend"
}

# ============================================================================
# TERRAFORM VALIDATION
# ============================================================================

validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    # Format check
    if terraform fmt -check -recursive . &>/dev/null; then
        log_success "Terraform format check passed"
    else
        log_warn "Terraform formatting issues found, attempting to fix..."
        terraform fmt -recursive .
        log_success "Terraform files formatted"
    fi
    
    # Syntax validation
    if terraform validate; then
        log_success "Terraform syntax validation passed"
    else
        log_error "Terraform validation failed"
        exit 1
    fi
}

# ============================================================================
# TERRAFORM PLAN
# ============================================================================

plan_terraform() {
    log_info "Running Terraform plan for $ENVIRONMENT environment..."
    
    PLAN_FILE="tfplan.${ENVIRONMENT}"
    
    terraform plan \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -out="$PLAN_FILE"
    
    log_success "Terraform plan completed"
    log_info "Plan saved to: $PLAN_FILE"
    
    # Show plan summary
    log_info "Plan summary:"
    terraform show -no-color "$PLAN_FILE" | tail -20
}

# ============================================================================
# TERRAFORM APPLY
# ============================================================================

apply_terraform() {
    log_info "Applying Terraform configuration for $ENVIRONMENT environment..."
    
    PLAN_FILE="tfplan.${ENVIRONMENT}"
    
    # Check if plan file exists from recent plan
    if [ ! -f "$PLAN_FILE" ]; then
        log_warn "Plan file not found, running plan first..."
        plan_terraform
    fi
    
    log_warn "About to apply changes to $ENVIRONMENT environment"
    log_info "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
    sleep 10
    
    if terraform apply -auto-approve "$PLAN_FILE"; then
        log_success "Terraform apply completed successfully"
        
        # Export outputs
        log_info "Exporting outputs..."
        terraform output -json > "outputs_${ENVIRONMENT}.json"
        log_success "Outputs saved to: outputs_${ENVIRONMENT}.json"
        
        # Display key outputs
        log_info "Key infrastructure endpoints:"
        if terraform output -raw vpc_id &>/dev/null; then
            echo "  VPC ID: $(terraform output -raw vpc_id)"
        fi
        if terraform output -raw rds_endpoint &>/dev/null; then
            echo "  RDS Endpoint: $(terraform output -raw rds_endpoint)"
        fi
        if terraform output -raw valkey_endpoint &>/dev/null; then
            echo "  Valkey Endpoint: $(terraform output -raw valkey_endpoint)"
        fi
        if terraform output -raw alb_dns_name &>/dev/null; then
            echo "  ALB DNS: $(terraform output -raw alb_dns_name)"
        fi
    else
        log_error "Terraform apply failed"
        exit 1
    fi
}

# ============================================================================
# TERRAFORM DESTROY
# ============================================================================

destroy_terraform() {
    log_warn "About to destroy $ENVIRONMENT environment resources!"
    log_warn "This action is IRREVERSIBLE and will delete ALL infrastructure"
    log_info "Enter 'yes' to confirm destruction (or anything else to cancel):"
    read -r CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    log_error "Destroying $ENVIRONMENT environment..."
    
    if terraform destroy \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -auto-approve; then
        log_success "Terraform destroy completed successfully"
        
        # Note: State file remains in S3 for potential recovery
        log_info "State file preserved in S3 for potential recovery"
    else
        log_error "Terraform destroy failed"
        exit 1
    fi
}

# ============================================================================
# STATE BACKUP
# ============================================================================

backup_state() {
    log_info "Backing up state file..."
    
    STATE_KEY="${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate"
    BACKUP_FILE="/tmp/terraform_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S).tfstate"
    
    aws s3 cp \
        "s3://$S3_BUCKET/$STATE_KEY" \
        "$BACKUP_FILE" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    log_success "State file backed up to: $BACKUP_FILE"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  ECS Cluster Infrastructure Deployment                         ║"
    echo "║  AWS Profile: $AWS_PROFILE                                      ║"
    echo "║  Environment: $ENVIRONMENT                                        ║"
    echo "║  Action: $ACTION                                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Validate inputs
    validate_inputs
    
    # Setup Terraform
    setup_terraform
    
    # Initialize Terraform with S3 backend
    init_terraform
    
    # Validate Terraform configuration
    validate_terraform
    
    # Backup state before operations
    if [ -f ".terraform/terraform.tfstate" ] || aws s3 ls "s3://$S3_BUCKET/${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate" --profile "$AWS_PROFILE" &>/dev/null; then
        backup_state
    fi
    
    # Execute action
    case "$ACTION" in
        plan)
            plan_terraform
            ;;
        apply)
            plan_terraform
            apply_terraform
            ;;
        destroy)
            destroy_terraform
            ;;
    esac
    
    echo ""
    log_success "Deployment script completed successfully"
    echo ""
}

# Run main function
main "$@"
