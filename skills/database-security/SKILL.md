---
name: database-security
description: Use for authorized database security assessment covering PostgreSQL/MySQL/MSSQL/Mongo/Redis exposure, authz, UDF/command paths, and misconfiguration review.
---

# Database Security Assessment

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read precedent-pentest. **Do not run destructive statements against a production database** unless explicitly allowed.
2. `NOW`: Record the instance, account permissions, and whether write or delete actions are allowed.
3. `NEXT`: Confirm client tool paths.
4. `ACT`: Check exposure, authentication, authorization, configuration, and safe exploitation-chain validation.

## Applicable Scenarios

- Unauthorized database access, weak passwords, or an incorrect 0.0.0.0 binding
- Excessive permissions and dangerous functions (xp_cmdshell, COPY PROGRAM, UDF)
- Lateral movement from an application account to a DBA account
- NoSQL injection and Redis file writing in an authorized environment

## Workflow

```text
□ Network exposure and TLS
□ Account roles and grantees
□ Sensitive-table access control
□ Dangerous settings: file_priv, xp_cmdshell, load_file
□ Audit logging enabled
□ Backup and snapshot permissions
```

## Toolchain

| Tool | Purpose |
|------|------|
| Official CLI | Connect and enumerate |
| sqlmap | Injection verification (authorized) |
| nuclei | Known-exposure templates |
| Cloud RDS console audit | Configuration |

## References

- `references/db-misconfig-checklist.md`
- `../pentest-tools/` `../cloud-k8s/`

## Routing Context

**Upstream**: MASTER R35
**Downstream**: OS command obtained -> attack-chain; cloud-managed -> cloud-k8s

## Task Completion Self-Check

- [ ] Did I avoid unauthorized writes and deletes?
- [ ] Did I distinguish configuration issues from an exploitable chain?
- [ ] Is the Checklist complete?
