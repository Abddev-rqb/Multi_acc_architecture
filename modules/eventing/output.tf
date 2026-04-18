output "securityhub_rule_arn" {
  value = aws_cloudwatch_event_rule.securityhub_findings.arn
}