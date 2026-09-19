# 2026-07-20 full Windows reverse-engineering toolchain bootstrap

## Scenario

Other, toolchain and environment

## Target summary

Install and verify a reverse-engineering toolchain on a Windows 24H2 host. The toolchain covers native, managed, Android, firmware, protocol, forensics, browser, and MCP tools.

## Execution record

1. Read the shared tool index and reuse installed tools first.
2. Run the common PATH probe. Fill gaps in static, dynamic, firmware, and protocol tools.
3. For large files, extract URLs and SHA-256 values from a trusted manifest. Download directly with aria2 with IPv6 disabled.
4. Create a unified entry point for portable tools at `{user_profile}\Tools\reverse-bin`.
5. Build and register Ghidra, IDA, JS, browser-traffic, and Burp MCP tools.
6. Verify the tools with real PE, APK, .NET, PYC, WASM, and firmware fixtures. Do not run version commands only.
7. Refresh the shared tool index and output a formal installation report and flowchart.

## Pitfalls

| Problem | Cause | Resolution | Time |
|---|---|---|---|
| winget large-file download showed no progress for a long time | Delivery Optimization and the default IPv6 path were unstable | Get the official URL and hash from winget metadata. Use `aria2c --disable-ipv6=true` | High |
| anything-analyzer SQLite ABI mismatch | Ordinary `pnpm rebuild better-sqlite3` built the Node ABI, but Electron needs the Electron ABI | Use the project's `pnpm run postinstall` | Medium |
| WSL service 1053 and missing system features | The Windows image removed WSL, VirtualMachinePlatform, and Hyper-V feature packages | Record the real Linux command gaps. Use Windows-native tools and QEMU full-system instead | Medium |
| Dr. Memory version worked but injection crashed | Compatibility issue with Windows 11 24H2 build 26100 | Record the upstream issue. Use AppVerifier, PageHeap, UMDH, CDB, or Frida | Medium |
| Codex TOML would not load | An old project path contained garbled text, causing a missing quote, invalid escape, and duplicate key | Fix only the table-header syntax and validate with `codex mcp list` | Low |
| Burp MCP registered with no tools | The Burp GUI had not loaded the extension, so 9876 was not listening | Build a fixed JAR and record the GUI load condition | Low |

## Tool findings

- The common probe found 57 of 64 tools. All 7 gaps required Linux userland or kernel capabilities.
- Windows SDK Debugging Tools are important supplements when Dr. Memory is incompatible. They provide CDB, GFlags, UMDH, NTSD, and KD.
- Verify MCP tools separately for stdio/HTTP initialization and a live GUI backend. Successful registration does not mean that a tool can be called.
- IDA Free supports local interactive analysis, but it cannot replace the legal IDA Pro idalib or Hex-Rays MCP backend.

## Key code and commands

```powershell
python "{skill_root}\scripts\toolchain_probe.py" --format markdown
aria2c --disable-ipv6=true --max-connection-per-server=16 --split=16 "{official_url}"
powershell -NoProfile -ExecutionPolicy Bypass -File "{package_root}\skills\scripts\refresh-tool-index.ps1"
codex mcp list
cdb -g -G C:\Windows\System32\where.exe cmd
```

## Improvement suggestions for this package

- Add Dr. Memory, CDB, GFlags, UMDH, DTC, SquashFS, flashrom, and Frida Trace to the Windows tool-index catalog.
- Distinguish `installed`, `bridge-ready`, `backend-online`, and `runtime-verified` capability states.
- Add a clear Linux-only gap note for reduced Windows editions. Do not generate same-name wrappers that are not real tools.

## Reusable pattern

For large-file downloads, first verify the version, URL, and SHA-256 from official package metadata. Then use aria2 with IPv6 disabled. After download, verify both the hash and Authenticode when applicable.

## Follow-up actions

- [ ] Update the routing matrix
- [x] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation
- [x] Add the pitfall record
- [ ] No update needed

## Environment

- OS: Windows NT build 26100.4946, 24H2, x64
- Tool versions: see the formal local installation report and tool index
- Target platform/version: Windows-native toolchain, covering Android, Linux/ELF static analysis, and full-system emulation

## Redaction requirements

This record contains no real target, credential, token, internal URL, or username. Paths use placeholders.

## Index synchronization

The `_index.md` statistics and the "Toolchain and environment" category were updated.

---
<!-- [Community contribution] The local record is complete. -->
