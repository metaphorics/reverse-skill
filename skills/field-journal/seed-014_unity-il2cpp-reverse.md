# [Seed] Unity IL2CPP game reverse engineering → recover metadata + modify logic

## Scenario category
Game security / mobile reverse engineering

## Goal summary
An Android game built with Unity uses IL2CPP. In-game purchases or core algorithms were written in C# and compiled to native code. Recover method names, locate key logic, and modify or hook it.

## Full execution path

1. Unpack the APK and confirm IL2CPP.
   ```bash
   unzip target.apk -d apk
   ls apk/lib/arm64-v8a/        # libil2cpp.so confirms IL2CPP
   ls apk/assets/bin/Data/Managed/Metadata/
   # Key file: global-metadata.dat
   ```
2. Recover metadata with **Il2CppDumper**.
   ```bash
   Il2CppDumper libil2cpp.so global-metadata.dat output/
   # Output: DummyDll/ + script.json + il2cpp.h + dump.cs
   ```
3. Run IDA's IL2CPP script (`ida_with_struct.py`).
   - Load libil2cpp.so → File → Script File → select ida_with_struct.py → select script.json.
   - IDA can now show C# method names, signatures, and strings.
4. Search `dump.cs` by business keywords (`AddCoin` / `OnPurchase` / `Verify` / `IsVip` / `CheckSign`).
5. Get the key method offset → jump to it in IDA and inspect the disassembly or decompilation.
6. Choose a modification method:
   - **Static patch**: change the condition in IDA to `mov w0, #1; ret`.
   - **Dynamic hook**: attach Frida to the il2cpp method with Frida-Il2CppBridge.
7. Verify the repackaging or injection.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Il2CppDumper reported an unsupported metadata version | A newer Unity version changed the metadata format | Upgrade Il2CppDumper or use Il2CppInspectorRedux | 30min |
| `global-metadata.dat` was encrypted | The game used AntiCheatToolkit or custom encryption | Find the decryption function during game initialization, usually around il2cpp_init → dump after mmap with Frida | 2h |
| `dump.cs` showed method names but IDA found no matches | `script.json` did not match the `.so` | Use output from the same dump and clear the cache when changing IDA | 20min |
| Frida hook of an IL2CPP method failed | IL2CPP methods are not standard Java/ObjC methods and need a method offset | Use the frida-il2cpp-bridge library instead of writing Interceptor.attach manually | 1h |
| The game crashed after a patch | It checked a file hash or used anti-tamper protection | Patch the hash-check logic too, or use a hook without changing the file | 2h |
| The game crashed after repackaging | An apksigner v2 signature cannot survive byte changes before signing again | Remove META-INF, run apktool b, and sign with apksigner in one sequence | 30min |

## Toolchain findings

- **Il2CppDumper** is old but remains a common default.
- **Il2CppInspectorRedux** is newer. It supports new Unity versions and can output plugin scripts for IDA, Ghidra, and Binary Ninja.
- **frida-il2cpp-bridge** is a common IL2CPP hooking library and is more capable than bare Frida.
- **DnSpy** / **dnSpyEx** inspect the DummyDll (the pseudo-.NET assembly produced by the dump).
- **UnityCheat** tools help with analysis. (The GameGuardian family is outside this entry.)

## Key code / commands

Frida-Il2CppBridge hook example:

```typescript
// hook.ts
import "frida-il2cpp-bridge";

Il2Cpp.perform(() => {
    const Assembly = Il2Cpp.domain.assembly("Assembly-CSharp").image;

    // Hook a static method
    const PlayerData = Assembly.class("PlayerData");
    PlayerData.method("AddCoin").implementation = function (n: number) {
        console.log("[+] AddCoin called with:", n);
        return this.method("AddCoin").invoke(99999); // Set to 99999
    };

    // Hook an instance method
    const Purchase = Assembly.class("Purchase");
    Purchase.method("VerifyReceipt").implementation = function () {
        console.log("[+] VerifyReceipt → always true");
        return true;
    };
});
```

# Compile and inject
npm install frida-il2cpp-bridge
frida-compile hook.ts -o hook.js
frida -U -f com.target.game -l hook.js --no-pause
```

IDA static patch:

```text
1. Open libil2cpp.so and run il2cpp_load_metadata.py
2. Jump to the offset for IsPurchaseValid in dump.cs
3. Change the function start to MOV W0, #1; RET (ARM64)
4. Apply Patches → Save → replace the APK → sign again
```

## Improvement suggestions for this package

- `reverse-engineering/SKILL.md` covers Unity but lacks a full IL2CPP workflow case.
- Add `reverse-engineering/references/il2cpp-cheatsheet.md` with dump-tool comparisons, a Frida bridge template, and encrypted-metadata handling.
- Add frida-il2cpp-bridge to the bootstrap manifest.

## Reusable patterns / script fragments

**Standard IL2CPP flow**:

```text
1. Confirm IL2CPP (check for libil2cpp.so under lib/abi)
2. Find metadata (assets/bin/Data/Managed/Metadata/global-metadata.dat or an encrypted copy)
3. Recover it with Il2CppDumper / Inspector
4. Restore metadata in IDA with the script
5. Search business keywords in dump.cs
6. Choose a patch or a hook
7. Verify (launch plus a real scenario)
```

**Encrypted metadata handling**:

```text
1. Hook fopen/open calls with Frida and find who reads global-metadata.dat
2. Dump the decrypted metadata from memory after mmap/read
3. Feed the dumped memory to Il2CppDumper as metadata
```

## Evolution actions
- [ ] Add a full il2cpp section to reverse-engineering/references
- [ ] Add frida-il2cpp-bridge / Il2CppInspectorRedux to the bootstrap manifest
- [x] The routing matrix includes Unity / IL2CPP

## Environment information
- Windows / macOS (for running Il2CppDumper), target Android arm64 device
- IDA Pro 7.7+ or Ghidra 11+
- frida-tools 16.x, frida-il2cpp-bridge 0.9+
- Unity version: 2019.x - 2022.x (metadata formats vary slightly)

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real game. The package name `com.target.game` is a placeholder.
