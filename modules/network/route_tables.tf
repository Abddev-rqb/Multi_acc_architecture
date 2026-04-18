# Public Route: "If you are in a public neighborhood and want to go to the internet, take the Front Gate (IGW)."
# Private Route: "If you are in a private neighborhood and want to go to the internet, take the Security Exit (NAT)."
# Associations: "Give a copy of these directions to every single neighborhood (subnet) we built."

# Public RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-vpc"
    Environment = terraform.workspace
    Project     = "aws-multi-account"
    ManagedBy   = "terraform"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id # This creates a "Map" for the public area.
  destination_cidr_block = "0.0.0.0/0" # This means "Anywhere on the Internet."
  gateway_id             = aws_internet_gateway.igw.id # This says "To get to the internet, go through the Internet Gateway (IGW)."
}

resource "aws_route_table_association" "public_assoc" { # This "hands the map" to each of your public subnets so they know to follow these rules.
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private RT

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-${count.index}"
  }
}

resource "aws_route" "private_nat" {
  count = length(var.private_subnets)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  # Map NAT based on AZ alignment (safe assumption: same index count)
  nat_gateway_id = element(aws_nat_gateway.nat[*].id, count.index)

  depends_on = [
    aws_nat_gateway.nat
  ]
}

resource "aws_route_table_association" "private_assoc" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}