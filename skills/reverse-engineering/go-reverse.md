# Go Binary Reverse Engineering Guide

> Go-compiled binaries have unique challenges: static linking creates large file sizes, the number of functions can exceed 10,000, string formats are unusual, and recovery is difficult after symbols are stripped.
> This document covers the toolchain, recovery techniques, and a practical workflow.

---

## Identifying Go Binary Features

Quickly determine whether a binary was compiled with Go:

```bash
# String Characteristics
strings binary | grep -E "runtime\.|go\.buildid|GOROOT"

# rabin2 Reconnaissance
rabin2 -z binary | grep -i "runtime"

# Unusually large file size (statically linked runtime)
# Typical Hello World: C ~20KB, Go ~2MB
```

Common features:
- Contains many functions with the `runtime.` prefix
- Contains the `go.buildid` section
- Contains string paths for `GOROOT` and `GOPATH`
- Contains 5000-50000+ functions, including the complete runtime and standard library

---

## Core Toolchain

### Symbol Recovery

| Tool | Purpose | Link |
|------|------|------|
| **GoReSym** | Developed by Mandiant. Parses Go symbol information (`pclntab/moduledata`) | https://github.com/mandiant/GoReSym |
| **GoResolver** | Developed by Volexity. Automatically deobfuscates Garble binaries by using CFG similarity | https://github.com/volexity/GoResolver |
| **redress** | Analyzes stripped Go binaries and recovers type, interface, and package structures | https://github.com/goretk/redress |
| **GoStringUngarbler** | Developed by Google. Recovers strings obfuscated by Garble | https://github.com/mandiant/GoStringUngarbler |

### IDA Plugins

| Tool | Purpose | Link |
|------|------|------|
| **go_parser** | An IDA plugin that parses `moduledata`/`pclntab`/type information | https://github.com/0xjiayu/go_parser |
| **IDAGolangHelper** | A set of IDA scripts that parses Go type information | https://github.com/sibears/IDAGolangHelper |
| **AlphaGolang** | An IDAPython script collection from SentinelLabs | https://github.com/SentineLabs/AlphaGolang |
| **IDA 9.2+ Native Support** | Official Hex-Rays improvements for Go decompilation | https://hex-rays.com/blog/stop-guessing-and-start-going |

### Ghidra Plugins

| Tool | Use | Link |
|------|------|------|
| **Ghidra + GoReSym output** | Import symbols into Ghidra after exporting them with GoReSym | Use together |
| **golang_loader_assist** | Ghidra Go loader assistant | Community script |

### Standalone analysis tools

| Tool | Use | Link |
|------|------|------|
| **gore** | Go reverse engineering library (the underlying library for redress) | https://github.com/goretk/gore |
| **garble** | Go obfuscation tool (understand it to counter it) | https://github.com/burrowers/garble |

---

## Key structures in Go binaries

### pclntab (PC Line Table)

The most important structures in Go binaries include:
- Mappings between all function names and addresses
- Source file paths
- Line number information
- Stack frame sizes

The `pclntab` usually remains even after symbols are stripped because the Go runtime depends on it.

```text
Location methods:
1. Search for magic bytes: 0xFFFFFFF0 (Go 1.16+) or 0xFFFFFFFB (Go 1.18+)
2. Use GoReSym to locate them automatically
3. Use the go_parser IDA plugin to parse them automatically
```

### moduledata

Includes:
- `pclntab` pointer
- Type information table
- `itab` (interface table)
- Global variable information

### String format

Go strings are not C-style null-terminated strings. They use a `(pointer, length)` structure:

```text
C string:   "hello\0"
Go string:  struct { ptr *byte; len int } → ptr points to "hello" (without \0)
```

This causes the default string detection in IDA/Ghidra to miss many Go strings.

**Solution**:
- Use `go_parser` to detect Go strings automatically
- Export the string list with GoReSym
- Manual: Find `runtime.stringtable` or locate it through cross-references

---

## Practical workflow

### Scenario 1: Unstripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   → Export all function names, types, and source file paths
2. Load into IDA/Ghidra
3. Import symbol information from GoReSym
4. Filter out runtime.* and standard library functions. Focus on user code
5. Start analysis from main.main
```

### Scenario 2: Stripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   → The pclntab usually remains even after stripping
2. If GoReSym fails → use redress
   redress -src binary    # Restore source file paths
   redress -pkg binary    # Restore package structure
   redress -type binary   # Restore type information
3. Load into IDA + the go_parser plugin
4. Run go_parser to recover automatically
5. Start from the recovered main.main
```

### Scenario 3: Go binary obfuscated with Garble

```text
Garble will:
- Randomize function names (main.main → main.a3f2b1c)
- Encrypt strings
- Remove file path information
- Obfuscate package names

Countermeasures:
1. GoResolver (CFG signature matching)
   → Recover standard library function names through control-flow graph similarity
2. GoStringUngarbler (string decryption)
   → Automatically identify Garble's string encryption patterns and decrypt them
3. Dynamic analysis (Frida/dlv)
   → Hook runtime functions to observe actual behavior
4. Comparative analysis
   → Compile Hello World with the same Go version and compare the runtime sections with binary-diff
```

### Scenario 4: CGo mixed compilation

```text
1. Identify the CGo boundary (_cgo_* functions)
2. Recover the Go portion with go_parser
3. Analyze the C portion with standard IDA methods
4. Focus on _cgo_topofstack, crosscall2, and other bridge functions
```

---

## Common command quick reference

```bash
# GoReSym: Export symbols
GoReSym -t -d -p binary > symbols.json
GoReSym -t -d -p binary -o ida_script.py  # Generate an IDA script

# redress: Analyze a stripped binary
redress -src binary          # Source file path
redress -pkg binary          # Package structure
redress -type binary         # Type information
redress -interface binary    # Interface information
redress -filepath binary     # Full file path

# GoResolver: Deobfuscate Garble
GoResolver -binary binary -output resolved.json

# GoStringUngarbler: Decrypt Garble strings
GoStringUngarbler -i binary -o deobfuscated_binary

# Quickly identify the Go version
strings binary | grep "go1\."
GoReSym -p binary | grep "Version"
```

---

## Go analysis workflow in IDA

```text
1. Load the binary (select the correct architecture)
2. Wait for the automatic analysis to finish
3. Run the go_parser plugin:
   - File → Script File → go_parser.py
   - Or select Edit → Plugins → Go Parser
4. The plugin will automatically:
   - Parse pclntab
   - Recover function names
   - Mark Go strings
   - Parse type information
5. Filter the view:
   - Hide runtime.* functions
   - Focus on main.* and third-party packages
6. Start reverse engineering from main.main
```

---

## Common pitfalls

| Pitfall | Description | Solution |
|------|------|------|
| Too many functions to review | Go static linking results in 5000-50000 functions | Filter by package name. Show only main.* and business packages |
| Incomplete string recognition | Go strings are not null-terminated | Use go_parser or GoReSym to recover them |
| Decompiled output is difficult to read | Go defer, goroutine, and interface features make the pseudocode complex | IDA 9.2+ has improvements. Use dynamic analysis as an aid |
| Garble obfuscation | All function names and strings are randomized | Use GoResolver + GoStringUngarbler |
| Version differences | The pclntab format differs between Go versions | GoReSym supports Go 1.2-1.23+ |
| CGo boundary | Go and C code are mixed | Identify _cgo_* functions as the boundary |

---

## Coordination with other skills

| Requirement | What to use |
|------|--------|
| In-depth IDA analysis of a Go binary | `ida-reverse/` + go_parser plugin |
| Ghidra analysis (free) | Ghidra + GoReSym symbol import |
| Quick reconnaissance | `radare2/` — `rabin2 -z` to view strings |
| Dynamic hooking | Frida (hook runtime functions) or dlv (native Go debugger) |
| Cross-version comparison | `binary-diff/` — migrate symbols from the old version to the new version |
| Garble deobfuscation | GoResolver + GoStringUngarbler |
