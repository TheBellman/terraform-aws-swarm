# backend
This directory contains scripts for creating and installing encryption keys, and for setting up an S3 bucket and dynamodb table for Terraform to store shared state in.

It is assumed that:
 - the AWS CLI is available (this was developed with 1.15.)
 - appropriate AWS credentials are available
 - terraform is available (this was developed with 0.11.11)
 - the scripts are being run on a unix account.

## Sets up
 - initial key pairs.
 - S3/Dynamodb storage for holding Terraform state for main platform scripts.

## To use
Copy the `env.rc.template` to `env.rc` and fill in the blanks. Be careful not to commit the actual `env.rc` to git!

Assuming that you have your profile setup correctly in `.aws` and that profile has appropriate (very broad) privileges, then just execute the `bootstrap.sh` script then jump into the console to verify it contains what you expect. Additionally some `.pem` files should be written into the data folder.

On a successful run, various useful ARNs and names are displayed - take note of these, you will need them for other parts of the solution:

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = arn:aws:s3:::terraform-state20190222125041734800000001
key_arn = arn:aws:kms:eu-west-2:889199313043:key/dcebdb94-dd79-4d33-b4f4-b00aee818b6d
project_tags = {
  Client = internal
  Owner = robert
  Project = aws-swarm
}
table_arn = arn:aws:dynamodb:eu-west-2:889199313043:table/terraform-state-lock
table_name = terraform-state-lock
```

## Teardown

Execute `destroy.sh` to tear down assets.

It is possible this will fail because the state bucket is not empty. If that is the case, manually delete the bucket from the AWS console and re-run `destroy.sh`
