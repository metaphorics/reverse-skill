---
name: dotnet-reverse
description: .NET / C# binary reverse engineering. Use this skill when the target is a .NET assembly (the PE header contains CLR, or the program is a managed .exe/.dll), a C# compilation output (including NativeAOT), a red-team Sharp* tool (Rubeus / SharpHound / SharpHound, etc.), a .NET obfuscated program (ConfuserEx / SmartAssembly / Babel / Eazfuscator), or .NET loader / info-stealer / packer-protected malware. Prefer dnSpyEx + de4dot. When AI must operate directly, use dnSpy MCP together. Do not use it for pure native binaries (use reverse-engineering / ida-reverse).
license: MIT
compatibility: Requires a filesystem-based code agent or CLI with shell access, Windows host preferred (dnSpyEx is a Windows GUI); Linux/macOS can use ILSpy/de4dot CLI + mono/dotnet runtime.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
metadata:
  user-invocable: "false"
---

# .NET / C# reverse engineering task rules

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Use DIE/`file`/the CLR header to confirm that the target is a .NET managed program (otherwise SWITCH to `ida-reverse/` / `reverse-engineering/`)
2. `NOW`: If obfuscation is suspected, run `de4dot` to unpack first, produce `*-clean.exe`, and keep the original sample
3. `NEXT`: Use dnSpyEx (or dnSpy MCP / `ilspycmd`) for static analysis: browse C# + use **IL view** to inspect key checks
4. `ACT`: Use dynamic debugging when you need plaintext/C2. Prefer **IL patching** over C# recompilation when you need to change logic
5. At the end of each stage, give the user a menu with 3–6 next steps, including report export

## Scope

Prefer this skill when the task belongs to one of the following scenarios:

- Identify and reverse engineer .NET / C# compilation outputs (managed PE / .exe / .dll)
- Analyze the red-team Sharp* toolchain (Rubeus, SharpHound, SharpShell, etc.)
- Unpack ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor and other packers
- Reverse engineer the decryption and C2 logic of .NET loader / info-stealer / RAT
- Patch C# programs (change checks, change constants, keygen)
- Analyze the Mono/Unity managed layer before IL2CPP (note: after IL2CPP compilation, it is native. Use `reverse-engineering/` + seed-014)

If the target is a pure native binary (compiled from C/C++/Go/Rust, with no CLR), use `reverse-engineering/`, `ida-reverse/` or `radare2/` instead.

## Core principles

- **Identify before action**: First confirm that it is a .NET managed program (PE header CLR + `#~` / `#Strings` streams + mscoree `_CorExeMain`), then choose dnSpy instead of IDA
- **Prefer IL to C#**: The dnSpyEx C# decompiler can lose or distort information (compiler-generated state machines, async/await, yield). Switch to the **IL editor** for key checks and patches. Use the C# view only for quick browsing
- **Run de4dot first**: When you find an obfuscator, run `de4dot` once to unpack it before static analysis. Otherwise, all strings and control flow are scrambled
- **Use MCP together**: If dnSpy MCP (`dnspy_*` tools) is registered in the environment, prefer the MCP interface for decompile / IL inspection to avoid switching back and forth with the GUI
- **Produce evidence**: Save the unpacked output, extracted configuration/C2/key, and patch diff to disk

## Toolchain Mapping

| Capability | First Choice | Notes |
|------|------|------|
| Decompilation + debugging + patching | **dnSpyEx** | Primary choice, the only GUI with an IL editor; old dnSpy is no longer maintained, use the Ex branch |
| Lightweight CLI / headless decompilation | **ILSpy v11.0** (`ilspycmd`) | Suitable for batch work and scripting on Linux/macOS |
| Deobfuscation | **de4dot** | Default choice for common packers such as the ConfuserEx family and SmartAssembly |
| Obfuscator identification | **Detect It Easy (DIE)** / **file** | Identify the packer type first, then select the de4dot parameters |
| Programmatic IL operations | **dnlib** | Write C# scripts to batch-edit metadata / string decryptors |
| Direct AI operations | **dnSpy MCP** | Includes tools such as `dnspy_decompile` / `dnspy_inspect_il` |

> Prerequisite: Install dnSpyEx + de4dot on a Windows host with choco or from a release; on Linux/macOS, install ILSpy v11.0 with `dotnet tool install -g ilspycmd --version 11.0.0.9375` and use the `dotnet` runtime. See the installation matrix in `references/sharp-tools.md`.

## Six-Stage Workflow

### 1. Identify (.NET)

Confirm that the target is a managed program. Do not analyze a native PE as .NET:

```powershell
# Windows
file target.exe                       # "PE32 executable ... for MS Windows" is not enough
# Key: check whether CLR is present
powershell -c "[System.Reflection.AssemblyName]::GetAssemblyName('target.exe')"
# Or
dnSpyEx: drag it in directly. If it opens, it is managed.

# General
strings target.exe | grep -iE "mscoree|_CorExeMain|mscorlib|System\\."
```

**.NET Identification Signs:**
- PE header `Data Directory[14]` (CLR Runtime Header) is non-zero
- `mscoree.dll` import / `_CorExeMain` entry point
- `#~`, `#Strings`, `#US`, `#GUID`, `#Blob` metadata streams
- `mscorlib` / `System.Private.CoreLib` strings

**NativeAOT Exception:** The program is compiled to native code and has no CLR header, but it has `System.Private.CoreLib` strings and reconstructed type metadata. Use `reverse-engineering/` for this type of target with IDA/r2. This skill only provides identification guidance.

### 2. Detect (Obfuscator)

```powershell
# DIE quick identification
diec target.exe                        # Detect It Easy CLI
# Or drag it into dnSpyEx and check whether it has many garbled class names / control-flow obfuscation
```

Common obfuscators and deobfuscation strategies. See `references/obfuscators.md`:

| Obfuscator | Features | de4dot Handling |
|--------|------|------------|
| ConfuserEx (1.0.0 / 2.x) | `<module>` anti-tamper, control-flow transformation, string encryption | `de4dot target.exe` usually detects it automatically |
| SmartAssembly | `circular`/`string encoding`, resource compression | `de4dot target.exe` |
| Babel.NET | Method-body encryption, control flow | `de4dot target.exe` |
| Eazfuscator.NET | String/resource encryption | `de4dot`, manual work is required for some versions |
| .NET Reactor | anti-tamper + necrobit | `de4dot`, new versions may fail. Do it manually |

### 3. Deobfuscate (deobfuscation)

```powershell
# de4dot automatically identifies most packers by default
de4dot target.exe -o target-clean.exe

# Specify the type (when automatic identification fails)
de4dot --type cfze target.exe          # ConfuserEx
de4dot --type sa target.exe            # SmartAssembly

# Multiple layers of obfuscation / de4dot reports unknown
de4dot --detect target.exe             # See what it identifies it as
# You may need to patch anti-tamper before running de4dot (see references/obfuscators.md)
```

Output: `target-clean.exe` for later analysis. **Keep the original sample** for comparison.

### 4. Static Analyze (static analysis)

Load the unpacked sample in dnSpyEx:

- **C# view**: Quickly review class structures, method signatures, and strings for locating targets
- **IL view**: You must inspect IL for key decisions and encryption logic in state machines (right-click -> Edit IL or IL view)
- Find the entry point: `Main` / `Startup` / module initializer (`Module .cctor`)
- Find key logic: Search for `flag`, `password`, `verify`, `check`, `encrypt`, `http`, and `Config`

```text
Locate the string → find cross-references → find the method that uses it → inspect the decision logic in the IL view
```

### 5. Dynamic (dynamic debugging)

dnSpyEx debugger: Attach to a process or start debugging. Set breakpoints at key methods and observe runtime behavior:
- Decrypted plaintext strings. Many obfuscators decrypt strings only at runtime
- C2 addresses and decrypted configuration results
- Exception-driven control flow. anti-debug often uses `try/catch` to hide the real path

> .NET dynamic debugging is much easier than native debugging - you can see object values and string contents directly. Prefer dynamic analysis instead of spending too much time on static analysis.

### 6. Patch (modify as needed)

```text
dnSpyEx → right-click the method → Edit Method (C#) or Edit IL
  - Change the condition: ldc.i4.0 → ldc.i4.1 (false→true)
  - Change constants: edit strings/numbers directly
  - Remove the check: replace the entire section with nop
File → Save Module → replace the original file
```

**IL patch reliability > C# patch**: C# recompilation may fail because of missing references or invalid syntax. IL editing almost never changes the original behavior. See `references/common-workflow.md`.

## Trigger-based routing

Enter this skill when the user says:
- ".NET / C# binary reverse engineering" / "C# program decompilation"
- "dnSpy analysis" / "dnSpyEx patch"
- "ConfuserEx / SmartAssembly / Babel deobfuscation / unpacking"
- "Sharp* tool analysis" (Rubeus / SharpHound / SharpShell)
- ".NET malware / loader / info-stealer reverse engineering"
- "C# program patch / keygen / modify checks"

## When to switch out

- IL2CPP-compiled Unity game -> `reverse-engineering/` + `seed-014_unity-il2cpp-reverse.md` (IL2CPP is native. Do not use dnSpy)
- NativeAOT output -> `reverse-engineering/` (same as above. Native)
- Pure native PE (no CLR) -> `reverse-engineering/` / `ida-reverse/`
- Need to move symbols or functions in batches to another version -> `binary-diff/`
- Need to draw an attack path or call-chain diagram -> `diagram-generator/`

## Routing context

**Upstream entry**: `skills/SKILL.md` (main control), `routing.md`
**Downstream exits**:
- IL2CPP / NativeAOT (native) -> `reverse-engineering/`
- Deep native .so/.dll section analysis -> `ida-reverse/` / `radare2/`
- Need AI to operate dnSpy directly -> Register and connect dnSpy MCP (see `references/sharp-tools.md`)

**Related modules at the same level**:
- `reverse-engineering/languages-compiled.md` (.NET introduction points to this module)
- `apk-reverse/` (For Xamarin/MAUI Android reverse engineering, switch back to this module to review the C# layer)

## Reference documents

- [references/obfuscators.md](references/obfuscators.md) — Detailed deobfuscation of ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor + anti-tamper bypass
- [references/common-workflow.md](references/common-workflow.md) — Complete workflow, IL patch reliability, string decryptor extraction, state machine identification
- [references/sharp-tools.md](references/sharp-tools.md) — Red-team Sharp* tool analysis, tool installation matrix, dnSpy MCP integration, community resource index

## Task completion self-check

- [ ] Did you confirm the CLR / managed identity (or SWITCH out of this skill)?
- [ ] Did you run de4dot / an equivalent unpacker before deep analysis of the obfuscated sample?
- [ ] Does the key logic use an IL view for verification rather than only C# pseudocode?
- [ ] Are the outputs (clean sample / configuration / patch diff) saved to disk and reproducible?
- [ ] Does it provide a next-step menu or a report output?
