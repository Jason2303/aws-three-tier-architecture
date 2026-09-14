# Security Design

This document covers the three security-critical aspects of the architecture: which ports are open between tiers and why, how database credentials are managed, and how encryption is enforced at rest and in transit.

---

## 1. Ports Open Between Each Tier

Every rule below is enforced at the security group level, and every rule past the public internet edge references the security group of the tier immediately before it. This means access is granted by group membership, not by IP address, so an instance can only reach the next tier if it genuinely belongs to the tier that's allowed to.

| From                   | To                     | Port | Protocol            | Reason                                                                                                                                                   |
| ---------------------- | ---------------------- | ---- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Internet (`0.0.0.0/0`) | External ALB           | 443  | TCP                 | Public HTTPS entry point                                                                                                                                 |
| Internet (`0.0.0.0/0`) | External ALB           | 80   | TCP                 | Accepts plain HTTP solely to issue a 301 redirect to 443                                                                                                 |
| External ALB           | Web tier (Nginx)       | 80   | TCP                 | TLS terminates at the ALB; traffic to the web tier is plain HTTP over the private VPC network                                                            |
| Web tier               | Internal ALB           | 80   | TCP                 | Nginx forwards to the internal load balancer rather than to app instances directly, keeping the internal ALB as the single entry point into the app tier |
| Internal ALB           | App tier (Node.js)     | 80   | TCP                 | Internal ALB has no public IP; this hop never leaves the VPC                                                                                             |
| App tier               | Database tier (RDS)    | 5432 | TCP                 | Standard PostgreSQL port, restricted to the app tier's security group only                                                                               |
| Web tier, App tier     | Internet (`0.0.0.0/0`) | 443  | TCP (outbound only) | Deliberate exception, routed through NAT, for OS package manager updates.                                                                                |

**Ports deliberately left closed:**

- **Port 3000 is never opened anywhere**, at any tier. The compute tiers communicate over 80, and this is enforced twice. The ALBs and instances only ever listen on 80, and the security groups have no rule for 3000 in any direction.
- **The database security group has no egress rules at all.** RDS never initiates an outbound connection; it only responds to queries directed at it. Since it has no legitimate reason to reach anywhere, all outbound traffic is blocked by default, which closes off any path a compromised database instance could use to exfiltrate data or reach another part of the network.
- **Nothing opens a port directly to the database tier from outside the app tier.** Not the web tier, not the ALBs, not the internet. The only ingress rule on `db_sg` is app-tier-to-5432.

**Isolation is also enforced independently at the network layer**, beneath the security groups. The isolated-db subnets have no route to `0.0.0.0/0` in their route table at all

---

## 2. Database Credential Management

The database master password is never stored as a Terraform variable, never appears in a `.tf` file, and is not present in `terraform.tfvars` or any file committed to version control.

The RDS instance is created with:

```hcl
manage_master_user_password = true
```

This instructs AWS to generate the master password itself at creation time and store it in **AWS Secrets Manager**, tied to that specific RDS instance. No password value ever passes through Terraform's configuration files or command-line arguments.

The instance's `master_user_secret` attribute exposes the secret's ARN, which this project surfaces as a Terraform output (`db_secret_arn`). An application needing to connect to the database would retrieve the actual password at runtime via the Secrets Manager API, using that ARN. The credential is fetched at connection time.

The database **username** is given as a Terraform variable (`db_username`), since a username alone is not a secret.

**Retrieval is scoped by IAM, not by network access alone.** The app tier's EC2 instances assume an IAM role via an instance profile, with a policy granting only `secretsmanager:GetSecretValue` against the ARN of the RDS secret. The web tier's EC2 instance does not hold this permission meaning if a malicious actor compromises the web tier specifically, they would have no IAM permission to retrieve the database credentials.

---

## 3. Encryption at Rest and in Transit

**At rest**, the RDS instance is created with:

```hcl
storage_encrypted = true
```

This encrypts the underlying storage volume and all automated backups using an AWS-managed KMS key. Encryption at rest is enabled at creation time. RDS does not support enabling it retroactively on an existing unencrypted instance, so this must be set from the first `apply`.

**In transit**, encryption is enforced at the point where the architecture meets untrusted networks. The external ALB:

- The HTTPS listener on port 443 terminates TLS using a certificate provisioned through AWS Certificate Manager
- The HTTP listener on port 80 does a HTTP 301 redirect to port 443, so no request is ever served without encryption at the public edge.
- `ssl_policy = "ELBSecurityPolicy-2016-08"` sets the minimum TLS version and cipher suite the ALB will negotiate, rejecting outdated or weak TLS handshakes.

Traffic **behind** the external ALB (ALB-to-web-tier), web-tier-to-internal-ALB, internal-ALB-to-app-tier, and app-tier-to-database travels entirely within the private VPC network rather than over the public internet making the traffic private.
