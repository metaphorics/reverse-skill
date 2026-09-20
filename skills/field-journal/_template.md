# [Date] [Project short name]

## Scenario category
<!-- APK reverse engineering / JS signatures / binary analysis / penetration testing / CTF / packet capture analysis / other -->

## Goal summary
<!-- State the task in one sentence -->

## Scope summary (redacted)
<!-- auth.basis / network_profile.mode / in_scope type (do not write real domains or IPs) -->
- auth_basis:
- network_profile:
- asset_types: []

## Roles
<!-- lead / cie / cpe / cre / … see skills/ops/role-map.md -->
- lead_role: lead
- specialists: []

## Full execution path
<!-- Record the full path from target intake to the result, including detours -->

1. ...
2. ...
3. ...

## Evidence chain summary (redacted)
<!-- Maximum 3 entries: E-id + command pattern + conclusion type; full evidence is in the user project -->
<!-- Align fields with the skills/case-review/scripts/review_case.py contract -->
| E-id | severity | status | source_type | Reusable command pattern | Linked finding |
|------|----------|--------|-------------|----------------|--------------|
| E-001 | info | observed | command | `checksec --file=./pwn1` | F-001 |
| E-002 | high | validated | command | `python3 exploit.py REMOTE` | F-001 |

> **Contract alignment (review_case.py)**: If this case produced a separate evidence directory (`evidence/E-xxx.md`),
> each evidence item must meet the field contract in `skills/case-review/scripts/review_case.py`, or `--strict` validation fails:
>
> - Title: `### E-xxx` (must match the filename, such as `E-001.md` → `### E-001`)
> - `- severity:` ∈ critical / high / medium / low / info / n/a
> - `- status:` ∈ observed / candidate / validated / false_positive / accepted_risk
> - `- repro_command:` required (for offline cases, note offline in notes to qualify for the exemption)
> - `- content_hash:` sha256 or n/a; when using sha256, also provide `- artifact_path:` (relative path inside the case)
> - `- linked_workitem:` optional, WI-xxx must exist
>
> Self-check: `python skills/case-review/scripts/review_case.py <case_root> --verify-hashes --strict`

## Finding / path summary
- top_finding:
- path_type: attack | callflow | solve
- path_one_liner:

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| ... | ... | ... | ... |

## Toolchain findings
<!-- Record the tools used, what worked well, pitfalls, and version compatibility issues -->

## Key code / commands

```
<!-- Paste the key commands, hook scripts, and decryption logic used -->
```

## Improvement suggestions for this package
<!-- Was routing accurate? Is bootstrap coverage missing? Does documentation need an update? Should a new tool be added to the manifest? -->

## Reusable patterns / script fragments
<!-- If you produced a reusable hook script, decryption logic, or bypass method, paste it here -->

## Evolution actions
- [ ] Update the routing matrix
- [ ] Update tool-index
- [ ] Update bootstrap-manifest
- [ ] Update child skill documentation
- [ ] Add a pitfalls record
- [ ] No update needed

## Environment information
<!-- Record the key environment details -->
- OS:
- Tool versions:
- Target platform/version:

## Redaction requirements

> **This file may sync with the repository to a remote location, so redact it. See [`anonymization.md`](anonymization.md) for the full rules (placeholder list + automatic detection script).**

- Target domains/IPs: replace them with `{target_domain}` / `{target_ip}` (see `anonymization.md`)
- Real URL paths: keep the structure and replace the domain
- Tokens/Cookies/passwords/JWT/API keys: use `{token}` / `{password}` / `{api_key}` placeholders
- Usernames/phone numbers/email addresses: use `{username}` / `{phone}` / `{user_email}` placeholders
- Internal IPs/ports: keep the first two octets of private IP ranges (`10.0.x.x`)
- Vulnerability payloads: you can keep the technical content, but replace target-specific parameters (such as `?id={user_id}`)

Before committing, run the regular-expression scan against the **Field-Journal required checklist** at the end of `anonymization.md`.

If this is a private repository and you confirm that it will not be public, you can relax these rules. Redaction is still recommended.

## Index synchronization (last step before commit)

After writing this entry, you must update `_index.md`:

1. Add a line under the matching section in "By scenario category", including the date and keywords.
2. Add this filename under the matching technology in "Frequent successful patterns (by technology)".
3. Add this filename under the matching entity in "Entity reverse index (by target feature)".
4. Update the total count and "last updated" date in "Cumulative statistics".

---
<!-- [Evolution statistics] Total completed projects in this package: N | New patterns this time: X | Toolchain issues fixed this time: Y -->
<!-- [Community contribution] After completion, ask the user whether to submit a PR to the main repository. See CONTRIBUTE-BACK.md for the process. -->
