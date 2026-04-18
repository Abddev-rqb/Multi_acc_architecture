terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.security]
    }
  }
}

variable "securityhub_rule_arn" {
  description = "ARN of the Security Hub findings rule to trigger the Lambda function"
  type        = string
}