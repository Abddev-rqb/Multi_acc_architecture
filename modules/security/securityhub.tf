##############################################

# SECURITY HUB - STABLE ORG SETUP
# Instead of logging into five different accounts to check for security vulnerabilities or 
# compliance issues (like unencrypted buckets), 
# the security team only has to look at one screen in the Security account to see the 
# health of the entire company.

##############################################

# Enable in Management Account
resource "aws_securityhub_account" "management" {
  provider = aws.management
}

# Enable in Security Account
resource "aws_securityhub_account" "security" {
  provider = aws.security
}

# Register Delegated Admin (from management)
# The Management account officially appoints the Security account as the "Admin". 
# This allows the Security account to see security data from all other accounts.
resource "aws_securityhub_organization_admin_account" "admin" {
  provider = aws.management

  admin_account_id = var.account_ids.security

  depends_on = [
    aws_securityhub_account.management,
    aws_securityhub_account.security
  ]
}

resource "time_sleep" "wait_for_securityhub" {
  depends_on = [
    aws_securityhub_finding_aggregator.org
  ]

  create_duration = "90s"
}

# Org Configuration 
#  The organization_configuration block ensures that any new accounts added to 
#  the organization in the future will have Security Hub turned on automatically
resource "aws_securityhub_organization_configuration" "org" {
  provider = aws.security

  auto_enable = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [
    aws_securityhub_organization_admin_account.admin,
    time_sleep.wait_for_securityhub

  ]
}

# Finding Aggregator (for visibility)
# The finding_aggregator acts like a funnel, 
# pulling in security alerts from every AWS region into one single view inside Security account.
resource "aws_securityhub_finding_aggregator" "org" {
  provider = aws.security

  linking_mode = "ALL_REGIONS"

  depends_on = [
    aws_securityhub_account.security,
    aws_securityhub_organization_admin_account.admin
  ]
}

# # The aws_securityhub_member block uses a loop (for_each) to automatically link existing dev, qa, and prod 
# # accounts to the central Security Hub dashboard without needing to send manual email invites.
# resource "aws_securityhub_member" "members" {
#   for_each = {
#     dev  = var.account_ids.dev
#     qa   = var.account_ids.qa
#     prod = var.account_ids.prod
#   }

#   provider = aws.security

#   account_id = each.value
#   email      = lookup(var.account_emails, each.key)

#   invite = false

#   depends_on = [
#     aws_securityhub_organization_configuration.org
#   ]
# }
