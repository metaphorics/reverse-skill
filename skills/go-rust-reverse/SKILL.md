---
name: go-rust-reverse
description: Use to reverse engineer Go and Rust binaries with symbols removed. Identify runtime features, recover pclntab and module data, analyze panic strings, and recover language-specific code patterns from decompiled code.
---

# Go / Rust Binary Reverse Engineering

## ACTION REQUIRED (Execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Confirm that the sample was compiled from Go or Rust (use `file`, strings, and runtime features)
3. `NEXT`: Check if GoReSym / related plugins are available
4. `ACT`: Identify the runtime → recover symbols/metadata → analyze application logic

## When to Use

- Analyze Go malware/tools with symbols removed
- Analyze Rust release binaries with panic strings
- Use language-specific methods with general ida/ghidra methods

## Workflow

### Go

```text
□ Identify go.buildid, remaining runtime symbols, and pclntab
□ Use GoReSym / redress / IDA Go plugins to recover function names
□ Examine interface, slice, and string structures in decompiled code
□ Examine network/cryptographic library paths: crypto/* net/http
```

### Rust

```text
□ Examine panic strings, rust_begin_unwind, and crate paths for evidence
□ Generic instantiation increases code size; first locate string xref references
□ Use cross-references to analyze asynchronous/tokio state machines
```

### Dynamic Analysis

```text
□ You can still use Frida; examine the Go stack and scheduling
□ First use log and configuration strings to select breakpoints
```

## Tools

| Tool | Use |
|------|------|
| GoReSym | Recover Go metadata |
| IDA/Ghidra + Go/Rust plugins | Decompile code |
| radare2 | Find strings quickly |
| strings / rabin2 | Make an initial assessment |

## References

- `references/go-rust-notes.md`
- `../reverse-engineering/go-reverse.md` `../ida-reverse/` `../ghidra-reverse/`
- seed: `field-journal/seed-002_go-malware-stripped.md`

## Routing Context

**Upstream**: MASTER R33  
**Downstream**: Malware sample workflow `malware-analysis`; general RE `reverse-engineering`

## Task Completion Check

- [ ] Confirm that you recovered key function names or an equivalent mapping.
- [ ] Confirm that you recorded evidence of the language runtime.
- [ ] Complete the checklist.