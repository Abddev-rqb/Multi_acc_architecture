terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.management]
    }
  }
}

variable "account_emails" {
  type = object({
    log_archive = string
    security    = string
    dev         = string
    qa          = string
    prod        = string
  })
}

variable "allowed_regions" {
  type = list(string)
}

variable "create" {
  type    = bool
  default = true
}