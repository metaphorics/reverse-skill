---
name: windows-ad
description: Use for authorized Active Directory and Windows identity attacks including Kerberos, AD CS, BloodHound paths, NTLM relay, and domain privilege escalation research.
---

# Windows / Active Directory Security

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md`.
2. `NOW`: **Define the authorized scope for every domain or AD test**. Include the DC and whether poisoning or relay is allowed.
3. `NOW`: Run case-init. Record network_profile and prohibited actions.
4. `NEXT`: Read tool-index. Impacket, Certipy, and BloodHound often require manual installation.
5. `ACT`: Start with identity enumeration and the BloodHound graph. Do not start with destructive exploitation.

## Applicable Scenarios

- Domain penetration, Kerberoasting, AS-REP, and delegation
- AD CS certificate attacks (ESC1-ESC8 and similar)
- BloodHound / SharpHound attack paths
- NTLM Relay / Coercer forced authentication
- Local privilege escalation to a domain path (Potato tools as a pivot)

## Relationship to attack-chain

- **Multi-stage path from the external network to the domain controller** -> `attack-chain/` may remain PRIMARY. This skill provides AD specialization.
- **Identity-focused work already inside the domain** -> PRIMARY = this skill.

## Workflow

### 1. Enumeration

```bash
# Example Impacket tools and built-ins (credentials and authorization required)
nxc smb <range> -u user -p pass
bloodhound-python -d domain.local -u user -p pass -c All -ns <DC>
```

### 2. Common Paths (Graph Before Exploitation)

```text
□ Kerberoast / AS-REP -> offline cracking
□ ACL abuse (GenericAll/WriteDacl)
□ Delegation (unconstrained, constrained, or resource-based)
□ AD CS template error -> Certipy
□ Relay: LLMNR/NBT-NS + ntlmrelayx (confirm authorization)
```

### 3. Credentials and Lateral Movement

```text
□ secretsdump / lsassy / mimikatz (strict authorization and cleanup)
□ PtH / PtT / Golden Ticket only within an authorized red-team scope
□ Write Evidence for every step. Ask the user before high-risk actions.
```

## Toolchain

| Tool | Purpose |
|------|------|
| BloodHound / SharpHound | Path graph |
| Certipy | AD CS |
| Impacket / NetExec | Lateral movement and enumeration |
| Rubeus / Mimikatz | Tickets and credentials (authorized) |
| Coercer / Responder | Forced authentication and poisoning |

## References

- `references/ad-attack-paths.md`
- `../pentest-tools/references/network-attack-defense.md`
- `../attack-chain/`
- Seeds: `field-journal/seed-005_ad-certipy-esc1.md` `seed-007_ntlm-relay-coercer.md` `seed-013_kerberoasting-spn.md`

## Routing Context

**Upstream**: MASTER R24
**Downstream**: report `docs-generator`; EDR research -> `edr-bypass-re`
**MUST NOT**: Run unauthorized DCSync or Golden Ticket operations against production.

## Task Completion Self-Check

- [ ] Did I enumerate and build the graph before exploitation?
- [ ] Did I record reproducible commands and apply redaction?
- [ ] Did I follow every prohibited scope item?
- [ ] Is the Checklist complete?
