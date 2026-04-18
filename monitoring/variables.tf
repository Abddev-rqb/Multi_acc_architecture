terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "alert_email" {}
variable "env" {}

variable "alb_arn_suffix" {}
variable "asg_name" {}
variable "lambda_name" {}