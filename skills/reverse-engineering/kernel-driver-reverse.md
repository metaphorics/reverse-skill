# Kernel Driver Reverse Engineering Reference

> Covers Windows/Linux kernel driver reverse engineering, Rootkit analysis, and C/C++ binary pattern recognition.

---

## Windows Driver Reverse Engineering

### Driver Types

| Type | Features | Analysis Focus |
|------|------|---------|
| WDM (Windows Driver Model) | Legacy driver, manual IRP management | DriverEntry → device creation → Dispatch routines |
| KMDF (Kernel Mode Driver Framework) | Modern framework, event-driven | EvtDriverDeviceAdd → Queue → I/O callbacks |
| WDF (Windows Driver Foundation) | General term for KMDF + UMDF | Check calls to WdfDriverCreate |
| Minifilter | File system filter driver | FltRegisterFilter → Pre/Post callbacks |

### WDM Driver Analysis Process

```text
1. Find DriverEntry (entry point)
   - Let IDA identify it automatically, or search for IoCreateDevice / IoCreateSymbolicLink

2. Find the device name and symbolic link
   - IoCreateDevice → DeviceName (such as \Device\MyDriver)
   - IoCreateSymbolicLink → SymLink (such as \DosDevices\MyDriver)

3. Find the Dispatch routine
   - DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = DispatchIoctl
   - User-mode code calls this entry point through DeviceIoControl

4. Analyze IOCTL handling
   - switch(IoControlCode) dispatches different functions
   - IOCTL encoding: CTL_CODE(DeviceType, Function, Method, Access)
   - Method: METHOD_BUFFERED / METHOD_IN_DIRECT / METHOD_OUT_DIRECT / METHOD_NEITHER

5. Find vulnerabilities
   - The length of a user-controlled buffer is not validated → overflow
   - METHOD_NEITHER directly uses a user pointer → arbitrary read/write
   - IOCTL permissions are not checked → unprivileged users can call it
```

### IOCTL Encoding Analysis

```python
# Parse IOCTL code
def decode_ioctl(code):
    device_type = (code >> 16) & 0xFFFF
    access = (code >> 14) & 0x3
    function = (code >> 2) & 0xFFF
    method = code & 0x3
    
    methods = {0: "BUFFERED", 1: "IN_DIRECT", 2: "OUT_DIRECT", 3: "NEITHER"}
    access_types = {0: "ANY", 1: "READ", 2: "WRITE", 3: "READ|WRITE"}
    
    return f"DevType=0x{device_type:X} Func=0x{function:X} Method={methods[method]} Access={access_types[access]}"

# Example
decode_ioctl(0x80002034)
# DevType=0x8000 Func=0x80D Method=BUFFERED Access=ANY
```

### IDA Plugins

| Plugin | Use | Link |
|------|------|------|
| **Driver Buddy Reloaded** | Automatically identifies IOCTL, Dispatch, and device names | https://github.com/VoidSec/DriverBuddyReloaded |
| **WinDbg + IDA** | Kernel debugging + static analysis | Built-in |
| **FLIRT/Lumina** | Identifies WDK library functions | Built into IDA |

### Reference Articles

- [Windows Drivers RE Methodology (VoidSec)](https://voidsec.com/windows-drivers-reverse-engineering-methodology/) — Full WDM driver reverse engineering methodology
- [Driver Reversing 101](https://eversinc33.com/posts/driver-reversing.html) — WDM vs KMDF comparison
- [Methodology of Reversing Vulnerable Killer Drivers](https://whiteknightlabs.com/2025/10/28/methodology-of-reversing-vulnerable-killer-drivers/) — Vulnerable driver analysis

---

## Linux Kernel Module Reverse Engineering

### LKM (Loadable Kernel Module) Structure

```text
Key functions:
- init_module / module_init → Execute when the module loads
- cleanup_module / module_exit → Execute when the module unloads

Key structures:
- struct file_operations → open/read/write/ioctl for character devices
- struct net_device_ops → network device operations
- struct block_device_operations → block device operations
```

### Analysis Process

```text
1. Confirm that it is a kernel module
   file module.ko → "ELF 64-bit ... relocatable" (note that it is relocatable, not executable)

2. Find the init/exit functions
   readelf -s module.ko | grep -E "init_module|cleanup_module"
   Or find the module information in the .modinfo section

3. Find the file_operations structure
   Search for register_chrdev / cdev_add / misc_register
   → Find the fops structure → Locate the ioctl/read/write handler functions

4. Analyze the ioctl handler
   unlocked_ioctl / compat_ioctl functions
   → Dispatch with switch(cmd)

5. Find rootkit behavior
   - Modify sys_call_table → syscall hook
   - Modify the /proc filesystem → hide processes/files
   - Register a netfilter hook → hide network connections
   - Modify the VFS layer → hide files
```

### Common Rootkit Techniques

| Technology | Feature | Detection method |
|------|------|---------|
| syscall table hook | Modify `sys_call_table` entries | Compare the table in memory with the table in the vmlinux file |
| VFS hook | Modify `file_operations` function pointers | Check if the fops pointer points outside the kernel code section |
| Netfilter hook | `nf_register_net_hook` | Traverse the Netfilter hook list |
| kprobe/ftrace hook | Register a kprobe or ftrace callback | Check the ftrace registration list |
| eBPF rootkit | Load a malicious BPF program | `bpftool prog list` |
| DKOM | Modify kernel objects directly (process list) | Traverse the task_struct list and compare it with /proc |

### Tools

| Tool | Purpose |
|------|------|
| `crash` | Analyze kernel dumps |
| `volatility3` | Linux memory forensics |
| `dmesg` / `journalctl` | Kernel logs |
| `lsmod` / `/proc/modules` | List of loaded modules |
| `modinfo` | Module metadata |
| `strace` | Trace system calls from user space |

---

## C/C++ Reverse Engineering Pattern Recognition

### Common C Language Patterns

| Source Code Pattern | Disassembly Features |
|---------|-----------|
| `if-else` | `cmp` + `jcc` (conditional jump) |
| `switch-case` | Jump table (`jmp [rax*8 + table]`) or consecutive `cmp` instructions |
| `for` loop | `cmp` + `jl/jle` + loop body + `inc/add` + `jmp` back to the loop |
| `while` loop | Condition check at the top of the loop |
| `do-while` | Condition check at the bottom of the loop |
| Function pointer call | `call rax` or `call [reg+offset]` |
| `struct` access | `[reg+fixed offset]` (such as `[rdi+0x10]`) |
| `malloc` + use | `call malloc` → store the return value in a register → access with that register+offset later |
| String comparison | `call strcmp` or `repe cmpsb` |

### C++-specific patterns

| Source-code pattern | Disassembly feature |
|---------|-----------|
| **Virtual function call** | `mov rax, [rcx]` (get vtable) → `call [rax+offset]` (call virtual function) |
| **Constructor** | Allocate memory → write the vtable pointer → initialize members |
| **Destructor** | Clean up members → possibly call `operator delete` |
| **this pointer** | The first parameter (`rcx/rdi`) is the object pointer |
| **Inheritance** | The vtable contains parent-class virtual functions + child-class overrides |
| **Multiple inheritance** | The object contains multiple vtable pointers at different offsets |
| **RTTI** | A `type_info` pointer is before the vtable |
| **Exception handling** | `__cxa_throw` / `_CxxThrowException` |
| **STL container** | `std::vector`: three-pointer structure `{begin, end, capacity}` |
| **std::string** | Small-string optimization (SSO): store short strings inline and allocate long strings on the heap |

### Vtable reverse-engineering method

```text
1. Find the vtable
   - Search for a contiguous array of function pointers (in the .rodata or .rdata section)
   - In the constructor, `mov [rcx], offset vtable` writes the vtable pointer

2. Determine the class hierarchy
   - The offset -8 before the vtable usually contains the RTTI pointer (if it was not stripped)
   - Multiple vtables sharing their first few entries → inheritance relationship

3. Label virtual functions
   - vtable[0] is usually the destructor (or deleting destructor)
   - Label subsequent entries by offset: vtable[1] = func1, vtable[2] = func2...

4. Work in IDA
   - Create a struct at the vtable address (each field is a function pointer)
   - Add a comment to `call [rax+offset]` identifying the virtual function being called
```

### Structure recovery

```text
Method 1: Infer from access patterns
  mov eax, [rdi+0x00]  → field_0: int/ptr (4/8 bytes)
  mov ecx, [rdi+0x08]  → field_8: int/ptr
  movss xmm0, [rdi+0x10] → field_10: float

Method 2: Infer from sizeof
  call malloc(0x30) → structure size 0x30 (48 bytes)
  
Method 3: Infer from the constructor
  The constructor initializes all fields → field types and offsets are immediately clear

Method 4: Use IDA's "Create struct" function
  Select the access pattern → Edit → Struct → Create struct from selection
```

---

## Common compiler features

| Compiler | Identification feature |
|--------|---------|
| MSVC | `_security_cookie` check, `__fastcall` calling convention, Rich Header |
| GCC | `__stack_chk_fail`, `-fstack-protector`, `.note.GNU-stack` |
| Clang/LLVM | Similar to GCC but with different optimization patterns, `__asan_*` (if the sanitizer is enabled) |
| MinGW | GCC features + Windows API calls |
| AOSP Clang | Android-specific `__android_log_print`, PGO markers |

### Optimization Level Identification

| Optimization Level | Characteristics |
|---------|------|
| -O0 | Many redundant mov instructions, every variable on the stack, no function inlining |
| -O1 | Basic optimization, some variables in registers |
| -O2 | Loop unrolling, function inlining, tail-call optimization |
| -O3 / -Os | Aggressive inlining, vectorization (SIMD), hard-to-read code |
| PGO | Hot-path optimization, move cold code to `.text.cold` |
| LTO | Cross-module inlining, global dead-code elimination |

---

## Kernel Debugging Environment

### Windows

```text
Debugger: WinDbg Preview
Connection method: network debugging (recommended) or serial

Debugged machine setup:
bcdedit /debug on
bcdedit /dbgsettings net hostip:192.168.x.x port:50000

Debugger connection:
WinDbg → File → Attach to Kernel → Net → Port:50000 Key:xxx

Common commands:
!analyze -v          # Automatically analyze the crash
lm                   # List loaded modules
!drvobj \Driver\xxx  # View the driver object
dt nt!_DRIVER_OBJECT # Display the structure
bp module!function   # Set a breakpoint
```

### Linux

```text
Debugger: GDB + QEMU or kgdb

QEMU kernel debugging:
qemu-system-x86_64 -kernel bzImage -s -S ...
gdb vmlinux -ex "target remote :1234"

Common commands:
info threads         # Kernel threads
lx-symbols           # Load kernel symbols (requires scripts/gdb/)
p init_task          # View the init process
lx-dmesg             # Kernel log
```

---

## Agent Action Anchors (Issue #65 U–AV)

Align with `references/nonpe-format-cookbook.md` §5 (short table, does not replace the preceding workflow):

| ID | Action | Evidence |
|----|------|----------|
| AG | `DriverEntry` is short → scan non-empty `MajorFunction` slots, prioritize DEVICE_CONTROL/CREATE | `E-driver-irp-handlers` |
| AH | Establish the IOCTL control-code → handler table and METHOD_* | `E-driver-ioctl` |
| AI | Suspect BYOVD: compare with public vulnerable-driver lists; record the name/hash/signature and call intent; **do not write exploit steps** | `E-driver-byovd` |

## Reference Resources

| Resource | Description | Link |
|------|------|------|
| VoidSec Driver Reverse Engineering Methodology | Complete Windows WDM driver analysis workflow | https://voidsec.com/windows-drivers-reverse-engineering-methodology/ |
| Elastic Rootkit Series | Linux Rootkit classification and detection | https://security-labs.elastic.co/security-labs/linux-rootkits-1-hooked-on-linux |
| Driver Buddy Reloaded | IDA driver analysis plugin | https://github.com/VoidSec/DriverBuddyReloaded |
| LOLDrivers | List of known vulnerable drivers | https://www.loldrivers.io/ |
| Windows Driver Samples | Official Microsoft driver samples | https://github.com/microsoft/Windows-driver-samples |
| Linux Kernel Module Programming | Kernel module development tutorial | https://sysprog21.github.io/lkmpg/ |
| Trail of Bits - Devirtualizing C++ | vtable reverse engineering method | https://blog.trailofbits.com/2017/02/13/devirtualizing-c-with-binary-ninja/ |
