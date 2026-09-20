# Automatic Routing Rules for Reverse Engineering, Penetration Testing, and Security Tasks (Kali Linux)

> **This file is the Kali path adapter, not a second behavior chain.** Behavior and authorization follow the repository root `RULES.md`.
> The core knowledge base (`skills/config/routing.json`, SKILL.md, and references) is shared with the Windows version.
> **Do not write this file to `~/.claude/CLAUDE.md` or any other client-wide configuration.** Core scripts must not write client-wide files.

Hot path (same as `RULES.md`): `skills/scripts/master-route.sh` → `case-init.sh` (do not ACT on a target before `auth.status=granted`) → PRIMARY `SKILL.md`. Identity: `skills/ops/IDENTITY.md`. Scripts use `kali/scripts/*.sh` in this directory.

---

## Trigger keywords (identical to the Windows version)

- APK, Android reverse engineering, decompilation, smali, jadx, apktool, Frida, Hook
- Binary analysis, IDA, radare2, r2, disassembly, reverse engineering, RE, source recovery, reverse recovery
- Front-end signatures, encrypted parameters, JavaScript reverse engineering, jshookmcp, CDP, SourceMap
- Packet capture, HTTP capture, request replay, anything-analyzer
- CTF, Pwn, web penetration testing, exploitation, privilege escalation
- MCP reverse-engineering tools, idalib-mcp
- Repackaging, signing, certificate validation, root detection, anti-debugging
- so analysis, native hook, JNI
- Penetration testing, red team, security assessment, blue team, incident response
- Write reports, write documentation, produce reports, writeup, technical documentation, penetration testing reports, reverse-engineering reports
- Browser automation, open webpages, fill forms, crawling, screenshots, automated login, Playwright, agent-browser, headless
- Symbol migration, bindiff, cross-version work, missing PDB, function-offset migration, version comparison, old-version symbols
- N-day, Nday, patch diff, Patch Tuesday, 1day, CVE reproduction, vulnerability reconstruction, ghidriff, Diaphora, DeepDiff, patch analysis
- pwn, stack overflow, heap overflow, ROP, ret2libc, ret2csu, one_gadget, libc-database, tcache, fastbin, kernel pwn, SMEP, SMAP, KASLR, modprobe_path, commit_creds, pwntools, GEF, pwndbg
- Firmware, IoT, binwalk, unblob, squashfs, UBI, JFFS2, Firmadyne, FAT, full-system QEMU emulation, EMBA, firmware penetration testing, router firmware, embedded exploitation, AFL++, boofuzz, UART, JTAG
- BurpSuite, Burp MCP, Intruder, Repeater, Collaborator, proxy-history analysis
- LLM security, AI security testing, prompt injection, jailbreak, Agent security, garak, PyRIT
- API security testing, GraphQL security, JWT attacks, supply-chain security, SBOM, Trivy
- iOS reverse engineering, Objection, YARA, yara-x, capa, malware analysis, AI decompilation, LLM4Decompile
- Agent does not work, AI is lazy, skipped steps, prompt engineering, Agent obedience
- EDR bypass, AV bypass, AV/EDR evasion, unhook, direct syscall, indirect syscall, Hell's Gate, SysWhispers, ETW patch, AMSI patch, call stack spoofing, MITRE T1562, CrowdStrike bypass, Defender bypass, SentinelOne bypass, pe-sieve
- Port scanning, Nmap, vulnerability scanning, Nuclei, SQL injection, SQLMap, directory brute force, FFUF, password cracking, Hashcat, Hydra, Metasploit, Impacket, pentestMCP
- SRC, Bug Bounty, crowdsourced testing, vulnerability bounty, HackerOne, WAF bypass, bypass WAF, IDOR, broken access control, arbitrary accounts
- Drawing, flowcharts, architecture diagrams, attack-path diagrams, sequence diagrams, state diagrams, data-flow diagrams, Mermaid, Graphviz, PlantUML, diagram
- Malware analysis, virus analysis, sample analysis, sandbox, YARA, yara-x, capa, IOC
- Kernel drivers, Rootkit, LKM, IOCTL, DeviceIoControl
- Cryptography, encryption and decryption, AES, RSA, hash collisions, signature verification
- Protocol reverse engineering, custom protocols, Protobuf, serialization
- Firmware reverse engineering, IoT, binwalk, ARM, MIPS, embedded systems
- WASM, WebAssembly, wabt, wasm-decompile, Python bytecode, pyc, .NET, dnSpy, IL
- macOS, iOS, Mach-O, ObjC, Swift, Frida iOS
- Go reverse engineering, Rust reverse engineering, stripped binary, GoReSym, redress, goretk, pclntab, Ghidra, PyGhidra
- Memory dump, forensics, forensic, steganography
- Cloud security, container escape, K8s, Docker, AWS, Azure
- Prompt injection, AI security, Agent security, LLM attacks
- Internal-network penetration, lateral movement, Pass-the-Hash, domain penetration, AD attacks, BloodHound
- Privilege escalation, SUID, Potato, UAC bypass
- Credential extraction, Mimikatz, Kerberoasting, DCSync, LSASS
- C2, remote access, persistence, backdoor, Cobalt Strike, reverse shell
- Blue team, detection, defense, incident response, SIEM, EDR, threat hunting, IOC
- Mobile security testing, OWASP MASTG, app security, unpacking, packer-protection analysis
- SSTI, template injection, SSTImap, XSS, XSStrike, cross-site scripting
- WordPress, WPScan, WPProbe, CMS penetration testing
- AdaptixC2, C2 framework, adversary emulation, red-team emulation, Atomic Red Team
- WiFi attacks, wireless penetration testing, Fluxion, aircrack-ng, deauth
- NTLM relay, Coercer, forced authentication, PetitPotam
- WinRM, evil-winrm, Windows remote command execution
- NetExec, nxc, CrackMapExec, SMB enumeration
- AI automated penetration testing, HexStrike, MetasploitMCP, mcp-kali-server
- Pentest Swarm, pentestswarm, swarm penetration testing, Swarm AI, autonomous scanning, stigmergy
- Bug Bounty automation, attack-surface management, ASM, continuous monitoring
- GEF, GDB enhancement, debugging framework
- Wireshark, tshark, PCAP analysis, packet-capture analysis
- BurpSuite, Web proxy, intercept requests, Intruder
- Responder, LLMNR poisoning, NBT-NS, MDNS
- BloodHound, AD paths, attack graphs, SharpHound
- Certipy, AD CS, certificate attacks, ESC1, ESC8
- wfuzz, parameter fuzzing, Web Fuzz
- objdump, strings, file, static analysis
- ProxyCat, proxy pool, IP rotation
- Red team, HW, adversary exercises, initial access, perimeter breach
- Full penetration testing, end-to-end penetration testing, external-to-internal penetration, external-to-domain-controller penetration
- Attack-surface assessment, attack-path planning, attack chain, kill chain
- What to do after obtaining a shell, post-exploitation, foothold expansion, deep penetration
- Near-source penetration, BadUSB, Rubber Ducky, WiFi Pineapple, Proxmark3, RFID cloning
- EDR bypass, AV/EDR evasion, AV bypass, shellcode loader, fileless attack
- Phishing email, social engineering, OAuth phishing, HTML smuggling
- Supply-chain attack, component poisoning, third-party penetration testing
- Trace cleanup, anti-forensics, log deletion, timestamp modification
- Cobalt Strike, Sliver, Havoc, Mythic, C2 framework

---

## Routing entry point

> **Detection method:** Find the parent directory of the directory that contains this file (`RULES-kali.md`) to get the package root.

Hot path (same as `RULES.md` / `routing.json`):

1. `skills/scripts/master-route.sh -Hint "<task>"` — PRIMARY
2. `skills/scripts/case-init.sh` — `scope.md`; do not ACT on a target before `auth.status=granted`
3. PRIMARY `SKILL.md` ACTION REQUIRED
4. `skills/tool-index.md` — real paths; if missing, run `kali/scripts/bootstrap-reverse.sh`

---

## Execution principles (same as the Windows version, with different commands)

### Tool use
- **Never guess a tool path.** Read `tool-index.md` first.
- If a tool is missing, call `bootstrap-reverse.sh` to install it.
- Kali has many tools preinstalled, so bootstrap fails less often than on Windows.
- After automatic installation of the same tool fails twice, stop retrying and output manual steps.
- If an MCP service port differs, ask the user for the actual port and help update the configuration.

### Routing decisions
- If no route matches, do not force the task into an existing skill. Propose a new skill.
- If one route fails, switch routes: use dynamic analysis when static analysis fails, inspect the so when the Java layer fails, and use r2 when IDA fails.
- For cross-module tasks, combine multiple skills according to the "path intersection" section in `routing.md`.

### Reuse of experience
- **Always check** `field-journal/_index.md` before entering a route.
- When similar experience exists, read the related log first and reuse the verified approach.
- If a historical approach does not apply, explain why in the new log.

### Security boundaries
- Perform all operations within the user's authorization.
- Confirm legal authorization for penetration testing (SRC, Bug Bounty, owned systems, or CTF).
- Do not expand the attack surface or exceed the target scope set by the user.
- Tell the user immediately when you find a high-risk vulnerability. Wait for instructions before continuing.
- Do not retain sensitive information without redaction in reports or logs.

### Output quality
- Give a reproducible command for each key operation. Do not only describe the steps.
- Mark the address, offset, and function name in reverse-engineering analysis. Do not write only "some function."
- Give a complete PoC for penetration testing (curl command, script, or screenshot path).
- Mark uncertain conclusions with a confidence level.

---

## Complete behavior chain

```
1. Identify the task as a security or reverse-engineering task
2. package root = parent directory of this file
3. master-route.sh → PRIMARY (routing.json)
4. case-init.sh / scope.md — do not ACT on a target before auth.status=granted
5. Open PRIMARY SKILL.md
6. Missing tool → kali/scripts/bootstrap-reverse.sh
7. Do not write to client-wide configuration
```

---

## Bootstrap command (Kali version)

```bash
bash "<package root>/kali/scripts/bootstrap-reverse.sh" <capability1> [capability2] ... [--start-services]
```

### Common combinations

```bash
# Install all native Kali MCP services in one command (recommended for first use)
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai

# Install all new 2026.1 tools
bash kali/scripts/bootstrap-reverse.sh adaptixc2 atomic-operator sstimap xsstrike wpprobe fluxion gef

# AD/internal-network penetration toolchain
bash kali/scripts/bootstrap-reverse.sh coercer evil-winrm-py netexec responder bloodhound certipy

# Reverse-engineering toolchain
bash kali/scripts/bootstrap-reverse.sh jadx frida gef ghidra-mcp

# Web penetration-testing toolchain
bash kali/scripts/bootstrap-reverse.sh sstimap xsstrike wpprobe nuclei
```

Supported capability names: jadx, apktool, frida, idalib-mcp, jshookmcp, xquik-mcp, anything-analyzer, idapro, r2, rabin2, adb, agent-browser, ghidra-mcp, nmap, sqlmap, hashcat, hydra, gobuster, ffuf, msfconsole, nuclei, seclists, proxycat, mcp-kali-server, metasploitmcp, hexstrike-ai, pentestswarm, adaptixc2, atomic-operator, sstimap, xsstrike, wpprobe, fluxion, gef, evil-winrm-py, coercer, netexec, responder, crackmapexec, bloodhound, certipy, wfuzz, aircrack-ng, redress, goresym, capa, yara-x, unblob, wabt, objection
Unblob is registered and auto-installable. EMBA and other capabilities absent from the manifest MUST use manual installation steps. Do not pretend bootstrap supports them.

## Refresh the tool index

```bash
bash "<package root>/kali/scripts/refresh-tool-index.sh"
```

---

## MCP service management

### Native Kali MCP services (install with apt, no extra configuration)

| Service | Package | Port | Purpose | Start command |
|------|------|------|------|---------|
| mcp-kali-server | mcp-kali-server | 5000 | Official Kali MCP. AI calls terminal tools directly. | `kali-server-mcp --port 5000` |
| MetasploitMCP | metasploitmcp | 8085/stdio | Metasploit Framework MCP interface | `metasploitmcp --transport stdio` |
| HexStrike AI | hexstrike-ai | — | MCP automation platform for 150+ security tools | `hexstrike-ai` |

### Third-party MCP services

| Service | Port | Purpose | Start command |
|------|------|------|---------|
| Pentest Swarm AI | stdio | Autonomous swarm penetration testing (recon→classify→exploit→report) | `pentestswarm mcp serve` |
| idapro | 13337-13350 | IDA Pro reverse-engineering tools | `bash kali/scripts/ida-start.sh` |
| anything-analyzer | 23816 | Browser automation and HTTP capture | `cd ~/tools/anything-analyzer && pnpm dev` |
| jshookmcp | — | JS Hook/CDP/Network/AST | `npx -y @jshookmcp/jshook@0.3.5` (stdio) |
| ghidra | tool-index | Ghidra decompilation | Install Ghidra via bootstrap; community bridges need supply-chain review; confirm the port from tool-index |
| burpsuite | 9876 | BurpSuite Web proxy | Start the BurpSuite extension |

### Recommended MCP priority (Kali 2026.1)

For penetration-testing scenarios, use this MCP priority order:

1. **pentestswarm** — Fully automated swarm penetration testing for large targets (1000+ subdomains) and continuous Bug Bounty monitoring
2. **mcp-kali-server** — Most general. It can call any terminal tool on Kali.
3. **metasploitmcp** — Metasploit-specific exploit, payload, and session management
4. **hexstrike-ai** — Automation coordination for multi-tool workflows
5. **jshookmcp** — Dedicated to Web and JavaScript reverse engineering

Install all penetration-testing MCP services in one command:
```bash
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai pentestswarm
```

---

## Error handling strategy

| Scenario | AI action |
|------|-------------|
| Bootstrap succeeds | Continue the task |
| `apt install` fails | Check the network and sources, run `apt update`, and retry once |
| `pip install` fails | Add `--break-system-packages`, or recommend a venv |
| GitHub download fails | Check the network and proxy, then provide a manual download link |
| Service port differs | Ask for the actual port and help update the MCP configuration |
| The same tool fails twice | Give complete manual steps and do not retry |

---

## Kali-specific advantages

AI should know the following about the Kali 2026.1 environment:

1. **Many tools are preinstalled** — nmap/sqlmap/hashcat/hydra/metasploit/gobuster/ffuf/radare2/binwalk/burpsuite/wireshark/nikto/impacket/netexec/responder/bloodhound do not need installation.
2. **Native MCP support** — `mcp-kali-server`, `metasploitmcp`, and `hexstrike-ai` are in the official Kali repository. Install them with `apt install`.
3. **New tools in 2026.1** — AdaptixC2 (C2 framework), Atomic-Operator (red-team testing), SSTImap (SSTI detection), XSStrike (XSS scanning), WPProbe (WordPress enumeration), Fluxion (WiFi social engineering), and GEF (GDB enhancement).
4. **New tools in 2025.4** — evil-winrm-py (WinRM remote execution), hexstrike-ai (AI security automation), and bpf-linker.
5. **Kernel 6.18** — Supports recent hardware and the NetHunter wireless-injection patch (QCACLD-3.0).
6. **Full Wayland support** — GNOME 49 and KDE Plasma 6.5 also support Wayland in VMs.
7. **Rich apt sources** — Install `ghidra`, `seclists`, and `coercer` with one `apt install` command each.
8. **Complete Python environment** — python3 and pip3 are preinstalled. Install frida-tools directly with pip.
9. **No permission limits** — The default is root or passwordless sudo.
10. **Complete network tools** — nc/curl/wget/socat/proxychains/chisel and other tools are preinstalled.
11. **SecLists path** — apt installs it at `/usr/share/seclists/`.
12. **Wordlists** — Common lists such as rockyou are under `/usr/share/wordlists/`.
13. **LLM integration** — The official Kali blog has a guide for local LLM integration with Claude Desktop, Ollama, and 5ire.
14. **BackTrack mode** — `kali-undercover --backtrack` switches to the classic BackTrack 5 appearance for social-engineering scenarios.

---

## Prohibited behavior (same as the Windows version)

- ❌ Do not start reverse-engineering or penetration-testing operations before reading `routing.md`.
- ❌ Do not guess tool paths. Get them from `tool-index`.
- ❌ Do not start a task before checking `field-journal`.
- ❌ Do not skip the Checklist after completing a task.
- ❌ Do not retain real target information without redaction in reports.
- ❌ Do not expand the penetration-testing scope without user authorization.
- ❌ Do not repeatedly retry an automatic installation that has already failed twice.
- ❌ Do not stay silent. Tell the user immediately when a problem occurs.
- ❌ Do not invent tool versions or feature descriptions.

---

## Mandatory checklist after task completion (do not skip)

After the task ends (the vulnerability is verified, reverse engineering is complete, or the flag is obtained), AI **must** complete each item:

```text
□ 1. Generate the formal report (docs-generator skill)
     - Use the correct template (reverse-engineering report / penetration-testing report / CTF writeup / signature report)
     - Include the target overview, complete steps, key evidence, and reproduction commands
     - Output to the user's project directory, not inside the skill package

□ 2. Generate a diagram (diagram-generator skill)
     - Embed at least one flowchart in the report
     - Select the type: penetration testing → attack-path diagram / reverse engineering → call-relationship diagram / JavaScript → sequence diagram / CTF → solution flowchart

□ 3. Write back to field-journal (with redaction)
     - Follow the format in field-journal/_template.md
     - Include lessons learned, reusable patterns, toolchain findings, and environment information
     - Check redaction: no real domain, IP, token, or username

□ 4. Record knowledge found through search (if this task used online search)
     - Write useful findings to the related skill's references/
     - Record the source URL and date
     - If you find a new tool → update bootstrap-manifest.json
     - If you find a new scenario → update routing.md and the RULES-kali.md keywords

□ 5. Ask about a community contribution
     - "Would you like to contribute this experience to the community repository? The data is redacted. Only the field-journal file will be submitted."
     - User agrees → create a PR according to the CONTRIBUTE-BACK.md process
     - User declines → skip this step

□ 6. Update the system index
     - Update field-journal/_index.md with the new entry
     - Check whether routing.md, bootstrap-manifest, or tool-index needs an update
     - If you find a new tool or scenario → perform the related update
```

If AI does not complete this checklist after the task, the user can say: "You forgot to write the report and record the experience." AI must complete it immediately.

---

## Multiple tasks and interruptions

- If the user changes topics during a task, first save the current progress to field-journal and mark it "incomplete".
- When the user returns, restore the context from field-journal.
- If the user gives multiple security tasks, execute them one at a time by priority. Do not run them in parallel to avoid tool conflicts.
- For long tasks such as large-file IDA analysis, report progress regularly so the user does not think the task is stalled.

---

## Online knowledge supplement (required when search is available)

When AI has online search access, it **must** search proactively in these cases:

| Scenario | Search for | After the search |
|------|---------|-------------|
| Unknown packer, protection, or obfuscation | Search for unpacking methods and tools for the packer | Write the method to the related skill's references/ |
| Unknown framework or protocol | Search for reverse-engineering or penetration methods for the framework | Write the method to references/ or propose a new skill |
| Tool error or incompatibility | Search for the error message and version compatibility | Record the issue in field-journal |
| New CVE or vulnerability | Search for a PoC and exploitation method | Write it to pentest-tools/references/ |
| No route matches a new scenario | Search for methods and tools in that field | Propose a new skill and include the sources |
| A specific Frida script is needed | Search for an existing script on GitHub or CodeShare | Write it to apk-reverse/references/ or use it directly |
| A specific payload is needed | Search PayloadsAllTheThings or HackTricks | Write it to pentest-tools/payloads/ |
| A tool version is outdated | Search for the latest version and breaking changes | Update the bootstrap manifest and documentation |

### Knowledge retention process after a search

```text
1. Search for information
2. Verify information reliability (official documentation > GitHub > blogs > forums)
3. Extract actionable content (commands / scripts / configuration / steps)
4. Write it to the related location in this package:
   - General methodology → references/*.md in the related skill
   - Specific tool use → references/ or SKILL.md in the related skill
   - Lessons learned → field-journal/
   - New tool discovery → kali/scripts/bootstrap-manifest.json + tool-discovery.sh
   - New scenario discovery → routing.md + RULES-kali.md keywords
5. Record the source (URL + date) so its currency can be checked later
6. If the information is large enough to define a new field, propose a separate skill
```

### Search quality requirements

- **Do not give the user only one link after a search.** Extract the key content and write it to this package.
- **Do not trust search results blindly.** Compare them with official documentation and mark confidence.
- **Prefer Chinese-language resources** when the user communicates in Chinese, but use English official documentation for technical details.
- **Mark currency.** Security information changes quickly. Record the search date and mark old content `[possibly outdated]`.

---

## New skills

When the routing matrix cannot cover a task type, add a skill according to `CONTRIBUTING.md`.

Path: `<package root>/skills/CONTRIBUTING.md`

After adding a skill, also update: routing.md, kali/scripts/bootstrap-manifest.json, kali/scripts/lib/tool-discovery.sh, and kali/scripts/refresh-tool-index.sh.
