---
name: radare2
description: |
  Use this skill whenever the user wants to analyze binaries with radare2/r2 from the command line, including reverse engineering, disassembly, function analysis, strings/import inspection, patching, binary diffing, hex inspection, or r2 scripting. Also use it when the user mentions PE/ELF/Mach-O/DEX/WASM files together with CLI analysis, `rabin2`, `rasm2`, `radiff2`, `r2pipe`, or asks for radare2 command help on Windows/Linux/macOS.
---

# radare2

Binary analysis skills for the `radare2` CLI. Focus on reconnaissance, analysis, location, export, and light modification from the command line without a GUI.

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm that this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task is within this skill's scope
3. `NEXT`: Read `../tool-index.md` and verify tool availability and actual paths
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths
5. `ACT`: Enter and execute the first step of the "workflow". Do not stop at the confirmation state

## Scope

Use this skill first when the user wants to:

- Use `r2` / `radare2` to analyze files such as `exe`, `dll`, `so`, `elf`, `apk`, `dex`, and `wasm`
- Ask how to use `rabin2`, `rasm2`, `radiff2`, and `rahash2`
- Perform command-line disassembly, view functions and strings, view imports and exports, find cross-references, or make patches
- Write `radare2` batch commands, `-c` automation commands, or `r2pipe` scripts

If the user specifically requests GUI reverse engineering, Hex-Rays-style pseudocode, or an IDA workflow, consider `ida-reverse` first. For web JS reverse engineering, consider `reverse-engineering` first.

## Confirm the environment first

Do not assume that `r2` is available. Check first:

```powershell
r2 -v
rabin2 -v
```

If it is not installed, check common installation locations or suggest installation.

Common Windows executable files:

- `radare2.exe`
- `rabin2.exe`
- `rasm2.exe`
- `radiff2.exe`
- `rahash2.exe`
- `rax2.exe`
- `r2pm.exe`

## Built-in resources

This skill includes two resources. Reuse them first instead of organizing a duplicate set of commands each time.

### `scripts/recon.ps1`

Standard reconnaissance script for the first overview analysis. It outputs:

- Basic information
- Sections
- Imports
- Export
- Strings
- Optional `r2 -A` automatic analysis summary

Usage:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe"
```

If you need to include `r2` automatic analysis:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe" -RunAnalysis
```

### `references/cheatsheet.md`

When you need more command details, common scenario templates, or a quick syntax reminder, read this quick reference instead of guessing from memory.

## Known Issues

### Occasional `.sdb` Missing Warning on Windows

Some PE files may show a warning like the one below during `rabin2` reconnaissance:

```text
ERROR: Cannot find ...\share\format\dll\*.sdb
```

If the main output returns normally, this usually does not affect the basic reconnaissance result. Continue the analysis. Do not mark the analysis as failed only because of this additional warning.

## Basic Principles

### 1. Perform Reconnaissance Before Detailed Analysis

Do not start with full automatic analysis. First use lightweight commands to confirm the file type, architecture, entry point, strings, and import table. Then decide whether to run `aaa`, `aaaa`, or targeted analysis.

### 2. Prefer the Smallest Sufficient Command

`radare2` has many commands. Users usually need the shortest path:

- View file information: `rabin2 -I`
- View strings: `rabin2 -z`
- View imports and exports: `rabin2 -i` / `rabin2 -E`
- Perform interactive analysis: run `r2 <file>` and then run local commands

### 3. Use Care Before Modification

If the user wants to patch a binary:

- Open it in read-only mode first by default: `r2 <file>`
- Use write mode only when modification is clearly required: `r2 -w <file>` or `oo+` in the session
- State the risks before modification. Avoid overwriting the original file by mistake.

## Common Workflow

## Workflow 1: Rapid reconnaissance

Use this workflow when you first obtain a binary file.

### Hard Gate (MUST - Do not enter Workflow 2 or later until this requirement is met)

For binaries that contain an import table, such as PE/ELF/Mach-O, **MUST** complete the import table check and record it as Evidence before function-level analysis or dynamic steps:

1. Run `rabin2 -i <sample>` (or use the imports section in the `recon.ps1` output); DLL/SYS files MUST also run `rabin2 -E` and record `E-exports`
2. Write the complete or classified import table results to Evidence (suggested id: `E-imports` or `E-triage-imports`). Include at least:
   - Reproduction command (`repro_command`)
   - Summary of key import categories: network / file / cryptography / process injection / registry / other suspicious APIs
   - If the import table is empty, parsing fails, or the tool reports an error: MUST still record the failure and the raw output as Evidence. **Do not skip it silently**
   - If the import table is "too clean" (only basic DLLs): MUST note possible dynamic loading and SHOULD switch to dynamic API tracing
3. For .NET and other binaries without a traditional IAT: MUST use an equivalent anchor (dnSpy/IL/metadata summary) and write it to the same Evidence semantic slot. Do not leave it empty
4. For IAT repair of packed samples: use ImportREC (or an equivalent tool) for x86 and Scylla (or an equivalent tool) for x64. If repair fails, MUST record `E-iat-repair-fail` and switch to dynamic API breakpoints; **Do not keep working on the static IAT indefinitely** (see `reverse-engineering/references/re-agent-workflow.md` §1.2)
5. When the user explicitly requests "redo the import table check / check the import table again / redo the IAT": MUST redo the requested step itself (if blocked, first use a feasibility gate: state the prerequisites and ask for confirmation; if forced, set quality=unreadable). **Do not replace it with an unrelated step and claim completion**

Before recording Evidence for the import table (or a valid equivalent anchor / IAT failure fallback): MUST NOT claim that "basic reconnaissance is complete". MUST NOT enter deep-dive conclusions in Workflow 2 or later.

Run the built-in script first:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "sample.exe"
```

If you only need the minimum manual command, use:

```powershell
rabin2 -I sample.exe
rabin2 -z sample.exe
rabin2 -i sample.exe
rabin2 -E sample.exe
```

Focus areas:

- File format, bitness, architecture, platform
- Entry point address
- Suspicious strings: URLs, paths, error messages, registry items, command-line arguments
- Imported functions: network, file, cryptography, process injection, registry operations (**MUST record them as Evidence. See the hard gate above**)

## Workflow 2: Interactive Function Analysis

```powershell
r2 sample.exe
```

After entry, commonly used:

```text
aaa          # Routine automated analysis
afl          # List functions
iz           # List strings
iS           # List sections
is           # List symbols
s entry0     # Jump to the entry point
pdf          # Disassemble the current function
VV           # Enter visual mode (if the terminal is suitable)
q            # Quit
```

Note:

- Prefer `aaa` by default. Do not start with the heavier `aaaa`.
- If the sample is large or analysis is slow, analyze only the area near the entry point first. Then expand it manually.

## Workflow 3: Locate main / key logic

```text
afl~main
afl~sym.
iz~http
iz~error
axt <addr>
```

Approach:

- Start with `main`, the entry point, and string references.
- Use `axt` to find who references a string or address.
- After you find a reference point, use `s <addr>` and then `pdf`.

## Workflow 4: View hexadecimal data and memory

```text
px 64        # Show 64 bytes in hexadecimal from the current address
pd 20        # Disassemble 20 instructions
psz          # Read the string at the current address
pxa          # Show a friendlier hexadecimal view
```

## Workflow 5: Binary patching

Use this only when the user clearly asks to modify a file:

```powershell
r2 -w sample.exe
```

For example, after entering:

```text
s 0x401000
wa nop
wa jmp 0x401050
wq
```

Common write commands:

- `wa <asm>`: Write assembly.
- `wx <hex>`: Write raw bytes.
- `wq`: Write and exit.

Back up the original file before you make changes. If the user does not mention a backup, remind them at least once.

## Workflow 6: Non-interactive automation

Use this for one-time result output:

```powershell
r2 -A -q -c "afl;iz;ii;q" sample.exe
```

Common options:

- `-A`: Analyze automatically at startup.
- `-q`: Quiet mode.
- `-c`: Execute a command string.

- If there are many commands, arrange them in a readable order. Do not put them in an excessively long string that is difficult to maintain.

Use the built-in reconnaissance script first, then decide whether to add custom commands.

## Common Subtools

### `rabin2`

For static information extraction:

```powershell
rabin2 -I sample.exe   # Basic information
rabin2 -S sample.exe   # Sections
rabin2 -s sample.exe   # Symbols
rabin2 -i sample.exe   # Imports
rabin2 -E sample.exe   # Exports
rabin2 -z sample.exe   # Strings
rabin2 -zz sample.exe  # More detailed strings
```

### `rasm2`

For quick assembly and disassembly:

```powershell
rasm2 -d "9090"
rasm2 -a x86 -b 64 "xor eax, eax"
```

### `radiff2`

For comparing two binaries:

```powershell
radiff2 old.exe new.exe
radiff2 -C old.exe new.exe
```

### `rahash2`

For calculating hashes:

```powershell
rahash2 -a md5 sample.exe
rahash2 -a sha256 sample.exe
```

### `rax2`

For base and encoding conversion:

```powershell
rax2 0x401000
rax2 4198400
rax2 -s hello
```

## Recommended Analysis Order

When you find an unknown sample, use this order:

1. `rabin2 -I` Check the format, architecture, and entry point
2. `rabin2 -z` Check the strings
3. `rabin2 -i` Check the imported functions — **MUST + Evidence (hard gate, see Workflow 1)**
4. If you need interactive analysis, enter `r2` (only when the Evidence from Step 3 is saved)
5. Run `aaa` first, then run `afl` / `iz` / `pdf`
6. Locate key functions step by step through string references, imported function calls, and the entry flow

This order reduces noise and helps you establish direction quickly. Step 3 is not an optional improvement. It is a hard gate before deeper analysis.

## Windows Notes

- When a path contains spaces, quote the command correctly
- If the current terminal cannot find `r2`, `PATH` may have just been updated. Open a new terminal and try again
- Some samples require administrator privileges to read. Do not raise privileges by default unless the user clearly needs it
- Confirm the user's intent before you perform dynamic debugging on a suspicious sample. Avoid unintended actions

## Output Style

When the user wants more than commands and wants you to analyze a file:

- First provide a summary of the reconnaissance results
- List the key evidence again: strings, imports, functions, and addresses
- Give next-step suggestions or continue the analysis

Do not only list commands without explaining why you use them.

## Typical Request Examples

### Example 1: Analyze an exe

User: `Help me see what this exe did. radare2 is enough.`

Method:

1. First use `rabin2 -I/-z/-i`
2. Decide whether to enter `r2`
3. Use `aaa`, `afl`, and `pdf` to examine the entry point and key string references

### Example 2: Find Where a String Is Called

User: `Which function triggers this error string?`

Method:

1. Use `iz~keyword` to find the string address
2. Use `axt <addr>` to find references
3. Go to the reference point with `s <addr>`, then use `pdf`

### Example 3: Change a Jump

User: `Change this jne to je`

Method:

1. First confirm the target address
2. Clearly tell the user that you must enter write mode
3. Use `wa je <target>` or use `wx` directly
4. Disassemble again after the change to verify it

## Practices to Avoid

- Do not treat `radare2` as a tool with only one command, `aaa`
- Do not open user files in write mode without stating the risks
- Do not draw conclusions before basic reconnaissance
- **Do not skip import table checks** (`rabin2 -i` / recon imports): Do not proceed to the next step until you write Evidence; when the user asks you to redo the import table, do not perform another step
- **Do not keep troubleshooting statically after IAT repair fails**: Record `E-iat-repair-fail` and switch to dynamic analysis; do not use only ImportREC for 64-bit samples
- Do not misroute web JS reverse engineering to this skill; that is within the scope of `reverse-engineering`

## References

- Command quick reference: `references/cheatsheet.md`
- Standard reconnaissance script: `scripts/recon.ps1`

## radare2-skills Ecosystem
This workflow targets radare2 6.2.2. Rizin is a fork of radare2 and remains outside bootstrap.

The radare2-skills project (radareorg/radare2-skills) provides a more complete ecosystem of tools and workflows:

- **r2xsql**: Query binary imports / strings / functions with SQL
- **r2mcp / r2http**: MCP tools and an HTTP stateful command channel
- **radius2**: Symbolic execution and symbolic dynamic analysis
- **r2pm**: Plugin management and extensions
- **decompiler plugins**: The radare2 plugin mechanism

**Use strategy**:
- When the user mentions `r2xsql`, `r2mcp`, `r2http`, `radius2`, `r2pm`, `rabin2`, `rasm2`, `radiff2`, `rahash2`, or `rax2`, route to this skill (`radare2/SKILL.md`) first
- These tools are only ecosystem accelerators and **cannot bypass**: authorization gates, `tool-index` checks, Evidence import, or write mode confirmation
- Provide a minimal reproducible command example:
  - `r2xsql -s <file> -q "SELECT ..."`
  - `curl.exe -sS --data-binary 'aaa' http://127.0.0.1:9393/cmd`
  - `radius2 -p <binary> ...`
  - `r2pm -ci <plugin>`
  - `r2pm -ci r2frida` for dynamic instrumentation with radare2 6.2.2

This skill keeps the original hard gates and evidence chain integrity. Do not skip any authorization or Evidence step.

---

## Routing context

**Upstream entry**: `skills/SKILL.md` (controller), `routing.md`
**Upstream alternative**: `ida-reverse/` (upgrade to IDA when decompilation or pseudocode is needed)
"**Downstream exits**:"
"- Requires dynamic analysis → `reverse-engineering/tools-dynamic.md` (Frida/GDB)"
"- Requires deep decompilation → `ida-reverse/`"
"- After PAT finds interesting strings, cross-reference them → `ida-reverse/` (IDA provides stronger xref support)"

"**Peer related modules**: `ida-reverse/` (complementary: r2 is fast for reconnaissance, and IDA is deep for decompilation)"

"## On-Demand Bootstrap"

"The entry script for this skill is connected to the unified bootstrap system. If radare2 is missing, the script does not fail immediately. It tries to install radare2 automatically."

"### Automation Limits"

"| Tool | Can install automatically | Installation method | Notes |"
|------|-----------|---------|------|
"| r2 | ✓ | GitHub Release ZIP (w64) | Automatically downloads and extracts to `%USERPROFILE%\\Tools\\radare2\\` |"
"| rabin2 | ✓ | Same as above (included in the radare2 release package) | — |"
"| rasm2 | ✓ | Same as above | — |"
"| radiff2 | ✓ | Same as above | — |"
"| rahash2 | ✓ | Same as above | — |"
"| rax2 | ✓ | Same as above | — |"

"### Bootstrap Triggers"

"- `scripts/recon.ps1`: Automatically calls `bootstrap-reverse.ps1` when `rabin2` or `r2` is missing"

"### If Bootstrap Fails"

"If automatic installation fails, for example because the network is unavailable or the GitHub API rate limit applies, the script reports a clear error and includes a manual installation link."

"Manual installation: Download `radare2-*-w64.zip` from https://github.com/radareorg/radare2/releases. Extract it to `%USERPROFILE%\\Tools\\radare2\\` and make sure the `bin\\` directory is in PATH."


"## Task Completion Self-Check (MUST pass before you claim completion)"

"- [ ] Did I execute every step in the workflow instead of only reading it?"
"- [ ] Did I check the import table and write the result to Evidence (E-imports / E-triage-imports or the .NET equivalent)? Do DLL/SYS files contain E-exports?"
"- [ ] If IAT repair failed, did I record E-iat-repair-fail and switch to dynamic analysis? If I replayed the request, did I return to the same step?"
- [ ] Did I use a real tool path based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the Checklist items required by RULES?

