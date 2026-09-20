---
name: macos-reverse
description: Use for authorized macOS and Mach-O reverse engineering including codesign, Objective-C/Swift recovery, endpoint security surfaces, and Apple platform malware analysis.
---

# macOS / Mach-O Reverse Engineering

## ACTION REQUIRED (Do these steps immediately after you read this file)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Make sure that the target is macOS/Mach-O/App bundle (iOS IPA → `mobile-reverse/`)
3. `NEXT`: Use tool-index; use tools such as jtool2/lldb
4. `ACT`: Examine signature and load information → Do static analysis → Do dynamic analysis (lldb/Frida)

## When to Use

- Mach-O executable files / dylib / framework
- .app bundle, LaunchAgent/Daemon
- Objective-C / Swift symbols and runtime
- Analysis of behavior related to notarization/signatures, Hardened Runtime, and TCC
- Static/dynamic analysis of macOS malware (use with malware-analysis)

## Workflow

### 1. Package Contents and Signatures

```bash
file target
codesign -dv --verbose=4 target
spctl -a -vv target 2>&1
otool -L target
```

### 2. Static Analysis

```text
□ Use class-dump / swift-demangle / Hopper / Ghidra / IDA
□ Examine strings, XPC service names, and TCC-sensitive APIs
□ Examine LC_LOAD_dylib dependencies and rpath
```

### 3. Dynamic Analysis

```text
□ Use lldb / Frida
□ Monitor with fs_usage / log stream
□ Network: Use protocol-reverse or a proxy
```

## Tools

| Tool | Use |
|------|------|
| otool / nm / codesign | Included with the system |
| Hopper / Ghidra / IDA | Decompilation |
| class-dump / dsdump | ObjC |
| Frida / lldb | Dynamic analysis |
| jtool2 | Mach-O |

## References

- `references/macho-triage.md`
- `../mobile-reverse/` (iOS) `../ghidra-reverse/` `../malware-analysis/`

## Routing Context

**Upstream**: MASTER R31  
**Downstream**: iOS → mobile-reverse; General samples → malware-analysis

## Task Completion Check

- [ ] Record the signature/Hardened Runtime status.
- [ ] Give conclusions at the address/symbol level.
- [ ] Complete the checklist.