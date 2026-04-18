# Put a big two-way front door on the VPC so the public subnets can talk to the world.

# Without this, the VPC is like a building with no doors—totally cut off from the world. 
# The IGW allows the Public Subnets to talk to the internet and allows people on the internet to reach the public servers.

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-vpc"
    Environment = terraform.workspace
    Project     = "aws-multi-account"
    ManagedBy   = "terraform"
  }
}