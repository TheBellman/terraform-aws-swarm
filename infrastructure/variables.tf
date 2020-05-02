# -----------------------------------------------------------------------------
# data lookups
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

data "aws_ami" "target_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20190110-x86_64-ebs"]
  }
}

# -----------------------------------------------------------------------------
# items not likely to change much
# -----------------------------------------------------------------------------

# 172.28.0.0 - 172.28.255.255
variable "vpc_cidr" {
  default = "172.28.0.0/16"
}

variable "tags" {
  type = "map"

  default = {
    "Owner"   = "robert"
    "Project" = "terraform-aws-swarm"
    "Client"  = "internal"
  }
}

variable "namespace" {
  description = "base name to use for putting resources in different namespaces"
  default     = "swarm"
}

variable "worker_count" {
  description = "number of swarm worker nodes to launch"
  default = 4
}

variable "sleep_seconds" {
  description = "number of seconds each worker waits to hope that the master is awake and configured"
  default = 180
}

variable "master_sleep_seconds" {
  description = "number of seconds the master will wait for the workers to sign up"
  default = 300
}

# -----------------------------------------------------------------------------
# variables to inject via terraform.tfvars or environment
# -----------------------------------------------------------------------------

variable "aws_account_id" {}
variable "aws_profile" {}
variable "aws_region" {}
