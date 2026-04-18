# ##############################################
# # DATA: SSO INSTANCE
# ##############################################
# data "aws_ssoadmin_instances" "this" {
#   provider = aws.management
# }

# locals {
#   sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
#   identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
# }

# ##############################################
# # PERMISSION SET: ADMIN
# ##############################################

# resource "aws_ssoadmin_permission_set" "admin" {
#   enable_sso = false
#   provider = aws.management

#   name         = "AdminAccess"
#   instance_arn = local.sso_instance_arn
# }

# resource "aws_ssoadmin_managed_policy_attachment" "admin_attach" {
#   enable_sso = false
#   provider = aws.management

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.admin.arn

#   managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# ##############################################
# # PERMISSION SET: READONLY
# ##############################################

# resource "aws_ssoadmin_permission_set" "readonly" {
#   enable_sso = false
#   provider = aws.management

#   name         = "ReadOnlyAccess"
#   instance_arn = local.sso_instance_arn
# }

# resource "aws_ssoadmin_managed_policy_attachment" "readonly_attach" {
#   enable_sso = false
#   provider = aws.management

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.readonly.arn

#   managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
# }

# ##############################################
# # PERMISSION SET: SECURITY
# ##############################################

# resource "aws_ssoadmin_permission_set" "security" {
#   enable_sso = false
#   provider = aws.management

#   name         = "SecurityAudit"
#   instance_arn = local.sso_instance_arn
# }

# resource "aws_ssoadmin_managed_policy_attachment" "security_attach" {
#   enable_sso = false
#   provider = aws.management

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.security.arn

#   managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
# }

# ##############################################
# # GROUP (IDENTITY STORE)
# ##############################################

# resource "aws_identitystore_group" "dev_admins" {
#   enable_sso = false
#   provider = aws.management

#   identity_store_id = local.identity_store_id
#   display_name      = "DevAdmins"
# }

# ##############################################
# # ACCOUNT ASSIGNMENT (DEV ADMIN)
# ##############################################

# resource "aws_ssoadmin_account_assignment" "dev_admin" {
#   enable_sso = false
#   provider = aws.management

#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.admin.arn

#   principal_id   = aws_identitystore_group.dev_admins.group_id
#   principal_type = "GROUP"

#   target_id   = var.account_ids.dev
#   target_type = "AWS_ACCOUNT"
# }