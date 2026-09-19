# [Seed] APK Frida bypass of OkHttp SSL Pinning

## Scenario category
APK reverse engineering / mobile security testing

## Goal summary
Use Frida to bypass certificate validation dynamically in an Android app that uses OkHttp and a custom CertificatePinner, so Burp can capture cleartext traffic.

## Full execution path

1. Install Frida and frida-server, start the target App, and confirm its process name.
   ```bash
   adb shell "ps -A | grep com.target.app"
   frida-ps -U | grep target
   ```
2. Try packet capture with Burp → receive a certificate error, which shows that Pinning is enabled.
3. Open the APK in jadx and decompile it → search for `CertificatePinner` or `checkServerTrusted`.
4. Confirm whether the app uses the built-in OkHttp `CertificatePinner` or a custom `X509TrustManager`.
5. Write a Frida script that hooks the key validation points.
6. Start Frida injection: `frida -U -f com.target.app -l bypass.js --no-pause`.
7. Capture traffic again → Burp can see cleartext HTTPS.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Frida reported `unable to connect to remote frida-server` | The server was not running or its port was occupied | Run `adb forward tcp:27042 tcp:27042` and start the server | 10min |
| The hook had no effect | The App started too quickly and Frida injected too late | Use spawn mode with `-f` and `--no-pause` | 15min |
| Some requests still failed with SSL errors after hooking | The app used both OkHttp and native HttpsURLConnection | Also hook `X509TrustManager.checkServerTrusted` and `HostnameVerifier.verify` | 20min |
| The App detected Frida and exited | The App checked the frida-server port and `/data/local/tmp/re.frida.server` | Use frida-gadget (inject the `.so` into the APK) or magisk + zygisk-frida | 30min+ |
| ProGuard obfuscation hid the class name | The class name became the short name `a.b.c` | Use `Find Usages` in jadx to find who instantiates OkHttpClient.Builder | 25min |

## Toolchain findings

- **objection** includes `android sslpinning disable`, which handles 80% of cases without a custom Frida script.
- **frida-multiple-unpinning** (GitHub: WithSecureLabs) covers OkHttp 3/4, Retrofit, HttpsURLConnection, Conscrypt, and Cordova with one script.
- **MEDUSA** includes Android bypass modules and is faster to start with than bare Frida.

## Key code / commands

Minimal working OkHttp Pin bypass script:

```javascript
Java.perform(function () {
    // 1. Built-in CertificatePinner for OkHttp 3/4
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function (host, peers) {
            console.log('[+] OkHttp CertificatePinner.check bypassed: ' + host);
            return;
        };
    } catch (e) {}

    // 2. Custom X509TrustManager.checkServerTrusted
    try {
        var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');
        TrustManagerImpl.verifyChain.implementation = function (untrusted, holdHost, host, clientAuth, ocspData, tlsSctData) {
            console.log('[+] TrustManagerImpl.verifyChain bypassed: ' + host);
            return untrusted;
        };
    } catch (e) {}

    // 3. Always pass HostnameVerifier
    var HostnameVerifier = Java.use('javax.net.ssl.HostnameVerifier');
    // Complete this with the template included in objection...
});
```

One-command option (recommended):

```bash
objection --gadget com.target.app explore -s "android sslpinning disable"
```

## Improvement suggestions for this package

- Add a dedicated `ssl-pinning-bypass.md` under `apk-reverse/references/`. Consolidate OkHttp 3/4, Conscrypt, custom TrustManager, and Flutter (boringssl) cases into a quick reference.
- Add `objection` (pip package) to the bootstrap manifest.

## Reusable patterns / script fragments

**General bypass flow**:

```text
1. Capture traffic → identify the error type (CertPin / Hostname / TrustManager)
2. Search key classes in jadx (CertificatePinner / X509TrustManager / HostnameVerifier)
3. Try one-command objection first → then frida-multiple-unpinning → then write a custom hook
4. If anti-Frida detection exists → switch to frida-gadget or zygisk
5. Handle Flutter apps separately (hook `libflutter.so` `ssl_verify_peer_cert`)
```

## Evolution actions
- [x] The routing matrix covers this case (apk-reverse + Frida)
- [x] The frida status in tool-index is checked
- [ ] Add an `ssl-pinning-bypass.md` quick reference

## Environment information
- Kali / Windows + adb + frida-tools 16.x
- Target Android: 8-14 (TrustManagerImpl paths differ by version)
- Injection method: USB debugging + frida-server, or hidden with zygisk-frida

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real target. The package name `com.target.app` is a placeholder.
