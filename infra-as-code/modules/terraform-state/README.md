# terraform-state

Terraform module to create the S3/DynamoDB backend to store the Terraform state and lock.
It will automatically create an .auto.tfvars file so you can use it later in your environment

## Usage

Start up the [utilities](../../../utilities/docker-image-bins/) docker image (which has already a section to properly configure your secrets), create an environment and then fill up the details needed by the module:

```bash
module "dev-tfstate" {
  source               = "../../../modules/terraform-state/"
  env                  = var.env
  s3_bucket            = var.s3_bucket
  s3_bucket_name       = var.s3_bucket_name
  dynamodb_table       = var.dynamodb_table
  bucket_sse_algorithm = var.bucket_sse_algorithm
}
```

We favour the usage of ".tfvars" files and it's reflected in the examples.

After you are done with this, issue the following command:

```bash
terraform init -backend-config=backend.conf.secret
```


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
