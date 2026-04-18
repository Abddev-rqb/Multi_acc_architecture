terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.management,
        aws.log_archive
      ]
    }
  }
}

variable "account_ids" {
  type = object({
    log_archive = string
    security    = string
    dev         = string
    qa          = string
    prod        = string
  })
}

variable "allowed_regions" {
  description = "Allowed AWS regions"
  type        = list(string)
  default     = ["ap-south-1", "us-east-1", "us-west-2"]
}