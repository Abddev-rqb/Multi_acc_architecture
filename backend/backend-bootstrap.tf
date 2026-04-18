
##############################################
# S3 BACKEND BUCKET (LOG ARCHIVE)
##############################################
# Creates the S3 bucket where Terraform state files will be stored
resource "aws_s3_bucket" "terraform_state" {
  provider = aws.log_archive
  # Names the bucket using the log archive account ID for uniqueness
  bucket = "org-terraform-state-${var.account_ids.log_archive}"
  # Allows Terraform to delete the bucket even if it contains files
  force_destroy = true
}

##############################################
# BLOCK PUBLIC ACCESS (MANDATORY)
##############################################
# Security layer: Ensures the bucket and its files can NEVER be accessed publicly
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################
# VERSIONING
##############################################
# Keeps a history of state files so you can recover from accidental deletions or errors
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

##############################################
# ENCRYPTION
##############################################
# Automatically encrypts all files uploaded to the bucket using AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##############################################
# BUCKET POLICY (ALLOW MANAGEMENT ACCOUNT)
##############################################
# Defines who can use this bucket (gives access to the Management account and local admins)
resource "aws_s3_bucket_policy" "tf_state_policy" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.management_account_id}:root",
            "arn:aws:iam::${var.account_ids.log_archive}:role/OrganizationAccountAccessRole"
          ]
        }
        # Standard permissions needed to read, write, and list Terraform state
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ]
  })
}

##############################################
# DYNAMODB LOCK TABLE (MANAGEMENT)
##############################################
# Creates a table to "lock" the state so two people can't run Terraform at once
resource "aws_dynamodb_table" "terraform_locks" {
  provider = aws.management

  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}