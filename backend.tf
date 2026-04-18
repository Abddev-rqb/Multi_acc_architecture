# # This block connects your Terraform commands to the S3 Storage and DynamoDB Lock you created earlier, making it safe for team collaboration.

# # This is the Backend configuration. It moves the "map" of your infrastructure (the state file) from your local computer to the AWS Cloud.
# # If you work in a team or use a different laptop, you need a shared, central place to store the status of your project. If this file was only on your computer, no one else could update the cloud.
# # How:
# #   bucket: This is the physical S3 bucket where the file is stored.
# #   key: This is the specific folder path and filename (terraform.tfstate) inside that bucket.
# #   region: Tells Terraform which AWS data center to talk to.
# #   dynamodb_table: This enables State Locking. When you are making changes, Terraform "locks" this table so a teammate cannot try to change the same thing at the exact same time, preventing data corruption.
# #   encrypt: This ensures the file is scrambled while sitting in the bucket, keeping your sensitive infrastructure data private.

# terraform {
#   backend "s3" {
#     bucket         = "org-terraform-state-713463137829"
#     key            = "root/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }