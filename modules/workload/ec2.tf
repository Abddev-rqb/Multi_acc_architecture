# The Data finds the OS, the Template defines the setup script, and 
# the ASG uses that template to keep 2-3 servers running in your private network.

# This is a lookup tool that finds the latest "Amazon Linux 2" operating system image.
# Instead of you manually typing in a version ID (which changes constantly), this automatically grabs the newest, most secure version for you.
# It filters through Amazon's public images to find the one matching the name "amzn2-ami..." on a 64-bit architecture.
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#  This is the master recipe for your servers.
# You don't want to manually configure every server. This template stores all the settings in one place.
# How:
  # Instance Type: Sets the size (t2.micro).
  # User Data: This is a startup script. As soon as the server turns on, it automatically installs a web server (Apache) and creates a "Hello World" webpage.
  # Security: It attaches the firewall rules (ec2_sg) so the server knows who can talk to it.
resource "aws_launch_template" "app" {
  name_prefix   = "app-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "Hello from $(hostname)" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "app-instance"
      Environment = terraform.workspace
    }
  }
}

# This is the Auto Scaling Group (ASG) that manages the actual live servers.
# It handles the "self-healing" and scaling. If a server crashes, this manager replaces it automatically.
# How:
  # Capacity: It is told to keep 2 servers running at all times, but it can grow to 3 if needed.
  # VPC Zone: It places the servers in your private_subnets (keeping them hidden from the direct internet for safety).
  # Health Check: It uses ELB (Load Balancer) checks. If the Load Balancer says a server isn't responding to web requests, the ASG will terminate it and start a fresh one.
  # Propagate at Launch: This ensures every new server created by the manager gets the "app-asg" name tag.
resource "aws_autoscaling_group" "app" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 2

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "app-asg"
    propagate_at_launch = true
  }
}