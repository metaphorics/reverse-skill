---
name: apk-reverse
description: Use for Android APK reverse engineering in a CLI environment. Applies to APK unpacking, Java decompilation, smali modification, repackaging, Frida dynamic Hook, and switching to so/native analysis as needed. Prefer locally installed jadx, apktool, frida, adb, ida-reverse, and radare2.
---

## ACTION REQUIRED (execute immediately after reading)

> Community references for endpoint extraction and adaptive Frida use: `../references/community-security-skills.md`. Dynamic analysis requires an authorized device scope.

1. `NOW`: Read `../field-journal/precedent-reverse.md` to confirm that this skill's operation is an authorized routine operation.
2. `NOW`: Confirm whether the current task matches this skill's scope.
3. `NEXT`: Read `../tool-index.md` to verify tool availability and actual paths.
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths.
5. `ACT`: Enter and execute the first workflow step. Do not stop in a confirmation state.

# APK Reverse Engineering CLI Procedure

## Scope

Use this skill first when the task includes any of these scenarios:

- Analyze APK Java business logic
- Locate login, signing, risk-control, certificate validation, or root detection logic
- View or modify `AndroidManifest.xml`
- View or modify smali
- Repackage an APK
- Use Frida for Java or native dynamic Hook
- Switch to native analysis when the APK contains `.so` files

## CLI Tools Verified on This Machine

- `jadx` `1.5.6`
- `apktool` `3.0.3`
- `frida-tools` `14.10.4` (`frida` core `17.18.0`)
- `adb`
- `java`

## When to Prefer Scripts

These workflows are frequent and their parameters are easy to get wrong. Prefer the scripts included with this skill:

- Run `jadx + apktool` once and write output and a summary: `scripts/decode.ps1`
- Check Frida devices, list processes, and inject with spawn/attach: `scripts/frida-run.ps1`
- Rebuild, align, sign, and install an APK: `scripts/rebuild-sign-install.ps1`
- Extract key Manifest components and permissions quickly: `scripts/manifest-summary.ps1`

Call these commands directly. Do not wrap them in another script:

- `adb devices`
- `adb logcat`
- `frida-ps -U`
- `jadx --version`
- `apktool --version`

## Included Scripts

### `scripts/decode.ps1`

Purpose:

- Run `jadx` and `apktool` with one interface
- Create a task output directory beside the original APK by default
- Output summaries such as `package`, `java_files`, `smali_dirs`, and `so_files`
- Support cases where `jadx` reports partial decompilation errors but produces usable output

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Name demo -SkipJadx
```

### `scripts/frida-run.ps1`

Purpose:

- Use one interface for Frida devices, processes, and spawn/attach entry points
- Avoid confusing `-f`, `-n`, and `-U` when writing parameters by hand

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -ListDevices
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -ListProcesses
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -Spawn -Package com.example.app -ScriptPath "D:\hooks\test.js"
```

### `scripts/rebuild-sign-install.ps1`

Purpose:

- Rebuild an APK with `apktool b`
- Align with `zipalign`
- Sign and verify with `apksigner`
- Optionally install directly with `adb install`

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- Generate and reuse a debug keystore by default
- Write output beside `ProjectDir` by default, so it stays with the original package and unpacked directory

### `scripts/manifest-summary.ps1`

Purpose:

- Extract the package name
- List permissions
- List activity, service, receiver, and provider components
- Mark the main launcher activity

Example:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\manifest-summary.ps1" -ManifestPath "C:\work\apktool_out\AndroidManifest.xml"
```

For `.so`, `lib/arm64-v8a/*.so`, or `lib/armeabi-v7a/*.so` analysis, also use:

- `ida-reverse`
- `radare2`

## Tool Roles

### `jadx`

Use it for:

- Java decompilation and reading
- Searching package, class, and method names
- Understanding APK logic at a high level first

Common commands:

```bash
jadx -d jadx_out app.apk
jadx --single-class com.example.LoginActivity -d jadx_out app.apk
jadx --deobf -d jadx_out app.apk
```

### `JEB Pro` (optional commercial tool)

Use it for:

- Cross-checking and deep decompilation of Android DEX, APK, and ARM targets
- Supplementing static analysis when JADX output is incomplete or heavily obfuscated
- Cross-checking classes, methods, and call relationships for the same target with a second toolchain

Boundaries:

- JEB Pro is commercial software. The user must obtain it and install a valid license. This package does not download, crack, or bypass the license.
- Call it only when `tool-index` confirms that JEB is available locally. Otherwise continue with `jadx`, `apktool`, Ghidra, IDA, or radare2.
- A third-party JEB MCP bridge is not a package dependency. Before installation, review its source, permissions, network behavior, and version under `../ops/skill-supply-chain.md`. Then require the user to confirm registration.

### `apktool`

Use it for:

- Unpacking APKs
- Viewing and modifying `AndroidManifest.xml`
- Viewing and modifying smali
- Rebuilding APKs

Common commands (Apktool 3 is AAPT2-only and 64-bit only; the legacy `-api` flag is gone):

```bash
apktool d app.apk -o apktool_out
apktool b apktool_out -o rebuilt.apk
```

### `frida`

Use it for:

- Observing Java method calls dynamically
- Hooking native exported functions
- Bypassing root detection, certificate validation, and debugger detection

Common commands:

```bash
frida-ps -U
frida -U -f com.example.app -l hook.js
frida-trace -U -f com.example.app -j '*!*certificate*'
```

### `adb`

Use it for:

- Connecting to devices
- Installing APKs
- Viewing logs
- Pulling files

Common commands:

```bash
adb devices
adb install -r app.apk
adb shell pm list packages
adb logcat
adb pull /data/local/tmp/file .
```

## Recommended Workflow

### 1. Triage

First determine the APK's rough structure. Do not modify the package or add Hooks yet.

Recommended actions:

1. Export Java code with `jadx -d jadx_out app.apk`.
2. Export smali and resources with `apktool d app.apk -o apktool_out`.
3. Check these items first:
   - `AndroidManifest.xml`
   - Main `package`
   - `application`, `activity`, `service`, and `receiver`
   - Any `.so` files in the `lib/` directory
4. Use the Issue #65 threat quick reference for authorized samples and devices. See `../reverse-engineering/references/nonpe-format-cookbook.md` sections 7–8:
   - Transparent or hidden icons (AU): use `aapt dump badging` and Manifest theme, label, and icon data. Record `E-android-hidden-icon-manifest`.
   - Magisk, device-wipe script, and remote `curl|sh` indicators (AR/AS): record the indicators and URL as evidence. **Do not execute** destructive commands.
   - Persistence paths (AT), such as `service.d` and `priv-app`: record `E-android-persistence`.

### 2. Observe Java Logic

Read these items from `jadx_out` first:

- `MainActivity`
- `Application`
- Login, network, encryption, and risk-control classes
- Third-party SDK initialization classes

Common keywords:

- `login`
- `sign`
- `encrypt`
- `cipher`
- `token`
- `root`
- `certificate`
- `trust`
- `okhttp`
- `retrofit`
- `webview`

If the Java code is readable, locate the business logic there first.

### 3. Confirm Smali and Resources

Switch to `apktool_out` when `jadx` output is incomplete, heavily obfuscated, or requires an actual patch:

- Check `smali*/`.
- Check `res/values/strings.xml`.
- Check `AndroidManifest.xml`.

Patch these items first:

- `android:exported`
- Debug flags
- Root detection return values
- Login validation logic
- Certificate validation branches

### 4. Rebuild and Install

After changes:

```bash
apktool b apktool_out -o rebuilt.apk
```

Or run the complete flow with the script:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- This skill guarantees only the `apktool` rebuild path.
- A later device installation normally also requires signing.
- Add `apksigner` and `zipalign` when the task includes signing or alignment.

### 5. Dynamic Hook

Use Frida when static analysis is not enough:

- Hook the login function.
- Hook key points in `OkHttp`, `Retrofit`, or `WebView`.
- Hook `javax.crypto` and `MessageDigest`.
- Hook root detection functions.
- Hook SSL pinning logic.

Principles:

- Hook the Java layer first. Then decide whether a native Hook is needed.
- Print parameters and return values first. Then decide whether to modify return values.

Recommendations:

- Use `frida-*` for a simple one-time command.
- Use `scripts/frida-run.ps1` for an injection flow that needs stable reuse.

### 6. Native `.so` Branch

When the APK contains important `.so` files:

- Find `lib/**/*.so` with `apktool` or `jadx`.
- Use `radare2` for exported symbols, strings, and quick triage.
- Use `ida-reverse` for long-term analysis, decompilation, renaming, and type recovery.

Switch to native analysis quickly when you see these signals:

- The Java layer only wraps JNI.
- Core signing logic is not in Java.
- Key logic disappears after `System.loadLibrary()`.
- Certificate validation or risk control is in `.so` files.

## Output Requirements

At minimum, report these items:

- Entry components and key classes
- Whether key logic is in Java, smali, or `.so`
- Confirmed sensitive points: login, signing, root, SSL, WebView, and JNI
- What changed if you made a patch
- Which class, method, or exported function you Hooked

## Prohibited Actions

- Do not modify smali blindly at the start.
- Do not write a Hook before viewing the Manifest and main entry point.
- Do not treat incomplete Java decompilation as proof that the logic cannot be analyzed.
- Do not keep working at the Java layer when `.so` files clearly carry the core logic.

## Quick Command Notes

```bash
# Java decompilation
jadx -d jadx_out app.apk

# APK unpacking
apktool d app.apk -o apktool_out

# Rebuild the APK
apktool b apktool_out -o rebuilt.apk

# Devices and processes
adb devices
frida-ps -U

# Launch and inject
frida -U -f com.example.app -l hook.js
```

---

## Routing Context

**Upstream entry**: `skills/SKILL.md` (controller) and `routing.md`
**Downstream exits**:
- Core logic in `.so` → `ida-reverse/` or `radare2/`
- Dynamic Hook or validation needed → `reverse-engineering/tools-dynamic.md` (Frida section)
- General reverse engineering methods → `reverse-engineering/SKILL.md`

**Related module**: `reverse-engineering/` (advanced `.so` analysis and Frida use)

---

## On-Demand Bootstrap

The entry scripts for this skill use the unified bootstrap system. When a tool is missing, they try to install it instead of failing immediately.

### Automation Boundaries

| Tool | Can install automatically | Installation method | Notes |
|------|-----------|---------|------|
| jadx | ✓ | GitHub Release ZIP | Download and extract to `%USERPROFILE%\Tools\jadx\` automatically |
| apktool | ✓ | GitHub Release JAR + wrapper | Download the jar and create a bat file in `%USERPROFILE%\Tools\apktool\` automatically |
| JEB Pro | ✗ | User installs it manually and provides a valid license | Optional Android / ARM cross-check tool. Audit a third-party MCP bridge separately. |
| frida / frida-ps | ✓ | pip install frida-tools | Python must be installed. |
| adb | ✓ | winget / fallback path | Install Android Platform-Tools automatically. |
| zipalign | ✗ | Install Android Build-Tools manually | `sdkmanager "build-tools;35.0.0"` |
| apksigner | ✗ | Install Android Build-Tools manually | Same as above |

### Bootstrap Triggers

- `scripts/decode.ps1`: Automatically calls `bootstrap-reverse.ps1` when jadx or apktool is missing.
- `scripts/rebuild-sign-install.ps1`: Automatically calls bootstrap when adb or apktool is missing.
- `scripts/frida-run.ps1`: Checks are still manual. Frida is usually already installed through pip.

### If Bootstrap Fails

If automatic installation fails, the script raises a clear error and includes a manual installation link. Common causes:
- Network connection failure (GitHub API / PyPI is unreachable)
- winget is unavailable (Windows version is too old)
- Java is not installed (apktool requires a JDK)


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow (not just read it)?
- [ ] Did I use actual tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and record the Checklist items required by RULES?
- [ ] If hidden-icon/device-wipe/persistence indicators were found: did I record E-android-* Evidence according to the U–AV cookbook (within the scope of authorization)?
