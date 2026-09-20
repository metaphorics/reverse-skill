# ELF Binary Analysis Reference

> Analyze Linux/Android ELF files through structure analysis, anti-analysis technique detection, and analysis methods.

---

## ELF Structure Quick Reference

### File Header (ELF Header)

```text
Offset  Size  Field             Description
0x00  4    e_ident[EI_MAG]   Magic: 7f 45 4c 46 ("\x7fELF")
0x04  1    e_ident[EI_CLASS] 1=32bit, 2=64bit
0x05  1    e_ident[EI_DATA]  1=LE, 2=BE
0x10  2    e_type            2=EXEC, 3=DYN(PIE/SO), 4=CORE
0x12  2    e_machine         0x03=x86, 0x3E=x86_64, 0xB7=AArch64, 0x28=ARM
0x18  8    e_entry           Entry point virtual address
0x20  8    e_phoff           Program header table offset
0x28  8    e_shoff           Section header table offset (may be 0 after strip)
0x38  2    e_phnum           Number of program headers
0x3C  2    e_shnum           Number of section headers
```

### Program Header (Program Header)

```text
Type value  Name       Description
0x01   PT_LOAD    Loadable segment (code/data)
0x02   PT_DYNAMIC Dynamic linking information
0x03   PT_INTERP  Interpreter path (/lib/ld-linux.so)
0x04   PT_NOTE    Auxiliary information
0x06   PT_PHDR    The program header table itself
0x6474e550 PT_GNU_EH_FRAME  Exception handling
0x6474e551 PT_GNU_STACK     Executable stack flag
0x6474e552 PT_GNU_RELRO     Read-only relocation
```

### Common Sections (Sections)

| Section Name | Description |
|------|------|
| `.text` | Code section |
| `.rodata` | Read-only data (string constants) |
| `.data` | Initialized global variables |
| `.bss` | Uninitialized global variables |
| `.plt` / `.got` | Dynamic-linking jump table |
| `.init_array` | Constructor pointer array |
| `.fini_array` | Destructor pointer array |
| `.dynamic` | Dynamic-linking information |
| `.symtab` / `.dynsym` | Symbol table |
| `.strtab` / `.dynstr` | String table |

---

## Anti-Analysis Technique Detection

### Common ELF Anti-Analysis Techniques

| Technique | Feature | Countermeasure |
|------|------|---------|
| Corrupted program header | PHDR contains garbage data (such as 0x0a) | Repair it manually or ignore the corrupted PHDR |
| No section header | `e_shoff = 0`, `e_shnum = 0` | Analyze only the program headers and do not rely on sections |
| Symbol stripping (strip) | No `.symtab`; all function names are lost | GoReSym(Go) / signature matching / FLIRT |
| Static linking | No `.dynamic`; very large file size | Use FLIRT/Lumina to identify library functions |
| Disguised file type | Suffix .sh/.txt/.jpg | Use the `file` command / magic bytes to identify it |
| UPX packing | Contains the `UPX!` marker | `upx -d` unpacking |
| Custom packer | Entry point jumps to unpacking code | Run dynamically to the OEP, then dump |
| Anti-debugging | ptrace(TRACEME) | LD_PRELOAD hook / patch |
| Anti-virtual machine | Check /proc/cpuinfo | Modify cpuinfo or hook the read operation |
| Code encryption | Decrypt .text at runtime | Set a breakpoint and dump after decryption |

### Identify self-extracting and self-modifying code

```text
Features:
1. An mmap(PROT_READ|PROT_WRITE|PROT_EXEC) call appears near the entry point
2. A memcpy or loop copy follows immediately
3. Then mprotect changes the permissions
4. Finally, br/jmp branches to the address of the new mapping

Analysis strategy:
1. Find the mmap call → record the returned address
2. Set a breakpoint after mprotect(PROT_EXEC)
3. Dump the decompressed memory region
4. Analyze it as a new binary
```

---

## ARM64 (AArch64) Reverse Engineering Quick Reference

### Registers

| Register | Use |
|--------|------|
| x0-x7 | Arguments/return values |
| x8 | Indirect result (syscall number) |
| x9-x15 | Temporary registers |
| x16-x17 | IP0/IP1 (PLT branch) |
| x18 | Platform register (Android: shadow call stack) |
| x19-x28 | Callee-saved |
| x29 (FP) | Frame pointer |
| x30 (LR) | Link register (return address) |
| SP | Stack pointer |
| PC | Program counter |

### Common instruction patterns

```text
Function prologue:
  stp x29, x30, [sp, #-N]!    # Save FP and LR
  mov x29, sp                  # Set the frame pointer

Function epilogue:
  ldp x29, x30, [sp], #N      # Restore FP and LR
  ret                          # Return (br x30)

System call:
  mov x8, #NR                  # syscall number
  svc #0                       # Trigger syscall

Conditional branches:
  cmp x0, #0
  b.eq label                   # Branch if equal
  b.ne label                   # Branch if not equal
  cbz x0, label                # Branch if x0 == 0
  cbnz x0, label               # Branch if x0 != 0

Address loading:
  adrp x0, page                # Load the page address high bits
  add x0, x0, #offset          # Add the low 12-bit offset
  ldr x0, [x1, #offset]        # Load from memory
```

### Linux ARM64 syscall numbers

| Number | Name | Description |
|------|------|------|
| 56 | openat | Open a file |
| 63 | read | Read |
| 64 | write | Write |
| 57 | close | Close |
| 222 | mmap | Memory mapping |
| 226 | mprotect | Modify memory permissions |
| 117 | ptrace | Process tracing |
| 220 | clone | Create a process or thread |
| 221 | execve | Execute a program |
| 93 | exit | Exit |
| 94 | exit_group | Exit the process group |

---

## Common Compression and Packing Algorithm Identification

| Algorithm | Identification Features | Decompression Method |
|------|---------|---------|
| **LZSS** | Bit stream + literal/match markers | Custom decompressor (as in this report) |
| **ZLIB/Deflate** | Magic: `78 01`/`78 9C`/`78 DA` | `zlib.decompress()` |
| **GZIP** | Magic: `1F 8B` | `gzip -d` / `gunzip` |
| **LZ4** | Magic: `04 22 4D 18` | `lz4 -d` |
| **LZMA/XZ** | Magic: `FD 37 7A 58 5A 00` (XZ) | `xz -d` / `lzma -d` |
| **Brotli** | No fixed magic, check the context | `brotli -d` |
| **Zstandard** | Magic: `28 B5 2F FD` | `zstd -d` |
| **UPX** | String `UPX!` | `upx -d` |
| **Custom** | Decompression loop at the entry point | Write a decompressor after reverse engineering the algorithm |

### Clues for Identifying Custom Compression

```text
1. Near the entry point, there is a loop plus bit operations (shift, AND, OR)
2. There is "sliding-window" back-copying (read backward from the output buffer) → LZ series
3. There is frequency-table/Huffman-tree construction → Deflate/Huffman
4. There is fixed-size block processing → block compression (LZ4/Snappy)
5. There are arithmetic-coding features (range narrowing) → LZMA/ANS
```

---

## Linux Process Injection Techniques

### mmap + Code Injection

```text
Process:
1. mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_ANON|MAP_PRIVATE, -1, 0)
2. Write shellcode/payload into the mapped region
3. mprotect(addr, size, PROT_READ|PROT_EXEC)  # Change it to executable
4. Jump to the mapped address and execute

Indicators:
- The mmap return value is saved
- This is immediately followed by memcpy or a write loop
- Then mprotect changes the permissions
- Finally, br/blr branches to that address
```

### ptrace Injection

```text
Process:
1. ptrace(PTRACE_ATTACH, target_pid)
2. waitpid(target_pid)
3. ptrace(PTRACE_GETREGS, target_pid, &regs)
4. Change regs.pc to point to the injected code
5. ptrace(PTRACE_SETREGS, target_pid, &regs)
6. ptrace(PTRACE_CONT, target_pid)

Indicators:
- Open /proc/<pid>/mem or use ptrace
- Read or modify the target process registers
- Write shellcode into the target process space
```

### /proc/self/mem Self-Modification

```text
Workflow:
1. open("/proc/self/mem", O_RDWR)
2. lseek(fd, target_addr, SEEK_SET)
3. write(fd, new_code, size)

Purpose:
- Bypass W^X protection (mmap pages cannot be W+X at the same time)
- Modify its own code segment (.text is usually read-only)
- Patch instructions at runtime
```

---

## Strategies for Analyzing Large ELF Files

For large binaries of 5 MB or more:

```text
1. Quick reconnaissance (5 minutes)
   - file / rabin2 -I → architecture, type, protections
   - strings | grep -i "error\|fail\|http\|/proc\|/dev" → key strings
   - rabin2 -i → imported functions (if any)
   - rabin2 -E → exported functions

2. Structural analysis (10 minutes)
   - readelf -l → program headers (LOAD segment layout)
   - Code near the entry point → check for unpacking or decryption
   - Find .init_array → constructors (may contain anti-debugging)

3. Locate key logic
   - Start with cross-references to strings
   - Start with system calls (mmap/ptrace/open)
   - Start with network functions (connect/send/recv)

4. Divide and conquer
   - If it is self-extracting → extract it first, then analyze the payload
   - If it has multiple modules → analyze them by function
   - Use binary-diff to compare different versions
```

---

## Tool Command Quick Reference

```bash
# Basic information
file binary
readelf -h binary          # ELF header
readelf -l binary          # Program headers
readelf -S binary          # Section headers (if present)
rabin2 -I binary           # General information

# Strings
strings -a binary | less
rabin2 -z binary           # Strings in data sections
rabin2 -zz binary          # Strings in the entire file

# Disassembly
r2 -A binary               # radare2 analysis
objdump -d binary          # GNU disassembly
aarch64-linux-gnu-objdump -d binary  # ARM64 cross-disassembly

# Dynamic analysis
strace -f ./binary         # System call tracing
ltrace -f ./binary         # Library function tracing
qemu-aarch64 -strace ./binary  # ARM64 emulation

# Memory dump
gdb -p <pid> -ex "dump memory out.bin 0xADDR 0xADDR+SIZE" -ex quit

# Repair the damaged ELF
# Manually modify e_phnum or patch the damaged PHDR
python -c "
import struct
with open('binary', 'r+b') as f:
    f.seek(0x38)  # e_phnum offset (64-bit)
    f.write(struct.pack('<H', 2))  # Change to the correct PHDR count
"
```
