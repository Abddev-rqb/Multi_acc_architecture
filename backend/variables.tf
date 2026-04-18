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

variable "management_account_id" {
  type = string
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