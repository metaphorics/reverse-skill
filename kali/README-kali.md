# Cybersecurity Skills Router — Kali Linux edition

> This directory is the optimized Kali Linux 2026.1 adapter. It targets Kali 2026.1, released in March 2026, with kernel 6.18.
> The core knowledge base (`skills/`, `CTF-Sandbox-Orchestrator/`) is shared with the Windows version. The Kali README and Bash entry points must cover the Windows capability names and add native Kali tools and MCP capabilities.
> The root [README-kali.md](../README-kali.md) is only a short redirect. **This file is authoritative.**

---

## AI: execute after reading

```text
1. Detect the package root (the repository root that contains skills/ and kali/)
2. Read kali/RULES-kali.md → global injection and tool scan
3. bash kali/scripts/refresh-tool-index.sh
4. Use the shared operational chain:
   - skills/MASTER-ROUTING.md (or pwsh skills/scripts/master-route.ps1)
   - skills/scripts/case-init.ps1 → work/<case>/scope.md
   - ACT on a target only after auth.status=granted + network_profile
   - skills/ops/ (evidence chain / roles / timeline / IDENTITY)
5. Report the configuration result to the user
```

For general Agent guidance, read the repository root [README_AI.md](../README_AI.md) when Kali is detected.

---

## 0. Relationship to the Windows version (capability-name alignment)

```text
Project root/
├── skills/                    # Shared: SKILL, routing, MASTER-ROUTING, ops, scripts, field-journal
├── CTF-Sandbox-Orchestrator/  # Shared: 40+ CTF subskills
├── kali/                      # ← You are here
│   ├── scripts/
│   │   ├── bootstrap-reverse.sh
│   │   ├── refresh-tool-index.sh
│   │   ├── bootstrap-manifest.json
│   │   └── lib/
│   │       └── tool-discovery.sh
│   ├── RULES-kali.md
│   └── README-kali.md
├── RULES.md                   # Windows rules
└── Readme.md                  # Windows instructions
```


### 0.1 Alignment principles

The Kali-specific entry point is not a simple copy of the Windows README. It uses **the same core capability names plus Kali capabilities**:

- Windows: `skills/scripts/bootstrap-reverse.ps1`
- Kali: `kali/scripts/bootstrap-reverse.sh`
- Standard Linux/macOS: `skills/scripts/bootstrap-reverse.sh`

JEB Pro is a commercial tool that users license and install themselves. Reqable MCP uses the fixed official `reqable-mcp-server` version and still requires a separate Reqable desktop client installation.

Kali scripts should cover the core capability names in the Windows manifest, such as `jadx`, `apktool`, `frida`, `jshookmcp`, `xquik-mcp`, `anything-analyzer`, `idapro`, `r2`, `adb`, `ghidra-mcp`, `seclists`, `burpsuite-mcp`, `nmap`, and `pentestswarm`. They can also support native Kali tools such as `mcp-kali-server`, `metasploitmcp`, `hexstrike-ai`, `sstimap`, `xsstrike`, and `netexec`.

**Shared parts** (no changes needed):
- All `SKILL.md`, `routing.md`, and `MASTER-ROUTING.md` files
- The `skills/ops/` operational contract (scope / evidence chain / roles / timeline)
- All `references/` knowledge bases
- The `field-journal/` self-improvement mechanism
- All of `CTF-Sandbox-Orchestrator/`
- `docs-generator/` and `diagram-generator/`
- `skills/scripts/case-init.ps1` and `master-route.ps1` (can be called with pwsh)

**Kali-specific parts**:
- All scripts use Bash (`.sh`).
- Package management uses `apt`.
- Paths follow Linux conventions (`/opt/`, `~/tools/`, `/usr/bin/`).
- Kali preinstalls many tools, so the bootstrap logic is much simpler.

---

## 1. Native Kali advantages

The following tools are available in Kali 2026.1 without bootstrap:

### Classic preinstalled tools

| Tool | Kali package | Status |
|------|----------|------|
| nmap | nmap | Preinstalled |
| sqlmap | sqlmap | Preinstalled |
| hashcat | hashcat | Preinstalled |
| john | john | Preinstalled |
| hydra | hydra | Preinstalled |
| metasploit | metasploit-framework | Preinstalled |
| gobuster | gobuster | Preinstalled |
| ffuf | ffuf | Preinstalled |
| radare2 | radare2 | Preinstalled |
| binwalk | binwalk | Preinstalled |
| frida | python3-frida-tools | Preinstalled or pip |
| burpsuite | burpsuite | Preinstalled |
| wireshark | wireshark | Preinstalled |
| nikto | nikto | Preinstalled |
| wfuzz | wfuzz | Preinstalled |
| impacket | impacket-scripts | Preinstalled |
| netexec | netexec | Preinstalled |
| responder | responder | Preinstalled |
| aircrack-ng | aircrack-ng | Preinstalled |
| bloodhound | bloodhound | Available through apt |
| ghidra | ghidra | Available through apt |

### New tools in Kali 2026.1 (March 2026)

| Tool | Package | Purpose |
|------|------|------|
| AdaptixC2 | adaptixc2 | Post-exploitation and adversary-emulation framework |
| Atomic-Operator | atomic-operator | Cross-platform Atomic Red Team test execution |
| Fluxion | fluxion | WiFi security auditing and social engineering |
| GEF | gef | Modern GDB debugging framework |
| MetasploitMCP | metasploitmcp | Metasploit MCP server interface |
| SSTImap | sstimap | Automatic server-side template injection detection and exploitation |
| WPProbe | wpprobe | Fast WordPress plugin enumeration |
| XSStrike | xsstrike | Advanced XSS scanner |

### New tools in Kali 2025.4 (December 2025)

| Tool | Package | Purpose |
|------|------|------|
| evil-winrm-py | evil-winrm-py | Python WinRM remote command execution |
| hexstrike-ai | hexstrike-ai | AI MCP security automation platform (150+ tools) |
| bpf-linker | bpf-linker | BPF static linker |

### Native Kali MCP tools (priority)

| Tool | Package | Purpose | Installation |
|------|------|------|------|
| mcp-kali-server | mcp-kali-server | Official Kali MCP. AI calls terminal tools directly. | `apt install mcp-kali-server` |
| MetasploitMCP | metasploitmcp | Metasploit MCP interface | `apt install metasploitmcp` |
| HexStrike AI | hexstrike-ai | MCP automation for 150+ security tools | `apt install hexstrike-ai` |

> **This is the main advantage of the Kali version over the Windows version:** install the three MCP tools directly with apt. No manual GitHub, npm, or Docker setup is needed.

Therefore, `bootstrap-reverse.sh` requires much less work on Kali than on Windows.

---

## 2. Quick start

### 2.0 One-command initialization (recommended for new systems)

```bash
# Configure a new Kali 2026.1 system with one command (requires root)
sudo bash kali/scripts/quick-setup.sh

# Skip system updates when the network is slow
sudo bash kali/scripts/quick-setup.sh --skip-update

# Minimal installation (do not install AD/internal-network tools)
sudo bash kali/scripts/quick-setup.sh --minimal
```

This script updates the system, installs new 2026.1 tools, configures native MCP, installs reverse-engineering tools, refreshes the index, and outputs a report.

### 2.1 First setup

```bash
# 1. Enter the project root
cd /path/to/cybersecurity-skills-router

# 2. Make the scripts executable
chmod +x kali/scripts/*.sh kali/scripts/lib/*.sh

# 3. Refresh the tool index (check local tool status)
bash kali/scripts/refresh-tool-index.sh

# 4. View the result
cat skills/tool-index.md
```

### 2.2 Install all native Kali MCP (strongly recommended)

```bash
# Install the three official Kali MCP tools
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai

# The MCP configuration is written automatically to ~/.claude/mcp.json after installation
# If you use Kiro, copy it manually to ~/.kiro/settings/mcp.json
```

### 2.3 Install new 2026.1 tools

```bash
# Install all new tools in one command
bash kali/scripts/bootstrap-reverse.sh adaptixc2 atomic-operator sstimap xsstrike wpprobe fluxion gef

# AD/internal-network penetration suite
bash kali/scripts/bootstrap-reverse.sh coercer evil-winrm-py netexec responder bloodhound certipy
```

### 2.4 Install missing tools

```bash
# Install one tool
bash kali/scripts/bootstrap-reverse.sh jadx

# Install several tools
bash kali/scripts/bootstrap-reverse.sh jadx apktool frida jshookmcp

# Install and start services
bash kali/scripts/bootstrap-reverse.sh idapro --start-services
```

### 2.5 Enable automatic routing in an AI client

Tell your AI client to read `kali/RULES-kali.md`. It will perform global injection automatically.

---

## 3. Path conventions

| Use | Kali path |
|------|----------|
| Tool installation directory | `~/tools/` or `/opt/` |
| jadx | `/opt/jadx/` or `~/tools/jadx/` |
| apktool | `/usr/local/bin/apktool` (apt) or `~/tools/apktool/` |
| Ghidra | `/opt/ghidra/` or `~/tools/ghidra/` |
| IDA Pro | `/opt/idapro/` (if a Linux version is available) |
| Android SDK | `~/Android/Sdk/` |
| SecLists | `/usr/share/seclists/` (apt) or `~/tools/SecLists/` |
| Node.js | `/usr/bin/node` (apt/nvm) |
| Python | `/usr/bin/python3` (system-provided) |
| MCP configuration | `~/.claude/mcp.json` or `~/.kiro/settings/mcp.json` |

---

## 4. Summary of differences from the Windows version

| Dimension | Windows version | Kali version |
|------|-----------|---------|
| Script language | PowerShell (.ps1) | Bash (.sh) |
| Package management | winget / GitHub Release ZIP | apt / pip / npm / GitHub Release tar.gz |
| Path separator | `\` | `/` |
| Environment variable | `%USERPROFILE%` | `$HOME` |
| Preinstalled tools | Almost none | Many security tools are preinstalled |
| IDA startup | `start.ps1` | Start the Linux IDA version manually. The script only registers or checks MCP unless the host has its own launcher. |
| MCP configuration path | `%USERPROFILE%\.claude\mcp.json` | `~/.claude/mcp.json` |
| Port detection | `TcpClient` | `nc -z` or `ss` |

---

## 5. Verification checklist

```bash
# --- Basic commands ---
java -version
python3 --version
pip3 --version
node -v
npx -v

# --- Reverse-engineering tools ---
jadx --version
apktool --version
adb version
frida --version
r2 -v
gdb --version          # GEF loads automatically

# --- Penetration-testing tools (preinstalled on Kali) ---
nmap --version
sqlmap --version
hashcat --version
hydra -h | head -1
msfconsole --version
gobuster version
ffuf -V
nuclei -version

# --- New Kali 2026.1 tools ---
sstimap -h 2>&1 | head -3
xsstrike -h 2>&1 | head -3
wpprobe --help 2>&1 | head -3
coercer -h 2>&1 | head -3
evil-winrm-py -h 2>&1 | head -3

# --- AD/internal-network tools ---
netexec --help 2>&1 | head -3
responder -h 2>&1 | head -3
certipy --version 2>&1 | head -1

# --- Native Kali MCP ---
which kali-server-mcp && echo "mcp-kali-server OK"
which metasploitmcp && echo "metasploitmcp OK"
which hexstrike-ai && echo "hexstrike-ai OK"

# --- Refresh tool index ---
bash kali/scripts/refresh-tool-index.sh

# --- Check MCP services (if configured) ---
nc -z 127.0.0.1 5000 && echo "mcp-kali-server OK" || echo "mcp-kali-server offline"
nc -z 127.0.0.1 8085 && echo "metasploitmcp OK" || echo "metasploitmcp offline"
nc -z 127.0.0.1 13337 && echo "IDA MCP OK" || echo "IDA MCP offline"
nc -z 127.0.0.1 23816 && echo "anything-analyzer OK" || echo "anything-analyzer offline"
```

---

## 6. Frequently asked questions

### Q: What if the radare2 version included with Kali is too old?

```bash
# Install the latest version from the official source
bash kali/scripts/bootstrap-reverse.sh r2
# The Kali version uses apt to install or complete radare2 by default. For the latest version, follow the platform documentation and use GitHub/source when needed.
```

### Q: Can I use this with Parrot OS or BlackArch?

Yes. The script checks whether commands exist and does not bind to a specific distribution. Automatic installation through `apt` may need to change to `pacman` on BlackArch.

### Q: How do I configure the Linux version of IDA Pro?

Install IDA at `/opt/idapro/`, then edit the `startScript` path for `idapro` in `kali/scripts/bootstrap-manifest.json`.

### Q: Can I use this system on both Windows and Kali?

Yes. The `skills/` directory syncs through Git, and the `field-journal/` experience is shared between both systems. Run `skills/scripts/*.ps1` on Windows and `kali/scripts/*.sh` on Kali.

