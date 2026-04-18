##############################################
# PERMISSION BOUNDARY (dev)
##############################################

resource "aws_iam_policy" "permission_boundary_dev" {
  provider = aws.dev

  name = "permission-boundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "iam:CreateUser",
        "iam:AttachUserPolicy",
        "iam:PutUserPolicy"
      ]
      Resource = "*"
    }]
  })
}

##############################################
# DEV ACCOUNT ROLES
##############################################

resource "aws_iam_role" "admin_dev" {
  provider = aws.dev
  name     = "AdminRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json

  permissions_boundary = aws_iam_policy.permission_boundary_dev.arn

  tags = {
    Environment = "dev"
    Role        = "Admin"
  }
}

resource "aws_iam_role_policy_attachment" "admin_dev_attach" {
  provider   = aws.dev
  role       = aws_iam_role.admin_dev.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "readonly_dev" {
  provider = aws.dev
  name     = "ReadOnlyRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json

  permissions_boundary = aws_iam_policy.permission_boundary_dev.arn

  tags = {
    Environment = "dev"
    Role        = "ReadOnly"
  }
}

resource "aws_iam_role_policy_attachment" "readonly_dev_attach" {
  provider   = aws.dev
  role       = aws_iam_role.readonly_dev.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "security_audit_dev" {
  provider = aws.dev
  name     = "SecurityAuditRole"

  assume_role_policy = data.aws_iam_policy_document.assume_security.json

  permissions_boundary = aws_iam_policy.permission_boundary_dev.arn

  tags = {
    Environment = "dev"
    Role        = "SecurityAudit"
  }
}

resource "aws_iam_role_policy_attachment" "security_audit_dev_attach" {
  provider   = aws.dev
  role       = aws_iam_role.security_audit_dev.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

##############################################
# PERMISSION BOUNDARY (qa)
##############################################

resource "aws_iam_policy" "permission_boundary_qa" {
  provider = aws.qa

  name = "permission-boundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "iam:CreateUser",
        "iam:AttachUserPolicy",
        "iam:PutUserPolicy"
      ]
      Resource = "*"
    }]
  })
}


##############################################
# QA ACCOUNT ROLES
##############################################

resource "aws_iam_role" "admin_qa" {
  provider = aws.qa
  name     = "AdminRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json
  permissions_boundary = aws_iam_policy.permission_boundary_qa.arn

  tags = {
    Environment = "qa"
    Role        = "Admin"
  }
}

resource "aws_iam_role_policy_attachment" "admin_qa_attach" {
  provider   = aws.qa
  role       = aws_iam_role.admin_qa.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "readonly_qa" {
  provider = aws.qa
  name     = "ReadOnlyRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json
  permissions_boundary = aws_iam_policy.permission_boundary_qa.arn

  tags = {
    Environment = "qa"
    Role        = "ReadOnly"
  }
}

resource "aws_iam_role_policy_attachment" "readonly_qa_attach" {
  provider   = aws.qa
  role       = aws_iam_role.readonly_qa.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "security_audit_qa" {
  provider = aws.qa
  name     = "SecurityAuditRole"

  assume_role_policy = data.aws_iam_policy_document.assume_security.json
  permissions_boundary = aws_iam_policy.permission_boundary_qa.arn

  tags = {
    Environment = "qa"
    Role        = "SecurityAudit"
  }
}

resource "aws_iam_role_policy_attachment" "security_audit_qa_attach" {
  provider   = aws.qa
  role       = aws_iam_role.security_audit_qa.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

##############################################
# PERMISSION BOUNDARY (prod)
##############################################

resource "aws_iam_policy" "permission_boundary_prod" {
  provider = aws.prod

  name = "permission-boundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "iam:CreateUser",
        "iam:AttachUserPolicy",
        "iam:PutUserPolicy"
      ]
      Resource = "*"
    }]
  })
}


##############################################
# PROD ACCOUNT ROLES
##############################################

resource "aws_iam_role" "admin_prod" {
  provider = aws.prod
  name     = "AdminRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json
  permissions_boundary = aws_iam_policy.permission_boundary_prod.arn

  tags = {
    Environment = "prod"
    Role        = "Admin"
  }
}

resource "aws_iam_role_policy_attachment" "admin_prod_attach" {
  provider   = aws.prod
  role       = aws_iam_role.admin_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "readonly_prod" {
  provider = aws.prod
  name     = "ReadOnlyRole"

  assume_role_policy = data.aws_iam_policy_document.assume_management.json
  permissions_boundary = aws_iam_policy.permission_boundary_prod.arn

  tags = {
    Environment = "prod"
    Role        = "ReadOnly"
  }
}

resource "aws_iam_role_policy_attachment" "readonly_prod_attach" {
  provider   = aws.prod
  role       = aws_iam_role.readonly_prod.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "security_audit_prod" {
  provider = aws.prod
  name     = "SecurityAuditRole"

  assume_role_policy = data.aws_iam_policy_document.assume_security.json
  permissions_boundary = aws_iam_policy.permission_boundary_prod.arn

  tags = {
    Environment = "prod"
    Role        = "SecurityAudit"
  }
}

resource "aws_iam_role_policy_attachment" "security_audit_prod_attach" {
  provider   = aws.prod
  role       = aws_iam_role.security_audit_prod.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

##############################################
# SHARED TRUST POLICIES
##############################################

data "aws_iam_policy_document" "assume_management" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "assume_security" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids.security}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}