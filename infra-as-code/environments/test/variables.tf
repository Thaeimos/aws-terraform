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

variable "environment" {
  type        = string
  description = "Environment where we are."
  default     = "no-environment"
}

variable "read_only_users" {
  type        = list
  description = "List of users to create with read only access."
}

variable "main_cidr_block" {
  type        = string
  description = "CIDR block of IPs for the VPC."
}

variable "frontend_name" {
  type        = string
  description = "Name for the application and related infrastructure that supports the frontend. This should be set up on the task file for the application."
}

variable "backend_name" {
  type        = string
  description = "Name for the application and related infrastructure that supports the backend. This should be set up on the task file for the application."
}