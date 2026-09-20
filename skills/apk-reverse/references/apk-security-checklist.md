# APK Security Testing Quick Reference

> Based on OWASP MASTG (Mobile Application Security Testing Guide).
> Covers six areas: static analysis, dynamic analysis, network communication, data storage, authentication and authorization, and code protection.

---

## Static Analysis Checklist

### Manifest Audit

```text
□ android:debuggable="true" → Debugging is enabled (must not occur in production)
□ android:allowBackup="true" → Data can be extracted through backups
□ Components with android:exported="true" → Exposed Activity/Service/Receiver/Provider
□ Custom permission protectionLevel → Check for normal (must be signature)
□ scheme in intent-filter → Check whether a custom deeplink can be hijacked
□ android:usesCleartextTraffic="true" → Cleartext HTTP is permitted
□ minSdkVersion too low → Security features can be missing
```

### Key Code Audit Checks

```text
□ Hardcoded keys/Token (search for "key", "secret", "password", "api_key")
□ Insecure random numbers (java.util.Random instead of SecureRandom)
□ Insecure encryption (ECB mode, DES, MD5 for passwords)
□ WebView configuration (setJavaScriptEnabled + addJavascriptInterface = RCE risk)
□ SQL injection (rawQuery concatenates user input)
□ Path traversal (ContentProvider openFile does not validate paths)
□ Log disclosure (Log.d/Log.i outputs sensitive information)
□ Clipboard disclosure (ClipboardManager stores sensitive data)
□ Implicit Intent disclosure (sendBroadcast does not specify a package name)
```

### Third-Party Library Audit

```text
□ Outdated OkHttp/Retrofit versions (known vulnerabilities)
□ Outdated WebView engine
□ SDKs with known vulnerabilities (check CVE)
□ Scope of data collection by advertising SDKs
□ Push notification SDK configuration (check for token disclosure)
```

---

## Dynamic Analysis Checklist

### Priority Frida Hook Targets

| Target | Hook Point | Purpose |
|------|---------|------|
| Login authentication | `LoginActivity.login()` | Monitor credential processing |
| Signature generation | `*Sign*`, `*sign*`, `*encrypt*` | Reconstruct the signature algorithm |
| SSL Pinning | `CertificatePinner.check` | Bypass pinning for packet capture |
| Root detection | `*root*`, `*su*`, `*magisk*` | Bypass detection |
| Encryption operations | `javax.crypto.Cipher` | Extract keys/IV |
| Token storage | `SharedPreferences.getString` | Monitor token reads and writes |
| Network requests | `OkHttpClient.newCall` | Monitor request construction |

### Common Frida One-Line Commands

```bash
# Trace all encryption operations
frida-trace -U -f com.target.app -j '*Cipher*!*'

# Trace all HTTP requests
frida-trace -U -f com.target.app -j '*OkHttp*!*'

# Trace SharedPreferences reads and writes
frida-trace -U -f com.target.app -j '*SharedPreferences*!*'

# Trace all native function calls
frida-trace -U -f com.target.app -i 'Java_*'
```

### Objection Quick Commands

```bash
# Connect
objection -g com.target.app explore

# Common commands
android hooking list activities
android hooking list services
android sslpinning disable
android root disable
android clipboard monitor
env                              # View application directories
sqlite connect <db_path>         # Connect to the database
```

---

## Network Communication Security

### Packet Capture Configuration

```text
Method 1: System proxy + Burp/mitmproxy
- Set the WiFi proxy → Burp listening address
- Install the CA certificate on the device
- Android 7+ requires network_security_config or a Frida bypass

Method 2: VPN mode (recommended)
- Use HttpCanary / Packet Capture
- No root access or proxy configuration is necessary
- Cannot decrypt traffic protected by SSL Pinning

Method 3: Frida + r2frida
- Intercept network calls directly within the process
- Not restricted by proxy/VPN limitations
```

### Checks

```text
□ Check for HTTPS use (all API calls)
□ Check for SSL Pinning (certificate pinning)
□ Check for correct certificate validation (reject self-signed certificates)
□ Check for certificate transparency (CT) checks
□ Check whether API keys are transmitted in cleartext in requests
□ Check whether Token expiration is implemented
□ Check for request signatures to prevent tampering
□ Check for replay attack protection (nonce/timestamp)
□ Check whether WebSocket is encrypted
□ Check for sensitive data in URL parameters (recorded in logs)
```

---

## Data Storage Security

### Locations to Check

| Location | Risk | Check Command |
|------|------|---------|
| SharedPreferences | Cleartext token/password storage | `adb shell cat /data/data/pkg/shared_prefs/*.xml` |
| SQLite database | Unencrypted sensitive data | `adb pull /data/data/pkg/databases/` |
| External storage | Any application can read it | `adb shell ls /sdcard/Android/data/pkg/` |
| Application logs | Disclosure of debugging information | `adb logcat \| grep pkg` |
| Backup files | allowBackup=true | `adb backup -f backup.ab pkg` |
| Keyboard cache | Input history | Check whether `inputType` is `textPassword` |
| Screenshot protection | Screenshots of sensitive pages are possible | Check `FLAG_SECURE` |

### Comparison of Encrypted Storage Methods

| Method | Security | Description |
|------|--------|------|
| Cleartext SharedPreferences | ❌ | Directly readable after root access is obtained |
| EncryptedSharedPreferences | ✓ | AndroidX Security library |
| SQLCipher | ✓ | Encrypted SQLite |
| Android Keystore | ✓✓ | Hardware-level key protection |
| Custom AES encryption | ⚠️ | Depends on key management |

---

## Authentication and Authorization

### Common Vulnerabilities

| Vulnerability | Test Method |
|------|---------|
| Weak password policy | Try 123456, password, and similar passwords |
| No lockout mechanism | Use brute force against the login endpoint |
| Token does not expire | Replay the old token after logout |
| Broken access control | Change user_id in the request |
| SMS verification codes permit brute force | 4/6 digits with no rate limit |
| Incorrect OAuth configuration | redirect_uri can be changed |
| Biometric authentication bypass | Hook BiometricPrompt |
| Device binding bypass | Change device_id |

### Test Payload

```bash
# Test for broken access control
curl -H "Authorization: Bearer USER_A_TOKEN" \
     "https://api.target.com/users/USER_B_ID/profile"

# Token replay
# 1. Log in normally to get a token
# 2. Log out
# 3. Send a request with the old token → Must return 401

# Use brute force against SMS verification codes
for code in $(seq 0000 9999); do
    curl -X POST "https://api.target.com/verify" \
         -d "phone=13800138000&code=$code"
done
```

---

## Code Protection Assessment

| Protection Measure | Detection Method | Bypass Difficulty |
|---------|---------|---------|
| ProGuard obfuscation | Use jadx to check whether class names are a/b/c | Low (renaming only) |
| String encryption | Search for decryption functions; use a Hook to get cleartext | Medium |
| Anti-debugging | Try to attach debugger | Medium (Frida can bypass it) |
| Root detection | Run on a device with root access | Medium (general-purpose scripts can bypass it) |
| Emulator detection | Run in an emulator | Low-Medium |
| Integrity verification | Change the APK, then install it | Medium (patch the verification function) |
| Hardening/packer protection | Examine the entry class and .so | Medium-High (requires unpacking) |
| Native protection | Core logic is in .so | High (requires IDA analysis) |
| VMP virtualization | Code execution is virtualized | Very high |

---

## Quick Test Procedure (30 Minutes)

```text
1. [5min] Unpacking + Manifest audit
   apktool d app.apk
   Check debuggable/allowBackup/exported/cleartext

2. [10min] Quick code audit
   jadx -d out app.apk
   Search: password, key, secret, token, http://

3. [5min] Network testing
   Configure the proxy → Operate the APP → Check for cleartext/weak encryption

4. [5min] Storage check
   adb shell → Check shared_prefs and databases

5. [5min] Dynamic verification
   Use Frida to hook key functions → Confirm findings
```