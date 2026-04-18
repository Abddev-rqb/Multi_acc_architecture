# This Terraform code creates the folder structure (Organizational Units, or OUs) for your AWS Organization.

# By grouping accounts into these OUs, you can apply Service Control Policies (SCPs) to an entire group at once—for example, 
#"Nobody in the Workloads OU can delete S3 buckets," while still allowing it in other areas.

# security OU: A dedicated folder for infrastructure-wide security tools, like the log_archive and security accounts you created earlier.
resource "aws_organizations_organizational_unit" "security" {
  
  provider  = aws.management
  name      = "Security"
  parent_id = aws_organizations_organization.org.roots[0].id # parent_id: This attaches both OUs directly to the Root (the very top level) of your AWS Organization.

}

# workloads OU: A folder for your application environments, like dev, qa, and prod.
resource "aws_organizations_organizational_unit" "workloads" {
  
  provider  = aws.management
  name      = "Workloads"
  parent_id = aws_organizations_organization.org.roots[0].id
}