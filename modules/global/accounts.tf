# This Terraform code automates the creation of multiple AWS accounts within an AWS Organization. 
# It organizes them into a structured hierarchy based on their purpose:
# Security Accounts: Creates the log_archive and security accounts under a "Security" Organizational Unit (OU).
# Workload Accounts: Creates the dev, qa, and prod accounts under a "Workloads" OU.
# By using this code, we're implementing a multi-account strategy, which helps isolate environments, improve security, and 
# manage billing centrally rather than running everything in a single AWS account.

resource "aws_organizations_account" "log_archive" {
  
  provider  = aws.management
  name      = local.account_names.log_archive
  email     = var.account_emails.log_archive
  parent_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_account" "security" {
  
  provider  = aws.management
  name      = local.account_names.security
  email     = var.account_emails.security
  parent_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_account" "dev" {
  
  provider  = aws.management
  name      = local.account_names.dev
  email     = var.account_emails.dev
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_account" "qa" {
  
  provider  = aws.management
  name      = local.account_names.qa
  email     = var.account_emails.qa
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_account" "prod" {
  
  provider  = aws.management
  name      = local.account_names.prod
  email     = var.account_emails.prod
  parent_id = aws_organizations_organizational_unit.workloads.id
}