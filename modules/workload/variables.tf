variable "vpc_id" {}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}