locals {
  project = "aws-org"

  common_tags = {
    Project     = local.project
    Environment = "organization"
    ManagedBy   = "terraform"
  }

  account_names = {
    log_archive = "log-archive"
    security    = "security"
    dev         = "dev"
    qa          = "qa"
    prod        = "prod"
  }

  scp_names = {
    deny_root = "deny-root-usage"
  }

  workload_accounts = {
    dev = {
      id    = var.account_ids.dev
      email = var.account_emails.dev
    }
    qa = {
      id    = var.account_ids.qa
      email = var.account_emails.qa
    }
    prod = {
      id    = var.account_ids.prod
      email = var.account_emails.prod
    }
  }
}
