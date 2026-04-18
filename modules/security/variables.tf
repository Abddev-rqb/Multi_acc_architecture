terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.management,
        aws.security,
        aws.dev,
        aws.qa,
        aws.prod,
        aws.log_archive
      ]
    }
  }
}

variable "account_emails" {
  description = "Map of account names to email addresses for AWS account registration"
  type = object({
    log_archive = string
    security    = string
    dev         = string
    qa          = string
    prod        = string
  })
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

variable "management_account_id" {
  type = string
}

variable "enable_sso" {
  description = "Enable AWS SSO (true/false)"
  type        = bool
  default     = false
}