# It ensures that you never have a "blind spot." Even if a developer creates a new testing account tomorrow, 
# this code ensures it is instantly protected and monitored by your central security team.

# 1. Enable GuardDuty in Security Account
# This turns on the "brain" of GuardDuty inside your Security Account 
# so it can start analyzing logs for malicious activity (like crypto-mining or unauthorized logins).
resource "aws_guardduty_detector" "security" {
  provider = aws.security
  enable   = true
}

# 2. Register Delegated Admin (MUST be from management account)
# This runs in the Management Account to officially designate the Security account as the "Boss." 
# It gives the Security account permission to manage GuardDuty for every other account in your fleet.
resource "aws_guardduty_organization_admin_account" "admin" {
  provider = aws.management

  admin_account_id = var.account_ids.security
}

# 3. Org Configuration (ONLY after admin is active)
# This tells the Security account to automatically enable GuardDuty for any current or 
# future accounts you add to the organization (auto_enable_organization_members = "ALL").
resource "aws_guardduty_organization_configuration" "org" {
  provider = aws.security

  detector_id = aws_guardduty_detector.security.id

  auto_enable_organization_members = "ALL"

  depends_on = [
    aws_guardduty_organization_admin_account.admin,
    aws_guardduty_detector.security
  ]
}

resource "aws_guardduty_detector_feature" "s3_logs" {
  provider    = aws.security
  detector_id = aws_guardduty_detector.security.id

  name   = "S3_DATA_EVENTS"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "eks" {
  provider    = aws.security
  detector_id = aws_guardduty_detector.security.id

  name   = "EKS_AUDIT_LOGS"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "runtime" {
  provider    = aws.security
  detector_id = aws_guardduty_detector.security.id

  name   = "RUNTIME_MONITORING"
  status = "ENABLED"
}

