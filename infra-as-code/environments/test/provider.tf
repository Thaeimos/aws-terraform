terraform {
  required_version = "~> 1.1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

# The backend config variables come from a backend.tfvars file
terraform {
  backend "s3" {
  }
}

provider "aws" {
  region  = var.region

  default_tags {
    tags = {
      purpose       = var.name
      environment   = var.environment
    }
  }
}