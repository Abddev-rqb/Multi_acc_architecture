# This Terraform code creates a centralized audit trail for your entire AWS Organization.
# it’s the "security camera" system for your whole AWS footprint, managed from the main management account.
resource "aws_cloudtrail" "org_trail" {
  provider = aws.management

  name                          = "org-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket # Centralizes Storage: Sends all those logs to a single, secure S3 bucket (s3_bucket_name).
  is_organization_trail         = true                                 # Logs Everything: Captures API activity and events from all accounts in the organization (is_organization_trail = true).
  is_multi_region_trail         = true                                 # Global Coverage: Monitors activity across all AWS regions (is_multi_region_trail = true) and includes global services like IAM.
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn # Ensures Security: Encrypts the logs using a KMS key and enables log file validation to ensure the data hasn't been tampered with.
  include_global_service_events = true
  enable_logging = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy,
    aws_kms_key.cloudtrail_key
  ]
}