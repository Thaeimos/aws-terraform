
resource "aws_s3_bucket" "backend" {
  bucket    = "${var.s3_bucket_prefix}-${var.environment}-tfstate"

  tags = {
    Name        = "${var.s3_bucket_name}"
    Environment = "${var.environment}"
  }
  force_destroy = true

}

resource "aws_s3_bucket_acl" "backend" {
  bucket    = aws_s3_bucket.backend.id
  acl       = "private"
}

  resource "aws_s3_bucket_versioning" "backend" {
  bucket    = aws_s3_bucket.backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend" {
  bucket    = aws_s3_bucket.backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.bucket_sse_algorithm
    }
  }
}

resource "aws_dynamodb_table" "terraform" {
  name           = "${var.environment}-${var.dynamodb_table}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "local_file" "backend_file" {
  filename          = "../environments/${var.environment}/backend.tfvars"
  file_permission   = "0644"
  content           = <<-EOT
    bucket                = "${aws_s3_bucket.backend.bucket}"
    dynamodb_table        = "${aws_dynamodb_table.terraform.name}"
    encrypt               = true
    region                = "${var.region}"
  EOT
}

resource "local_file" "main_file" {
  filename          = "../environments/${var.environment}/main.tf"
  file_permission   = "0644"
  content           = <<-EOT
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
        Name = "$${var.name}"
      }
    }


  EOT
}

resource "local_file" "vars_file" {
  filename          = "../environments/${var.environment}/variables.tf"
  file_permission   = "0644"
  content           = <<-EOT
    variable "region" {
      type        = string
      description = "Currently mono region. Region where to deploy."
      default     = "${var.region}"
    }

    variable "name" {
      type        = string
      description = "Suffix name for all the entities to create."
      default     = "${var.s3_bucket_prefix}"
    }

  EOT
}