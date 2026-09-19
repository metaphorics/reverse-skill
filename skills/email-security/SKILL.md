---
name: email-security
description: Use for authorized email security review including phishing analysis, header authentication (SPF/DKIM/DMARC), BEC patterns, and mailbox token abuse research.
---

# Email Security & Phishing Analysis

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Confirm authorization (sample email analysis / tenant configuration review)
2. `NOW`: Do not redeliver malicious samples to real users
3. `ACT`: Header authentication → content/URL → attachment sandbox → tenant control-plane recommendations

## Use cases

- Phishing email breakdown and IOCs
- SPF/DKIM/DMARC configuration review
- BEC business email fraud patterns
- OAuth application phishing / mailbox token abuse (pair with llm/cloud identity skills)
- Security awareness exercise design (authorized)

## Workflow

```text
□ Full raw headers: Received chain, From/Return-Path consistency
□ SPF/DKIM/DMARC alignment results
□ URL sandbox and attachment static analysis (pair with malware-analysis)
□ Brand impersonation and reply-address mismatch
□ Tenant: anti-phishing policy, external tagging, MFA, OAuth app consent
```

## Toolchain

| Tool | Use |
|------|------|
| Mail client "view source" | Headers |
| dig/nslookup | SPF/DMARC records |
| urlscan / sandbox | Links and attachments |
| Tenant admin center | Policy |

## References

- `references/email-auth-checklist.md`
- `../malware-analysis/` `../attack-chain/` (phishing phase) `../windows-ad/` (tokens)

## Routing context

**Upstream**: MASTER R36
**MUST NOT**: Send test phishing to third-party domains without authorization

## Completion self-check

- [ ] Header-authentication conclusion is complete
- [ ] IOCs are made detectable (pair with threat-hunting)
- [ ] Checklist read
