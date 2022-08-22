# terraform-state

Terraform module to create the S3/DynamoDB backend to store the Terraform state and lock.
The state created by this tf should be stored in source control.

## Usage

Configure your AWS credentials.

    $ brew install awscli
    $ aws configure

Initialize the AWS provider with your preferred region.

    provider "aws" {
      region  = "us-west-2"
      version = "~> 0.1"
    }

Add the tfstate store resource.

    module "dev-tfstate" {
      source = "github.com/confluentinc/terraform-state"
      env = "dev"
      s3_bucket = "com.example.dev.terraform"
      s3_bucket_name = "Dev Terraform State Store"
      dynamodb_table = "terraform_dev"
    }

This should be used in a dedicated terraform workspace or environment. The
resulting `terraform.tfstate` should be stored in source control. As long as
you configured AWS credentials as above (not in the provider), then no secrets
will be stored in source control as part of your state.

You can now configure your Terraform environments to use this backend:

    terraform {
      backend "s3" {
        bucket         = "com.example.dev.terraform"
        key            = "terraform.tfstate"
        region         = "us-west-2"
        dynamodb_table = "terraform_dev"
      }
    }