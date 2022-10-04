variable "region" {
  type        = string
  description = "Currently mono region. Region where to deploy."
  default     = "eu-west-2"
}

variable "name" {
  type        = string
  description = "Suffix name for all the entities to create."
  default     = "sre-challenge"
}

