# Disaster Recovery (DR) Design

## 1. Type of DR
**Active–Passive (Backup-based DR)**

**Explanation:**
- Primary Region: `us-east-1`
- DR Region: `us-west-2`
- DR does not serve traffic under normal conditions
- Activated only during failure

---

## 2. RTO (Recovery Time Objective)

**Realistic RTO:**  
`30 minutes – 2 hours`

**Why:**
- No pre-provisioned compute in DR
- Required steps:
  - Detect and validate failure
  - Switch endpoints
  - Redeploy workloads if necessary

> Claiming “5 minutes” is unrealistic in this setup.

---

## 3. RPO (Recovery Point Objective)

**Realistic RPO:**  
`Near real-time (seconds to minutes)`

**Why:**
- S3 replication is asynchronous
- Small replication lag exists

**Implication:**
- Data loss is minimal, but not zero

---

## 4. What is Protected

### Covered
- CloudTrail logs (critical audit data)
- S3 objects (replicated)

### Not Covered
- EC2 instances
- VPC infrastructure
- Databases (not present)

> This is **partial DR**, not full system recovery.

---

## 5. Failover Process

### Steps
1. Detect region failure (CloudWatch or manual)
2. Confirm primary region outage
3. Access DR region (`us-west-2`)
4. Verify replicated data in DR S3 bucket
5. Recreate infrastructure if needed:
   - Terraform apply
   - Deploy workloads
6. Update DNS (Route53) to DR
7. Resume operations

---

## 6. Failback Process

1. Primary region is restored
2. Sync data back if required
3. Redirect traffic to primary region
4. Validate system consistency

---

## 7. Why This Design

### Pros
- Cost-efficient
- Simple architecture
- Strong for audit/log recovery
- No always-on DR infrastructure cost

### Cons
- Higher RTO (slower recovery)
- No full application recovery
- Requires manual intervention

---

## 8. Improvements (Architect-Level Thinking)

To enhance DR capability:
- Add AMI backups for EC2
- Use AWS Backup service
- Replicate infrastructure in DR region (Terraform)
- Implement Route53 failover routing
- Move toward:
  - Pilot Light
  - Warm Standby