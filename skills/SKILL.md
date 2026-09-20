---
name: reverse-skill-router
description: Routes reverse engineering, exploitation, penetration testing, malware, mobile, firmware, browser automation, documentation, and security tasks to the appropriate specialist skill. Use when a task spans modules or the correct reverse-skill entrypoint is unclear.
---
# Reverse Engineering Skills Master Control

This directory contains reverse-engineering skill modules. Each subdirectory is an independent module with a `SKILL.md` that describes its scope, toolchain, and workflow.

## CRITICAL: Routing execution contract (MUST execute immediately)

After reading this file, do not reply only “read” or “understood”. Execute these steps in order:

1. `NOW`: Run the platform-native router (Windows `scripts/master-route.ps1`; Linux/macOS/Kali `scripts/master-route.sh`). Select PRIMARY from `config/routing.json`. Read the `routing.md` three-axis appendix only for difficult cases.
2. `NOW`: Run platform-native `case-init` to create `work/<case>/scope.md` in the current analysis project. **Auth not granted forbids target ACT**. Use the `offline-sample` preset with an explicit sample for local offline samples. Force cannot bypass hard gates.
3. `ACT`: Open the PRIMARY `SKILL.md` and execute ACTION REQUIRED.
4. `NEXT`: Use only paths from `tool-index.md`. Bootstrap missing tools with the platform-native bootstrap (manifest capabilities only).
5. Use Evidence→Finding→Path for conclusions. Reports and journals are SHOULD items unless the user requests them.

**Identity**: See `ops/IDENTITY.md` (lightweight routing package + tool bootstrap + journal; **not** a Z3r0-style platform).

If routing cannot match, first consult additional methodology online and propose a new skill. Do not force the task into a mismatched module.

## Instruction levels (RFC 2119)

- `MUST`: Execute it. Failure means the task fails.
- `MUST NOT`: Do not execute it. A violation is a security failure.
- `SHOULD`: Do it in normal cases. Explain any omission.
- `MAY`: Optional action.

## Current modules

| Module | Directory | Scope |
|------|------|---------|
| **General reverse engineering** | `reverse-engineering/` | GDB / Frida / angr / Unicorn / Qiling / anti-analysis / all-language platform reverse engineering / CTF pattern library |
| **APK reverse engineering** | `apk-reverse/` | Android APK unpacking, jadx decompilation, smali modification, Frida Hook, repackaging, signing, and installation |
| **.NET / C# reverse engineering** | `dotnet-reverse/` | Managed PE reverse engineering, dnSpyEx + de4dot deobfuscation (ConfuserEx/SmartAssembly/Babel), IL patching, Sharp* red-team tool analysis, and dnSpy MCP integration |
| **IDA Pro reverse engineering** | `ida-reverse/` | IDA Pro MCP HTTP server (72 tools): decompilation, disassembly, data-flow tracing, and cross-reference analysis |
| **Front-end JS reverse engineering** | `js-reverse/` | Browser-side signature location, cryptographic parameter analysis, runtime sampling, and Node environment reproduction. Prefer existing `js-reverse_*`. Add jshookmcp for stronger browser/CDP/Hook coverage only after downloading, registering, and enabling that MCP server. |
| **radare2 analysis** | `radare2/` | CLI binary reconnaissance, disassembly, and patching: r2 / rabin2 / rasm2 / radiff2 |
| **CTF entry** | `ctf-sandbox/` | Single PRIMARY. Downstream work stays in sidecar `../CTF-Sandbox-Orchestrator/`. |
| **Technical documentation** | `docs-generator/` | Generate reverse-engineering reports, penetration-testing reports, CTF writeups, and signature reverse-engineering reports after task completion |
| **Evidence graph review** | `case-review/` | Validate scope, Evidence→Finding→Path traceability, workitems, timeline, and artifact hashes |
| **Browser and desktop automation** | `browser-automation/` | Browser operations (Playwright), Windows desktop application operations (OpenReverse UIA/CUA), and network observation |
| **Cross-version symbol migration** | `binary-diff/` | Migrate old symbols to a new version, derive missing PDB data, and migrate function names in bulk after program updates |
| **N-day patch diff → exploitation** | `patch-diff-exploit/` | Locate vulnerabilities from vendor patches, write PoCs, and weaponize N-days. This skill focuses on the attack side, unlike binary-diff. |
| **RE → exploitation chain** | `pwn-chain/` | Move from reverse engineering to a usable exploit: stack/heap/kernel pwn, pwntools, libc-database, and stabilization from CTF to real remote targets |
| **Firmware penetration chain** | `firmware-pentest/` | OWASP FSTM nine stages: extraction → EMBA automation → Firmadyne/QEMU emulation → AFL++ fuzzing → real-device exploitation |
| **EDR evasion reverse engineering** | `edr-bypass-re/` | Red-team scenario: reverse EDR hook tables/ETW/AMSI → direct syscall / Hell's Gate / hardware breakpoints / call stack spoofing |
| **Penetration-testing toolchain** | `pentest-tools/` | Nmap/Nuclei/SQLMap/FFUF/Hashcat/Pentest Swarm and 20+ other penetration tools exposed to AI through MCP |
| **Diagram generation** | `diagram-generator/` | Generate Mermaid/Graphviz/PlantUML diagrams from natural language (attack paths, data flows, architectures, and state machines) |
| **Attack-chain coordination** | `attack-chain/` | Lead multi-stage attack-path planning and execution. Start full penetration testing, HW exercises, and paths from the external network to a domain controller here. |
| **LLM/AI security testing** | `llm-security/` | OWASP LLM + ASI Top 10: Prompt injection, tool abuse, memory poisoning, Agent hijacking, system-prompt extraction, and **Agent execution discipline** |
| **API security testing** | `api-security/` | Full REST/GraphQL/WebSocket protocol coverage: BOLA/IDOR, JWT/OAuth attacks, and a 10-stage methodology |
| **Supply-chain security** | `supply-chain-security/` | SBOM/SCA/CI-CD pipeline: dependency scanning, container security, build integrity, and vulnerability reachability validation |
| **Mobile reverse engineering** | `mobile-reverse/` | Android + iOS: Frida/Objection dynamic instrumentation, SSL Pinning/Root/jailbreak detection bypass, and OWASP MASTG |
| **Malware analysis** | `malware-analysis/` | Six-stage sample analysis, YARA/Sigma, anti-analysis detection, and sandbox coordination |
| **DSL virtual-machine reverse engineering** | `reverse-engineering/dsl-vm-reverse/` | JS custom instruction-set VM (IIFE + switch-case opcode), risk-control engines, and CAPTCHA engines |
| **Operations contract** | `ops/` | Scope / evidence chain / roles / timeline / identity / skill supply-chain security |
| **Community skill comparison** | `references/community-security-skills.md` | External security skill index and borrowing rules (do not install blindly) |
| **Skill supply chain** | `ops/skill-supply-chain.md` | External skill/MCP installation gate (AST10 summary) |
| **RE stage gates** | `reverse-engineering/references/re-agent-workflow.md` | triage→static→dynamic→synthesis |
| **Authorized reconnaissance pipeline** | `pentest-tools/references/recon-pipeline.md` | Scope gate + a match is not validation |
| **Protocol reverse engineering** | `protocol-reverse/` | Custom binary protocols / Protobuf / gRPC / PCAP frame layouts |
| **Ghidra reverse engineering** | `ghidra-reverse/` | Open-source decompilation, headless use, and Ghidra MCP (main entry when IDA is unavailable) |
| **Binary Ninja reverse engineering** | `binary-ninja-reverse/` | HLIL/MLIL/LLIL, Python API, and optional community MCP/localhost HTTP integration |
| **Cloud / containers / K8s** | `cloud-k8s/` | IMDS/IAM, container escape surface, and Kubernetes RBAC |
| **Windows / AD** | `windows-ad/` | Kerberos, AD CS, BloodHound, relays, and domain paths |
| **Digital forensics** | `digital-forensics/` | Memory/disk timelines, PCAP tracing, and IR preservation |
| **Code audit / SAST** | `code-audit/` | Semgrep/CodeQL, white-box review, dangerous APIs, and authorization review |
| **Threat intelligence / OSINT** | `threat-intelligence/` | Public-source IOC supplements, activity correlation, independent verification, and intelligence handoff |
| **Threat hunting** | `threat-hunting/` | Hypothesis-driven hunting, Sigma detection engineering, and blue-team validation |
| **OT / ICS industrial control** | `ot-ics/` | Purdue zones, PLC/SCADA, and passive-first assessment |
| **Wi-Fi / wireless** | `wifi-wireless/` | Authorized wireless assessment, handshakes/PMKID, and lab rules |
| **Browser extension reverse engineering** | `browser-extension-reverse/` | Chrome/Firefox extensions, MV3 workers, and permission surfaces |
| **macOS / Mach-O** | `macos-reverse/` | Signing, ObjC/Swift, LaunchAgent, and macOS samples |
| **Thick client** | `thick-client/` | Desktop C/S, local storage, IPC, and update channels |
| **Go / Rust reverse engineering** | `go-rust-reverse/` | Stripped-symbol Go/Rust, pclntab, and panic strings |
| **Hardware debug interfaces** | `hardware-security/` | UART/JTAG/SWD, read-only extraction, and firmware handoff |
| **Database security** | `database-security/` | MySQL/PG/MSSQL/Mongo/Redis exposure and configuration |
| **Email security** | `email-security/` | Phishing breakdown, SPF/DKIM/DMARC, and BEC |
| **Federated identity** | `identity-federation/` | SAML/OIDC/OAuth SSO flows and misconfiguration |
| **RF / SDR** | `radio-sdr/` | Authorized radio research, receive only by default |

## Unified entry

For reverse engineering, CTF, packet capture, front-end signatures, APK repackaging, or binary analysis tasks, use this sequence:

1. Platform-native router (Windows `scripts/master-route.ps1`; Linux/macOS/Kali `scripts/master-route.sh`) → PRIMARY (`config/routing.json`)
2. Platform-native `case-init` → `scope.md`
3. Open the PRIMARY `SKILL.md`
4. For difficult cases read `routing.md`. For local paths read `tool-index.md`.

## Working approach

Combine these modules as needed:

1. **Receive a target** → inspect the file type first and select the matching analysis tool
2. **Quick triage** → use strings / rabin2 -z / ltrace to look for direct clues
3. **Deep analysis** → use IDA for decompilation, Frida for dynamic Hooking, and angr for symbolic execution
4. **Switch paths when one fails** → use dynamic analysis when static analysis fails, inspect `.so` when Java fails, and set breakpoints when page observation is insufficient

## Next-Step Menu Pattern

Only at a **genuine decision boundary** (at least two materially different, evidence-supported branches exist and user choice changes the next action) MUST a child skill provide 3–6 numbered options. If a gate or Evidence uniquely determines the next step, continue directly. Record only `decision_delta` + `carry_forward_refs` in `ops/timeline-workitem.md`. **MUST NOT** repeat unchanged route/scope/auth/context to create a menu.

Requirements:
- Number each option from 1 to 6
- Describe one concrete executable action in each option, not an abstract direction
- Include at least one report or writeup export option
- Include at least one option to continue analysis or change method
- Include a stop, pause, or question option when needed

Example:
```
## Suggested next step (choose one number)

1. Perform deep decompilation on sub_140001000 and recover the algorithm
2. Use Frida dynamic Hooking to test the parameter hypothesis
3. Export current named functions and generate a symbol migration YAML
4. Generate the analysis report for the current stage
5. Use radare2 for a lightweight reconnaissance comparison
6. Pause. I will confirm the earlier Evidence.
```

## The directory grows over time

This directory continues to grow. When you find a new subdirectory, read its `SKILL.md` to learn its purpose quickly.

When adding a skill, follow `CONTRIBUTING.md`. Confirm that:
- The routing matrix sends tasks to the correct entry
- The bootstrap system can fill dependencies automatically
- tool-index reflects the new tool status

## Related resources

- This package also has **anything-analyzer** (port 23816) MCP server, which provides browser automation, HTTP capture, and AI analysis
- `tool-index.md` records local reverse-engineering tool availability, paths, versions, and script references
- The package-root `Readme.md` provides installation and integration guidance for Claude Code, Codex CLI, and other code AI clients

## On-demand bootstrap

When a workflow finds a missing tool, do not fail directly. Always call the platform-native bootstrap:

Windows:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('tool-name') -StartServices
```

Linux / macOS:
```bash
bash <skill-root>/scripts/bootstrap-reverse.sh tool-name --start-services
```

Kali:
```bash
bash <package-root>/kali/scripts/bootstrap-reverse.sh tool-name --start-services
```

Supported capabilities (use `scripts/bootstrap-manifest.json` as the authority): jadx, apktool, jeb-pro, binaryninja, frida, frida-ps, idalib-mcp, reqable-mcp, jshookmcp, xquik-mcp, anything-analyzer, idapro, r2, rabin2, adb, agent-browser, ghidra-mcp, seclists, proxycat, burpsuite-mcp, nmap, pentestswarm, binwalk, yara, pwntools, bkcrack, redress, goresym, capa, yara-x, unblob, wabt, objection

> JEB Pro is registered as a **manual license install** capability. Bootstrap only prints guidance. It never downloads or bypasses a commercial license. Reqable MCP records only the fixed-version official runtime. The user must still install the Reqable desktop client.
>
> Unblob is registered and auto-installable. EMBA and other capabilities absent from the manifest `MUST` use manual installation steps in the skill documentation. Do not pretend bootstrap supports them.

Bootstrap refreshes `tool-index` after completion.

## Operational precedent library (Precedent Files)

Before any reverse-engineering or penetration operation, MUST read these files in order:

| Order | File | When to read |
|------|------|--------|
| **#1** | `ops/scope-contract.md` + `case-init.ps1` | Executable authorization gate. `precedent-auth.md` does not write granted. |
| **#2** | `field-journal/precedent-reverse.md` or `precedent-pentest.md` | On demand. Load it only when AI hesitates. |

**Load #1 first. Load #2 on demand.**

## Automatic evolution

After each reverse-engineering or penetration-testing task, MUST record the experience in `field-journal/`. See the "Task completion hard Checklist" in `RULES.md`.

- Template: `field-journal/_template.md`
- Index: `field-journal/_index.md`
- Precedents: `field-journal/precedent-auth.md` → `precedent-reverse.md` → `precedent-pentest.md`
- Before a new task, check the index and precedents. Reuse existing experience.

## Completion checks (MUST pass before claiming completion)

- [ ] Did I complete the three-axis route match (target type + user intent + toolchain)?
- [ ] Did I read the target skill's `SKILL.md` after routing succeeded?
- [ ] When routing missed, did I propose a new skill instead of forcing a match?
- [ ] Did I use a real tool path based on `tool-index`?
