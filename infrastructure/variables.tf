# -----------------------------------------------------------------------------
# data lookups
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

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
  default = "swarm"
}

# -----------------------------------------------------------------------------
# variables to inject via terraform.tfvars or environment
# -----------------------------------------------------------------------------

variable "aws_account_id" {}
variable "aws_profile" {}
variable "aws_region" {}
