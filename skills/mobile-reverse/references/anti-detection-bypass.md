# Root / Jailbreak / Anti-debugging / SSL Pinning Bypass

## Detection Layer Model

```
Layer 1: Static detection (at installation/startup)
  ├─ Package manager detection (Cydia, apt, Magisk)
  ├─ File detection (su, busybox, frida-server)
  └─ Permission detection (ro.debuggable, ro.secure)

Layer 2: Runtime detection (continuous)
  ├─ Process detection (frida-server, magiskd)
  ├─ Port detection (27042 frida default)
  ├─ Memory detection (injection traces in /proc/self/maps)
  └─ Stack detection (Frida call frames)

Layer 3: Environment detection (on demand)
  ├─ ptrace detection (TracerPid)
  ├─ /proc/self/status detection
  ├─ build.prop detection (test-keys)
  └─ Direct syscall detection (bypasses libc)
```

## Android Root Detection Bypass

### Common Detection Libraries and Bypasses

| Detection library | Detection method | Bypass method |
|--------|---------|---------|
| RootBeer | Combines 8 checks | Hook each detection method to return false |
| SafetyNet | Google Play Services remote authentication | Use Magisk Hide / Shamiko / Play Integrity Fix |
| Google Play Integrity | Replaces SafetyNet | Trickystore + PIF |
| Custom native detection | syscall reads /proc/self/status | Hook syscall or change the /proc mount |

### Frida Bypass for Multiple Checks

```javascript
Java.perform(function() {
    // RootBeer
    var RootBeer = Java.use("com.scottyab.rootbeer.RootBeer");
    var methods = ["isRooted", "isRootedWithBusyBox", "checkSuExists",
        "detectRootManagementApps", "detectPotentiallyDangerousApps",
        "detectTestKeys", "checkForDangerousProps", "checkForRWPaths"];
    methods.forEach(function(m) {
        RootBeer[m].implementation = function() { return false; };
    });

    // General Build.TAGS detection
    var Build = Java.use("android.os.Build");
    var original = Build.TAGS.value;
    Build.TAGS.value = "release-keys";

    // PackageManager → Hide package names
    var PackageManager = Java.use("android.content.pm.PackageManager");
    PackageManager.getPackageInfo.overload('java.lang.String', 'int').implementation = function(pkg, flags) {
        if (pkg == "de.robv.android.xposed.installer" || 
            pkg.includes("magisk") || pkg.includes("frida")) {
            throw Java.use("android.content.pm.PackageManager$NameNotFoundException").$new();
        }
        return this.getPackageInfo(pkg, flags);
    };
});
```

## iOS Jailbreak Detection Bypass

### Frida Hooks at Multiple Layers

```javascript
// 1. File system detection
var NSFileManager = ObjC.classes.NSFileManager;
var paths = [
    "/Applications/Cydia.app", "/var/lib/apt", "/bin/bash",
    "/usr/sbin/sshd", "/etc/apt", "/Library/MobileSubstrate"
];
// Hook fileExistsAtPath to return NO

// 2. fork detection (the sandbox prohibits fork)
var fork_ptr = Module.findExportByName("libSystem.B.dylib", "fork");
Interceptor.replace(fork_ptr, new NativeCallback(function() {
    return -1;
}, 'int', []));

// 3. Scheme detection
// Hook through MobileSubstrate
var LSApplicationWorkspace = ObjC.classes.LSApplicationWorkspace;
// Hook defaultWorkspace → canOpenURL → return NO for cydia://

// 4. Signature detection
var MISValidateSignature = Module.findExportByName(null, "MISValidateSignature");
Interceptor.attach(MISValidateSignature, {
    onLeave: function(retval) { retval.replace(0); }
});
```

## Anti-debugging Bypass

### Android

```javascript
// 1. ptrace on the current process → prevents attachment
// Native: ptrace(PTRACE_TRACEME, 0, NULL, 0)
// Bypass: Hook ptrace → return 0

// 2. TracerPid detection
// /proc/self/status → TracerPid: 0
var fopen = Module.findExportByName(null, "fopen");
Interceptor.attach(fopen, {
    onEnter: function(args) {
        this.path = Memory.readUtf8String(args[0]);
    },
    onLeave: function(retval) {
        if (this.path && this.path.includes("status")) {
            // Change the returned FILE* to return fake content
        }
    }
});

// 3. isDebuggerConnected (Java)
var Debug = Java.use("android.os.Debug");
Debug.isDebuggerConnected.implementation = function() { return false; };
```

### iOS

```javascript
// 1. PT_DENY_ATTACH
// ptrace(PT_DENY_ATTACH, 0, NULL, 0) → prevents debugger attachment
var ptrace = Module.findExportByName(null, "ptrace");
Interceptor.replace(ptrace, new NativeCallback(function(request, pid, addr, data) {
    if (request == 31) return 0; // PT_DENY_ATTACH → ignore
    return ptrace(request, pid, addr, data);
}, 'int', ['int', 'int', 'pointer', 'int']));

// 2. sysctl detection
var sysctl = Module.findExportByName(null, "sysctl");
Interceptor.attach(sysctl, {
    onLeave: function(retval) {
        // Change the p_flag field in kinfo_proc → clear P_TRACED
    }
});

// 3. getppid detection (checks if the parent process is launchd)
// During debugging, getppid() != 1
```

## SSL Pinning Bypass

### Android Bypass at Five Layers

```text
Layer 1 — TrustManager: Accept all certificates
Layer 2 — OkHttp CertificatePinner: Hook to clear the pins list
Layer 3 — WebView SSL Error Handler: Ignore certificate errors
Layer 4 — Network Security Config: Change xml → trust user certificates
Layer 5 — Native SSL (OpenSSL/BoringSSL): Hook SSL_get_verify_result → X509_V_OK
```

### iOS Bypass at Four Layers

```text
Layer 1 — NSURLSession: Hook SecTrustEvaluate → kSecTrustResultProceed
Layer 2 — Alamofire: Hook ServerTrustManager
Layer 3 — AFNetworking: Hook AFSecurityPolicy
Layer 4 — libcurl: Use LD_PRELOAD to replace the SSL verification callback
```

### Common Objection Commands

```bash
# Android
objection -g "com.app" explore
android sslpinning disable
# Equivalent to: Automatically hook the 5 layers above

# iOS
objection -g "com.app" explore
ios sslpinning disable
# Equivalent to: Automatically hook the 4 layers above
```

Source: OWASP MSTG, Frida CodeShare, objection wiki