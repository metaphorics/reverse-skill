# Penetration attack-chain lifecycle checklist

> Cross-checked against community pentest skill packages (for example Orizon claude-code-pentest, six phases) and the `attack-chain` + `ops` integration in this package.
> Source: public Claude pentest lifecycle skills (retrieved 2026-07). **Commands and authorization always follow this package's scope.**
> Date: 2026-07-17

## Before use

- [ ] `case-init` is complete, and `auth.status=granted`
- [ ] Do not use an unrestricted `network_profile` against production targets
- [ ] The `lead` assigned specialist_roles (see `ops/role-map.md`)

## Phase gates

| Phase | Role | Skill in this package | Exit criteria |
|-------|------|-----------------------|---------------|
| 0 Scope | lead | ops/scope-contract | ready_for_act |
| 1 Recon | cie | pentest-tools | Asset list + timeline |
| 2 Enum/Vuln | cpe | pentest-tools / api-security | Candidate F-* drafts |
| 3 Validate | cpe | pentest-tools | E-* + validated Finding |
| 4 Post-ex (if authorized) | cpe/lead | attack-chain (second half) | No step uses out_of_scope assets or activities |
| 5 RE support | cre | ida/apk/js/... | Only when client or binary work is needed |
| 6 Report | doc | docs-generator | Evidence→Finding→Path |
| 7 Journal | lead | field-journal | Redaction applied |

## Differences from fully automated single-domain skills

| Common in external automation packages | reverse-skill |
|-----------------------------------------|---------------|
| Scans the whole domain aggressively by default | Requires the scoped asset list |
| Writes the report from weak evidence | Enforces the E/F/P chain |
| One session, no roles | role-map handoffs |
| No tool index | tool-index + bootstrap |

## At least one timeline entry per phase

See `ops/timeline-workitem.md` for the format.
