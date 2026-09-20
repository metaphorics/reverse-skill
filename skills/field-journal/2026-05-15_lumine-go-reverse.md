---
name: lumine-reverse-2026-05-15
description: Full reverse-engineering recovery of lumine v0.9.1, a Go 1.24.5 TLS-fragmenting proxy, including a source rebuild of 7 packages
metadata:
  type: project
---

# lumine v0.9.1 — Go TLS-fragmenting proxy reverse engineering

- Date: 2026-05-15
- Target: `lumine_v0.9.1_windows_amd64.exe` (PE32+, Go 1.24.5, 11.6 MB)
- Source report: `REVERSE_REPORT.md`

## Background

The user asked to recover readable Go source from the binary. The target is an anti-DPI TLS proxy derived from the Python [TlsFragment](https://github.com/maoist2009/TlsFragment) project.

## Process

1. **Toolchain setup**: Python + capstone for disassembly; GoReSym recovered the symbol table (1944 Go functions, 269 from the project)
2. **Package structure identification**: Inferred 12 packages from the GoReSym `package.function` names
3. **Type recovery**: Reconstructed the JSON deserialization types from `config.json`, then recovered fields from function references
4. **Source rebuild**: Wrote readable Go code package by package; kept the logic, not line-for-line fidelity
5. **Subpackage completion**: dial (outbound binding), errors (error types), format (string utilities)

## Key findings

- Core anti-DPI mechanism: TLS record fragmentation + noise injection + ACK wait + OOB + fake TTL
- Policy engine: domain Trie + IP Trie → policy matching
- Depends on `go-freelru` (LRU cache) for DNS/TTL caching
- Upstream repo `github.com/moi-si/lumine` returns 404; recovery relied entirely on the binary

## Tools

| Tool | Purpose | Version |
|---|---|---|
| GoReSym | Go symbol recovery | v1.7.1 (Mandiant) |
| Capstone | Disassembly engine | latest |
| pefile | PE structure parsing | latest |

## Pitfalls

1. **Python3 path**: The WindowsApps stub python3 does not support `pip install capstone`; use the full CPython path
2. **GoReSym subprocess path**: `~` is not expanded automatically; call `os.path.expanduser()`
3. **Tab/space mixing**: The generated Python disassembly script mixed tabs and spaces and corrupted the Go source formatting; v3 uses spaces everywhere
4. **Vendor-less GoReSym**: On a Go 1.24.5 binary without vendor symbols, GoReSym still extracts function names but cannot recover parameters or local variables
5. **String noise**: Go standard-library string constants are mixed into the results; filter carefully at package level

## Deliverables

- `REVERSE_REPORT.md` — full reverse-engineering report
- `reconstructed_src_v3/` — 7 Go source files: core engine + 3 subpackages
