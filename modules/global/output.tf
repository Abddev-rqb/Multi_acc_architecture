output "accounts" {
  value = {
    log_archive = aws_organizations_account.log_archive.id
    security    = aws_organizations_account.security.id
    dev         = aws_organizations_account.dev.id
    qa          = aws_organizations_account.qa.id
    prod        = aws_organizations_account.prod.id
  }
}