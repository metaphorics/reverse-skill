---
name: edr-bypass-re
description: |
  Reverse-engineer defensive implementations, then build targeted red-team evasion. First reverse the EDR, Defender, or AV hook table, ETW providers, and AMSI implementation.
  Then write targeted unhook, indirect syscall, ETW patch, or call stack spoof code. Map the work to MITRE ATT&CK T1562 defense evasion.
  Trigger keywords: EDR evasion, AV bypass, AV/EDR evasion, unhook, direct syscall, indirect syscall, Hell's Gate, Halo's Gate,
  Tartarus Gate, ETW patch, AMSI patch, call stack spoofing, hardware breakpoint Blindside, MITRE T1562,
  ntdll unhook, kernel callback, CrowdStrike evasion, Defender evasion, Sentinel One evasion, Elastic Defend,
  Sysmon evasion, PPID spoof, Sleep mask, Process Hollowing, Reflective DLL.
---

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` to confirm that this Skill's actions are authorized routine actions.
2. `NOW`: Confirm that the current task fits this Skill's scope.
3. `NEXT`: Read `../tool-index.md` and check tool availability and actual paths.
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths.
5. `ACT`: Enter and execute the first workflow step. Do not stop at confirmation.

# EDR evasion: from defensive implementation reverse engineering to red-team evasion

> Use only for authorized red teams, adversary simulations, and owned-product testing. Do not use against unauthorized targets.

## Scope

Use this Skill when an authorized red team or adversary simulation must deliver an implant to a target host while avoiding modern EDR.

1. **Red team, Purple Team, or adversary simulation**: The client wants to assess SOC and EDR detection capability.
2. **In-house implant or C2 framework development**: Develop a payload for owned-product testing. It may need to bypass the owned or target EDR.
3. **EDR product assessment**: Objectively assess an EDR's detection coverage within a confirmed compliance boundary.
4. **CTF or attack-and-defense exercise on Windows**: Execute reliably on a hardened host during the event.

**Do not use this Skill for**:

- A full commercial assessment of an antivirus vendor's product. Work with the vendor.
- AV/EDR evasion against an unauthorized target. This is illegal.
- AV/EDR evasion for ordinary malware. This Skill covers red-team OPSEC, not malicious-code development.

### Division of work with other Skills

| Scenario | Use |
|----------|-----|
| Full attack and defense chain (external network to domain controller) | `attack-chain/` |
| Internal-network lateral movement / AD attack | `pentest-tools/network-attack-defense.md` |
| Deliver an implant through EDR on a specific host | **This Skill** |
| Static AV/EDR evasion (obfuscation / packers) | `malware-analysis/` (reverse perspective) |

`attack-chain` covers the complete kill chain. This Skill focuses on the internal mechanisms of **EDR as one opponent** and targeted evasion methods.

## Core principles

```text
EDR's four main monitoring surfaces               Red-team countermeasures
─────────────────────              ─────────────────────
User-mode ntdll hook       ◄──►   unhook (Peruns Fart / fresh ntdll)
                                  indirect syscall / Hell's Gate
                                  hardware breakpoint Blindside

kernel callback         ◄──►   call stack spoof
(Ps/Cm/Ob series)                   use a legitimate trigger chain (do not bypass directly, combine with upstream stealth)

ETW telemetry           ◄──►   EtwEventWrite patch
(Microsoft-Windows-Threat-          disable provider with NtTraceControl
 Intelligence and others)                  handle AmsiContext at the same time

AMSI scanning               ◄──►   AmsiScanBuffer patch (mov eax,0x80070057; ret)
(amsi.dll)                       hardware breakpoint bypass
                                  reflective-load a copy of amsi.dll
```

Key points:

- **EDR is not a black box**: Use IDA + windbg to reverse key hooks, callbacks, and providers.
- **Combine evasion techniques**: One unhook does not stop ETW alerts. One AMSI patch does not stop syscall hooks.
- **Order matters**: Patch ETW first, then AMSI, then unhook. The wrong order lets EDR receive an unhook alert first.
- **Modern EDR treats ETW and kernel callbacks as the main battleground**. User-mode unhook alone is no longer enough.

## Workflow

### Step 1: Identify EDR on the target host

```powershell
# List common EDR / AV drivers
Get-Service | Where-Object {$_.Name -match 'CSAgent|SentinelAgent|elasticendpoint|esets|ekrn|MsMpEng|wdsvc|cyserver|sysmon|aswbidsagent'}

# List loaded minifilters
fltmc filters

# List registered kernel callbacks (requires windbg + kernel debugging, or PChunter / DRVHV)
# !object \Callback
# !pnpcallback / Process / Thread / Image
```

See the EDR fingerprint table at the top of `references/hook-survey.md`.

### Step 2: Extract the hook table from the EDR DLL

1. Attach to a process with an injected EDR user-mode component.
2. Dump the current `ntdll.dll` `.text` section in windbg.
3. Diff it against the clean `C:\Windows\System32\ntdll.dll` on disk.
4. Treat differences as hook points.

Or use `pe-sieve` directly:

```powershell
pe-sieve64.exe /pid 1234 /shellc 3 /modules 3 /dir hooks_dump
```

See `references/hook-survey.md` for the detailed method.

### Step 3: Choose an evasion combination

| Defense point | Recommended evasion |
|---------------|---------------------|
| ntdll inline hook | indirect syscall + dynamic SSN (Halo's Gate) |
| ETW-TI provider | EtwEventWrite head patch |
| AMSI (PowerShell / .NET) | AmsiScanBuffer patch or HWBP |
| Kernel callback | call stack spoof + use a legitimate gadget |
| Sysmon ProcessCreate | PPID spoof + unbacked memory |

### Step 4: Implement in the implant

See the code skeletons in `references/unhook-techniques.md` and `references/telemetry-blinding.md`.

### Step 5: Verify in a local sandbox

```powershell
# Deploy a trial EDR in an isolated environment (start with default Defender)
# Enable Sysmon + olaf config
sysmon64.exe -i sysmonconfig.xml

# Run the implant and check whether it triggers these alert sources:
#   - Defender AMSI
#   - ETW-TI
#   - Sysmon Event ID 1/7/8/10
#   - EDR console
```

### Step 6: Deliver

- Use a legitimate software directory for the file path.
- Spoof PPID to explorer.exe.
- Combine with the `initial access` section in `attack-chain`.

## Typical scenarios

### Scenario 1: Deliver a Cobalt-Strike-like beacon through Defender + Sysmon

```text
Target: Windows 11 Enterprise + Defender (cloud scanning enabled) + Sysmon (olaf configuration)
Requirement: The beacon must call back after delivery without triggering any alert.

Combination:
  1. Store encrypted shellcode and decrypt it at runtime.
  2. Patch AMSI (when delivery uses PowerShell).
  3. Patch EtwEventWrite (suppress ETW-TI).
  4. Use indirect syscall + Halo's Gate (suppress ntdll hook alerts).
  5. Spoof PPID to explorer.exe.
  6. Encrypt the beacon's memory during Sleep with Ekko / Foliage.
```

### Scenario 2: Apply an EDR sleep mask on an existing low-privilege shell

```text
Prerequisite: Phishing already provided a medium-IL shell. EDR is monitoring it.
Risk: Long-term residence makes the beacon features easy to find with memory scans.

Solution:
  1. Do not allocate new RWX memory.
  2. Use Ekko during Sleep:
       - WaitForSingleObjectEx + CreateTimerQueueTimer
       - Encrypt the .text section and clear the stack in the timer.
  3. Restore it with ROP on wake.
  4. Combine call stack spoof so RtlCaptureStackBackTrace cannot see the beacon address.
```

## On-demand bootstrap

### Tool dependencies

| Tool | Purpose | Automatic installation |
|------|---------|------------------------|
| pe-sieve | Detect hooks and injection in processes | ✓ |
| API Monitor v2 | Observe API calls and hooks dynamically | Semi-automatic (manual download) |
| SysWhispers3 | Generate direct / indirect syscall stubs | ✓ (git clone + Python) |
| Hell's Gate POC | Reference implementation for dynamic SSN parsing | ✓ (git clone) |
| windbg + IDA | Reverse EDR DLLs and kernel callbacks | ✗ (install manually) |
| Sysmon + olaf config | Local verification environment | ✓ |

### Bootstrap command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "&lt;SKILL_ROOT&gt;\skills\scripts\bootstrap-reverse.ps1" -Capability @('pe-sieve','syswhispers3','sysmon') -StartServices
```

## Routing context

**Upstream entry**:

- `reverse-engineering/`: Understand the EDR DLL or driver implementation first.
- `attack-chain/`: Decide where to introduce this Skill in the kill chain.

**Peer relationships**:

- `pentest-tools/network-attack-defense.md`: Coordinate with this Skill during internal-network lateral movement.
- `malware-analysis/`: Use the reverse perspective to see how defenders write detection rules.
- `field-journal/`: Write back lessons after each engagement.

**Downstream delivery**:

- Cite MITRE ATT&CK **T1562 (Impair Defenses)**, T1562.001 (Disable or Modify Tools), T1562.006 (Indicator Blocking), T1055 (Process Injection), and T1027 (Obfuscated Files or Information) in reports.

## Legal boundary statement

- Use only for authorized red teams, adversary simulations, or owned-product testing.
- Obtain written authorization before operation (SoW, test contract, or SRC scope statement).
- Do not use against unauthorized targets or beyond the authorized scope.
- Report critical issues to the client immediately. Follow responsible disclosure.
- Apply redaction to real target information in all reports (IP, host name, domain, credential placeholders).

## References

- Detailed hook survey: `references/hook-survey.md`
- Unhook and syscall techniques: `references/unhook-techniques.md`
- ETW, AMSI, and anti-forensics: `references/telemetry-blinding.md`
- MITRE ATT&CK T1562: <https://attack.mitre.org/techniques/T1562/>


## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow rather than only read it?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
