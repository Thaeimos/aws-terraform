terraform {
  required_version = "~> 1.1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# The backend config variables come from a backend.auto.tfvars file
terraform {
  backend "s3" {
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.name}"
  }
}


