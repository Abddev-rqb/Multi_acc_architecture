#  It creates a central alert channel that filters for serious threats and emails them directly to your security team.

data "aws_caller_identity" "current" {}

##############################################
# SNS TOPIC (SECURITY ACCOUNT)
# It creates an SNS Topic, which is like a broadcast channel.
##############################################

resource "aws_sns_topic" "security_alerts" {
  provider = aws.security

  name = "security-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  provider = aws.security

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  # This tells AWS, "Whoever is on this channel should receive an email at the address stored in var.alert_email."
  endpoint = var.alert_email
}

##############################################
# EVENTBRIDGE RULE - SECURITY HUB FINDINGS
# This watches your Security Hub dashboard.
# It’s programmed to be quiet unless the threat is "HIGH" or "CRITICAL". 
# When a major threat appears, it "pushes the button" on the SNS Topic to send that email.
##############################################

resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  provider = aws.security

  name        = "securityhub-critical-findings"
  description = "Capture high/critical Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"],
    detail-type = ["Security Hub Findings - Imported"],
    detail = {
      findings = {
        Severity = {
          Label = ["HIGH", "CRITICAL"]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_sns" {
  provider = aws.security

  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn

  depends_on = [
    aws_sns_topic_policy.allow_eventbridge
  ]
}

##############################################
# EVENTBRIDGE RULE - GUARDDUTY FINDINGS
# This watches the AI Guard (GuardDuty).
# It captures all GuardDuty findings. 
# GuardDuty is usually very accurate, so we generally want to know about every "finding" it generates.
# Just like the other rule, it sends these alerts to the same SNS Topic.
##############################################

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  provider = aws.security

  name        = "guardduty-findings"
  description = "Capture all GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  provider = aws.security

  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn

  depends_on = [
    aws_sns_topic_policy.allow_eventbridge
  ]
}

##############################################
# PERMISSIONS FOR EVENTBRIDGE → SNS
# This "Policy" tells the SNS Topic: "It is okay to let EventBridge (the alarm system) publish messages here." 
# Without this, the alarm would trigger, but the email would never be sent.
##############################################

resource "aws_sns_topic_policy" "allow_eventbridge" {
  provider = aws.security

  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowEventBridgeFromSameAccount"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.security_alerts.arn

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}