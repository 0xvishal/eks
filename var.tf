variable "aws_region" {
  description = "Region for the VPC"
  default = "ap-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "20.0.0.0/16"
}

variable "public_subnet_cidr1" {
  description = "CIDR for the public subnet"
  default = "20.0.128.0/19"
}

variable "public_subnet_cidr2" {
  description = "CIDR for the public subnet"
  default = "20.0.160.0/19"
}

variable "public_subnet_cidr3" {
  description = "CIDR for the public subnet"
  default = "20.0.192.0/19"
}

variable "public_subnet_cidr4" {
  description = "CIDR for the public subnet"
  default = "20.0.224.0/19"
}


variable "private_subnet_cidr1" {
  description = "CIDR for the private subnet"
  default = "20.0.0.0/19"
}

variable "private_subnet_cidr2" {
  description = "CIDR for the private subnet"
  default = "20.0.32.0/19"
}

variable "private_subnet_cidr3" {
  description = "CIDR for the private subnet"
  default = "20.0.64.0/19"
}

variable "private_subnet_cidr4" {
  description = "CIDR for the private subnet"
  default = "20.0.96.0/19"
}


variable "ami" {
  description = "AMI for EC2"
  # default = "ami-0036ab7a"
   default = "ami-0f9cf087c1f27d9b1"
}
