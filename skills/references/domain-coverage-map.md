# Package domain coverage map (depth first)

> Compared with hundreds of community micro skills, we cover core areas with **a few deep skills + routing + ops**.  
> Date: 2026-07-18

## Domain → package entry

| Domain | PRIMARY / module | Notes |
|----|----------------|------|
| Mobile Android | `apk-reverse/` `mobile-reverse/` | |
| Mobile iOS | `mobile-reverse/` | |
| Deep binary analysis | `ida-reverse/` `radare2/` `ghidra-reverse/` | Ghidra = open-source main path |
| General RE / anti-debugging / OLLVM | `reverse-engineering/` | |
| .NET | `dotnet-reverse/` | |
| Front-end JS / signing | `js-reverse/` | |
| Browser extensions | `browser-extension-reverse/` | |
| DSL/risk-control VM | `reverse-engineering/dsl-vm-reverse/` | |
| Protocol / PCAP protocol | `protocol-reverse/` | |
| Firmware IoT | `firmware-pentest/` | |
| Malware samples | `malware-analysis/` | |
| Digital forensics / IR | `digital-forensics/` | |
| Threat hunting / blue team | `threat-hunting/` | |
| Penetration tools | `pentest-tools/` (+ src-hunter) | |
| Windows / AD | `windows-ad/` | |
| Cloud / containers / K8s | `cloud-k8s/` | |
| Code audit / SAST | `code-audit/` | |
| Wi-Fi / wireless | `wifi-wireless/` | |
| OT / ICS | `ot-ics/` | Passive first. Register writes are forbidden by default. |
| macOS | `macos-reverse/` | iOS still uses mobile-reverse |
| Binary Ninja | `binary-ninja-reverse/` | Commercial GUI/Python API. Enable community MCP only explicitly, with loopback binding by default. |
| Thick client | `thick-client/` | |
| Go / Rust binaries | `go-rust-reverse/` | |
| Hardware debug ports | `hardware-security/` | Handoff to firmware-pentest |
| Database | `database-security/` | |
| Email / phishing | `email-security/` | |
| Federated identity SSO | `identity-federation/` | Complements api-security JWT |
| RF / SDR | `radio-sdr/` | Receive only by default. Not Wi-Fi. |
| Multi-stage attack | `attack-chain/` | |
| Pwn | `pwn-chain/` | |
| N-day patches | `patch-diff-exploit/` | |
| EDR research | `edr-bypass-re/` | |
| API | `api-security/` | |
| Supply-chain SBOM | `supply-chain-security/` | |
| LLM/Agent | `llm-security/` | + `ops/skill-supply-chain.md` |
| Browser automation | `browser-automation/` | |
| Reports/diagrams | `docs-generator/` `diagram-generator/` | |
| Symbol migration | `binary-diff/` | |
| Operations contract | `ops/` | **Feature** |
| CTF coordination | `CTF-Sandbox-Orchestrator/` | |
| Cryptographic pattern recognition | `reverse-engineering` mode documentation | Shared with reverse-engineering tasks. No standalone extension package. |

## Domains not merged as full libraries

| Domain | Policy |
|----|------|
| Pure game cheat development | Not a product direction. Unity samples may still use `reverse-engineering` + seed-014 |
| Deep automotive or aviation certification | Link externally. This package has only entry-level RF/OT coverage. |
| Pure GRC/compliance long-form content | Does not replace professional GRC tools. Report templates may cite it. |
| 800+ ATT&CK micro skills | Use this map + optional ATT&CK labels (Finding field) |

## MITRE ATT&CK (optional)

The Finding template permits `optional_attack: Txxxx` (see `ops/evidence-finding-path.md`). It does **not** require a full ATT&CK engine.
