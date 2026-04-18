##############################################
# SCP: DENY ROOT USAGE
# What it does: Completely blocks the Root User of any account from performing any action (Action = "*").
# Why? The Root user is a "super-user" that can’t be easily restricted by standard IAM policies. 
# This forces everyone to use IAM Roles, which are easier to track, audit, and limit.
##############################################
resource "aws_organizations_policy" "deny_root_usage" {

  provider = aws.management
  name     = "scp-deny-root-usage"
  type     = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootAccess"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
          }
        }
      }
    ]
  })
}

##############################################
# SCP: WORKLOAD GUARDRAILS (FIXED)
##############################################
resource "aws_organizations_policy" "workload_guardrails" {
  
  provider    = aws.management
  name        = "scp-workload-guardrails"
  description = "Combined guardrails for workload accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [

      ##################################
      # REGION RESTRICTION
      # Blocks the creation of resources in any AWS region not listed in your var.allowed_regions.
      ##################################
      {
        Sid    = "DenyUnapprovedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "s3:*",
          "route53:*",
          "cloudfront:*",
          "support:*",
          "organizations:*",
          "guardduty:*",
          "securityhub:*",
          "cloudtrail:*",
          "config:*",
          "logs:*",
          "sso:*",
          "sso-admin:*",
          "identitystore:*",
          "organizations:ListAccounts",
          "organizations:DescribeOrganization"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      },

      ##################################
      # CLOUDTRAIL PROTECTION
      # Makes it impossible for anyone to turn off your security logging or threat detection.
      ##################################
      {
        Sid    = "DenyCloudTrailDisable"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      },

      ##################################
      # GUARDDUTY PROTECTION
      ##################################
      {
        Sid    = "DenyGuardDutyDisable"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:StopMonitoringMembers"
        ]
        Resource = "*"
      },

      ##################################
      # IAM ESCALATION PROTECTION
      # Prevents users from "tricking" the system into giving them more power by creating new policy versions,
      # unless it's being done by a trusted AWS service.
      ##################################
      # {
      #   Sid    = "DenyEscalation"
      #   Effect = "Deny"
      #   Action = [
      #     "iam:CreatePolicyVersion",
      #     "iam:SetDefaultPolicyVersion"
      #   ]
      #   Resource = "*"
      #   Condition = {
      #     StringNotEqualsIfExists = {
      #       "aws:CalledVia" = [
      #         "config.amazonaws.com",
      #         "cloudtrail.amazonaws.com",
      #         "guardduty.amazonaws.com"
      #       ]
      #     }
      #   }
      # },

      ##################################
      # S3 ENCRYPTION ENFORCEMENT
      # A strict rule that prevents deleting objects if they aren't properly encrypted with KMS, 
      # encouraging a "secure-by-default" culture.
      ##################################
      {
        Sid      = "DenyUnEncryptedS3"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEqualsIfExists = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
            "aws:PrincipalService" = "s3.amazonaws.com"
          }
        }
      }
    ]
  })
}