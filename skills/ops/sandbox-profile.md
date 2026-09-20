# Optional sandbox tool profile (compared with bootstrap manifest)

> Z3r0's default image includes many tools. reverse-skill **does not bundle an image**. Use this table for coverage comparison and optional Docker guidance.

## Capabilities that reverse-skill can bootstrap

Source: `skills/scripts/bootstrap-manifest.json` (use the file as the authority):

| Capability | Typical scenario |
|------|----------|
| jadx / apktool / adb / frida / frida-ps | Android |
| r2 / rabin2 | Binary CLI |
| idalib-mcp / idapro | IDA MCP |
| jeb-pro | Commercial Android / ARM decompiler (manual license install) |
| jshookmcp / reqable-mcp / anything-analyzer / agent-browser | Web/JS/packet capture/browser |
| ghidra-mcp | Ghidra |
| nmap / seclists / proxycat / burpsuite-mcp / pentestswarm | Penetration testing |
| binwalk / pwntools / yara | Firmware/pwn/malware |

```powershell
powershell -File skills\scripts\bootstrap-reverse.ps1 -Capability @('jadx','nmap','yara') -StartServices
powershell -File skills\scripts\refresh-tool-index.ps1
```

## Common Z3r0 sandbox tools that this manifest does not install automatically

| Tool | reverse-skill policy |
|------|-------------------|
| subfinder / amass / httpx / ffuf / nuclei / sqlmap | Documentation install / Kali script / external MCP; **do not claim bootstrap includes them** |
| Full Ghidra GUI | ghidra-mcp capability + manual plugin steps |
| gdb / pwndbg | Manual platform documentation; pwntools can bootstrap |
| hydra / hashcat | Manual or Kali |
| JEB Pro | Manual install after the user has a license; review the supply chain before using a third-party MCP bridge |
| Reqable desktop client | User installs it manually; `reqable-mcp` records only the official fixed-version MCP runtime |
| SecLists | seclists capability |

## Optional lightweight Docker operations profile

Use only when the user **has** Docker and an authorized lab:

```text
Minimal: nmap + nuclei + sqlmap container or pentestMCP image
Mobile: jadx + apktool + frida on the host
Reverse engineering: IDA/r2 on the host + tool-index
```

**MUST NOT** require the user to install Z3r0 to use reverse-skill.

## network_profile relation

Sandbox scans still follow the case `scope.md` `network_profile`:

- `offline` → Do not recommend external scanning containers  
- `authorized_target_only` → Containers may target only in_scope  
