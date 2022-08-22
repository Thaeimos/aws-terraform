module "dev-tfstate" {
  source = "../../../modules/terraform-state/"
  env = "dev"
  s3_bucket = "com.example.dev.terraform-asdasd"
  s3_bucket_name = "Dev Terraform State Store"
  dynamodb_table = "terraform_dev"
}
