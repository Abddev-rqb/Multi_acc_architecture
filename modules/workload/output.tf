output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "alb_arn_suffix" {
  value = aws_lb.app_alb.arn_suffix
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}