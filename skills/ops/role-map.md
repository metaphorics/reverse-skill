# Expert role → Skill mapping (no multi-agent server)

> Role codes draw on the Z3r0 expert team. **Implementation** uses reverse-skill routing and a handoff protocol, not process coordination.

## Role table

| Code | Name (localizable) | Responsibilities | PRIMARY / tool skill |
|------|------------------|------|----------------------|
| **lead** | Lead / commander | Break down tasks, set scope, gate stages, compile reports | `attack-chain/` or current PRIMARY hub; finish → `docs-generator/` |
| **cie** | Reconnaissance | Discover assets, map exposure, identify relationships | `pentest-tools/` (recon); browser → `browser-automation/`; cloud → `cloud-k8s/` |
| **cpe** | Penetration validation | Scan, validate exploitation, confirm impact | `pentest-tools/`; API → `api-security/`; AD → `windows-ad/`; wireless → `wifi-wireless/`; database → `database-security/`; SSO → `identity-federation/`; OT → `ot-ics/` |
| **cre** | Reverse engineering | Binary / firmware / mobile / front-end logic | `ida-reverse/` `ghidra-reverse/` `binary-ninja-reverse/` `radare2/` `apk-reverse/` `mobile-reverse/` `macos-reverse/` `js-reverse/` `browser-extension-reverse/` `dotnet-reverse/` `go-rust-reverse/` `firmware-pentest/` `hardware-security/` `malware-analysis/` `protocol-reverse/` `thick-client/` `reverse-engineering/` |
| **cae** | Code audit | Source code / dependencies / supply chain | `code-audit/` + `supply-chain-security/` |
| **cbe** | Blue team / forensics | Threat hunting, detection, IR artifacts | `threat-hunting/` `digital-forensics/` |
| **cce** | Cryptography | Algorithms / protocols / key misuse | `reverse-engineering` mode documentation |
| **llm** | AI security | Prompt / Agent | `llm-security/` |
| **doc** | Documentation lead | Reports / writeups / diagrams | `docs-generator/` + `diagram-generator/` |

## Lead required protocol

```text
1. Output PRIMARY (master-route) + lead_role=lead
2. Write scope.md (ops/scope-contract)
3. Assign specialist_roles[] and handoff conditions
4. At each stage end, update timeline + workitems; decide whether to continue, change role, or report
5. Do not skip scope and scan production directly with cpe
```

## Handoff rules

| From → To | Trigger | Deliverable |
|---------|------|--------|
| lead → cie | Need asset coverage | scope + known domains/IPs |
| cie → cpe | Live surface or service exists | asset list + ports/URLs |
| cpe → cre | Need reverse validation or client logic | sample path + suspicious points |
| cre → cpe | Protocol, key, or check recovered | algorithm notes + reproduction command |
| any → doc | Stage or task complete | Evidence/Finding/Path draft |
| any → lead | Blocked, unauthorized, or path change | timeline note + blocked reason |

## How one Agent works (feature)

No need to start six Agents:

```text
Within one session:
  [lead] plan
  [cie] execute the reconnaissance skill
  [cpe] switch to pentest-tools
  …
Use role-prefix labels in output so timeline search works:
  [cpe] nuclei high findings → E-003
```

## Relation to master-route

- `master-route` sets the **PRIMARY skill**  
- `role-map` sets **who owns the current stage** (may be written in scope.md)  
- Multi-stage tasks often use `attack-chain/` as PRIMARY, then lead assigns work  

## MUST NOT

- Do not assume a Z3r0 session API exists  
- Do not start extra scans against unauthorized targets for a role  
