variable "region" {
  type        = string
  description = "Currently mono region. Region where to deploy."
  default     = "eu-west-1"
}

variable "name" {
  type        = string
  description = "Suffix name for all the entities to create."
  default     = "sre-challenge"
}

variable "read_only_users" {
  type        = list
  description = "List of users to create with read only access."
}

variable "main_cidr_block" {
  type        = string
  description = "CIDR block of IPs for the VPC."
}
