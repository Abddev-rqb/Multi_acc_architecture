# these are the "Connectors" that turn your written security policies into live, enforced restrictions.



##############################
# ROOT
##############################

# root_deny_root: Attaches the "Deny Root Usage" policy to the entire organization (the Root). 
# This means no one in any account (Security, Dev, Prod, etc.) can use the root user for daily tasks.
resource "aws_organizations_policy_attachment" "root_deny_root" {
  
  policy_id = aws_organizations_policy.deny_root_usage.id
  target_id = aws_organizations_organization.org.roots[0].id
}

##############################
# WORKLOADS
##############################

# workload_guardrails_attach: Attaches your specific workload rules (like Region restrictions and S3 encryption) only to the Workloads OU. 
# This ensures your dev, qa, and prod accounts are strictly governed without accidentally locking down your administrative or security accounts.
resource "aws_organizations_policy_attachment" "workload_guardrails_attach" {
  
  policy_id = aws_organizations_policy.workload_guardrails.id
  target_id = aws_organizations_organizational_unit.workloads.id
}