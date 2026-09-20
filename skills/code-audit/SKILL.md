---
name: code-audit
description: Use for authorized source-code security review and SAST workflows including Semgrep, CodeQL patterns, dangerous API hunting, and fix verification.
---
# Source Code Security Audit

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` or the code-audit authorization.
2. `NOW`: Confirm access to the source code or repository. For a binary without source, switch to the reverse-engineering skill.
3. `NOW`: Define the language stack and scope (directory, service, or PR diff).
4. `NEXT`: Read `tool-index`. Check Semgrep and other tools.
5. `ACT`: Sketch the threat model. Run automated scans. Perform manual validation.

## Applicable Scenarios

- White-box audit and PR or differential security review
- Semgrep, CodeQL, Bandit, gosec, and other SAST tools
- Dangerous APIs, injection points, missing authorization, and cryptographic misuse
- Division with `supply-chain-security/`: this skill focuses on owned-code logic. Supply-chain security focuses on dependencies and pipelines.

## Workflow

### 1. Scope and Threat Model

```text
□ Trust boundaries: user input, files, deserialization, SSRF, and authorization middleware
□ High-value assets: authorization, payments, admin interfaces, and secret handling
```

### 2. Automated Scan

```bash
semgrep --config auto .
# Or use the project rule package
semgrep --config p/owasp-top-ten .
```

### 3. Manual Validation (MUST)

```text
□ For every SAST hit: check reachability, exploitability, and false-positive status
□ Authorization: IDOR/broken access control, missing checks, and incorrect multi-tenant isolation
□ Injection: SQL, command, template, and LDAP
□ Cryptography: hard-coded keys, ECB, and custom crypto
```

### 4. Output

```text
Finding: location + data flow + PoC + remediation recommendation
Optional ATT&CK / CWE number
```

## Toolchain

| Tool | Language / scenario |
|------|-----------|
| Semgrep | Fast multi-language rules |
| CodeQL | Deep data flow (GitHub) |
| Bandit | Python |
| gosec / staticcheck | Go |
| SpotBugs / FindSecBugs | Java |

## References

- `references/sast-review-checklist.md`
- `../supply-chain-security/` `../api-security/` `../llm-security/` (agent code)

## Routing Context

**Upstream**: MASTER R26
**Role**: `ops/role-map.md` cae
**Downstream**: dependency vulnerability -> supply-chain; runtime validation -> pentest-tools

## Task Completion Self-Check

- [ ] Did I perform manual validation instead of only pasting scanner output?
- [ ] Did I include remediation recommendations?
- [ ] Did I stay within the authorized repository scope?
- [ ] Checklist complete?
