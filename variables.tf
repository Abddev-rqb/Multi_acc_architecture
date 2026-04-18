variable "management_account_id" {
  default = "638453941520"
}

variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "organization_feature_set" {
  description = "AWS Organizations feature set"
  type        = string
  default     = "ALL"
}

variable "account_ids" {
  description = "AWS account IDs"
  type = object({
    log_archive = string
    security    = string
    dev         = string
    qa          = string
    prod        = string
    management  = string
  })
}

variable "account_emails" {
  description = "Emails for AWS accounts"
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

variable "alert_email" {
  description = "Email for security alerts"
  type        = string
}

