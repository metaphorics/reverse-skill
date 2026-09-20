# General .NET reverse-engineering workflow

Complete workflow details, IL patch reliability, string decryptor extraction, state machine identification, and dnlib scripting.

## Complete workflow (end to end)

```text
1. Identify  → Confirm it is a .NET managed program (not native)
2. Detect    → DIE / de4dot --detect identifies the obfuscator
3. Deobf     → de4dot deobfuscates it (keep the original sample)
4. Static    → Use the dnSpyEx C# view to locate it; use the IL view to inspect key logic
5. Dynamic   → Set a breakpoint on the key method in the dnSpyEx debugger and view plaintext at runtime
6. Patch     → Modify it in the IL editor, Save Module
```

Save the output of each step to disk: original sample `target.exe` → unpacked `target-clean.exe` → patched `target-patched.exe`.

## IL patch vs C# patch reliability

**Key conclusion: Use an IL editor for critical changes. Do not use a C# editor.**

| Dimension | C# editor (Edit Method C#) | IL editor (Edit IL) |
|------|---------------------------|---------------------|
| Compilation failure risk | High (missing references, syntax errors, lambda rewrite failure) | Almost zero |
| Information fidelity | The compiler regenerates IL, which can differ from the original IL | Replaces the original and edits one instruction at a time |
| Use | Change a string, change a constant, or change simple logic | Change conditions, delete checks, or change control flow |
| async/await/state machine | Compilation often fails or the code becomes distorted | Directly change state machine fields with reliable results |

dnSpyEx's C# decompiler uses read-only decompilation plus attempted recompilation. Recompilation often fails for compiler-generated code such as state machines, closures, and `yield`. The IL editor changes one instruction at a time, so the result matches the edit.

### Typical IL patch patterns

```text
Change the condition (if (check) → always true):
  Original: call bool Foo::Check()
      brfalse.s SKIP
  Change: ldc.i4.1            ; push true
      brfalse.s SKIP      ; it never branches now, so SKIP does not execute
  Or more directly:
      ldc.i4.1
      ret                 ; the method returns true directly

Change the condition (if (check) → always false):
  ldc.i4.0
  ret

Delete the entire check:
  Replace everything with nop, or change it to ret + the correct return value

Change string constants:
  Changing strings in the C# editor usually works (replace the token directly in ldstr), but if the string is in resources or encrypted, change the decryption logic

Change numeric constants:
  Directly change the operands of ldarg / ldc instructions
```

## State machine identification (async/await / yield)

C# `async/await` and `IEnumerator` yield compile into a **state machine**. The compiler generates a nested class, and `MoveNext()` uses the `state` field for switch dispatch. The dnSpyEx C# view restores the code as async, but the decompilation can be inaccurate. The IL view of `MoveNext` is the most accurate.

```text
The MoveNext structure for async/await:
  switch(this.<>1__state) {
    case 0: ... logic before await; this.<>1__state = 1; await MoveNext;
    case 1: ... logic after await;
  }

To patch async logic: change the state transition in MoveNext or the condition in the specific case.
It almost always fails to edit async code in the C# editor → you must use IL.
```

## String decryptor extraction

See `obfuscators.md`. This section adds batch string decryption with dnlib scripts:

```csharp
// dnlib script: scan all string-decryptor calls, restore them at runtime, and write them back
// Usage: dotnet script decrypt.csproj target.exe 0x06000012
using System;
using System.Reflection;
using dnlib.DotNet;
using dnlib.DotNet.Writer;
using dnlib.DotNet.Emit;

var module = ModuleDefMD.Load(args[0]);
var decryptorToken = uint.Parse(args[1], System.Globalization.NumberStyles.HexNumber);

// Find the decryption method and invoke it through reflection (you must load the assembly into the AppDomain)
// Iterate through all methods and replace call Decryptor(token) with ldstr "decrypted result"
foreach (var type in module.GetTypes())
    foreach (var method in type.Methods)
    {
        if (!method.HasBody) continue;
        var instrs = method.Body.Instructions;
        for (int i = 0; i < instrs.Count; i++)
        {
            // Identify the call-decryptor pattern, invoke the decryptor to get the plaintext, and replace it with ldstr
            // (Omit the reflection-call boilerplate for the decryptor here; the approach is: load the original assembly →
            //   use MethodInfo.Invoke to get the plaintext → instrs[i] = OpCodes.Ldstr + operand=plaintext)
        }
    }

var opts = new ModuleWriterOptions(module);
module.Write("target-decrypted.exe", opts);
```

dnlib is the de facto standard for .NET metadata programming, and de4dot uses it internally. Use it first when you write a custom deobfuscation script.

## Dynamic debugging points

The dnSpyEx debugger is much friendlier for .NET programs than for native programs:

- **Breakpoint at the method entry**: Right-click the method → Add Breakpoint
- **View object values**: After the breakpoint hits, view object fields and string contents directly in the Locals / Watch windows
- **Write to memory**: Directly change runtime variable values with Edit Value
- **Exception breakpoints**: Select Debug → Exceptions, then check the exception types that must trigger a breakpoint. Obfuscators often use exceptions to drive control flow, so breaking on exceptions shows the real path

### Exception-Driven Control Flow

Some obfuscators put normal logic in `try` and use `throw` + `catch` for jumps. In a static view, IL looks like exception handling, but it actually controls the flow:

```text
try { throw new CustomException(0x42); }
catch (CustomException e) {
    switch(e.Code) {
        case 0x42: actual logic A; break;
        case 0x43: actual logic B; break;
    }
}
```

Set an exception breakpoint for `CustomException` and track how the `Code` value moves. This is faster than reading IL line by line.

## Module Initializer (`Module .cctor`)

The static constructor (`.cctor` of `<module>`) of a `.NET` module runs first when the assembly loads. Obfuscators often put anti-tamper / decryption initialization there. Analysis order:

```text
1. First inspect <module>.cctor (Module .cctor) — decryption/anti-debugging initialization
2. Then inspect Program.Main / Startup
3. Anti-tamper is in .cctor → patch .cctor before unpacking
```

## Common Patterns for Extracting Configuration / C2 / Key

Red-team tools and loaders often encrypt configuration data and embed it in resources or fields. They decrypt it at run time:

```text
Workflow:
1. Use strings to check for plaintext URLs/IPs (they are usually absent after obfuscation)
2. Find the byte[] field and the decryption method (AES/XOR)
3. Set a dynamic breakpoint at the return point of the decryption method and dump the decrypted plaintext
4. Common: AES-256-CBC with Key==IV (Codegate 2013 pattern; see reverse-engineering/tools.md .NET section)
```

See `references/sharp-tools.md` for the specific configuration structure of the red-team tool.

## Boundary with reverse-engineering

- **IL2CPP / NativeAOT** → Compiled to native code with no CLR metadata → Use `reverse-engineering/` (IDA/r2). This skill only identifies it
- **Managed .NET** (standard C# exe/dll, Mono/Unity managed layer, Xamarin) → Use this skill
- **Hybrid (native loader + .NET payload)** → Use `reverse-engineering/` for the loader. Dump the .NET payload, then use this skill

## List of Output Files

Each .NET reverse-engineering task should produce:
- `target-original.exe` (the original sample. Do not modify it)
- `target-clean.exe` (after unpacking with de4dot)
- `notes.md` (identified obfuscator, decryption token, key method addresses, configuration/C2/key)
- `target-patched.exe` (after patching, if needed)
- `il-diff.txt` (IL comparison before and after patching, if patched)
