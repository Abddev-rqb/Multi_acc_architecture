# If we are using Modules (like we did in the main.tf), these outputs are how the "Network" module talks to other modules. Without outputs, 
# our other modules (like a "Database" module) wouldn't be able to find the network we just built.

output "vpc_id" {  # It grabs the unique ID of the VPC was just created.
  # If we want to build a database or a server later, those resources will ask, "Which VPC should I live in?" We’ll need this ID to tell them.
  value = aws_vpc.main.id
}

# We'll use this list to tell a Load Balancer exactly which neighborhoods it should guard.
output "public_subnets" {
  # Since we used count to create multiple subnets, 
  # this "Splat" symbol tells Terraform: "Don't just give me one; give me a list of every public subnet ID we made."  
  value = aws_subnet.public[*].id
}

# When we launch a private database, we'll use this list to make sure the database is tucked away safely in the private zone.
output "private_subnets" {
  value = aws_subnet.private[*].id
}