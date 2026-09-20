# Community security Skill ecosystem comparison (2026-07)

> Source search date: **2026-07-17**  
> Purpose: help reverse-skill **know what exists**, borrow as needed, and **not** merge large external libraries into this package.  
> Package identity: routing + tool bootstrap + evidence/scope contract + field-journal (see `ops/IDENTITY.md`).

## 1. High-value external repositories (learn from them, do not install blindly)

| Repository | Size/positioning | Value to this package | Risk |
|------|-----------|------------|------|
| [trailofbits/skills](https://github.com/trailofbits/skills) | ToB security research Claude plugin marketplace | Audit, vulnerability analysis, and RE plugin quality benchmark | Install through the ToB marketplace. Do not trust non-curated copies by default. |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | Audited plugin list | Prefer it over any community skill | Same as above |
| [Orizon-eu/claude-code-pentest](https://github.com/Orizon-eu/claude-code-pentest) | Six pentest lifecycle skills + pure Python scripts | Compare its reconnaissance → exploitation → report workflow with `attack-chain` + `pentest-tools` | Check authorization boundaries. Run scripts in a sandbox. |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 16 skills + 6 expert subagents | Compare its multi-role division with `ops/role-map.md` | Plugin form differs from this monorepo |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | ~15–19 domain skills (including RE/OT/CSOC) | Domain coverage checklist | Less depth than this package's single-domain skills |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **800+** skills · ATT&CK/NIST mapping | **Framework mapping** and domain catalog can inform this package. Do not depend on the full library. | Scale, maintenance cost, and poisoning surface are high |
| [Eyadkelleh/awesome-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) | SecLists packaged as agent skills | Dictionary and payload entry point | Overlaps seclists bootstrap |
| [securityfortech/awesome-security-skills](https://github.com/securityfortech/awesome-security-skills) | Curated security skill list | Index for finding new skills | It is a list. Audit each item. |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 1000+ cross-vendor skill index | Find official and community skills | Not security-specific |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | PR security review GitHub Action | Compare its change-audit use case with this package's docs and reports | CI product, not an RE router |
| [agentskills.io](https://agentskills.io) | Open Agent Skills standard | Align frontmatter and directory conventions | The standard has no offensive or defensive content |

### 1.1 Second search additions (2026-07-17)

| Repository / resource | Positioning | Package use |
|-------------|------|----------|
| [trailofbits/skills](https://github.com/trailofbits/skills) plugins: `audit-context-building` `differential-review` `semgrep-rule-creator` `sharp-edges` `dwarf-expert` `burpsuite-project-parser` | Audit context, differential security review, dangerous APIs, DWARF, and Burp project parsing | Compare with `ida-reverse`/`docs-generator`/audit workflows. **Do not** merge the full repository. |
| [HexRaysSA/ida-claude-code-plugins](https://github.com/HexRaysSA/ida-claude-code-plugins) | Official IDA Claude plugins, including domain automation marked unsafe | Compare with the `ida-reverse` MCP path. Disable unsafe plugins by default. |
| [P4nda0s/reverse-skills](https://github.com/P4nda0s/reverse-skills) | IDA-NO-MCP: export decompilation, then analyze it; rev-frida/dex-dump/u3d | Complements offline export when MCP is unavailable |
| [2389-research/binary-re](https://github.com/2389-research/binary-re) | triage→static(r2/Ghidra)→dynamic(QEMU/GDB/Frida)→synthesis | See stage gates in `re-agent-workflow.md` |
| [incogbyte/android-reverse-engineering-claude-skill](https://github.com/incogbyte/android-reverse-engineering-claude-skill) | APK unpacking, endpoint extraction, and adaptive Frida bypass | Compare with `apk-reverse`. Dynamic scripts require scope. |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Apple-focused Ghidra+LLDB+Frida three-loop | Reference for macOS/iOS dynamic loops |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | CTF reverse/pwn; install tools as needed | Compare with CTF-Sandbox + `pwn-chain` |
| [shuvonsec/claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty) | /recon→/hunt→/validate→/report | Compare with `recon-pipeline.md` + scope gate |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Web payload + Prompt Injection sections | Prefer `pentest-tools/payloads`. See `llm-security` for LLM. |
| [HackTricks](https://hacktricks.wiki/) | Penetration testing methods + **AI/MCP abuse** | See the MCP section in skill-supply-chain |
| [appsecsanta AI pentesting agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026) | Categories of 39+ open-source AI pentest agent architectures | Multiple agents are not required. Use role-map. |
| Snyk evaluation “More skills ≠ better” | Skill stacking can reduce audit quality | Reinforce the **deep skill + routing** strategy |

### 1.2 Third search additions (2026-09-20)

| Repository / resource | Positioning | Package use |
|-------------|------|----------|
| [goretk/redress](https://github.com/goretk/redress) | Go stripped-binary CLI (info/packages/types/source/r2) | Absorbed into `go-rust-reverse`; bootstrap the release binary, never vendor AGPL sources |
| [mandiant/capa](https://github.com/mandiant/capa) | Capability detection, static + dynamic | Absorbed into `malware-analysis` Phase 1 triage |
| [VirusTotal/yara-x](https://github.com/VirusTotal/yara-x) | Current YARA engine (`yr` CLI) | New rules in `malware-analysis` Phase 4; existing `.yar` stays on classic yara |
| [onekey-sec/unblob](https://github.com/onekey-sec/unblob) | Firmware extraction fallback | Absorbed into `firmware-pentest` Stage 4, ahead of binwalk |
| [WebAssembly/wabt](https://github.com/WebAssembly/wabt) | wasm-objdump/wasm2wat/wasm2c toolkit | Absorbed into `reverse-engineering` WASM sections; 1.0.42 removed wasm-decompile |

## 2. Security standards and threats (2025–2026)

| Source | Key point | Package use |
|------|------|----------|
| [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) | Malicious skills, supply chain, excessive permission, memory poisoning, and more | `ops/skill-supply-chain.md` |
| [Anthropic Agent Skills engineering paper](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Install trusted sources only. Review scripts and dependencies. | Same source + bootstrap must not guess paths |
| ClawHavoc and other poisoning campaigns (recorded in AST10) | Bulk malicious skills in registries | Do not install from an unknown registry with one click |

## 3. Existing package coverage versus broad external coverage

| Domain | reverse-skill | Why we do not merge the full external library |
|------|---------------|--------------------------------|
| APK/JS/IDA/r2/firmware/pwn | **Deep** skills + scripts | Keep depth tied to tool-index |
| Penetration testing/attack chain/SRC | pentest-tools + attack-chain + src-hunter | Orizon-type projects can inform methods |
| LLM/Agent security | llm-security | AST10 strengthens the skill's own security |
| Evidence/scope/roles | **ops/** (feature) | Most skill packages lack a case contract |
| OT/ICS / pure GRC / fraud F3 | No standalone skill | When routing misses, propose a new skill or link externally. Do not force a fit. |
| 800+ micro skills | Not copied | Use MASTER routing + domain skills instead of fragmentation |

## 4. Borrowing rules (MUST)

```text
1. Do not use git submodule to pull an 800+ skill library as a runtime dependency
2. When borrowing, extract stage, checklist, and command patterns into this package's references or an existing skill
3. For external scripts, inspect dependencies and network behavior in an isolated environment before considering bootstrap-manifest
4. For a new scenario, follow CONTRIBUTING to add a skill, then update routing + RULES keywords
5. Mark the source URL + search date (use this file's format)
6. Follow the ops/skill-supply-chain.md checklist before installation or merging
7. At runtime, load only the PRIMARY from MASTER-ROUTING (+ required secondary) to avoid skill stacking overload
```

## 4.1 Borrowed artifacts already retained in this package

| Artifact | Path |
|------|------|
| Four RE stages | `reverse-engineering/references/re-agent-workflow.md` |
| Authorized reconnaissance | `pentest-tools/references/recon-pipeline.md` |
| Attack-chain gates | `attack-chain/references/lifecycle-checklist.md` |
| Skill supply chain | `ops/skill-supply-chain.md` |
| Domain coverage | `references/domain-coverage-map.md` |

## 5. Priority suggestions (future iterations)

| Priority | Action |
|--------|------|
| P0 done | Ops contract, MASTER routing, skill supply-chain security document |
| P1 | Compare Orizon/ToB and add a pentest stage checklist to attack-chain references |
| P2 | Optional external-link skill allowlist configuration, not in the default path |
