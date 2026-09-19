# Frida Bypass Kit — General Android Security Bypass Framework

> Source: [FridaBypassKit](https://github.com/okankurtuluss/FridaBypassKit) (2025)
> Use cases: Bypass root detection, SSL pinning, emulator detection, and anti-debugging during APK dynamic analysis

## Overview

FridaBypassKit is a Frida script with four main bypass functions. It works without changes for a specific app.

## Four Main Bypass Functions

### 1. Root Detection Bypass

- Hook `File.exists()` to hide su binaries
- Intercept root check calls to `Runtime.exec()`
- Hide root-related packages (Magisk, SuperSU, and others) from PackageManager
- Change system properties to make the device appear unrooted

### 2. SSL Pinning Bypass

- Hook `TrustManagerImpl.verifyChain()`
- Hook `TrustManagerImpl.checkTrustedRecursive()`
- Bypass certificate validation for the chain
- Return an empty certificate chain to prevent validation
- Support OkHttp, Retrofit, and custom implementations

### 3. Emulator Detection Bypass

- Return false values from TelephonyManager
- Return a false phone number and operator name
- Change Build properties

### 4. Anti-Debugging Bypass

- Hook `Debug.isDebuggerConnected()`
- Prevent debugger detection
- Bypass anti-debugging checks

## Instructions for Use

```bash
# Prerequisites
pip install frida-tools
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
adb shell su -c /data/local/tmp/frida-server &

# Inject into the target app
frida -U -f com.example.app -l FridaBypassKit.js
```

## Other Recommended Frida Bypass Scripts

| Project | Features | Link |
|------|------|------|
| httptoolkit/frida-interception-and-unpinning | Directly intercepts all HTTPS traffic through MitM | [GitHub](https://github.com/httptoolkit/frida-interception-and-unpinning) |
| 0xCD4/SSL-bypass | Provides a general SSL bypass without customization | [GitHub](https://github.com/0xCD4/SSL-bypass) |
| incogbyte/ssl-bypass gist | Bypasses common SSL pinning methods | [Gist](https://gist.github.com/incogbyte/1e0e2f38b5602e72b1380f21ba04b15e) |
| Zero3141/Frida-OkHttp-Bypass | Specifically targets OkHttp CertificatePinner | [GitHub](https://github.com/Zero3141/Frida-OkHttp-Bypass) |

## Integration with This Package

Use this script in the `apk-reverse` workflow for these conditions:

1. The app detects root and refuses to run → Enable Root Detection Bypass
2. HTTPS requests do not show plain text during packet capture → Enable SSL Pinning Bypass
3. The app detects an emulator and refuses to run → Enable Emulator Detection Bypass
4. The app crashes after you attach Frida → Enable Debug Detection Bypass

Recommended combined use: Run the full FridaBypassKit first. Then make specific adjustments.