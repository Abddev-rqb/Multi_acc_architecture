# Create a one-way security exit. Give it a permanent ID card (EIP), and place it in the public neighborhood so it can reach the street. 
# Now, my private servers can 'call out' for updates, but nobody from the street can 'call in' to them.

# A NAT Gateway needs a "return address" so the internet knows where to send the data back to.
resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count = length(var.public_subnets)

  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = {
    Name        = "main-vpc"
    Environment = terraform.workspace
    Project     = "aws-multi-account"
    ManagedBy   = "terraform"
  }
}