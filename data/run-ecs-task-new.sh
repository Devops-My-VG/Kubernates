#!/bin/sh

export AWS_PAGER=""
var_task_file="vars-ecs-task.json"
task_new_file="ecs-task-new.json"

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://task-ecs-role.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

AWS_ACC_ID=`aws sts get-caller-identity --query Account --output text`
echo $AWS_ACC_ID

sed -e "s/AWS_ACC_ID/$AWS_ACC_ID/g" $var_task_file > $task_new_file

#aws ecs register-task-definition --cli-input-json file://$task_new_file
aws ecs register-task-definition --cli-input-json file://ecs-task-new.json

aws ecs run-task \
  --cluster my-ecs-cluster \
  --launch-type EC2 \
  --task-definition httpd-task \
  --count 2
