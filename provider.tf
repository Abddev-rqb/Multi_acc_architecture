terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

##############################
# DEFAULT (management)
##############################
provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "management"
  region = var.region
}

##############################
# LOG ARCHIVE ACCOUNT
##############################
provider "aws" {
  alias  = "log_archive"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.log_archive}:role/OrganizationAccountAccessRole"
  }
}

##############################
# SECURITY ACCOUNT
##############################
provider "aws" {
  alias  = "security"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.security}:role/OrganizationAccountAccessRole"
  }
}

##############################
# WORKLOAD ACCOUNTS
##############################
provider "aws" {
  alias  = "dev"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.dev}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "qa"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.qa}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "prod"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.prod}:role/OrganizationAccountAccessRole"
  }
}