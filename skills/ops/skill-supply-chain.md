# Agent Skill supply-chain security (package feature)

> Combined sources: OWASP Agentic Skills Top 10 (AST10), Anthropic Agent Skills security guidance, and public poisoning incidents (such as ClawHavoc, see the AST10 timeline)  
> Review date: 2026-07-17  
> Applies when installing, writing, or merging **any** skill, MCP, or bootstrap script

This package statically audits its **executable script surface** (backdoors / data deletion / pipe execution): [`docs/PACKAGE-SECURITY-AUDIT.md`](../../docs/PACKAGE-SECURITY-AUDIT.md).

## 1. Why reverse-skill handles this separately

This package:

- Guides AI to **run commands and bootstrap downloads**
- Uses MCP to access local systems and networks  
- Records field-journal entries and reports  

Malicious skills can cause credential theft, persistence prompts, and supply-chain backdoors.  
We use **documentation gates + a tool source of truth**, not another skill app store.

## 2. Threat comparison (condensed AST10 model)

| Risk class | Symptom | Package control |
|--------|------|----------|
| Malicious or poisoned skill | Prompts exfiltration, writes memory or a backdoor | Trust only this repository and user-authorized external sources. Read external SKILL.md and scripts manually first. |
| Excessive permission | Unrestricted `curl \| bash`, full-disk reads | Bootstrap only manifest capabilities. Enforce scope `network_profile`. |
| Dependency poisoning | Malicious pip/npm package | Prefer official releases. Record versions in tool-index. |
| Blind MCP trust | Unreviewed MCP server | Check tool-index registration and probe ports. Do not trust remote MCP by default. |
| MCP/CLI auto-execution poisoning | Repository `.env` changes `CODEX_HOME` or similar and runs a malicious MCP at startup (HackTricks / CVE examples) | Do not trust default MCP configuration in the repository. Check env and MCP lists before starting an Agent. |
| Prompt injection into a skill | Hidden instructions in the SKILL body | Review the diff. Do not allow execution instructions hidden in HTML comments without user approval. |
| Scope drift | A skill expands a scan or claims it can automatically break into one domain | Enforce `ops/scope-contract`: require `out_of_scope` and auth. Do not run broad scans without `in_scope`. |
| Skill stacking overload | Too many mounted skills cause missed findings (public evaluation observation) | Load only PRIMARY and required secondary skills (MASTER-ROUTING). |

## 3. MUST checklist for external skill installation

```text
□ Source: official org / audited list (such as ToB curated) / user-owned
□ Read all SKILL.md files, scripts/*, and package dependencies
□ No unexplained external connections or default reads of ~/.ssh or browser stores
□ When routing conflicts with this package, follow this package's MASTER-ROUTING + scope
□ Do not copy into a monorepo unless you follow CONTRIBUTING and redaction
□ Update skills/references/community-security-skills.md with the source date
```

## 4. Boundary with bootstrap / MCP

| Action | Allowed | Forbidden |
|------|------|------|
| `bootstrap-reverse.ps1 -Capability X` | X ∈ bootstrap-manifest.json | Any new name without a manifest change |
| Register MCP | User confirmation + tool-index refresh | Silently write a global MCP entry that points to an unknown URL |
| Run a community Python pentest | Authorized lab + source review first | Direct production target + unknown script |

## 5. Package authors and contributors

- New skill: CONTRIBUTING + ACTION REQUIRED + completion checks  
- Community content: mark the URL + date (this file / community-security-skills.md)  
- Suspicious behavior: stop execution, tell the user, and do not try to bypass it automatically

## 6. Quick self-check (before each external-material merge)

```powershell
# List script extensions to be introduced
Get-ChildItem -Recurse -Include *.ps1,*.sh,*.py,*.js | Select-Object FullName
# Search dangerous patterns roughly (manual review, not complete)
# Run in the external directory: Select-String -Pattern 'Invoke-WebRequest|curl .\||wget .\||~/.ssh|exfil'
```

## 7. Related

- Identity: `IDENTITY.md`  
- External directory: `../references/community-security-skills.md`  
- Authorization: `scope-contract.md` + `field-journal/precedent-auth.md`  
