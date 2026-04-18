terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.security]
    }
  }
}

variable "alert_email" {
  description = "Email for SNS alerts"
  type        = string
}