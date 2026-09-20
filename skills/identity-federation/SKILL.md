---
name: identity-federation
description: Use for authorized assessment of federated identity systems including SAML, OIDC, OAuth2 flows, SSO misconfiguration, and token confusion issues.
---

# Identity Federation (SAML / OIDC / OAuth)

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read precedent-pentest. Add SSO test accounts and the IdP/SP scope to scope.
2. `NOW`: Do not brute-force real user accounts or lock them out.
3. `NEXT`: Prepare packet-capture tools and documentation (metadata URL).
4. `ACT`: Map the protocol flow. Check common mismatches. Verify findings.

## Applicable Scenarios

- SAML Response signature or assertion tampering surfaces (classic defect pattern)
- OIDC implicit or authorization-code flow with missing PKCE
- redirect_uri, state, or nonce issues
- IdP and SP metadata or multi-tenant issuer confusion
- Complementary API-security JWT attacks. This skill focuses on federation and SSO flows.

## Workflow

```text
□ Map the full flow: User -> SP -> IdP -> Token -> SP
□ Collect: /.well-known/openid-configuration and SAML metadata
□ Check: exact redirect_uri matching, state binding, and PKCE
□ Check: SAML signature coverage and algorithm downgrade
□ Check session fixation and logout failure
```

## Toolchain

| Tool | Purpose |
|------|------|
| Burp + SAML Raider and similar tools | Assertion editing (authorized) |
| jwt_tool | JWT testing |
| Browser DevTools | Redirect chain |
| IdP administration logs | Audit |

## References

- `references/sso-flow-checklist.md`
- `../api-security/` `../windows-ad/` (enterprise IdP)

## Routing Context

**Upstream**: MASTER R37
**Downstream**: API-only JWT -> api-security; cloud IdP -> cloud-k8s

## Task Completion Self-Check

- [ ] Did I map the complete SSO flow?
- [ ] Does every Finding include reproduction and impact?
- [ ] Is the Checklist complete?
