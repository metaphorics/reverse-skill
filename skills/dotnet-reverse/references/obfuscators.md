# Detailed .NET Obfuscator Deobfuscation

Identification, unpacking, and anti-tamper bypass for mainstream .NET obfuscators. Core tools: **de4dot** (automatically identifies most packers) + **dnSpyEx** (manual patching) + **dnlib** (scripting).

## Overall Decision Table

| Obfuscator | de4dot type | Typical features | Automatic unpacking | Manual points |
|--------|-------------|---------|---------|---------|
| ConfuserEx 1.x/2.x | `cfze` | anti-tamper, control-flow transformation, string encryption, anti-debugging | ✅ Mostly automatic | Patch anti-tamper first for newer versions |
| ConfuserEx 3.x / custom builds | `cfze` | Same as above + custom protector | ⚠️ Partial | Dump at runtime / dnlib |
| SmartAssembly | `sa` | String encoding, resource compression, hidden method calls | ✅ Automatic | Decompress resources |
| Babel.NET | `babel` | Method-body encryption, control flow, strings | ✅ Automatic | — |
| Eazfuscator.NET | `eaz` | String/resource encryption, expression obfuscation | ⚠️ Partial | String decryptor |
| .NET Reactor | `reactor` | necrobit (code-section encryption) + anti-tamper | ⚠️ Difficult for newer versions | Dump + rebuild metadata |
| Themida .NET | — | Wrapper + virtualization | ❌ de4dot does not work | Dump memory and use a native approach |
| Agile.NET / CliSecure | `agile` | Method-body encryption | ✅ Automatic | — |

## Standard de4dot Usage

```powershell
# Automatic identification (enough for most cases)
de4dot target.exe -o target-clean.exe

# Explicitly specify type (when automatic identification fails)
de4dot --type cfze target.exe -o target-clean.exe

# Detect the packer type first
de4dot --detect target.exe

# Batch
de4dot *.exe

# Unpack strings only; do not modify control flow (minimal intervention)
de4dot --strtyp delegate --strtok METHOD_TOKEN target.exe
```

The `--strtyp` / `strtok` mode of de4dot: Decrypt only the string decryptor by specifying the decrypt method token, and keep the original control flow. Use this when you only want to view plaintext strings and do not want to touch anti-tamper.

---

## ConfuserEx (Most Common)

### Feature Identification

- The entry module `<module>` class has an anti-tamper check with `[MethodImpl(NoInlining)]`
- Many string decryptor calls that use `Dictionary<string, T>`
- Control-flow flattening (switch dispatch + state variable)
- `.cmp` compressed resources embedded in resources
- dnSpyEx C# view: Class and method names are unreadable (`\uXXXX` or meaningless characters), and the method body is full of `int num = ...; switch(num)`

### Unpacking Process

```powershell
# 1. Standard unpacking
de4dot target.exe -o target-clean.exe

# 2. If de4dot reports "unknown" or the file will not open after unpacking → newer/custom-modified ConfuserEx
#    Confirm anti-tamper first:
Open in dnSpyEx → find the integrity check in Module .cctor or Main
```

### anti-tamper Bypass (Common in Newer ConfuserEx Versions)

ConfuserEx `anti tamper` checks method-body hashes at runtime. It crashes if the code changes. de4dot usually handles older versions. Newer versions require manual work:

```text
Method A — patch the check function directly in dnSpyEx:
  1. Find the anti-tamper check method (usually called in the static constructor of <module>)
  2. Edit the IL: change the check method body to ret (return directly)
  3. Save → feed it to de4dot again

Method B — dump at runtime:
  1. Run it with MegaDumper / ExtremeDumper and dump the assembly from memory
  2. The dump is already decrypted; use de4dot to clean up the leftovers
```

### After Control-Flow Restoration

de4dot restores a flattened switch dispatch to normal if/while logic. If it does not restore all of it and you see a remaining state machine, run de4dot again or trace the IL manually.

---

## SmartAssembly

```powershell
de4dot --type sa target.exe -o target-clean.exe
```

Features:
- Encode strings with the `SmartAssembly.Runtime.Strong` series
- Compress resources (`{assembly}.Resources`)
- Hide method calls (`ProcessCaller` / indirect call)

de4dot has the best compatibility with SmartAssembly and usually works with one click.

---

## .NET Reactor (necrobit)

`.NET Reactor` **necrobit** encrypts real method bodies and stores them in resources. It decrypts and injects them at run time. The original method body is a stub. de4dot works with older versions but often fails with newer versions (4.x+).

```text
When de4dot fails:
1. Run the program (dotnet target.exe or double-click it)
2. Use MegaDumper / ExtremeDumper to dump the process memory → export the decrypted assembly
3. Use de4dot to clean up leftover obfuscation in the dump
4. If the metadata is corrupted, rebuild it with dnlib (see common-workflow.md)
```

---

## Manually Extract the String Decryptor

The obfuscator encrypts strings and calls a decryption method at run time to restore them. de4dot can identify most decryptors automatically. If identification fails, do it manually:

```text
1. Use dnSpyEx to find the decryption method (the signature is usually fixed: static string Decrypt(int) or Decrypt(string, int))
   - Characteristics: called many times, takes numeric constants as parameters, returns string
2. Record the method token (such as 0x06000012)
3. Specify the decryptor in de4dot:
   de4dot --strtyp delegate --strtok 0x06000012 target.exe -o target-clean.exe
```

If the decryption method itself is also obfuscated with control-flow flattening, first restore the control flow and then locate the decryptor.

## Common anti-debug Techniques

| Technique | Location | Bypass |
|------|------|------|
| `Debugger.IsAttached` check | Any method | Change IL to `ldc.i4.0; ret` or patch the getter |
| `Debugger.IsLogging` | — | Same as above |
| Time check (`DateTime.Now` difference) | Method entry | Patch out the difference comparison |
| `CheckRemoteDebuggerPresent` P/Invoke | — | Nop the call |
| Exception-driven control flow (try/catch path selection) | Main logic | Do not simply nop it. Analyze the real path in the catch block |

> .NET anti-debugging is simpler than native anti-debugging. Most cases use managed API calls. Change one IL line in dnSpyEx.

## Fallbacks When de4dot Fails

1. **de4dot --detect** Check the detection result against the table above
2. **Runtime dump** (MegaDumper / ExtremeDumper / Process Hacker export the module)
3. **dnlib script** Decode manually (see the dnlib section in common-workflow.md)
4. **Dynamic first**: Run it and set a breakpoint at the decryption point. View the plaintext directly. You can collect information without unpacking.

Community references: Washi blog "misconceptions-about-dotnet" (common misconceptions in IL analysis), Kanxue .NET reverse engineering section, Guided Hacking "Top 5 .NET RE Tools".
