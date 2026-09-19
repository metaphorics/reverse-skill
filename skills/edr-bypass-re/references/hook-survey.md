# EDR hook survey quick reference

> Use only for authorized red teams, adversary simulations, and owned-product testing. Do not use against unauthorized targets.

This document summarizes common EDR / AV monitoring points in user and kernel mode. Use it during red-team reconnaissance to locate what needs handling.

## 1. Common EDR fingerprints and hook patterns

| Vendor / product | User-mode components | Kernel drivers | Main monitoring surface |
|------------------|----------------------|----------------|-------------------------|
| CrowdStrike Falcon | `CSFalconService.exe`, `CSAgent.sys` injected into the target process | `CSAgent.sys`, `CSBoot.sys` | Heavy kernel callbacks + ETW-TI. Few user-mode hooks (cloud analysis). |
| Microsoft Defender for Endpoint (MDE) | `MsMpEng.exe`, `MpClient.dll` | `WdFilter.sys`, `WdBoot.sys`, `WdNisDrv.sys` | Broad AMSI + ETW-TI + ntdll inline hooks + kernel callbacks |
| SentinelOne | `SentinelAgent.exe`, `SentinelHelperService.exe` | `SentinelMonitor.sys`, `SentinelDeviceControl.sys` | Heavy ntdll user-mode hooks + kernel callbacks + custom ETW provider |
| Elastic Defend (formerly Endpoint Security) | `elastic-endpoint.exe` | `elastic-endpoint-driver.sys` | Mainly ETW + a few ntdll hooks, uploaded through Elastic Agent |
| ESET | `ekrn.exe`, `eamsi.dll` | `eamonm.sys`, `epfwwfp.sys` | Many user-mode hooks (NtCreateFile / NtOpenProcess and others) |
| Sophos Intercept X | `SophosFileScanner.exe`, `SophosNtpService.exe` | `SophosED.sys`, `hmpalert.sys` | ntdll hooks + HMPA memory protection + kernel callbacks |
| Kaspersky | `avp.exe`, `klif.sys` | `klif.sys`, `klhk.sys` | Heavy user-mode hooks + KLIF custom minifilter + network filter driver |
| Trend Micro Apex One | `TmListen.exe`, `TmCCSF.dll` | `tmcomm.sys`, `tmactmon.sys` | User-mode hooks + behavior-monitoring driver |
| Carbon Black | `RepMgr.exe`, `RepWAV.exe` | `ParityDriver.sys` | Kernel callbacks + ETW |

### Quick fingerprint script

```powershell
$edrSigs = @{
    'CSAgent'           = 'CrowdStrike Falcon'
    'SentinelAgent'     = 'SentinelOne'
    'elastic-endpoint'  = 'Elastic Defend'
    'ekrn'              = 'ESET'
    'MsMpEng'           = 'Microsoft Defender'
    'SophosFileScanner' = 'Sophos Intercept X'
    'avp'               = 'Kaspersky'
    'TmListen'          = 'Trend Micro Apex One'
    'cb'                = 'Carbon Black'
}

Get-Process | ForEach-Object {
    foreach ($k in $edrSigs.Keys) {
        if ($_.ProcessName -match $k) {
            "[+] $($edrSigs[$k]) detected: $($_.ProcessName) (PID $($_.Id))"
        }
    }
}

Get-ChildItem 'C:\Windows\System32\drivers\*.sys' |
    Where-Object { $_.Name -match 'CSAgent|Sentinel|elastic|eam|WdFilter|Sophos|klif|tmcomm|Parity' } |
    Select-Object Name, VersionInfo
```

## 2. Key user-mode ntdll hooks

EDR almost always hooks these `ntdll.dll` exports, grouped by ATT&CK behavior:

| Function | Monitored behavior | ATT&CK |
|----------|--------------------|--------|
| `NtCreateThreadEx` | Remote thread injection, QueueUserAPC injection | T1055.002 / T1055.004 |
| `NtAllocateVirtualMemory` | Allocate RWX memory for shellcode | T1055 |
| `NtAllocateVirtualMemoryEx` | Cross-process memory allocation (new Win10+ API) | T1055 |
| `NtProtectVirtualMemory` | Change page permissions RW→RX | T1055 |
| `NtWriteVirtualMemory` | Write shellcode across processes | T1055.012 |
| `NtMapViewOfSection` | Section-based injection (Process Doppelganging / Ghosting) | T1055.013 |
| `NtCreateSection` | Used with MapViewOfSection | T1055.013 |
| `NtOpenProcess` | Open the target process and obtain a handle | T1057 |
| `NtQueueApcThread` / `NtQueueApcThreadEx` | APC injection | T1055.004 |
| `NtCreateProcess` / `NtCreateProcessEx` / `NtCreateUserProcess` | Create a child process, including PPID spoofing | T1106 |
| `NtSetContextThread` | Change thread context (thread-hijack injection) | T1055.003 |
| `NtResumeThread` | Resume a thread after injection | T1055 |
| `NtQuerySystemInformation` | Enumerate processes / drivers / handles | T1057 / T1082 |
| `NtAdjustPrivilegesToken` | Escalate privileges to obtain SeDebugPrivilege and others | T1134 |
| `NtLoadDriver` | Load a kernel driver (BYOVD) | T1543.003 |

### Check whether a hook exists

```powershell
# Simple: disassemble and diff the disk ntdll against the current process ntdll
# 1. Get the disk ntdll
copy C:\Windows\System32\ntdll.dll C:\temp\ntdll_clean.dll

# 2. Attach windbg to any process and export the current ntdll .text section
# .writemem c:\temp\ntdll_live.bin ntdll!.text L?<size>

# 3. Disassemble NtAllocateVirtualMemory with IDA / radare2. It should normally be:
#    mov r10, rcx
#    mov eax, <SSN>
#    test byte ptr [...]
#    jne ...
#    syscall
#    ret
# If the first instruction becomes jmp <some address>, it is a hook.
```

## 3. Kernel callback monitoring points

Common kernel callbacks registered by EDR can be unregistered through the BYOVD route in `attack-chain`, but the cost is high:

| API | Callback timing | Defensive use |
|-----|-----------------|---------------|
| `PsSetCreateProcessNotifyRoutineEx` | Process create / exit | Block suspicious child processes |
| `PsSetCreateThreadNotifyRoutine` | Thread create / exit | Detect remote thread injection |
| `PsSetLoadImageNotifyRoutine` | DLL / EXE loads into any process | Module integrity / block unsigned modules |
| `CmRegisterCallback` / `CmRegisterCallbackEx` | Registry operations | Persistence detection |
| `ObRegisterCallbacks` | `OpenProcess` / `OpenThread` handle requests | Prevent LSASS handle access (T1003.001) |
| `MmRegisterPhysicalMemoryCallback` | Physical memory mapping | Prevent DMA / memory forensics |
| `IoRegisterFsRegistrationChange` | Filesystem registration | Minifilter coordination |
| `KeRegisterNmiCallback` | NMI (rarely used by EDR) | Anomaly monitoring |
| `EtwRegister` (kernel side) | Kernel ETW reporting | Works with ETW-TI |

### Enumerate registered callbacks with windbg

```text
0: kd> dx -r1 nt!PspCreateProcessNotifyRoutine
0: kd> dx -r1 nt!PspCreateThreadNotifyRoutine
0: kd> dx -r1 nt!PspLoadImageNotifyRoutine

0: kd> !object \Callback
0: kd> !object \Callback\ProcessObject
```

You can also use PChunter or DRVHV to view the callback list as a normal user.

## 4. Static hook-table dump (IDA + windbg process)

### Process A: Compare one process

```text
1. Find a process with an injected EDR user-mode component (any live process).
2. Attach windbg (-pn target.exe).
3. lm m ntdll  → get the module base address.
4. .writemem c:\temp\ntdll_live.bin ntdll+0x0 L?<image size>
5. Copy C:\Windows\System32\ntdll.dll to c:\temp\ntdll_disk.dll.
6. Load both files in IDA and jump to NtAllocateVirtualMemory:
     - disk: standard prologue
     - live: first instruction jmp <0x7FFE000000xx>
7. Follow the jmp target. This is the EDR trampoline. Dump it.
8. Inspect the trampoline's final DLL to confirm the EDR module name.
```

### Process B: Generate a batch hook table

Use `HookHunter` or write a script:

```powershell
# Pseudo workflow. See the scripts cited in references.
$disk = Get-Content C:\Windows\System32\ntdll.dll -Encoding Byte
$live = # Obtain through OpenProcess + ReadProcessMemory.
# Compare the first 16 bytes of every export in the .text section.
```

## 5. Automatic detection with pe-sieve

`pe-sieve` is the first choice for EDR-hook reconnaissance and implant self-checks:

```powershell
# Basic scan
pe-sieve64.exe /pid 1234

# Recommended combination (including shellcode and hook checks)
pe-sieve64.exe /pid 1234 /shellc 3 /modules 3 /imp 3 /data 3 /dir hooks_dump

# Key parameters:
#   /shellc N    Shellcode scan level (0-3)
#   /modules N   Module integrity check (0-3)
#   /imp N       IAT hook check
#   /data N      Data-section scan
#   /dir <path>  Dump output directory
```

The output creates `*.tag` files under `hooks_dump/<pid>.<name>/` and lists hook addresses:

```text
Example modified_modules.tag:
71f10000;ntdll.dll
71f1a3b0;hook;jmp_far
71f1c020;hook;jmp_near
```

Feed these addresses to IDA and jump to the corresponding RVA for further analysis.

### Embed pe-sieve in an implant (self-check)

In an engagement, compile `pe-sieve` as a library (`libpe-sieve`) so the implant checks itself at startup. If ntdll has a hook, start the unhook process. If the implant finds that it is hooked, be careful. It may be running in a sandbox.

## 6. Observe dynamically with API Monitor v2

API Monitor v2 (Rohitab) helps you observe when and where EDR inserts hooks in a lab:

```text
1. Start API Monitor v2 (administrator).
2. In API Filter, select:
     - NT Native API → Memory Management
     - NT Native API → Process and Thread
     - Windows Defender / AMSI (when visible)
3. Monitor New Process → select the implant test sample.
4. Observe:
     - NtAllocateVirtualMemory call order.
     - Whether an EDR DLL relays the call.
5. In the Modules tab, inspect which EDR DLLs were injected with LoadLibrary.
```

## 7. Common EDR DLLs (user mode)

| DLL | Vendor | Notes |
|-----|--------|-------|
| `umppc*.dll` | Microsoft Defender | MpClient userland |
| `mpoav.dll` | Microsoft Defender | AMSI provider |
| `aswAMSI.dll` | Avast | AMSI provider |
| `eamsi.dll` | ESET | AMSI provider |
| `IDPMServiceClient.dll` | Sophos | HMPA injection |
| `klsihk64.dll` | Kaspersky | Injected into the target process |
| `CrowdStrike.Sensor.dll` | CrowdStrike | Old versions. New versions mainly use the kernel. |
| `SentinelInjection64.dll` | SentinelOne | User-mode injection |
| `TmUmEvt64.dll` | Trend Micro | Behavior monitoring |

After confirming the target EDR, choose which DLL to reverse for its hook table.

## Reference links

- pe-sieve: <https://github.com/hasherezade/pe-sieve>
- HollowsHunter: <https://github.com/hasherezade/hollows_hunter>
- API Monitor v2: <http://www.rohitab.com/apimonitor>
- MITRE ATT&CK T1562: <https://attack.mitre.org/techniques/T1562/>
- MITRE ATT&CK T1055: <https://attack.mitre.org/techniques/T1055/>
- ired.team EDR notes: <https://www.ired.team/offensive-security/defense-evasion>

## Routing callback

After the hook survey, return to Step 3 in `SKILL.md` to choose the evasion combination. Then follow `references/unhook-techniques.md` and `references/telemetry-blinding.md`.
