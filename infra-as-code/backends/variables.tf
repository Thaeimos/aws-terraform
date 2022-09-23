variable "environments" {
  description = "List of environments."
  type        = list
  nullable    = false
}

variable "s3_bucket_prefix" {
  description = "S3 bucket for terraform state."
  type        = string
}

variable "s3_bucket_name" {
  description = "'Name' tag for S3 bucket with terraform state."
  type        = string
}

variable "dynamodb_table" {
  description = "DynamoDB table name for terraform lock."
  type        = string
}

variable "bucket_sse_algorithm" {
  type        = string
  description = "Encryption algorithm to use on the S3 bucket. Currently only AES256 is supported"
  default     = "AES256"
}