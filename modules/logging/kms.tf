##############################################
# SOURCE REGION KMS KEY (us-east-1)
##############################################

resource "aws_kms_key" "cloudtrail_key" {
  provider = aws.log_archive

  description             = "KMS key for CloudTrail logs (primary region)"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ROOT FULL ACCESS
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_ids.log_archive}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # CLOUDTRAIL ACCESS (WRITE LOGS)
      {
        Sid    = "AllowCloudTrail"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },

      # 🔥 CRITICAL: REPLICATION ROLE (SOURCE SIDE)
      {
        Sid    = "AllowReplicationRoleSource"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################################
# DR REGION KMS KEY (us-west-2)
##############################################

resource "aws_kms_key" "cloudtrail_key_dr" {
  provider = aws.log_archive_us_west_2

  description             = "KMS key for CloudTrail logs (DR region)"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ROOT FULL ACCESS
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_ids.log_archive}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # 🔥 CRITICAL: REPLICATION ROLE (DESTINATION SIDE)
      {
        Sid    = "AllowReplicationRoleDestination"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}