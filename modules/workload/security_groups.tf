# The Front Gate (ALB SG) lets the public in, but the Inner Vault (EC2 SG) only opens for the Load Balancer, 
# creating a "sandwich" of security that keeps your servers hidden from hackers.

##############################################
# ALB SECURITY GROUP
# This is the security rule for your Load Balancer.
# Since the Load Balancer is the first thing users hit, its gate needs to be open to the public internet.
# How:
#   Ingress (Incoming): It allows anyone in the world (0.0.0.0/0) to connect via Port 80 (HTTP).
#   Egress (Outgoing): It allows the Load Balancer to talk back to anything (protocol = "-1") so it can send traffic to your servers.

##############################################
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.env}"
  description = "Allow HTTP traffic from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg-${var.env}"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

##############################################
# EC2 SECURITY GROUP
# This is the security rule for your EC2 Servers.
# You don't want the whole internet talking directly to your servers—that's dangerous. You only want them to listen to your Load Balancer.
# How:
#   Ingress (Incoming): This is the "secret sauce." Instead of an IP address, it uses security_groups = [aws_security_group.alb_sg.id]. This means the server will only accept visitors if they are coming from the Load Balancer. Everyone else is blocked.
#   Egress (Outgoing): It allows the servers to reach out to the internet (0.0.0.0/0) so they can download software updates or security patches.

##############################################
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-${var.env}"
  description = "Allow HTTP traffic only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound traffic (updates, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-sg-${var.env}"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}