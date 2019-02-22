#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc

echo "======== setting up terraform back end ========"
cat <<EOF > terraform/terraform.tfvars
aws_region="$AWS_DEFAULT_REGION"
aws_profile="$AWS_PROFILE"
aws_account_id="$AWS_ACCOUNT_ID"
EOF

cd terraform
terraform init
terraform apply
