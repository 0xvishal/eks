module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "xyz"
  cidr = "${var.vpc_cidr}"

  azs             = ["ap-east-1a", "ap-east-1b", "ap-east-1c"]
  private_subnets = ["${var.public_subnet_cidr1}", "${var.public_subnet_cidr2}", "${var.public_subnet_cidr3}"]
  public_subnets  = ["${var.private_subnet_cidr1}", "${var.private_subnet_cidr2}", "${var.private_subnet_cidr3}"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "staging"
  }
}

