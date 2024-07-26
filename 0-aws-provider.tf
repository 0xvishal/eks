provider "aws" {
  region = "ap-east-1"
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
    helm = {
      source  = "hashicorp/helm"
    }
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
