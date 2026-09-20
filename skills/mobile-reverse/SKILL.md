---
name: mobile-reverse
description: Use for authorized Android or iOS application reverse engineering and security testing, including APK or IPA analysis, runtime instrumentation, SSL pinning, and platform protection checks.
---
# Mobile Reverse Engineering

## ACTION REQUIRED (Execute immediately after you read this file)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — Make sure that the operations in this skill are authorized routine operations.
2. `NOW`: Make sure that the current task is in the scope of this skill.
3. `NEXT`: Read `../tool-index.md`. Check tool availability and actual paths.
4. `NEXT`: If tools are missing, call bootstrap. Do not guess paths.
5. `ACT`: Start and execute the first step in "Workflow". Do not stop after confirmation.

> A common reverse engineering method for Android + iOS
> Frida / Objection / OWASP MSTG / SSL Pinning Bypass

## Scope

- Android APK reverse engineering and security tests
- iOS IPA reverse engineering and security tests
- Dynamic instrumentation of mobile applications at runtime
- Bypass of SSL Pinning / Root detection / jailbreak detection
- Extraction of mobile application cryptographic algorithms (AES/RSA/HMAC keys)
- Mobile application penetration tests (OWASP MASTG)
- Application tests without Root/jailbreak access

## Four-Phase Workflow

### Phase 1: Information Collection

```text
Android:
□ Get the APK (Google Play / APKMirror / adb pull).
□ Analyze the Manifest: permissions, exported components, Intent Filter, backup flag.
□ androguard: androguard analyze APK → components/permissions/signatures
□ APKLeaks: Scan for hard-coded API Key / Token / Secret values.
□ Check for application protection: packers (360/Tencent/Bangcle/iJiami).

iOS:
□ Get the IPA (App Store / ipatool / Apple Configurator).
□ Decrypt the App Store binary: frida-ios-dump / Clutch.
□ Analyze Info.plist: ATS configuration, URL Scheme, Queries Schemes.
□ class-dump: Export ObjC class structures.
□ Check for application protection: Swift/ObjC obfuscation.
```

### Phase 2: Static Analysis

```text
Cross-platform:
□ JADX-GUI: APK → Java source code (Android)
□ Ghidra / Hopper: Decompile .so / Mach-O files.
□ radare2 / Cutter: Do a quick initial examination with the CLI.

Android-specific:
□ apktool d app.apk → smali code + resources
□ dex2jar: DEX → JAR → JD-GUI
□ smali/baksmali: Modify Dalvik bytecode.

iOS-specific:
□ class-dump: Export ObjC header files.
□ Recover Swift symbols: swift-demangle.
□ dsymutil: Extract debug symbols.
□ otool -L: Examine dynamic library dependencies.
□ jtool2: Analyze Mach-O files.
```

### Phase 3: Dynamic Analysis

```text
Frida — General-purpose dynamic instrumentation:
□ frida-ps -U: List device processes.
□ frida-trace -U -i "open*" com.app: Trace function calls.
□ Custom Hook scripts: Modify parameters/return values and call private methods.

Objection — Frida extension layer (no scripts necessary):
□ objection -g "com.app" explore
□ android root disable / ios jailbreak disable
□ android sslpinning disable / ios sslpinning disable
□ android keystore list / ios keychain dump
□ env / ls / sqlite connect

Frida Gadget (no Root/jailbreak necessary):
□ Inject frida-gadget.so / FridaGadget.dylib into the APK/IPA.
□ Sign again → Install → Install hooks without privileged device access.
□ objection patchapk --source app.apk (fully automatic)
```

### Phase 4: Network Analysis

```text
□ Burp Suite: Intercept HTTP/HTTPS and modify requests/responses.
□ mitmproxy: Use a script-controlled proxy (Python API).
□ Wireshark: Analyze PCAP packet captures.
□ Install certificates: Android user certificates → system certificates (Magisk + MoveCert).
□ Bypass SSL Pinning: Frida/Objection/Xposed/SSL Kill Switch 2.
□ Analyze WebSocket / gRPC traffic.
```

## Common Bypass Quick Reference

### SSL Pinning

```bash
# Objection (simplest method)
objection -g "com.app" explore
android sslpinning disable

# Frida general-purpose script
frida -U -l ssl_pinning_bypass.js -f com.app

# Xposed (Android)
TrustMeAlready module → Disable certificate verification globally.
```

### Root / Jailbreak Detection

```bash
# Objection
android root disable
ios jailbreak disable

# Custom Frida script (multiple detection layers)
Java.perform(function() {
    var RootBeer = Java.use("com.scottyab.rootbeer.RootBeer");
    RootBeer.isRooted.implementation = function() { return false; };
    // Additional bypasses: Magisk su detection, frida-server detection, /proc/self/maps detection.
});
```

### Anti-Debugging

```bash
# Android
frida -U -l anti_debug_bypass.js -f com.app
# Bypass: ptrace(TracerPid), /proc/self/status, isDebuggerConnected().

# iOS
# Bypass: PT_DENY_ATTACH, sysctl CTL_KERN/KERN_PROC/KERN_PROC_PID.
frida -U -l ios_anti_debug.js -f com.app
```

## Mobile Cryptographic Data Extraction

```javascript
// Android — Hook Cipher.getInstance to get the key+algorithm.
Java.perform(function() {
    var Cipher = Java.use("javax.crypto.Cipher");
    Cipher.getInstance.overload('java.lang.String').implementation = function(algo) {
        console.log("[Cipher] Algorithm: " + algo);
        return this.getInstance(algo);
    };
    Cipher.init.overload('int', 'java.security.Key').implementation = function(mode, key) {
        console.log("[Cipher] Key: " + bytesToHex(key.getEncoded()));
        return this.init(mode, key);
    };
});

// iOS — Hook CCCrypt
Interceptor.attach(Module.findExportByName("libcommonCrypto.dylib", "CCCrypt"), {
    onEnter: function(args) {
        console.log("CCCrypt op: " + args[0] + " alg: " + args[1]);
        console.log("Key: " + hexdump(args[3], { length: args[4].toInt32() }));
    }
});
```

## Toolchain

| Tool | Platform | Purpose |
|------|:--:|------|
| JADX-GUI | A | Java decompilation |
| apktool | A | APK unpacking/rebuilding |
| Ghidra | A+I | Multi-architecture decompilation |
| Hopper | I | iOS-specific disassembly |
| Frida (frida-tools 14.10.4) | A+I | Dynamic instrumentation |
| Objection 1.12.5 | A+I | Frida REPL extension |
| MobSF | A+I | Automatic SAST+DAST |
| class-dump | I | ObjC class export |
| frida-ios-dump | I | IPA decryption |
| jtool2 | I | Mach-O analysis |
| Burp Suite | A+I | HTTP interception |
| mitmproxy | A+I | Script-controlled proxy |

> A=Android, I=iOS

## References

- `references/frida-objection-deep.md` — Advanced use of Frida + Objection
- `references/ios-reverse-guide.md` — iOS-specific reverse engineering
- `references/anti-detection-bypass.md` — Bypass of Root/jailbreak/anti-debugging/SSL Pinning


## Task Completion Check (You MUST pass before you report completion)

- [ ] Make sure that you executed each workflow step, not only read it.
- [ ] Make sure that you used actual tool paths from `tool-index`.
- [ ] Make sure that you produced reproducible evidence (commands/scripts/screenshots/reports).
- [ ] Make sure that you completed and recorded the Checklist items that RULES requires.