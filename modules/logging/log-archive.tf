# This Terraform code sets up the secure storage vault for your organization’s audit logs.
# It creates and configures an S3 bucket in the log_archive account specifically to hold the CloudTrail data.


#  this is the "black box" recorder for your entire AWS infrastructure—hardened, encrypted, and restricted.

resource "aws_s3_bucket" "cloudtrail_logs" {
  provider = aws.log_archive

  bucket = "org-cloudtrail-logs-${var.account_ids.log_archive}"

  force_destroy = true
}

# aws_s3_bucket_versioning: Keeps a history of every version of a log file. This prevents accidental overwrites or deletions from being permanent.
resource "aws_s3_bucket_versioning" "versioning" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# aws_s3_bucket_server_side_encryption_configuration: Forces the bucket to use the KMS key you created earlier to encrypt every file stored inside.
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# aws_s3_bucket_public_access_block: The "fortress walls" around your log storage. It blocks any public access to the bucket, ensuring that your sensitive audit logs are not exposed to the internet.
resource "aws_s3_bucket_public_access_block" "block" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# aws_s3_bucket_policy: The "security guard" for the bucket. 
# it explicitly allows the CloudTrail service to check the bucket's status and write log files into it, while blocking unauthorized access.

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      }
    ]
  })
}

resource "aws_s3_bucket" "cloudtrail_logs_dr" {
  provider = aws.log_archive_us_west_2

  bucket = "org-cloudtrail-logs-dr-${var.account_ids.log_archive}"

  force_destroy = true
}

resource "aws_iam_role_policy" "replication_policy" {
  provider = aws.log_archive

  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # SOURCE BUCKET PERMISSIONS
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
      },

      # DESTINATION BUCKET PERMISSIONS
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.cloudtrail_logs_dr.arn}/*"
      },

      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.cloudtrail_key.arn,
          aws_kms_key.cloudtrail_key_dr.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "replication_role" {
  provider = aws.log_archive

  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_s3_bucket_versioning" "dr_versioning" {
  provider = aws.log_archive_us_west_2

  bucket = aws_s3_bucket.cloudtrail_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.log_archive

  bucket = aws_s3_bucket.cloudtrail_logs.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.cloudtrail_logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.cloudtrail_key_dr.arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.versioning,
    aws_s3_bucket_versioning.dr_versioning
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_encryption" {
  provider = aws.log_archive_us_west_2

  bucket = aws_s3_bucket.cloudtrail_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_key_dr.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "dr_bucket_policy" {
  provider = aws.log_archive_us_west_2

  bucket = aws_s3_bucket.cloudtrail_logs_dr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Allow replication role to write objects
      {
        Sid    = "AllowReplicationWrite"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:PutObject",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.cloudtrail_logs_dr.arn}/*"
      },

      # Allow replication role to read bucket metadata
      {
        Sid    = "AllowReplicationBucketAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.cloudtrail_logs_dr.arn
      }
    ]
  })
}