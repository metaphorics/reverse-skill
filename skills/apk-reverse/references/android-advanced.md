# Android Advanced Reverse Engineering Reference

> Covers Native SO analysis, advanced Frida use, SSL Pinning bypass, Root detection bypass, packer protection and unpacking, and Flutter/React Native reverse engineering.

---

## Native SO Reverse Engineering

### Analysis Procedure

```text
1. Extract .so files from the APK
   unzip app.apk lib/arm64-v8a/*.so -d extracted/

2. Identify the architecture and basic information
   file libxxx.so
   rabin2 -I libxxx.so

3. Find JNI entry points
   - Search for JNI_OnLoad (dynamic registration)
   - Search for Java_com_xxx_yyy (static registration)
   - nm -D libxxx.so | grep -i java

4. Load files in IDA/Ghidra for analysis
   - Import JNI header files (jni.h types)
   - Label JNIEnv* parameters
   - Find RegisterNatives calls (the function table for dynamic registration)

5. Find key logic
   - Trace native method names from the Java layer
   - Follow cross-references from strings (keys, URLs, error messages)
   - Trace crypto library function calls (AES/MD5/SHA)
```

### JNI Function Registration

```c
// Static registration: function name = Java_packageName_className_methodName
JNIEXPORT jstring JNICALL Java_com_example_app_Security_getSign(
    JNIEnv *env, jobject thiz, jstring input) { ... }

// Dynamic registration: Call RegisterNatives in JNI_OnLoad
static JNINativeMethod methods[] = {
    {"getSign", "(Ljava/lang/String;)Ljava/lang/String;", (void*)native_getSign},
};

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env;
    vm->GetEnv((void**)&env, JNI_VERSION_1_6);
    jclass clazz = env->FindClass("com/example/app/Security");
    env->RegisterNatives(clazz, methods, sizeof(methods)/sizeof(methods[0]));
    return JNI_VERSION_1_6;
}
```

### Tips for JNI Analysis in IDA

```text
1. Import the JNI type library
   File → Load File → Parse C Header → jni.h

2. Set the first parameter type to JNIEnv*
   Right-click the parameter → Set type → JNIEnv*
   IDA then identifies calls such as env->FindClass / env->GetMethodID automatically

3. Find RegisterNatives
   Search for calls to JNIEnv vtable offset 0x35C (ARM64)
   → The third parameter is a JNINativeMethod array
   → Extract all native function addresses from the array
```

---

## Advanced Frida Use

### Hook Native Functions

```javascript
// Hook libc functions
Interceptor.attach(Module.findExportByName("libc.so", "open"), {
    onEnter: function(args) {
        this.path = args[0].readUtf8String();
        console.log("[open] " + this.path);
    },
    onLeave: function(retval) {
        if (this.path.includes("su") || this.path.includes("magisk")) {
            console.log("[open] Blocked root check: " + this.path);
            retval.replace(-1);  // Return failure
        }
    }
});

// Hook functions in a custom SO
var base = Module.findBaseAddress("libsecurity.so");
var targetFunc = base.add(0x1234);  // Address offset
Interceptor.attach(targetFunc, {
    onEnter: function(args) {
        console.log("arg0: " + args[0].readUtf8String());
    },
    onLeave: function(retval) {
        console.log("return: " + retval.readUtf8String());
    }
});
```

### Hook Java Methods

```javascript
Java.perform(function() {
    // Hook an instance method
    var Security = Java.use("com.example.app.Security");
    Security.getSign.implementation = function(input) {
        console.log("[getSign] input: " + input);
        var result = this.getSign(input);  // Call the original method
        console.log("[getSign] output: " + result);
        return result;
    };

    // Hook the constructor
    Security.$init.overload('java.lang.String').implementation = function(key) {
        console.log("[Security.<init>] key: " + key);
        this.$init(key);
    };

    // Hook an overloaded method
    Security.encrypt.overload('java.lang.String', 'int').implementation = function(data, mode) {
        console.log("[encrypt] data=" + data + " mode=" + mode);
        return this.encrypt(data, mode);
    };
});
```

### Memory Search and Modification

```javascript
// Search for strings in memory
Process.enumerateModules().forEach(function(module) {
    if (module.name === "libtarget.so") {
        Memory.scan(module.base, module.size, "48 65 6C 6C 6F", {  // "Hello"
            onMatch: function(address, size) {
                console.log("Found at: " + address);
            }
        });
    }
});

// Modify memory (patch instructions)
var addr = Module.findBaseAddress("libsecurity.so").add(0x5678);
Memory.patchCode(addr, 4, function(code) {
    var writer = new Arm64Writer(code, {pc: addr});
    writer.putNop();  // Replace with NOP
    writer.flush();
});
```

---

## SSL Pinning Bypass

### General Method (Recommended)

```javascript
// General Frida SSL Pinning bypass
// Source: https://github.com/0xCD4/SSL-bypass
Java.perform(function() {
    // 1. TrustManager bypass
    var TrustManager = Java.registerClass({
        name: 'com.custom.TrustManager',
        implements: [Java.use('javax.net.ssl.X509TrustManager')],
        methods: {
            checkClientTrusted: function(chain, authType) {},
            checkServerTrusted: function(chain, authType) {},
            getAcceptedIssuers: function() { return []; }
        }
    });

    // 2. SSLContext replacement
    var SSLContext = Java.use('javax.net.ssl.SSLContext');
    var sslContext = SSLContext.getInstance("TLS");
    sslContext.init(null, [TrustManager.$new()], null);

    // 3. OkHttp CertificatePinner bypass
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function() {};
    } catch(e) {}
});
```

### Bypass Methods for Each Framework

| Framework | Bypass Method |
|------|---------|
| OkHttp3 | Hook `CertificatePinner.check` to return nothing |
| Retrofit | Same as OkHttp (uses OkHttp internally) |
| Volley | Hook the SSL factory in `HurlStack` |
| Flutter | Hook `SecurityContext` in `dart:io` (requires a special script) |
| React Native | Hook `OkHttpClientProvider` |
| WebView | Hook `WebViewClient.onReceivedSslError` |

### Flutter-Specific Method

```javascript
// Flutter SSL Pinning bypass (requires the location of the ssl_verify_peer_cert function)
var flutter_lib = Module.findBaseAddress("libflutter.so");
// Search for the byte pattern of ssl_verify_peer_cert
var pattern = "FF 03 05 D1 FD 7B 0F A9";  // ARM64 pattern
Memory.scan(flutter_lib, Module.findModuleByName("libflutter.so").size, pattern, {
    onMatch: function(address) {
        Interceptor.replace(address, new NativeCallback(function() {
            return 0;  // Return success
        }, 'int', []));
    }
});
```

---

## Root Detection Bypass

### Common Detection Methods

| Detection Method | Bypass Method |
|---------|---------|
| Check `/system/app/Superuser.apk` | Hook `File.exists()` to return false |
| Check the `su` command | Hook `Runtime.exec()` to intercept su calls |
| Check `/proc/self/mounts` | Hook file reads to filter out magisk-related content |
| SafetyNet/Play Integrity | Magisk Hide / Zygisk + Shamiko |
| Check the Magisk package name | Randomize the Magisk package name |
| Check `/data/adb/` | Hook `opendir`/`access` |

### General Frida Root Bypass

```javascript
Java.perform(function() {
    // Hook File.exists
    var File = Java.use("java.io.File");
    File.exists.implementation = function() {
        var path = this.getAbsolutePath();
        var blacklist = ["su", "Superuser", "magisk", "busybox", "xposed"];
        for (var i = 0; i < blacklist.length; i++) {
            if (path.toLowerCase().includes(blacklist[i])) {
                return false;
            }
        }
        return this.exists();
    };

    // Hook System.getProperty
    var System = Java.use("java.lang.System");
    System.getProperty.overload('java.lang.String').implementation = function(key) {
        if (key === "ro.debuggable" || key === "ro.secure") {
            return "1";
        }
        return this.getProperty(key);
    };
});
```

---

## Packer Protection Identification and Unpacking

### Common Packer Protection Vendors

| Packer Protection | Identification Features | Unpacking Method |
|------|---------|---------|
| 360 Jiagu | `libjiagu.so`, `com.stub.StubApp` | FART / Frida dump dex |
| Tencent Legu | `libshell*.so`, `com.tencent.StubShell` | FART / BlackDex |
| Bangcle | `libDexHelper.so`, `com.secneo.apkwrapper` | FART |
| Ijiami | `libexec.so`, `s.h.e.l.l` | Frida dump |
| NetEase Yidun | `libnesec.so` | Frida dump |
| Naga | `libnaga.so` | Frida dump |

### General Unpacking Methods

```text
Method 1: FART (unpacking in the ART environment)
- Flash the FART ROM or use the Frida version of FART
- Automatically dump dex files that all ClassLoader instances load

Method 2: Frida DEX Dump
- frida -U -f com.target.app -l dex_dump.js
- Hook DexFile::OpenMemory. Dump dex files from memory.

Method 3: BlackDex
- Unpacking tool that does not require root
- Install the BlackDex APK directly. Select the target app for unpacking.

Method 4: Manual dump
- Use Frida to enumerate all ClassLoader instances
- Find the app's ClassLoader → Get the DexFile object
- Read the dex memory region. Save it.
```

### Frida DEX Dump Script

```javascript
Java.perform(function() {
    Java.enumerateClassLoaders({
        onMatch: function(loader) {
            try {
                var dexFiles = loader.getDexFileList();
                console.log("ClassLoader: " + loader);
                console.log("  DEX files: " + dexFiles);
            } catch(e) {}
        },
        onComplete: function() {}
    });
});
```

---

## React Native / Flutter Reverse Engineering

### React Native

```text
1. Extract the APK → assets/index.android.bundle (JS code)
2. Format the JS → Search for API addresses, keys, and signing logic
3. If Hermes bytecode exists (.hbc files) → Use hermes-dec for decompilation
4. Hook: Use Frida to hook ReactBridge in the Java layer
```

### Flutter

```text
1. Flutter compiles code into libapp.so (Dart AOT)
2. Direct decompilation to Dart source code is not possible
3. Analysis methods:
   - reFlutter tool: Patch libflutter.so to get a snapshot
   - Doldrums: Parse the Dart snapshot to recover class/function information
   - Use Frida to hook key functions in libflutter.so
4. Network analysis: Flutter does not use the system proxy. SSL requires special handling.
```

---

## Tool Quick Reference

| Tool | Purpose | Installation |
|------|------|------|
| jadx | Java decompilation | Already in bootstrap |
| apktool | Unpacking/repackaging | Already in bootstrap |
| Frida | Dynamic Hook | `pip install frida-tools` |
| Objection | Frida wrapper (easier to use) | `pip install objection` |
| MobSF | Automated mobile security analysis | Docker deployment |
| BlackDex | Unpacking without root | APK installation |
| FART | ART unpacking | Flash the ROM or use the Frida version |
| hermes-dec | Hermes bytecode decompilation | npm installation |
| reFlutter | Flutter reverse engineering support | pip installation |
| Magisk + Shamiko | Root hiding | Flash |

---

## Reference Resources

| Resource | Description | Link |
|------|------|------|
| OWASP MASTG | Mobile security testing guide | https://mas.owasp.org/ |
| FridaBypassKit | General bypass framework | https://github.com/okankurtuluss/FridaBypassKit |
| SSL-bypass | General SSL Pinning bypass | https://github.com/0xCD4/SSL-bypass |
| awesome-frida | Frida resource collection | https://github.com/dweinstein/awesome-frida |
| Android Security Awesome | Android security resources | https://github.com/ashishb/android-security-awesome |