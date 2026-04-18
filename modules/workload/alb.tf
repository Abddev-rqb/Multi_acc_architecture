# Traffic hits the LB, the Listener catches it, sends it to the Target Group, which then picks a healthy server provided by the ASG Attachment.

# It acts as the single entry point for users. Instead of hitting a specific server, users hit this URL.
# It is set to internal = false (publicly accessible) and sits in your public_subnets. 
# It uses a Security Group to control who can talk to it and has an idle_timeout of 120 seconds to keep connections open for slow requests.
resource "aws_lb" "app_alb" {
  name               = "app-alb-${var.env}"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnets

  security_groups = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false

  idle_timeout = 120

  tags = {
    Name = "app-alb-${var.env}"
  }
}

# A logical grouping of your servers.
# The Load Balancer needs to know where to send the traffic and how to check if those servers are "healthy."
# It listens on Port 80 (HTTP). The health_check block is the "pulse check"—it pings the path / every 30 seconds. 
# If a server doesn't respond with a 200 OK twice, the LB stops sending traffic there.
resource "aws_lb_target_group" "tg" {
  name     = "app-tg-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# A rule that watches for incoming connections.
# The Load Balancer exists, but it needs instructions on what to do when someone knocks.
#  It listens on Port 80. The default_action tells it to "forward" every request it receives directly to the Target Group (the waiting room) created above.
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# The connection between your Auto Scaling Group (ASG) and the Load Balancer
# Without this, the Load Balancer is just a receptionist with no workers.
# it tells the ASG: "Whenever you spin up a new server, automatically register it with the Target Group so it can start receiving traffic immediately."
resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}