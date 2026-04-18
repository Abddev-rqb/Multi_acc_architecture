# Create a private plot of digital land. Use the size I specified in my variables.
# Make sure the 'phonebook' is turned on so my servers can find each other by name,
# and label the gate 'main-vpc' so I know which one it is.

resource "aws_vpc" "main" { # This tells Terraform: "Go to AWS and create a Virtual Private Cloud (VPC)." We name it main inside our code so other files (like subnets) can easily find and use it.
  cidr_block = var.vpc_cidr #  It sets the size of our network; We can use this same file for Dev, QA, and Prod but give each one a different size or address (e.g., 10.10.0.0/16) via main.tf.

  enable_dns_hostnames = true # Turns on the AWS internal DNS "phonebook."
  enable_dns_support   = true # Ensures that when we launch a server, AWS automatically gives it a readable name (like ec2-11-22-33.compute.internal).

  # When we log into the AWS Console, this is the name you will see in the list so we don't get confused between different networks.
  tags = {
    Name        = "main-vpc"
    Environment = terraform.workspace
    Project     = "aws-multi-account"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "/vpc/flow-logs-${terraform.workspace}"
}

resource "aws_iam_role" "flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_logs" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn

  iam_role_arn = aws_iam_role.flow_logs_role.arn
}