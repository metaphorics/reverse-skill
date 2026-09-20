---
name: ghidra-reverse
description: Use for free/open reverse engineering with Ghidra (headless or GUI), including decompile, cross-refs, and optional Ghidra MCP workflows when IDA is unavailable.
---

# Ghidra Reverse Engineering

## ACTION REQUIRED (Execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Confirm that **Ghidra** is required (no IDA / prefer open source / batch headless)
3. `NEXT`: Read `../tool-index.md` to find the ghidra / ghidra-mcp paths
4. `NEXT`: Missing tool → bootstrap `ghidra-mcp` (if the manifest supports it) or install Ghidra by following the manual steps
5. `ACT`: Import the sample → run automatic analysis → export key function decompilation

## Applicable Scenarios

- Main reverse engineering entry point when no IDA license is available
- Batch headless analysis / decompilation in CI
- Automation with PyGhidra scripts (Python 3; Jython is legacy, do not start new scripts on it)
- Integration with ghidriff from `binary-diff` / `patch-diff-exploit`

## Division of Work with IDA

| Requirement | Priority |
|------|------|
| Existing IDA MCP deep analysis | `ida-reverse/` |
| Open source / batch / training | **this skill** |
| CLI-only quick reconnaissance | `radare2/` |

## Workflow

### 1. Project and Automatic Analysis

```text
□ Create a new Project → Import the file → Analyze (default analyzer)
□ Record the language/compiler identification results and base address
□ Mark the entry point, export table, and string xrefs
```

### 2. Key Functions

```text
□ Trace back from strings / imported APIs
□ Use the Decompile window to reconstruct the algorithm
□ Rename functions/variables; write a Plate comment
□ Hand off to Frida/GDB when dynamic analysis is needed (reverse-engineering dynamic chapter)
```

### 3. Headless (Batch)

```bash
# Example: the analyzeHeadless path varies by installation; MUST get it from tool-index
analyzeHeadless /path/to/project Proj -import sample.bin -postScript ExportDecomp.py
```

### 4. MCP (If Configured)

```text
□ Confirm the ghidra MCP port from tool-index; do not assume a default port
□ Use MCP tools to retrieve decompilation / xrefs; do not guess the port
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|------|------|
| Ghidra 12.1.3 (current PUBLIC; requires 64-bit JDK 21) | Main decompilation tool | Manual release / package manager |
| PyGhidra (bundled with Ghidra) | Python 3 automation via support/pyghidraRun | Ships under Ghidra/Features/PyGhidra; install the wheel from pypkg/dist, never PyPI |
| ghidra-mcp | AI bridge | bootstrap capability name `ghidra-mcp` |
| ghidriff | patch diff | See `patch-diff-exploit` |

## References

- `references/ghidra-cheatsheet.md`
- `../ida-reverse/` `../radare2/` `../binary-diff/`

## Routing Context

**Upstream**: MASTER R22  
**Downstream**: Dynamic validation → Frida/GDB; exploitation → `pwn-chain`  
**Peer**: `ida-reverse` (commercial deep analysis)

## Task Completion Self-Check

- [ ] Is this based on a real Ghidra/tool-index path?
- [ ] Does it identify function addresses and renaming?
- [ ] Are reproducible steps included?
- [ ] Checklist / journal?