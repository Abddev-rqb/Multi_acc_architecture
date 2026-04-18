# It creates a "Digital First Responder" that automatically receives high-priority security alerts so 
# they can be handled by code instantly.

##############################################
# IAM ROLE FOR LAMBDA
# The AWSLambdaBasicExecutionRole attachment gives the Lambda the simple power to write logs. 
# This is vital so you can see what the function did if you need to debug it.
##############################################

resource "aws_iam_role" "lambda_role" {
  provider = aws.security
  name     = "security-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  provider   = aws.security
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

##############################################
# LAMBDA FUNCTION
##############################################

resource "aws_lambda_function" "security_handler" {
  provider = aws.security

  function_name = "security-auto-response"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  # Tells AWS to look for a file named index.py and run the function named handler.
  handler = "index.handler"

  filename = "${path.module}/lambda.zip"
  # This is a clever "fingerprint." Terraform looks at your lambda.zip file; if you change even one letter of your Python code, 
  # Terraform sees the fingerprint changed and knows it needs to upload the new version.
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

##############################################
# EVENTBRIDGE TARGET → LAMBDA
# It connects your Security Hub alarm to this Lambda.
# The moment a "CRITICAL" alert hits Security Hub, EventBridge "calls" 
# this Lambda function and hands it all the details of the threat.
##############################################

resource "aws_cloudwatch_event_target" "lambda_target" {
  provider = aws.security

  rule      = element(split("/", var.securityhub_rule_arn), 1)
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.security_handler.arn

  depends_on = [
    aws_lambda_permission.allow_eventbridge
  ]
}

##############################################
# PERMISSION FOR EVENTBRIDGE → LAMBDA
# Lambda is private by default.
# It explicitly tells the Lambda: "It is okay to let EventBridge trigger you." 
# Without this, the alarm would go off, but the Lambda would refuse to start.
##############################################

resource "aws_lambda_permission" "allow_eventbridge" {
  provider = aws.security

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.securityhub_rule_arn  
}