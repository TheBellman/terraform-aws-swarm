# infrastructure

This projects sets up a VPC and subnet to place assets in at a later stage.

## Usage

 - use values from `bootstrap\backend` to update `backend.tf` if necessary
 - create  `terraform.tfvars` from `terraform.tfvars.template`
 - apply `terraform init` then `terraform apply`

On successful completion, information is reported that you may need to set up other assets:

```
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

subnet_cidr = 172.33.10.0/26
subnet_id = subnet-0dd94f6227827fe77
vpc_cidr = 172.33.0.0/16
vpc_id = vpc-084060e9759718d7d
```

## Teardown

To teardown the infrastructure, execute `terraform destroy`.

It is possible this will fail because the provisioning bucket is not empty. If that is the case, manually delete the bucket from the AWS console and re-run `terraform destroy`
