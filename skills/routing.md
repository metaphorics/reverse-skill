# Reverse Engineering Skill Routing Matrix

> PRIMARY comes from `config/routing.json` via `scripts/master-route.ps1`. This file is a three-axis disambiguation view. Apply it by default as an execution contract, not as optional advice. If a row here disagrees with JSON, JSON wins.

Route tasks to the most appropriate skill module by target type, user intent, and toolchain.

## CRITICAL: Routing Execution Protocol

1. **MUST** complete routing BEFORE executing. Do NOT "do first, route later".
2. **SHOULD** start from `scripts/master-route.ps1` (JSON) to determine PRIMARY. Use this matrix for ambiguous cases.
3. **MUST** state the routing basis. Match at least one of target type, user intent, or toolchain.
4. **MUST** complete `case-init` and `scope.md` before target ACT. Require `auth.status=granted` and `network_profile`.
5. **MUST NOT** place a task in a mismatched skill because it seems similar.
6. **MUST** use network research to supplement the method when no route matches. Propose a new skill.
7. **MUST NOT** reply only with “Please provide a specific task”. Start a determinate step from the available input.
8. **MUST** combine skills for cross-module tasks. Follow the "Path Crossing" section.
9. **MUST** read the target skill's `SKILL.md` after routing and before action.
10. **Ops contract**: read `ops/scope-contract.md` before ACT. Track Evidence→Finding→Path. Use `ops/role-map.md` for roles. Store timeline and workitems under `work/<case>/`. Read `ops/IDENTITY.md`.
11. **External skills**: do NOT bulk-vendor community packs. Map rules in `references/community-security-skills.md` and `ops/skill-supply-chain.md`. Use `reverse-engineering/references/re-agent-workflow.md` for RE stages and `pentest-tools/references/recon-pipeline.md` for reconnaissance.

## By Target Type

| Target Type | Recommended Entry | Alternative |
|-------------|------------------|-------------|
| APK / Android app | `apk-reverse/` — jadx decompile + apktool unpack, with Frida/Objection/MobSF support | Optional licensed JEB Pro cross-check; if core is in .so → `ida-reverse/` or `radare2/` |
| Binary exe/dll/so/elf | `ida-reverse/` — IDA Pro decompile | `radare2/` — CLI analysis, or `reverse-engineering/tools.md` — GDB/Unicorn |
| JavaScript / Web frontend | `js-reverse/` — 5-stage workflow | anything-analyzer MCP browser tools, or jshookmcp CDP/Hook |
| HTTP capture / browser sampling / request replay | anything-analyzer MCP (23816) | Reqable MCP, `js-reverse/`, jshookmcp, or `competition-web-runtime/` |
| Firmware / IoT | `firmware-pentest/` — OWASP FSTM: extract → emulate → fuzz → exploit | `reverse-engineering/platforms.md` — static RE only |
| WASM / Python bytecode / .NET / **DSL VM / custom virtual machine** | `reverse-engineering/dsl-vm-reverse/SKILL.md` — IIFE + switch-case opcode JS VM | `reverse-engineering/languages.md` — real WASM binaries |
| Malware / virus sample | `malware-analysis/SKILL.md` — six-stage + YARA/Sigma | `ida-reverse/` deep dive |
| macOS / iOS | `reverse-engineering/platforms.md` — Mach-O/ObjC/Swift | `mobile-reverse/` for iOS-specific |
| Game (Unity) | `reverse-engineering/` — engine reverse, anti-cheat, IL2CPP/Mono (see seed-014) | `ida-reverse/` deep analysis |
| Memory dump / PCAP | `digital-forensics/` — memory/timeline/PCAP IR | `protocol-reverse/` for protocol recovery |
| Existing case package / evidence handoff | `case-review/`: Evidence graph and fixity review | `docs-generator/` for final report writing |
| Custom protocol / Protobuf / gRPC | `protocol-reverse/` | `js-reverse/` if pure browser WS crypto |
| Cloud / Container / K8s | `cloud-k8s/` | CTF: `../CTF-Sandbox-Orchestrator/competition-agent-cloud/` |
| Windows AD / Kerberos / AD CS | `windows-ad/` | multi-stage: `attack-chain/` |
| Source code / SAST | `code-audit/` | deps/CI: `supply-chain-security/` |
| Game client (Unity/UE) | `reverse-engineering/` + seed-014 | `dotnet-reverse/` for Mono assemblies |
| OT / ICS / SCADA | `ot-ics/` | `firmware-pentest/` offline firmware |
| macOS / Mach-O desktop | `macos-reverse/` | iOS → `mobile-reverse/` |
| Thick desktop client | `thick-client/` | Electron → also `js-reverse/` |
| Go / Rust stripped binary | `go-rust-reverse/` | `ida-reverse/` / `ghidra-reverse/` |
| UART / JTAG / debug pads | `hardware-security/` | then `firmware-pentest/` |
| Database instance security | `database-security/` | SQLi web path → `pentest-tools/` |
| Email / phishing / DMARC | `email-security/` | |
| SAML / OIDC / SSO | `identity-federation/` | JWT-only API → `api-security/` |
| RF / SDR (non-Wi-Fi) | `radio-sdr/` | Wi-Fi → `wifi-wireless/` |
| Browser extension (crx/xpi) | `browser-extension-reverse/` | page JS only → `js-reverse/` |
| Wi-Fi / wireless | `wifi-wireless/` | close-range chain → `attack-chain/` |
| Public-source threat intelligence / OSINT | `threat-intelligence/` | X/Twitter posts remain leads until independently corroborated |
| Blue team / threat hunt | `threat-hunting/` | sample IOC → `malware-analysis/` |
| Ghidra (no IDA) | `ghidra-reverse/` — tools, Ghidra MCP, and automatic bootstrap registration | `ida-reverse/` if IDA MCP available |
| Binary Ninja / Binja | `binary-ninja-reverse/` — HLIL/MLIL/LLIL + Python API | Community Binary Ninja MCP/localhost HTTP adapter when explicitly enabled |

### Additional target mappings

| Target Type | Recommended Entry | Alternative |
|-------------|------------------|-------------|
| OLLVM-obfuscated binary (control-flow flattening / bogus control flow / MBA) | `reverse-engineering/references/ollvm-deobfuscation.md` — full deobfuscation workflow | obpo-plugin / d810-ng (IDA) / ollvm-unflattener (Miasm) / ollvm-breaker (Binary Ninja) / angr / deollvm (ARM64) |
| Cryptography / encryption algorithms | `reverse-engineering/patterns*.md` — crypto patterns | `js-reverse/` (if frontend crypto) |
| Protocol reverse / custom protocol | `reverse-engineering/platforms.md` — network protocols | `js-reverse/` (if WebSocket/HTTP) |
| Go / Rust binary | `reverse-engineering/languages-compiled.md` + `go-reverse.md` | `ida-reverse/` or `radare2/` |
| LLM / AI application | `llm-security/` — OWASP LLM Top 10 + ASI Top 10 | Prompt injection and Agent security |
| API / REST / GraphQL / WebSocket | `api-security/` — ten-stage API method with BOLA/BFLA/JWT/OAuth | `pentest-tools/` for scanning |
| Supply chain / SBOM / CI-CD | `supply-chain-security/` — six-layer governance with Trivy/Syft/Gitleaks | — |
| iOS app (IPA) | `mobile-reverse/` — class-dump/Hopper/Frida iOS | `reverse-engineering/platforms.md` or `mobile-reverse/references/ios-reverse-guide.md` |
| **CTF competition (full stack)** | `../CTF-Sandbox-Orchestrator/ctf-sandbox-orchestrator/SKILL.md` — master entry | Route to 40+ sub-skills by evidence |
| **CTF ZIP / PKZIP archive** | `../CTF-Sandbox-Orchestrator/competition-zip-archive/SKILL.md` — legacy ZipCrypto + `bkcrack` known plaintext | Use before password brute force |
| Web runtime / API | `../CTF-Sandbox-Orchestrator/competition-web-runtime/SKILL.md` | — |
| Cloud / Container / K8s | `cloud-k8s/` | CTF-only extra: sidecar coordinator after PRIMARY `ctf-sandbox/` |
| Windows / AD / Identity | `../CTF-Sandbox-Orchestrator/competition-identity-windows/SKILL.md` | — |
| Forensics / PCAP / Steganography | `../CTF-Sandbox-Orchestrator/competition-forensic-timeline/SKILL.md` | — |
| Prompt injection / Agent | `../CTF-Sandbox-Orchestrator/competition-prompt-injection/SKILL.md` | — |
| Mobile (Android/iOS) | `../CTF-Sandbox-Orchestrator/competition-android-hooking/SKILL.md` | — |
| Firmware / Malware sample | `../CTF-Sandbox-Orchestrator/competition-firmware-layout/SKILL.md` | — |

## By User Intent

| User Says | Route To |
|-----------|----------|
| "DSL VM / custom instruction set / reverse engineering of a risk-control engine" | `reverse-engineering/dsl-vm-reverse/SKILL.md` — IIFE + switch-case opcode |
| "fireye / fireyejs / reverse getToken" | `reverse-engineering/dsl-vm-reverse/SKILL.md` — runtime capture |
| "582KB JS file is not WASM / large JavaScript reverse engineering" | `reverse-engineering/dsl-vm-reverse/SKILL.md` — classify the DSL VM first |
| "decompile / IDA analyze" | `ida-reverse/SKILL.md` — IDA MCP workflow |
| "recover source / disassemble" | `reverse-engineering/SKILL.md` + `ida-reverse/` |
| "Frida hook / dynamic inject" | `reverse-engineering/tools-dynamic.md` — Frida section |
| "radare2 / r2 analyze" | `radare2/SKILL.md` — CLI workflow |
| "find frontend signature / encrypted params" | `js-reverse/SKILL.md` — Observe→Capture→Rebuild |
| "jshookmcp / JS hook / CDP debug" | `js-reverse/SKILL.md` — same JS/Web chain. Download, register, and enable the MCP server before use. |
| "Reqable / Reqable MCP / capture replay" | `pentest-tools/SKILL.md` — authorized local capture and API workflow |
| "JEB / JEB Pro" | `apk-reverse/SKILL.md` — licensed Android / ARM cross-check; verify local install first |
| "APK unpack / repack / modify smali" | `apk-reverse/SKILL.md` — decode→rebuild-sign-install |
| "bypass anti-debug / anti-detection" | `reverse-engineering/anti-analysis.md` |
| "OLLVM deobfuscate / remove control-flow flattening / deflat / deobfuscate" | `reverse-engineering/references/ollvm-deobfuscation.md` — full workflow |
| "obpo / obpo-plugin / d810-ng / d810" | `reverse-engineering/references/ollvm-deobfuscation.md` — modern deobfuscation tools |
| "Hikari / Polaris / Pluto / O-MVLL / Arkari / goron obfuscation" | `reverse-engineering/references/ollvm-deobfuscation.md` — modern OLLVM variant handling |
| "Tigress / Hodur / Approov obfuscation" | `reverse-engineering/references/ollvm-deobfuscation.md` — d810-ng unflattener |
| "Trap Angr / angr path explosion" | `reverse-engineering/references/ollvm-deobfuscation.md` — Pluto/Polaris trap handling |
| "BR obfuscation / indirect-branch obfuscation removal" | `reverse-engineering/references/ollvm-deobfuscation.md` — DeObfBR + read-only data |
| "what obfuscation / VM is this" | `reverse-engineering/patterns*.md` — match by pattern |
| "Go/Rust/Swift reverse" | `reverse-engineering/languages-compiled.md` + `go-reverse.md` |
| "kernel driver / Rootkit / LKM" | `reverse-engineering/kernel-driver-reverse.md` |
| "Python bytecode / pyc" | `reverse-engineering/languages.md` — Python section |
| "symbolic execution / angr" | `reverse-engineering/tools-dynamic.md` — angr section |
| "patch environment / Node reproduce" | `js-reverse/references/env-patching.md` |
| "CTF challenge / competition reverse" | `ctf-sandbox/SKILL.md` → sidecar coordinator |
| "CTF ZIP / PKZIP / bkcrack / archive known-plaintext attack" | `../CTF-Sandbox-Orchestrator/competition-zip-archive/SKILL.md` |
| "write report / documentation" | `docs-generator/` — technical documentation |
| "review case / evidence chain / traceability" | `case-review/`: read-only Evidence Graph Review |
| "write writeup" | `docs-generator/` — CTF writeup template |
| "open webpage / browser automation / fill form" | `browser-automation/SKILL.md` — Playwright |
| "crawl page / screenshot / auto login" | `browser-automation/SKILL.md` |
| "desktop automation / Windows automation" | `browser-automation/SKILL.md` — OpenReverse |
| "game reverse / anti-cheat / hack analysis" | `reverse-engineering/SKILL.md` — game reverse (IL2CPP/Unity/Cheat Engine) |
| "Unity / IL2CPP / Mono" | `reverse-engineering/SKILL.md` — Unity + `seed-014_unity-il2cpp-reverse.md` |
| "Cheat Engine / memory scan" | `reverse-engineering/SKILL.md` — Cheat Engine memory analysis |
| "symbol migration / cross-version compare" | `binary-diff/SKILL.md` — LLM batch migration |
| "missing PDB / old version symbols" | `binary-diff/SKILL.md` — cross-version symbol migration |
| "bindiff / function offset migration" | `binary-diff/SKILL.md` — binary diff |
| "port scan / Nmap" | `pentest-tools/SKILL.md` — information gathering |
| "vulnerability scan / Nuclei" | `pentest-tools/SKILL.md` — vulnerability detection |
| "SQL injection / SQLMap" | `pentest-tools/SKILL.md` — web pentest |
| "directory brute force / FFUF / Gobuster" | `pentest-tools/SKILL.md` — web pentest |
| "password cracking / Hashcat" | `pentest-tools/SKILL.md` — password cracking |
| "penetration testing / active scan" | `pentest-tools/SKILL.md` — pentest toolchain |
| "SRC hunting / Bug Bounty" | `pentest-tools/src-hunter/SKILL.md` — 19 playbooks + H1 cases |
| "WAF bypass" | `pentest-tools/src-hunter/references/payloader/` — 263 bypass steps |
| "draw diagram / flowchart / architecture" | `diagram-generator/SKILL.md` |
| "attack path diagram / sequence diagram" | `diagram-generator/SKILL.md` — Mermaid/Graphviz/PlantUML |
| "malware / virus analysis / sample analysis" | `reverse-engineering/SKILL.md` + YARA/sandbox |
| "firmware / IoT / binwalk / ARM" | `reverse-engineering/platforms-hardware.md` |
| "cryptography / AES / RSA" | `reverse-engineering/patterns*.md` — crypto pattern recognition |
| "protocol reverse / Protobuf / custom protocol" | `reverse-engineering/platforms.md` |
| "cloud security / container escape / K8s" | `cloud-k8s/SKILL.md` |
| "Prompt injection / AI security" | `llm-security/SKILL.md` — OWASP LLM + ASI Top 10 |
| "internal network / lateral movement" | `pentest-tools/SKILL.md` + `references/network-attack-defense.md` |
| "privilege escalation" | `pentest-tools/references/network-attack-defense.md` — escalation section |
| "Mimikatz / credential extraction / PtH" | `pentest-tools/references/network-attack-defense.md` |
| "Kerberos / domain pentest / AD" | `pentest-tools/references/network-attack-defense.md` |
| "C2 / persistence / remote control" | `pentest-tools/references/network-attack-defense.md` |
| "blue team / detection / defense / IR" | `pentest-tools/references/network-attack-defense.md` |
| "APK security testing / mobile security" | `apk-reverse/references/apk-security-checklist.md` — OWASP MASTG |
| "SSTI / template injection" | `pentest-tools/SKILL.md` — SSTImap |
| "XSS scan / cross-site scripting" | `pentest-tools/SKILL.md` — XSStrike |
| "WordPress pentest / WP enumeration" | `pentest-tools/SKILL.md` — WPProbe |
| "C2 framework / adversary simulation" | `pentest-tools/SKILL.md` — AdaptixC2 |
| "WiFi attack / wireless pentest" | `pentest-tools/SKILL.md` — Fluxion + aircrack-ng |
| "NTLM relay / auth coercion" | `pentest-tools/SKILL.md` — Coercer |
| "NetExec / CrackMapExec / nxc" | `pentest-tools/SKILL.md` — network service enumeration |
| "AI auto pentest / MCP security" | `pentest-tools/SKILL.md` — HexStrike AI / MetasploitMCP |
| "Swarm / swarm pentest / autonomous scan" | `pentest-tools/SKILL.md` — Pentest Swarm AI |
| "red team / HW / attack exercise" | `attack-chain/SKILL.md` — full attack-chain coordination |
| "initial breach / boundary breach" | `attack-chain/SKILL.md` — boundary breach phase |
| "close-range pentest / BadUSB / WiFi phishing" | `attack-chain/SKILL.md` — close-range section |
| "EDR bypass / evasion / AV bypass" | `edr-bypass-re/SKILL.md` |
| "phishing / social engineering" | `email-security/SKILL.md` |
| "supply chain attack" | `attack-chain/SKILL.md` — supply chain section |
| "trace cleanup / anti-forensics" | `attack-chain/SKILL.md` — cleanup section |
| "full pentest / end-to-end" | `attack-chain/SKILL.md` — full chain planning |
| "from external to domain controller" | `attack-chain/SKILL.md` — cross-phase path coordination |
| "attack surface assessment / path planning" | `attack-chain/SKILL.md` — path planning decision tree |
| "got shell, what next / post-exploitation" | `attack-chain/SKILL.md` — plan from current foothold |
| "BurpSuite / Burp proxy / intercept" | `pentest-tools/SKILL.md` + `references/burpsuite-mcp-guide.md` |
| "Burp MCP / proxy history analysis" | `pentest-tools/references/burpsuite-mcp-guide.md` — 78 tools |
| "Intruder brute force / Repeater replay" | `pentest-tools/references/burpsuite-mcp-guide.md` |
| "Collaborator / OOB testing" | `pentest-tools/references/burpsuite-mcp-guide.md` |
| "API security / GraphQL / JWT attack" | `api-security/SKILL.md` — REST/GraphQL/JWT/OAuth |
| "supply chain security / SBOM / SCA" | `supply-chain-security/SKILL.md` — Trivy/Syft/Gitleaks |
| "iOS reverse / IPA / Mach-O" | `mobile-reverse/SKILL.md` — class-dump/Hopper/Frida iOS |
| "Objection / SSL Pinning bypass" | `mobile-reverse/SKILL.md` — dynamic instrumentation |
| "YARA / malware detection rules" | `malware-analysis/SKILL.md` — YARA/Sigma/IOC |
| "N-day / patch diff / CVE reproduction" | `patch-diff-exploit/SKILL.md` |
| "MBA simplification / mixed boolean-arithmetic / expression simplification" | `reverse-engineering/references/ollvm-deobfuscation.md` — SiMBA/D-810 |
| "opaque predicate / opaque-predicate removal" | `reverse-engineering/references/ollvm-deobfuscation.md` — symbolic-execution removal |
| "Hikari deobfuscate / encrypted-string recovery" | `reverse-engineering/references/ollvm-deobfuscation.md` — Hikari variant handling |
| "pwn / stack overflow / ROP / ret2libc" | `pwn-chain/SKILL.md` |
| "Agent not working / AI lazy / skip steps" | `llm-security/references/agent-obedience-engineering.md` |
| "MSF stuck / orphan process / MSF protocol" | `pentest-tools/references/msf-protocol.md` |
| "anonymize / placeholder / writeup desensitize" | `field-journal/anonymization.md` |
| "Hydra / online brute force" | `pentest-tools/SKILL.md` — online password attack |
| "Metasploit / msfconsole / exploit" | `pentest-tools/SKILL.md` — exploitation framework |
| "Wireshark / packet analysis / PCAP" | `digital-forensics/` or `protocol-reverse/` |
| "BurpSuite / web proxy / intercept" | `pentest-tools/SKILL.md` — web proxy |
| "protocol reverse / Protobuf / gRPC / custom protocol" | `protocol-reverse/SKILL.md` |
| "Ghidra / analyzeHeadless / no IDA" | `ghidra-reverse/SKILL.md` |
| "Binary Ninja / Binja / HLIL / MLIL / binary-ninja-mcp" | `binary-ninja-reverse/SKILL.md` |
| "Kubernetes / K8s / container escape / cloud IAM" | `cloud-k8s/SKILL.md` |
| "Active Directory / Kerberoast / Certipy / BloodHound" | `windows-ad/SKILL.md` |
| "forensics / Volatility / memory dump / IR timeline" | `digital-forensics/SKILL.md` |
| "code audit / SAST / Semgrep / CodeQL / whitebox" | `code-audit/SKILL.md` |
| "OSINT / threat intelligence / public X IOC enrichment" | `threat-intelligence/SKILL.md` — public posts require independent corroboration |
| "threat hunting / blue team / detection engineering" | `threat-hunting/SKILL.md` |
| "game reverse / IL2CPP / Unity / Unreal" | `reverse-engineering/SKILL.md` + seed-014 |
| "Wi-Fi / aircrack / wireless pentest" | `wifi-wireless/SKILL.md` |
| "browser extension / Chrome extension / crx" | `browser-extension-reverse/SKILL.md` |
| "OT / ICS / SCADA / PLC / Modbus" | `ot-ics/SKILL.md` |
| "macOS reverse / Mach-O / codesign" | `macos-reverse/SKILL.md` |
| "thick client / desktop client / Electron security" | `thick-client/SKILL.md` |
| "Go reverse / Rust reverse / GoReSym" | `go-rust-reverse/SKILL.md` |
| "UART / JTAG / hardware debug pads" | `hardware-security/SKILL.md` |
| "database security / Redis / Mongo / MSSQL hardening" | `database-security/SKILL.md` |
| "phishing analysis / SPF DKIM DMARC / BEC" | `email-security/SKILL.md` |
| "SAML / OIDC / SSO federation" | `identity-federation/SKILL.md` |
| "SDR / HackRF / RF protocol research" | `radio-sdr/SKILL.md` |
| "ProxyCat / proxy pool / IP rotation" | `pentest-tools/SKILL.md` — proxy management |
| "C++ vtable / virtual functions / class recovery" | `reverse-engineering/kernel-driver-reverse.md` — C/C++ pattern recognition |
| "IOCTL / DeviceIoControl" | `reverse-engineering/kernel-driver-reverse.md` — Windows driver analysis |
| "emulation / Unicorn" | `reverse-engineering/tools.md` — Unicorn section |
| "Playwright / headless" | `browser-automation/SKILL.md` — browser automation |
| "UIA / CUA / desktop GUI control" | `browser-automation/SKILL.md` — OpenReverse UIA/CUA mode |
| "OpenReverse" | `browser-automation/SKILL.md` — desktop interaction and network observation |
| "N-day / patch diff / CVE recovery / 1-day weaponization" | `patch-diff-exploit/SKILL.md` — patch to PoC to pre-patch host |
| "Patch Tuesday / MSRC / Microsoft Update Catalog" | `patch-diff-exploit/references/patch-tuesday-workflow.md` |
| "ghidriff / Diaphora / DeepDiff (offensive use)" | `patch-diff-exploit/references/diff-tools-comparison.md` |
| "heap exploitation / tcache / fastbin / unsorted bin" | `pwn-chain/references/heap-pwn.md` |
| "kernel pwn / kernel privilege escalation / modprobe_path / commit_creds" | `pwn-chain/references/kernel-pwn.md` |
| "pwntools / GEF / pwndbg / one_gadget / libc-database" | `pwn-chain/SKILL.md` |
| "firmware pentest / router firmware / IoT exploitation" | `firmware-pentest/SKILL.md` — extraction through hardware validation |
| "binwalk / unblob / SquashFS / UBI / JFFS2" | `firmware-pentest/references/extraction-methodology.md` |
| "EMBA / automated firmware audit / cve-bin-tool" | `firmware-pentest/references/emba-automated-analysis.md` |
| "Firmadyne / FAT / QEMU full-system emulation / AFL++ fuzzing" | `firmware-pentest/references/emulation-and-fuzz.md` |
| "direct syscall / indirect syscall / Hell's Gate / SysWhispers" | `edr-bypass-re/references/unhook-techniques.md` |
| "ETW patch / AMSI patch / telemetry blinding" | `edr-bypass-re/references/telemetry-blinding.md` |
| "ntdll hook / pe-sieve / EDR hook table" | `edr-bypass-re/references/hook-survey.md` |
| "sequence diagram / state diagram / ER diagram / data-flow diagram" | `diagram-generator/SKILL.md` — Mermaid, Graphviz, and PlantUML |
| "Mermaid / Graphviz / PlantUML" | `diagram-generator/SKILL.md` |
| "memory dump / dump analysis" | `digital-forensics/` — memory and timeline analysis |
| "make the AI work / force execution / strengthen Agent instructions" | `llm-security/references/agent-obedience-engineering.md` |
| "prompt engineering / Skill engineering / harness engineering" | `llm-security/references/agent-obedience-engineering.md` — context-window layout and five modes |
| "Codex not working / Claude Code not executing / coding Agent inactive" | `llm-security/references/agent-obedience-engineering.md` — forced-start template |
| "precedent / operation record / executed action / operation authorization" | `field-journal/precedent-auth.md` → `precedent-reverse.md` or `precedent-pentest.md` |
| "authorization / may I do this / safety warning / legal risk / scope" | `field-journal/precedent-auth.md` — authorization pre-declaration |
| "Atomic Red Team / detection testing" | `pentest-tools/SKILL.md` — Atomic-Operator |
| "WinRM / Windows remote execution" | `pentest-tools/SKILL.md` — evil-winrm-py |
| "automated bug bounty / continuous monitoring" | `pentest-tools/SKILL.md` — Pentest Swarm AI bug-bounty playbook |
| "attack surface management / ASM" | `pentest-tools/SKILL.md` — Pentest Swarm AI external-asm playbook |
| "EDR delivery / practical EDR bypass / shellcode loader" | `attack-chain/SKILL.md` — EDR/AV evasion delivery stage |
| "full internal-network penetration" | `attack-chain/SKILL.md` — lateral movement, privilege escalation, and domain attack |
| "Nikto / web server scan" | `pentest-tools/SKILL.md` — web vulnerability scanning |
| "Responder / LLMNR poisoning / NBT-NS" | `pentest-tools/SKILL.md` — internal-network poisoning |
| "BloodHound / AD path / attack graph" | `pentest-tools/SKILL.md` — AD attack-path visualization |
| "Certipy / AD CS / certificate attack" | `pentest-tools/SKILL.md` — AD certificate-service attack |
| "wfuzz / parameter fuzzing / web fuzzing" | `pentest-tools/SKILL.md` — web fuzzing |
| "GDB / GEF / debugging / breakpoints" | `reverse-engineering/tools.md` — dynamic debugging |
| "objdump / disassembly / ELF analysis" | `reverse-engineering/SKILL.md` — static analysis |
| "strings / string extraction" | `reverse-engineering/SKILL.md` — fast reconnaissance |
| "LLM jailbreak / system-prompt extraction" | `llm-security/references/prompt-injection-methodology.md` — five-level injection |
| "Agent security / tool abuse / memory poisoning / goal hijacking" | `llm-security/references/agent-security-testing.md` — seven-stage Agent testing |
| "garak / PyRIT / AI red team" | `llm-security/SKILL.md` — LLM security toolchain |
| "API security testing / API penetration testing" | `api-security/SKILL.md` — ten-stage API testing method |
| "GraphQL security / introspection attack / batch-query bypass" | `api-security/references/rest-graphql-testing.md` — GraphQL specialization |
| "JWT attack / OAuth bypass / alg:none" | `api-security/references/jwt-oauth-testing.md` — JWT and OAuth testing |
| "BOLA / IDOR / BFLA / object-level authorization bypass" | `api-security/SKILL.md` — phase 3 authorization testing |
| "CI/CD security / pipeline audit / build integrity" | `supply-chain-security/references/cicd-pipeline-security.md` — pipeline security |
| "container security / image scan / Trivy / Cosign" | `supply-chain-security/SKILL.md` — container security |
| "gitleaks / secret scan / credential leak" | `supply-chain-security/SKILL.md` — CI/CD pipeline security |
| "supply-chain security / SBOM / SCA / dependency scanning" | `supply-chain-security/SKILL.md` — six-layer supply-chain governance |
| "iOS reverse / IPA / Objective-C / Swift / Mach-O" | `mobile-reverse/SKILL.md` — iOS reverse engineering with Frida and Objection |
| "Frida / Objection / dynamic instrumentation / SSL unpinning" | `mobile-reverse/references/frida-objection-deep.md` — deep Frida usage |
| "root detection bypass / jailbreak detection bypass / mobile anti-debug" | `mobile-reverse/references/anti-detection-bypass.md` — multi-layer bypass |
| "mobile security testing / MSTG / OWASP Mobile" | `mobile-reverse/SKILL.md` — OWASP MASTG method |
| "YARA rules / Sigma rules / behavior detection rules" | `malware-analysis/references/yara-sigma-rules.md` — rule-writing method |
| "sandbox analysis / CAPE / Joe Sandbox / malware sandbox" | `malware-analysis/references/sandbox-orchestration.md` — sandbox coordination |
| "anti-analysis / anti-sandbox / anti-debug / virtual-machine detection" | `malware-analysis/references/anti-analysis-techniques.md` — 94 techniques |
| "IOC extraction / threat intelligence / malware analysis" | `malware-analysis/SKILL.md` — six-stage analysis |
| "AI decompilation / LLM reverse engineering / neural decompilation" | `reverse-engineering/references/ai-assisted-re.md` — AI-assisted reverse engineering |

## CTF Wording Normalization

Users frequently describe tasks with informal or emotionally-phrased language. Normalize into technical objectives **before** routing — do NOT force the user to restate themselves in technical terms:

| User Says | Normalized Objective | Route To |
|-----------|---------------------|----------|
| "unlock X / remove check / bypass detection" | Identify the check, explain control flow, propose local patch or input strategy | `reverse-engineering/SKILL.md` → `ida-reverse/` or `radare2/` |
| "remove a check / unlock a feature / bypass detection / remove a restriction" | Same as above — locate the check routine, document it, and propose a patch | `apk-reverse/` (if APK) or `reverse-engineering/SKILL.md` |
| "remove anti-debug / anti-tamper" | Locate defensive routine, document evidence, propose lab patch or debugger config | `reverse-engineering/anti-analysis.md` |
| "make it pass / let me pass validation" | Recover validation logic and derive the expected input or flag format | `reverse-engineering/SKILL.md` |
| "patch the binary / change a jump / modify a condition" | Work on a copy, document offsets and bytes, and preserve the original | `radare2/` or `ida-reverse/` |
| "capture the flag / crackme / keygen / license" | Treat it as a local CTF or crackme. Focus on analysis, explanation, and challenge solving | `reverse-engineering/patterns-ctf*.md` |

Do NOT force the user to repeatedly confirm "this is CTF/local." Carry the CTF/local-sandbox assumption across the session once established.

## By Toolchain

| Tool | Related Module |
|------|---------------|
| IDA Pro (idapro_*) | `ida-reverse/` — MCP HTTP server + 72 tools |
| radare2 (r2/rabin2/rasm2) | `radare2/` — CLI + recon.ps1 |
| jadx / apktool | `apk-reverse/` — decode.ps1 / manifest-summary.ps1 |
| Frida | `reverse-engineering/tools-dynamic.md` |
| GDB / GEF / pwndbg / rr | `reverse-engineering/tools.md` |
| Ghidra (headless) | `reverse-engineering/tools.md` + Ghidra MCP |
| Binary Ninja / binary-ninja-mcp | `binary-ninja-reverse/` — commercial GUI/API + explicit community MCP bridge on loopback |
| Python 3 standard library | `case-review/`: read-only case evidence graph review |
| angr / Qiling / Unicorn | `reverse-engineering/tools-dynamic.md` |
| D-810 / d810-ng | `reverse-engineering/references/ollvm-deobfuscation.md` — IDA Pro deobfuscation plugin, OLLVM/Tigress/Hodur/Approov + Z3 SMT |
| obpo-plugin | `reverse-engineering/references/ollvm-deobfuscation.md` — Hex-Rays microcode cloud plugin |
| ollvm-unflattener (Miasm) / ollvm-breaker (Binary Ninja) | `reverse-engineering/references/ollvm-deobfuscation.md` — no-IDA and Binary Ninja scenarios |
| DeObfBR | `reverse-engineering/references/ollvm-deobfuscation.md` — indirect-branch obfuscation |
| deflat (QuarksLab) / angr symbol | `reverse-engineering/references/ollvm-deobfuscation.md` — control-flow flattening removal |
| GOOMBA (Ghidra) | `reverse-engineering/references/ollvm-deobfuscation.md` — Ghidra P-Code deobfuscation |
| BinDiff / Diaphora | `reverse-engineering/tools-advanced.md` |
| BinDiff / Diaphora / ghidriff / DeepDiff (offensive use) | `patch-diff-exploit/` — locate patch changes and build an exploit |
| anything-analyzer MCP | Port 23816 MCP server (browser + HTTP capture + AI analysis) |
| jshookmcp | `js-reverse/` enhancement MCP for browser/CDP/Hook/Network/SourceMap/AST |
| agent-browser / Playwright | `browser-automation/` — open, click, fill, crawl, and screenshot |
| OpenReverse (UIA/CUA) | `browser-automation/` — Windows desktop automation and network observation with mitmproxy |
| Cheat Engine / x64dbg / ReClass | `reverse-engineering/` — game memory analysis (seed-014) |
| IL2CPP Dumper / dnSpy | `reverse-engineering/` — Unity/Mono game reverse (seed-014) |
| LLM symbol migration / BinDiff alternative | `binary-diff/` — cross-version batch migration with DeepSeek/GPT |
| Nmap / Masscan | `pentest-tools/` — port scan, service identification |
| Nuclei / ZAP / Nikto | `pentest-tools/` — vulnerability scanning |
| SQLMap / FFUF / Gobuster | `pentest-tools/` — web pentest (injection/brute force) |
| SSTImap | `pentest-tools/` — SSTI auto-detection (Kali 2026.1: `apt install sstimap`) |
| XSStrike | `pentest-tools/` — advanced XSS scanning (Kali 2026.1: `apt install xsstrike`) |
| WPProbe | `pentest-tools/` — WordPress plugin enumeration (Kali 2026.1: `apt install wpprobe`) |
| Hashcat / John / Hydra | `pentest-tools/` — password cracking |
| Metasploit / Impacket | `pentest-tools/` — exploitation framework |
| BurpSuite | `pentest-tools/` — web proxy, interception, vulnerability scanning (Kali Community edition preinstalled) |
| BurpSuite MCP | `pentest-tools/` — 78-tool AI full control, see `references/burpsuite-mcp-guide.md` |
| ProxyCat | `pentest-tools/` — proxy pool management & IP rotation |
| Cobalt Strike / Sliver / Havoc | `attack-chain/` — C2 framework |
| pentestMCP (Docker) | `pentest-tools/` — 20+ tools one-click MCP |
| Mermaid / Graphviz / PlantUML | `diagram-generator/` — diagram generation for flowcharts, sequence diagrams, architecture, and attack paths |
| garak / PyRIT / promptfoo | `llm-security/` — LLM red team testing |
| Trivy / Syft / Gitleaks / OSV-Scanner | `supply-chain-security/` — supply-chain scanning |
| Objection / Frida iOS / class-dump | `mobile-reverse/` — iOS dynamic analysis |

### Additional toolchain entries

| Tool | Related Module |
|------|---------------|
| binwalk v3 / unblob / EMBA / Firmadyne / FAT | `firmware-pentest/` — firmware extraction, automated audit, and emulation |
| pwntools / GEF / pwndbg / ROPgadget / Ropper / one_gadget / libc-database | `pwn-chain/` — reverse engineering to usable exploit |
| SysWhispers3 / Hell's Gate / pe-sieve / API Monitor | `edr-bypass-re/` — EDR evasion research and implementation |
| MetasploitMCP | `pentest-tools/` — Metasploit MCP interface (Kali 2026.1: `apt install metasploitmcp`) |
| mcp-kali-server | `pentest-tools/` — Kali MCP for direct terminal-tool calls (`apt install mcp-kali-server`) |
| HexStrike AI | `pentest-tools/` — MCP automation for more than 150 security tools (Kali 2025.4: `apt install hexstrike-ai`) |
| Pentest Swarm AI | `pentest-tools/` — autonomous penetration-testing framework with shared-blackboard multi-agent coordination (`go install` or Docker) |
| AdaptixC2 | `pentest-tools/` — post-exploitation and adversary-simulation framework (Kali 2026.1: `apt install adaptixc2`) |
| Atomic-Operator | `pentest-tools/` — Atomic Red Team test execution (Kali 2026.1) |
| Coercer | `pentest-tools/` — Windows authentication coercion and NTLM relay (`apt install coercer`) |
| NetExec (nxc) | `pentest-tools/` — network-service enumeration and exploitation (CrackMapExec successor, preinstalled on Kali) |
| evil-winrm-py | `pentest-tools/` — Python WinRM remote execution (Kali 2025.4) |
| Fluxion / aircrack-ng | `pentest-tools/` — Wi-Fi security auditing (aircrack-ng preinstalled on Kali, Fluxion added in Kali 2026.1) |
| Responder | `pentest-tools/` — LLMNR, NBT-NS, and mDNS poisoning (preinstalled on Kali) |
| BloodHound | `pentest-tools/` — AD attack-path visualization (`apt install bloodhound`) |
| Certipy | `pentest-tools/` — AD certificate-service attacks (`apt install certipy-ad`) |
| CrackMapExec / NetExec | `pentest-tools/` — network-service enumeration (nxc is the CrackMapExec successor, preinstalled on Kali) |
| wfuzz | `pentest-tools/` — web parameter fuzzing (preinstalled on Kali) |
| Wireshark / tshark | `pentest-tools/` — protocol analysis and PCAP parsing (preinstalled on Kali) |
| objdump / strings / file | `reverse-engineering/` — basic static analysis (preinstalled on Kali) |
| Rubber Ducky / WiFi Pineapple / Proxmark3 | `attack-chain/` — close-range penetration hardware |
| Vespasian / Entropy / api.sh | `api-security/` — API discovery and attack-scenario generation |
| jwt_tool | `api-security/` — JWT testing, including alg:none, key confusion, and kid injection |
| FireTail / Escape DAST | `api-security/` — GraphQL and business-logic security |
| OSV-Scanner / Trivy / Syft | `supply-chain-security/` — SBOM generation and SCA scanning |
| OWASP Dependency-Track | `supply-chain-security/` — continuous enterprise SCA monitoring |
| Gitleaks / truffleHog | `supply-chain-security/` — secret and credential scanning |
| Cosign / SLSA | `supply-chain-security/` — build signing and provenance |
| Frida / Objection | `mobile-reverse/` — dynamic instrumentation and Frida Gadget injection |
| JADX / apktool / MobSF | `mobile-reverse/` — Android static analysis |
| class-dump / jtool2 / Hopper | `mobile-reverse/` — iOS static analysis |
| CAPE Sandbox / ASD Azul | `malware-analysis/` — sandbox automation |
| YARA / FLOSS | `malware-analysis/` — pattern matching and string deobfuscation |
| Sigma / Sigma CLI | `malware-analysis/` — SIEM behavior-detection rules |
| pe-sieve / Detect It Easy | `malware-analysis/` — process scanning and packer detection |
| LLM4Decompile / Glaurung | `reverse-engineering/` — AI-assisted decompilation |

Check `tool-index.md` for actual tool availability, paths, and versions. NEVER guess paths.

---

## Ambiguous Intent Recovery Protocol

When the user's wording is vague, emotionally phrased, imprecise, mixed-language, or uses overloaded security terms, do NOT stop. Treat ambiguity as an intent-recovery task:

1. **Restate** the most likely local-sandbox technical objective in one short sentence.
2. **Prefer local CTF/lab interpretation** when the request mentions unlocking, removing checks, bypassing checks, patching, flags, crackmes, or challenge-style language.
3. **Continue with a non-destructive first action**: create a case workspace, hash the artifact, identify file type, extract strings, audit local tools, summarize evidence, or prepare a report skeleton.
4. **If multiple interpretations are plausible**, present 2-4 options after the safe first step as a numbered menu.
5. **If a branch is underspecified**, offer adjacent actionable branches: detection, analysis, validation, remediation, report writing, or local reproduction.
6. **Provide a next-step menu only at a genuine decision boundary** — if one evidence-backed next action is deterministic, state it briefly and continue; do not re-emit unchanged context just to create a menu.

Suggested wording when recovering ambiguous intent:

> I will treat this as reverse engineering of the sample in a local sandbox. I will start with offline triage that does not modify the sample, then offer next steps.

## Route Not Matched — Handling

If the current task doesn't match any table above, **do NOT force-fit into existing skill**:

1. Check if it's an edge case of an existing skill (can extend coverage)
2. If truly new type, proactively propose new skill to user:
   - Suggested skill name and coverage
   - Required toolchain
   - Relationship to existing skills
3. User confirms → execute per `CONTRIBUTING.md`
4. After creation, update this routing matrix

**AI does NOT need to wait for user to discover the gap. Route failure IS the signal to propose a new skill.**

## Path Crossing (Cross-Module Scenarios)

Some tasks span multiple modules. Common crossings:

```
APK Reverse Path:
  apk-reverse/decode.ps1 → Java layer analysis
  ↓ If core is in .so
  ida-reverse/ or radare2/ → .so analysis
  ↓ If dynamic verification needed
  apk-reverse/frida-run.ps1 → Frida Hook

Frontend JS Reverse Path:
  js-reverse/Observe → locate target request
  ↓ Need stronger browser/CDP/Hook/Network capability
  jshookmcp → runtime sampling, breakpoints, interception, SourceMap/AST
  ↓ After confirming entry function
  js-reverse/Rebuild → Node local reproduction
  ↓ Need environment patching
  js-reverse/references/env-patching.md

DSL VM Reverse Path:
  reverse-engineering/dsl-vm-reverse/SKILL.md → identify DSL VM (IIFE + single-letter vars + DG() switch-case)
  ↓ Extract opcode table & constant table
  reverse-engineering/dsl-vm-reverse/SKILL.md Phase 2-4 → opcode classification, C[9] constant analysis
  ↓ If runtime capture needed
  browser-automation/ → Playwright/Selenium CDP injection
  ↓ If pure API protocol needed
  js-reverse/ → Observe→Capture→Rebuild (API layer only)

CTF Competition Path (via CTF-Sandbox-Orchestrator):
  ../CTF-Sandbox-Orchestrator/ctf-sandbox-orchestrator/SKILL.md → build sandbox model
  ↓ Route by dominant evidence
  competition-web-runtime/ or competition-reverse-pwn/ or competition-identity-windows/
  ↓ Blocked → return to master
  ctf-sandbox-orchestrator → re-route

Web Pentest + BurpSuite MCP Path:
  browser-automation/ → auto-browse target with Burp proxy
  ↓ Traffic captured
  burpsuite MCP proxy_history → AI analyzes all requests
  ↓ Suspicious endpoints found
  burpsuite MCP intruder_attack → automated enumeration
  ↓ Vulnerability confirmed
  docs-generator/ → generate pentest report

Binary Reverse Path:
  radare2/scripts/recon.ps1 → fast triage
  ↓ Deep analysis
  ida-reverse/ → IDA decompilation
  ↓ Dynamic validation
  reverse-engineering/tools-dynamic.md → Frida/GDB

Cookie HMAC key reuse → admin authentication bypass:
  competition-web-runtime/references/cookie-hmac-key-reuse-auth-bypass.md
  ↓ Applicable when the URL contains an access token, a signed cookie, or an admin_session
  The access token, cookie, and session share one key.

Firmware Penetration Path:
  firmware-pentest/references/extraction-methodology.md → extract the file system
  ↓ Binary analysis
  firmware-pentest/references/emba-automated-analysis.md → EMBA audit for known CVEs
  ↓ Known CVEs are insufficient or a zero-day is required
  firmware-pentest/references/emulation-and-fuzz.md → Firmadyne emulation and AFL++ fuzzing
  ↓ Crash found
  pwn-chain/references/stack-pwn.md or heap-pwn.md → write an exploit
  ↓ Hardware validation
  attack-chain/SKILL.md → add the result to the attack chain

N-day Weaponization Path:
  patch-diff-exploit/references/patch-tuesday-workflow.md → obtain pre- and post-patch binaries
  ↓ Align symbols
  patch-diff-exploit/references/diff-tools-comparison.md → select BinDiff, ghidriff, or Diaphora
  ↓ Locate the change
  patch-diff-exploit/references/root-cause-and-poc.md → find the root cause and write a PoC
  ↓ Build the exploit
  pwn-chain/SKILL.md (stable exploit) + pentest-tools/references/msf-protocol.md (Metasploit module)

Red-Team Delivery Path:
  attack-chain/SKILL.md → select the phase
  ↓ EDR evasion is required
  edr-bypass-re/references/hook-survey.md → identify hooks in the target EDR
  ↓ Select an evasion technique
  edr-bypass-re/references/unhook-techniques.md → direct syscall or Hell's Gate
  edr-bypass-re/references/telemetry-blinding.md → ETW patch or AMSI patch
  ↓ Validate locally
  pe-sieve / API Monitor → confirm a clean unhook
  ↓ Deliver
  Return to the post-exploitation phase in attack-chain
```


## Completion self-check (MUST pass before claiming completion)

- [ ] Did I complete the three-axis route match (target type + user intent + toolchain)?
- [ ] After routing, did I read the target skill's SKILL.md?
- [ ] If no route matched, did I propose a new skill instead of forcing a match?
- [ ] Did I use real tool paths from `tool-index`?
