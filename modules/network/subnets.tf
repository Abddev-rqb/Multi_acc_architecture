# Take the land we just bought (VPC) and carve it into two zones. 
#Make the Public zone easy for visitors to find by giving everyone there a public ID. Keep the Private zone hidden. 
# Put half the houses in Data Center A and the other half in Data Center B so we're safe if one crashes.

resource "aws_subnet" "public" {
  # Instead of writing the same code 3 times for 3 subnets, Terraform looks at your list of subnets and says, 
  # "Okay, you gave me 2 IP addresses, so I'll run this block twice."  
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.main.id # This is the "glue." It tells the subnets exactly which VPC they belong to. They "reach out" to the vpc.tf file to get that ID.
  cidr_block        = var.public_subnets[count.index] # This assigns the specific "street address" for that subnet from your variable list.
  # This places the subnet in a specific physical data center (like us-east-1a). By using the index, Terraform spreads your subnets across different buildings so if one loses power, the other stays up.
  availability_zone = var.azs[count.index] # This is a counter (0, 1, 2...). It ensures each subnet gets its own unique IP and name (e.g., public-0, public-1).

  # This is the "Front Door." It tells AWS, "Any server put here should automatically get a public internet address."
  # The Private Subnet leaves this out, meaning servers there stay hidden from the outside world.
  map_public_ip_on_launch = true

  tags = {
    Name = "public-${count.index}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "main-vpc"
    Environment = terraform.workspace
    Project     = "aws-multi-account"
    ManagedBy   = "terraform"
  }
}