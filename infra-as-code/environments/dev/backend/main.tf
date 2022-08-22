module "dev-tfstate" {
  source                  = "../../../modules/terraform-state/"
  env                     = var.env
  s3_bucket               = var.s3_bucket
  s3_bucket_name          = var.s3_bucket_name
  dynamodb_table          = var.dynamodb_table
  bucket_sse_algorithm    = var.bucket_sse_algorithm
}
