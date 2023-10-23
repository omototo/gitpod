
data "aws_availability_zones" "available" {}

locals {
  name     = "demo-vpc"
  vpc_cidr = "10.0.0.0/16"
  region   = "eu-central-1"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Blueprint  = local.name
    GitHubRepo = "github.com/omototo/gitpod"
  }
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
  }

}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = module.vpc.public_route_table_ids

  tags = {
    Name = "S3 VPC Endpoint"
  }
}