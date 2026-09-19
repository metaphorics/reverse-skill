# [Seed] iOS jailbreak detection bypass + packet capture

## Scenario category
iOS reverse engineering / mobile security testing

## Goal summary
An iOS app crashes on launch or shows "environment error" on a jailbroken device. Bypass jailbreak detection before analyzing its HTTP requests.

## Full execution path

1. Prepare a jailbroken device (Dopamine / palera1n / unc0ver) → install frida-server from the Cydia source `build.frida.re`.
2. Copy the IPA to the device and sign it with AppSync Unified → confirm at launch that `frida-ps -U` works.
3. Start the App → it crashes or shows "environment error".
4. Trace detection calls with `frida-trace -U -i 'open' -i 'stat' -i 'access' -i 'fork' com.target.app`.
5. Common hits include checks for `/Applications/Cydia.app`, `/private/var/lib/apt`, `/usr/sbin/sshd`, successful `fork()`, and `/etc/apt`.
6. Bypass it with one objection command: `objection --gadget com.target.app explore -s "ios jailbreak disable"`.
7. After a successful launch, hook NSURLSession with Frida for packet capture, or install a system certificate with mitmproxy.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The App still crashed after the objection bypass | The App used both SSL Pinning and jailbreak detection | Enable `ios sslpinning disable` and `ios jailbreak disable` together | 15min |
| The App checked before launch and the hook was too late | Jailbreak detection ran in `+load` or `__attribute__((constructor))` | Use spawn mode with `-f` and `frida-trace --aux 'spawn=1'` | 20min |
| The App hung after hooking stat | The hook also affected some system calls | Hook only stat calls triggered by code inside the App bundle, filtered by caller | 30min |
| The App detected Frida after frida-server started | The App checked port 27042 and Frida strings | Rename `frida-server` and change its default port (`-l 0.0.0.0:1234`); use `-H ip:1234` in the client | 25min |
| SSL errors remained after installing a mitmproxy certificate | iOS 14+ requires another switch under "General → About → Certificate Trust Settings" | Enable the certificate in the trust settings after installation | 10min |

## Toolchain findings

- **objection** provides several iOS security-testing modules, including jailbreak, sslpin, clipboard, and keychain dump.
- **r2frida** connects radare2 to Frida. It can disassemble at runtime and modify registers, so it is more capable than bare Frida.
- **Hopper / IDA** decompile iOS binaries. IDA 7+ and Ghidra both work with iOS Mach-O files.
- **dumpdecrypted** is obsolete. Use **frida-ios-dump** for unpacking.

## Key code / commands

General jailbreak-detection hook template:

```javascript
// Intercept NSFileManager fileExistsAtPath checks for jailbreak directories
var NSFileManager = ObjC.classes.NSFileManager;
Interceptor.attach(NSFileManager['- fileExistsAtPath:'].implementation, {
    onEnter: function (args) {
        var path = ObjC.Object(args[2]).toString();
        var jbPaths = [
            '/Applications/Cydia.app',
            '/Library/MobileSubstrate/MobileSubstrate.dylib',
            '/bin/bash', '/usr/sbin/sshd',
            '/etc/apt', '/private/var/lib/apt/'
        ];
        if (jbPaths.indexOf(path) !== -1) {
            this.shouldFake = true;
            console.log('[+] Hide JB path: ' + path);
        }
    },
    onLeave: function (retval) {
        if (this.shouldFake) retval.replace(0);
    }
});

// Intercept fork() — a jailbroken device can fork, while a non-jailbroken device returns -1
var fork = Module.findExportByName(null, 'fork');
Interceptor.replace(fork, new NativeCallback(function () {
    return -1;
}, 'int', []));
```

One-command unpacking for decompilation with jadx:

```bash
frida-ios-dump -l com.target.app
# Output: Payload/TargetApp.app + unpacked Mach-O
```

## Improvement suggestions for this package

- Add a new `ios-reverse/` child skill parallel to `apk-reverse/`. Cover unpacking, jailbreak-detection bypass, SSL Pin, Keychain dump, frida-ios-dump, and `+load` timing.
- Keep iOS content out of `apk-reverse/` to avoid confusion.

## Reusable patterns / script fragments

**iOS security-testing quick reference**:

```text
1. Prepare the jailbroken environment (Dopamine 16.x / older palera1n)
2. Unpack with frida-ios-dump
3. Inspect class hierarchies with otool / class-dump
4. Start the objection console
5. ios jailbreak disable
6. ios sslpinning disable
7. Capture traffic with mitmproxy (enable both the system certificate and trust setting)
8. Deeply inspect key logic with IDA / Hopper after locating it
```

## Evolution actions
- [ ] **Add an ios-reverse skill** (the current iOS route uses reverse-engineering/platforms.md and lacks detail)
- [ ] Add frida-ios-dump to the bootstrap manifest
- [ ] Add an "iOS security-testing checklist" to references/

## Environment information
- Jailbroken device: iPhone X (iOS 16.5) + Dopamine 1.1.7
- Host: macOS 13+ / Kali (mitmproxy + frida-tools)
- frida-server-ios: 16.x

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real target. Bundle ID `com.target.app` is a placeholder.
