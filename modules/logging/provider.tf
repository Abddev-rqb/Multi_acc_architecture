provider "aws" {
  alias  = "log_archive_us_west_2"
  region = var.allowed_regions[2]

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids.log_archive}:role/OrganizationAccountAccessRole"
  }
}