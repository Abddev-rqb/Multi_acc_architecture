# AWS Multi-Account Secure Architecture (Terraform)

## Overview
This project implements a multi-account AWS architecture using AWS Organizations to enforce centralized governance, security, and observability. It separates responsibilities across Management, Security, Log Archive, and Workload accounts, using Terraform for modular and reproducible infrastructure.

---

## What This Architecture Gets Right

- **Strong Account Isolation**
  - Clear separation of security, logging, and workloads
  - Reduced blast radius across environments

- **Centralized Governance**
  - SCPs enforce guardrails (region restriction, root access denial, service protection)
  - Organization-level control instead of per-account policies

- **Security-First Design**
  - GuardDuty + Security Hub enabled at organization level
  - Centralized findings aggregation in Security account
  - KMS-based encryption for logs and data

- **Centralized Logging**
  - Organization-wide CloudTrail → Log Archive account
  - Immutable audit trail for all accounts

- **Automated Detection & Response**
  - EventBridge + Lambda for reactive security workflows

- **Highly Available Workloads**
  - Multi-AZ VPC design
  - ALB + Auto Scaling for resilience

- **Disaster Recovery Awareness**
  - Cross-region S3 replication for log durability

---

## Known Limitations (Realistic Trade-offs)

This is **architecture-focused**, not a fully production-hardened platform:

-  No Control Tower (manual org setup instead)
-  No Identity Center (SSO) integration
-  No centralized secrets management (Secrets Manager not integrated)
-  No full CI/CD pipeline for Terraform modules
-  Limited DR scope (compute not replicated, only data/logs)
-  No cost governance (Budgets / Cost Anomaly Detection not configured)
-  Event-driven automation is minimal (not full SOAR)

---

## Account Structure

| Account        | Purpose                     |
|----------------|-----------------------------|
| Management     | Organization & SCP control  |
| Security       | Central security monitoring |
| Log Archive    | Immutable log storage       |
| Dev / QA / Prod| Workload environments       |

---

## Key Engineering Decisions

### 1. Organizational Isolation Over Single Account
Chose multi-account model to:
- Reduce blast radius
- Enable independent security boundaries
- Enforce governance centrally

---

### 2. SCP-First Governance Model
Used SCPs instead of relying only on IAM:
- Prevents misconfiguration at account level
- Enforces non-bypassable guardrails

---

### 3. Centralized Logging Strategy
All logs routed to Log Archive account:
- Prevents tampering by workload accounts
- Enables compliance and forensic analysis

---

### 4. Security as a Separate Account
Security tooling isolated to:
- Avoid privilege overlap
- Maintain independent monitoring plane

---

### 5. Data-Focused Disaster Recovery
Prioritized log/data durability over full infra replication:
- Faster implementation
- Lower cost
- Trade-off: slower compute recovery

---

## Architecture Flow (Simplified)

![Architecture](docs/diagrams/aws_multi_gov_arch.png)


---

## Tech Stack

- AWS Organizations
- SCPs (Governance)
- IAM (Role-based access)
- CloudTrail, Config
- GuardDuty, Security Hub
- EventBridge, Lambda
- S3 + KMS (Logging & Encryption)
- Terraform (modular IaC)

---

## Outcome

- Established secure multi-account foundation with enforced guardrails
- Centralized logging and threat detection across all accounts
- Demonstrated governance, isolation, and compliance-oriented design
- Built modular Terraform structure suitable for scaling

---

## Future Improvements

- Integrate AWS Control Tower for lifecycle management
- Add AWS IAM Identity Center (SSO)
- Implement Secrets Manager + rotation policies
- Add cost governance (Budgets, anomaly detection)
- Expand DR to include compute (pilot-light / warm standby)
- Introduce CI/CD pipeline for Terraform (GitHub Actions)

---
