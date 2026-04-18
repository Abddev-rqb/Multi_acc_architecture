# This Terraform code is the "Master Switch" that officially turns on AWS Organizations for the entire environment.


resource "aws_organizations_organization" "org" {
  
  provider = aws.management
  # feature_set = "ALL": This enables all features, including consolidated billing and Service Control Policies (SCPs). 
  # This is required if we want to restrict what our sub-accounts (like dev or prod) are allowed to do.
  feature_set = "ALL"

  # aws_service_access_principals: This "invites" specific AWS services—like CloudTrail, GuardDuty, and SecurityHub—to work across the whole organization.
  # It allows them to automatically see and manage all sub-accounts from one place.
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com"
  ]

  # enabled_policy_types = ["SERVICE_CONTROL_POLICY"]: This turns on the ability to use SCPs, 
  # which are high-level guardrails used to block specific actions (like preventing anyone from deleting logs or launching expensive servers) across accounts.
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}