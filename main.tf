# This file is the Controller. It connects your network, security, and servers across multiple AWS accounts in the correct order.

##############################################
# Foundation (global, backend, logging)
# These modules set up the basic rules, the storage for Terraform (S3/DynamoDB), and centralize all AWS logs.
# They use the management and log_archive accounts to keep your administrative data separate from your apps.
# Why: You need a solid foundation before building apps.
##############################################
module "global" {
  source = "./global"

  # Tells each module which AWS account to log into.
  # By passing aws.dev or aws.prod, the module knows exactly which "office" to walk into to start building.
  providers = {
    aws.management = aws.management
  }

  allowed_regions = var.allowed_regions
  account_emails = var.account_emails

}

module "backend" {
  source = "./backend"

  providers = {
    aws.management  = aws.management
    aws.log_archive = aws.log_archive
  }

  account_ids = var.account_ids
  management_account_id = var.management_account_id
}

module "logging" {
  source = "./logging"

  providers = {
    aws.management  = aws.management
    aws.log_archive = aws.log_archive
  }

  account_ids = var.account_ids
  allowed_regions = var.allowed_regions

}
############################################################################################

##############################################
# Shield (security, eventing, lambda)
# These set up security tools (like Security Hub) and the "Alarm System" (EventBridge rules and Lambda functions) to alert you when something goes wrong.
# To ensure that if a threat is detected in any account, an email is sent and a Lambda function can automatically react.
# depends_on ensures security isn't turned on until the logging foundation is ready.
##############################################

module "security" {
  source = "./security"

  providers = {
    aws.management  = aws.management
    aws.security    = aws.security
    aws.dev         = aws.dev
    aws.qa          = aws.qa
    aws.prod        = aws.prod
    aws.log_archive = aws.log_archive
  }

  account_ids = var.account_ids
  account_emails = var.account_emails
  management_account_id = var.management_account_id

  depends_on = [module.logging]

}

module "eventing" {
  source = "./eventing"

  providers = {
    aws.security = aws.security
  }

  alert_email = var.alert_email

  depends_on = [module.security]

}

module "lambda" {
  source = "./lambda"

  providers = {
    aws.security = aws.security
  }
  securityhub_rule_arn = module.eventing.securityhub_rule_arn

  depends_on = [module.eventing]
}
############################################################################################

##############################################
# Neighborhoods (dev_network, qa_network, prod_network)
# These create the VPCs (private networks) for your three main environments
# To keep your "Playground" (Dev) completely isolated from your "Real World" (Prod).
# Each uses a different CIDR (IP range) like 10.10..., 10.20..., and 10.30... so the networks never overlap.
##############################################

module "dev_network" {
  source = "./network"

  providers = {
    aws = aws.dev
  }

  vpc_cidr       = "10.10.0.0/16"
  public_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.11.0/24", "10.10.12.0/24"]
  azs            = ["us-east-1a", "us-east-1b"]
  
  depends_on = [module.global]
}

module "qa_network" {
  source = "./network"

  providers = {
    aws = aws.qa
  }

  vpc_cidr       = "10.20.0.0/16"
  public_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnets = ["10.20.11.0/24", "10.20.12.0/24"]
  azs            = ["us-east-1a", "us-east-1b"]
  
  depends_on = [module.global]
}

module "prod_network" {
  source = "./network"

  providers = {
    aws = aws.prod
  }

  vpc_cidr       = "10.30.0.0/16"
  public_subnets = ["10.30.1.0/24", "10.30.2.0/24"]
  private_subnets = ["10.30.11.0/24", "10.30.12.0/24"]
  azs            = ["us-east-1a", "us-east-1b"]
  
  depends_on = [module.global]
}
############################################################################################

# "depends_on" (The Order of Operations)
# You can't build a house (workload) before the land is ready (network).
# It forces Terraform to finish the network modules before it even tries to start the workload modules.

##############################################
# Houses (dev_workload, qa_workload, prod_workload)
# These put the Servers and Load Balancers into the neighborhoods created above.
# They take the vpc_id and subnets from the network modules and deploy the EC2 instances
# Why: This is where your actual application lives.
##############################################

module "dev_workload" {
  source = "./workload"

  env =  "dev"

  providers = {
    aws = aws.dev
  }

  vpc_id          = module.dev_network.vpc_id
  public_subnets  = module.dev_network.public_subnets
  private_subnets = module.dev_network.private_subnets
}

module "qa_workload" {
  source = "./workload"

  env = "qa"

  providers = {
    aws = aws.qa
  }

  vpc_id          = module.qa_network.vpc_id
  public_subnets  = module.qa_network.public_subnets
  private_subnets = module.qa_network.private_subnets

  depends_on = [module.qa_network]
}

module "prod_workload" {
  source = "./workload"

  env = "prod"

  providers = {
    aws = aws.prod
  }

  vpc_id          = module.prod_network.vpc_id
  public_subnets  = module.prod_network.public_subnets
  private_subnets = module.prod_network.private_subnets

  depends_on = [module.prod_network]
}
############################################################################################

module "monitoring_dev" {
  source = "./monitoring"

  providers = {
    aws = aws.dev
  }

  env              = "dev"
  alert_email      = var.alert_email
  alb_arn_suffix   = module.dev_workload.alb_arn_suffix
  asg_name         = module.dev_workload.asg_name
  lambda_name      = "security-auto-response"
}

module "monitoring_qa" {
  source = "./monitoring"

  providers = {
    aws = aws.qa
  }

  env              = "qa"
  alert_email      = var.alert_email
  alb_arn_suffix   = module.qa_workload.alb_arn_suffix
  asg_name         = module.qa_workload.asg_name
  lambda_name      = "security-auto-response"
}

module "monitoring_prod" {
  source = "./monitoring"

  providers = {
    aws = aws.prod
  }

  env              = "prod"
  alert_email      = var.alert_email
  alb_arn_suffix   = module.prod_workload.alb_arn_suffix
  asg_name         = module.prod_workload.asg_name
  lambda_name      = "security-auto-response"
}