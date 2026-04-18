##############################################
# CENTRAL CONFIG BUCKET (LOG ARCHIVE)
##############################################

resource "aws_s3_bucket" "config_bucket" {
  provider = aws.log_archive

  bucket = "org-config-logs-${var.account_ids.log_archive}"

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "config_block" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "config_versioning" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.config_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

##############################################
# KMS KEY (FOR CONFIG - REQUIRED FOR SCP)
##############################################

resource "aws_kms_key" "config_key" {
  provider = aws.log_archive

  description             = "KMS key for AWS Config logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_ids.log_archive}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowConfigService"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_encryption" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.config_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

##############################################
# BUCKET POLICY
##############################################

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "config_role_dev" {
  provider = aws.dev

  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_dev" {
  provider   = aws.dev
  role       = aws_iam_role.config_role_dev.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role" "config_role_qa" {
  provider = aws.qa
  name     = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_qa" {
  provider   = aws.qa
  role       = aws_iam_role.config_role_qa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role" "config_role_prod" {
  provider = aws.prod
  name     = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_prod" {
  provider   = aws.prod
  role       = aws_iam_role.config_role_prod.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

##############################################
# DEV CONFIG
##############################################

resource "aws_config_configuration_recorder" "recorder_dev" {
  provider = aws.dev
  name     = "default"

  role_arn = aws_iam_role.config_role_dev.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel_dev" {
  provider = aws.dev
  name     = "default"

  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  s3_kms_key_arn = aws_kms_key.config_key.arn

    depends_on = [
      aws_config_configuration_recorder.recorder_dev
    ]
}

resource "aws_config_configuration_recorder_status" "status_dev" {
  provider   = aws.dev
  name       = aws_config_configuration_recorder.recorder_dev.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.channel_dev,
    aws_iam_role_policy_attachment.config_policy_dev
  ]
}

##############################################
# QA CONFIG
##############################################

resource "aws_config_configuration_recorder" "recorder_qa" {
  provider = aws.qa
  name     = "default"

  role_arn = aws_iam_role.config_role_qa.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel_qa" {
  provider = aws.qa
  name     = "default"

  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  s3_kms_key_arn = aws_kms_key.config_key.arn

    depends_on = [
      aws_config_configuration_recorder.recorder_qa
    ]
}

resource "aws_config_configuration_recorder_status" "status_qa" {
  provider   = aws.qa
  name       = aws_config_configuration_recorder.recorder_qa.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.channel_qa,
    aws_iam_role_policy_attachment.config_policy_qa
  ]
}

##############################################
# PROD CONFIG
##############################################

resource "aws_config_configuration_recorder" "recorder_prod" {
  provider = aws.prod
  name     = "default"

  role_arn = aws_iam_role.config_role_prod.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel_prod" {
  provider = aws.prod
  name     = "default"

  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  s3_kms_key_arn = aws_kms_key.config_key.arn

  depends_on = [
    aws_config_configuration_recorder.recorder_prod
  ]
}

resource "aws_config_configuration_recorder_status" "status_prod" {
  provider   = aws.prod
  name       = aws_config_configuration_recorder.recorder_prod.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.channel_prod,
    aws_iam_role_policy_attachment.config_policy_prod
  ]
}

##############################################
# AGGREGATOR (SECURITY ACCOUNT)
##############################################

resource "aws_config_configuration_aggregator" "org" {
  provider = aws.security

  name = "org-config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = "arn:aws:iam::${var.account_ids.security}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
  }

  depends_on = [
    aws_config_configuration_recorder_status.status_dev,
    aws_config_configuration_recorder_status.status_qa,
    aws_config_configuration_recorder_status.status_prod
  ]
}

resource "aws_iam_role_policy" "allow_passrole_dev" {
  provider = aws.dev

  role = "OrganizationAccountAccessRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "allow_passrole_prod" {
  provider = aws.prod

  role = "OrganizationAccountAccessRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "allow_passrole_qa" {
  provider = aws.qa

  role = "OrganizationAccountAccessRole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "*"
      }
    ]
  })
}