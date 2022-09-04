terraform {
  required_version = "~> 1.1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = var.region
}

# The backend config variables come from a backend.tfvars file
# which is not in this repo
# Terraform init -backend-config=
terraform {
  backend "s3" {
  }
}
