# Terraform version
terraform {
  required_version = ">= 5.80.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 5.80.0"
    }
  }
}
