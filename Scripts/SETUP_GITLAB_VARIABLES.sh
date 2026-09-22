#!/bin/bash
# GitLab Variables Setup Script
# Requirements: curl, jq (for parsing), valid PAT token with 'api' scope
# Usage: GITLAB_TOKEN="glpat-xxxx" bash SETUP_GITLAB_VARIABLES.sh

set -e

if [ -z "$GITLAB_TOKEN" ]; then
    echo "❌ Error: GITLAB_TOKEN environment variable not set"
    echo "Usage: export GITLAB_TOKEN='glpat-xxxx' && bash $0"
    exit 1
fi

GITLAB_API="https://gitlab.com/api/v4"
PROJECT_ID="devops8004932%2Fkubernetes%2Fecs-cluster"
NAMESPACE="devops8004932/kubernetes/ecs-cluster"

echo "================================================================================"
echo "GitLab Variables Setup - $NAMESPACE"
echo "================================================================================"
echo ""

# Test authentication
echo "Testing authentication..."
auth_response=$(curl -s -w "\n%{http_code}" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API/user")
http_code=$(echo "$auth_response" | tail -1)
body=$(echo "$auth_response" | head -n-1)

if [ "$http_code" = "200" ]; then
    username=$(echo "$body" | jq -r '.username // "unknown"' 2>/dev/null || echo "unknown")
    echo "✅ Authenticated as: $username"
else
    echo "❌ Authentication failed (HTTP $http_code)"
    echo "Response: $body"
    exit 1
fi

echo ""

# Function to create/update variable
set_variable() {
    local key=$1
    local value=$2
    local masked=$3
    
    printf "%-45s " "Setting $key..."
    
    # Escape JSON values
    local json_value=$(echo -n "$value" | jq -Rs '.')
    
    # Try to create
    response=$(curl -s -w "\n%{http_code}" -X POST "$GITLAB_API/projects/$PROJECT_ID/variables" \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"key\":\"$key\",\"value\":$json_value,\"protected\":true,\"masked\":$masked}")
    
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "201" ]; then
        echo "✅ Created"
        return 0
    elif [ "$http_code" = "400" ]; then
        # Variable might already exist, try update
        response=$(curl -s -w "\n%{http_code}" -X PUT "$GITLAB_API/projects/$PROJECT_ID/variables/$key" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"key\":\"$key\",\"value\":$json_value,\"protected\":true,\"masked\":$masked}")
        
        http_code=$(echo "$response" | tail -1)
        body=$(echo "$response" | head -n-1)
        
        if [ "$http_code" = "200" ]; then
            echo "✅ Updated"
            return 0
        else
            echo "❌ HTTP $http_code"
            return 1
        fi
    else
        echo "❌ HTTP $http_code"
        if [ ! -z "$body" ]; then
            echo "   Response: $(echo "$body" | head -c 100)"
        fi
        return 1
    fi
}

# Set all variables (non-masked first)
echo "Setting variables..."
echo ""

set_variable "AWS_ACCOUNT_ID" "639140327478" "false"
set_variable "AWS_REGION" "us-east-1" "false"
set_variable "VPC_ID" "vpc-0301d6ba38834d6aa" "false"
set_variable "SUBNET_IDS" "subnet-05db786298e4e5df9,subnet-03e658a1a4fac1ff2" "false"
set_variable "SECURITY_GROUP_ID" "sg-04506e2e244ebc25a" "false"
set_variable "BACKEND_ECR_REGISTRY" "639140327478.dkr.ecr.us-east-1.amazonaws.com" "false"
set_variable "BACKEND_ECR_REPOSITORY" "ecs-cluster-int/backend" "false"
set_variable "FRONTEND_ECR_REGISTRY" "639140327478.dkr.ecr.us-east-1.amazonaws.com" "false"
set_variable "FRONTEND_ECR_REPOSITORY" "ecs-cluster-int/frontend" "false"
set_variable "DB_HOST" "ecs-cluster-int-postgres-db.c638ae4w03nm.us-east-1.rds.amazonaws.com" "false"
set_variable "DB_PORT" "5432" "false"
set_variable "DB_NAME" "ecommercedb" "false"
set_variable "DB_USERNAME" "postgres" "false"
set_variable "ECS_TASK_EXECUTION_ROLE_ARN" "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-execution-role" "false"
set_variable "ECS_TASK_ROLE_ARN" "arn:aws:iam::639140327478:role/ecs-cluster-int-ecs-task-role" "false"
set_variable "ENVIRONMENT" "int" "false"
set_variable "LOG_LEVEL" "info" "false"
set_variable "NODE_ENV" "production" "false"

echo ""
echo "Setting masked variables (secrets)..."
echo ""

set_variable "DB_PASSWORD" "8pzPwmSuuA8XDlXVqfhh3yDBXgFLkV0g" "true"
set_variable "JWT_SECRET" "e8Z3fZnRz/nm0qPRBmNWbIYY5RA6KaZAYEuSSvpWrEg=" "true"

echo ""
echo "================================================================================"
echo "✅ Setup Complete!"
echo "================================================================================"
echo ""
echo "Next steps:"
echo "1. Verify variables: https://gitlab.com/$NAMESPACE/-/settings/ci_cd"
echo "2. Push code: git push origin main"
echo "3. Monitor pipeline: https://gitlab.com/$NAMESPACE/-/pipelines"
echo ""
