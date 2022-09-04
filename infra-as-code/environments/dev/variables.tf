
variable "s3_bucket" {
  description = "S3 bucket for terraform state."
  type        = string
}

variable "key" {
  description = "Prefix and routes for the terraform state"
  type        = string
}

variable "region" {
  description = "'Name' tag for S3 bucket with terraform state."
  type        = string
}

variable "dynamodb_table" {
  description = "DynamoDB table name for terraform lock."
  type        = string
}

variable "bucket_state_encryption" {
  type        = bool
  description = "Encryption enabled for the bucket that holds the state"
  default     = true
}