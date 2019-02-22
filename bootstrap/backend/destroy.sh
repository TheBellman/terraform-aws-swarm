#!/bin/bash

cd `dirname $0`
[[ -s ./env.rc ]] && source ./env.rc

cd terraform
terraform init
terraform destroy
rm terraform.tfvars
cd ..
