variable "region" {
  description = "The region to deply the resources"
  type        = string
}

variable "zone" {
  description = "The zone to deploy the resources"
  type        = string
}

variable "server_port" {
  description = "The port where the HTTP server listens for requests"
  type        = string
  default     = "8080"
}