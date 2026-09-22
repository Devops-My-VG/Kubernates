#!/bin/sh

echo "Running cleanup.sh to remove some reources using AWS CLI"

./cleanup.sh

sleep 30

echo "Running terraform destroy, destroy stage in pipeline"

terraform destroy --auto-approve


