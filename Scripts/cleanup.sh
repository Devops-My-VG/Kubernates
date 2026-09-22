#!/bin/bash

export AWS_PAGER=""

# ===== CONFIGURATION =====
REGION="us-east-1"
CLUSTER_NAME="my-ecs-cluster"
ASG_NAME="${CLUSTER_NAME}-asg"
LAUNCH_TEMPLATE_NAME="${CLUSTER_NAME}-lt"
VPC_NAME_TAG="${CLUSTER_NAME}-vpc"
PROFILE="--profile default"

echo "🚨 WARNING: This script will DELETE your ECS cluster, EC2 instances, ASG, ALB, and VPC. Proceeding in 5 seconds..."
sleep 5

# ===== 1. Delete ECS Services =====
echo "🧹 Deleting ECS Services..."
SERVICE_ARNS=$(aws ecs list-services --cluster $CLUSTER_NAME $PROFILE --region $REGION --query "serviceArns[]" --output text)
for SERVICE_ARN in $SERVICE_ARNS; do
  aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_ARN --desired-count 0 $PROFILE --region $REGION
  aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_ARN --force $PROFILE --region $REGION
done

# ===== 2. Deregister ECS Task Definitions (optional) =====
echo "🧹 Deregistering ECS Task Definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --status ACTIVE $PROFILE --region $REGION --query 'taskDefinitionArns' --output text)
for TD in $TASK_DEFS; do
  aws ecs deregister-task-definition --task-definition $TD $PROFILE --region $REGION
done

# ===== 3. Delete ECS Cluster =====
echo "🧹 Deleting ECS Cluster..."
aws ecs delete-cluster --cluster $CLUSTER_NAME $PROFILE --region $REGION

# ===== 4. Delete Auto Scaling Group =====
echo "🧹 Deleting Auto Scaling Group..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0 --max-size 0 --desired-capacity 0 $PROFILE --region $REGION
sleep 5
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME --force-delete $PROFILE --region $REGION

# ===== 5. Delete Launch Template =====
echo "🧹 Deleting Launch Template..."
aws ec2 delete-launch-template --launch-template-name $LAUNCH_TEMPLATE_NAME $PROFILE --region $REGION

# ===== 6. Get VPC ID =====
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME_TAG" $PROFILE --region $REGION --query "Vpcs[0].VpcId" --output text)
echo "ℹ️ VPC ID: $VPC_ID"

# ===== 7. Delete Target Groups =====
echo "🧹 Deleting Target Groups..."
TG_ARNs=$(aws elbv2 describe-target-groups --region $REGION $PROFILE --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text)
for TG in $TG_ARNs; do
  aws elbv2 delete-target-group --target-group-arn $TG $PROFILE --region $REGION
done

# ===== 8. Delete ALB and Listeners =====
echo "🧹 Deleting ALBs and Listeners..."
ALB_ARNs=$(aws elbv2 describe-load-balancers --region $REGION $PROFILE --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
for ALB in $ALB_ARNs; do
  LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn $ALB $PROFILE --region $REGION --query "Listeners[].ListenerArn" --output text)
  for L in $LISTENERS; do
    aws elbv2 delete-listener --listener-arn $L $PROFILE --region $REGION
  done
  aws elbv2 delete-load-balancer --load-balancer-arn $ALB $PROFILE --region $REGION
done

# ===== 9. Delete Security Groups =====
echo "🧹 Deleting Security Groups (except default)..."
SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" $PROFILE --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
for SG in $SG_IDS; do
  aws ec2 delete-security-group --group-id $SG $PROFILE --region $REGION
done

# ===== 10. Delete Subnets =====
echo "🧹 Deleting Subnets..."
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" $PROFILE --region $REGION --query 'Subnets[].SubnetId' --output text)
for SUBNET in $SUBNETS; do
  aws ec2 delete-subnet --subnet-id $SUBNET $PROFILE --region $REGION
done

# ===== 11. Detach & Delete Internet Gateway =====
echo "🧹 Detaching and Deleting Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" $PROFILE --region $REGION --query 'InternetGateways[0].InternetGatewayId' --output text)
if [ "$IGW_ID" != "None" ]; then
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID $PROFILE --region $REGION
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID $PROFILE --region $REGION
else
  echo "No IGW attached to $VPC_ID"
fi

# ===== 12. Delete Route Tables (non-main) =====
echo "🧹 Deleting Custom Route Tables..."
RTB_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" $PROFILE --region $REGION --query 'RouteTables[?Associations[?Main==`false`]].RouteTableId' --output text)
for RTB in $RTB_IDS; do
  aws ec2 delete-route-table --route-table-id $RTB $PROFILE --region $REGION
done

# ===== 13. Delete the VPC =====
echo "🧹 Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID $PROFILE --region $REGION

echo "✅ Cleanup complete. ECS, EC2, ASG, ALB, IGW, and VPC have been deleted."
