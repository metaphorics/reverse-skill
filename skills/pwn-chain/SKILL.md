---
name: pwn-chain
description: |
  Engineering method for moving from reverse engineering to a working exploit.
  Use when you have a binary, a vulnerability, and a target environment, and need a stable exploit. Do not use for local-only reproduction.
  Covers stack overflow, heap exploitation, and kernel pwn. Emphasizes the engineering gap between local CTF success and stable remote exploitation: libc version mismatch, heap-spray timing, SMEP/SMAP/KASLR, stack alignment, and remote buffering.
  Core tools: pwntools + GEF/pwndbg + ROPgadget/Ropper + one_gadget + libc-database + qemu-system kernel debugging.
  Trigger keywords: pwn, stack overflow, heap overflow, ROP, ret2libc, ret2csu, one_gadget, libc-database, heap exploitation, tcache, fastbin, unsorted bin, kernel pwn, kROP, SMEP, SMAP, KASLR, modprobe_path, pwntools, GEF, pwndbg.
---

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` to confirm that this Skill's actions are authorized routine actions.
2. `NOW`: Confirm that the current task fits this Skill's scope.
3. `NEXT`: Read `../tool-index.md` and check tool availability and actual paths.
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths.
5. `ACT`: Enter and execute the first workflow step. Do not stop at confirmation.

# From vulnerability point to working exploit (Pwn Chain)

## Scope

Use this Skill when the task matches one of these scenarios:

1. **Binary + known vulnerability point**: Static analysis, audit, or fuzzing found an overflow, UAF, or double free. Move from trigger to shell.
2. **CTF works locally but fails remotely**: Remote environment differences broke the script. Stabilize it.
3. **Exploitation of a real target binary**: An SRC or red-team task identified a memory-corruption vulnerability. Build RCE.
4. **Linux kernel driver ioctl bug**: Trigger it from user mode. Escalate privileges to root.

**Prerequisite**: You already know where the failure occurs. This Skill does not find vulnerabilities. Fuzzing and audit skills find them. This Skill writes an exploit from the vulnerability point.

### Division of work with other Skills

| Scenario | Use |
|----------|-----|
| Identify a custom VM, anti-debugging, or complex obfuscation | `reverse-engineering/` |
| Open a binary for static analysis from the start | `ida-reverse/` or `radare2/` |
| **Known vulnerability point. Write an exploit for remote success.** | **This Skill** |
| Integrate a pwn shell into a complete attack chain | `attack-chain/` (downstream) |

`reverse-engineering/` focuses on understanding what a program does, such as pattern recognition, protocol recovery, and unusual CTF mechanisms. This Skill turns an understood vulnerability into an executable attack. Use both Skills when needed. Keep their roles separate.

## Core workflow

```text
Step 1: Confirm the vulnerability type + protections
   ├─ checksec ./vuln (NX / Canary / PIE / RELRO / Fortify)
   ├─ file ./vuln  + readelf -d ./vuln
   ├─ Classify the vulnerability: stack overflow / format string / heap (UAF/DF/OF) / integer / race / kernel
   └─ → Choose the applicable references/

Step 2: Choose an exploitation strategy
   ├─ NX off + no ASLR → direct shellcode
   ├─ NX on + libc provided → ret2libc / one_gadget
   ├─ NX on + libc not provided → leak, then identify it with libc-database
   ├─ Heap → choose the technique for the glibc version (tcache/fastbin/unsorted/large)
   └─ Kernel → commit_creds / modprobe_path / core_pattern

Step 3: Prepare libc + gadgets
   ├─ libc-database: ./find puts 0x6f0
   ├─ ROPgadget --binary ./libc.so.6 --only "pop|ret"
   ├─ one_gadget ./libc.so.6
   └─ Calculate the base: leak_addr - libc.sym['puts']

Step 4: Write a pwntools template (local process)
   ├─ context.binary = ELF('./vuln')
   ├─ p = process('./vuln')  /  p = gdb.debug('./vuln','b *main+xx')
   ├─ payload = cyclic(N) + p64(ret) + ...
   └─ p.interactive()

Step 5: Make it work locally
   ├─ Repeatedly attach, inspect registers, and adjust the offset
   ├─ Use vmmap / heap / bins / telescope in pwndbg/GEF
   └─ Switch to remote() after local success

Step 6: Stabilize it remotely
   ├─ libc offset: identify libc with leak and libc-database. Do not guess.
   ├─ Stack alignment: 16-byte misalignment → movaps crash → add a ret gadget
   ├─ Remote network delay → recvuntil with an exact anchor string. Disable vague sleep calls.
   ├─ Remote buffering: sendlineafter is more stable than sendline
   ├─ Heap-spray success rate: increase the spray count and leave padding chunks to prevent merging
   └─ Run it repeatedly: use while True to verify a success rate of at least 95%
```

## Typical scenarios

### Scenario 1: Remote 64-bit binary (NX+PIE+canary, libc provided)

```text
Available: ./vuln (64-bit ELF, NX, PIE, canary) + ./libc.so.6 + nc host port
Vulnerability: read(buf, 0x200) but buf is only 0x40 bytes → stack overflow
Protection: the canary blocks the overwrite, and PIE randomizes .text

Strategy:
1. First leak the canary (stack/format string/partial read)
2. Then leak a libc function address (puts@got)
3. Calculate the libc base with libc.address = leaked - libc.sym['puts']
4. Run one_gadget ./libc.so.6 and choose a magic gadget with satisfiable constraints
5. payload = padding + canary + saved_rbp + (pop_rdi + bin_sh + system), or use one_gadget directly
6. Add a ret gadget to fix stack alignment (critical)
```

See `references/stack-pwn.md` for the complete template.

### Scenario 2: Linux kernel driver ioctl out-of-bounds write → root

```text
Available: vmlinux + bzImage + initramfs.cpio.gz + custom vuln.ko
Vulnerability: copy_from_user length is controllable in ioctl(0x1337, ptr) → kernel heap overflow (kmalloc-64 slab)
Protection: SMEP, SMAP, KASLR, KPTI

Strategy:
1. Modify the init script to get a root shell (CTF), or leak the KASLR base first and continue (real target)
2. Leak the kernel base through /proc/kallsyms (may be restricted) or an uninitialized heap spray
3. Spray tty_struct / msg_msg / pipe_buffer in the kmalloc-64 slab
4. Overwrite the vtable pointer to point to user mode → not possible (SMEP). Use stack pivot + kernel ROP instead.
5. ROP chain: prepare_kernel_cred(0) → commit_creds → swapgs+iretq → user-mode execve("/bin/sh")
6. Or use the simpler path: overwrite modprobe_path with "/tmp/x", write /tmp/x, then trigger modprobe
```

See `references/kernel-pwn.md` for the complete template.

## On-demand bootstrap

### Tool dependencies

| Tool | Purpose | Installation |
|------|---------|--------------|
| pwntools | Exploit-writing framework | `pip install pwntools` |
| GEF | gdb enhancement (recommended for kernel and user mode) | `git clone https://github.com/bata24/gef` (actively maintained fork) |
| pwndbg | gdb enhancement (best heap debugging experience) | `git clone https://github.com/pwndbg/pwndbg && ./setup.sh` |
| ROPgadget | Gadget search | `pip install ropgadget` |
| Ropper | Gadget search (alternative, supports more architectures) | `pip install ropper` |
| one_gadget | Find libc magic gadgets | `gem install one_gadget` (requires Ruby) |
| libc-database | Identify libc from fingerprints | `git clone https://github.com/niklasb/libc-database && ./get` |
| qemu-system-x86_64 | Kernel challenge debugging | `apt install qemu-system-x86` |
| binwalk / cpio | Unpack initramfs | `apt install binwalk cpio` |
| patchelf | Switch libc versions | `apt install patchelf` |

### Bootstrap check script

```bash
# Check and install core tools in one pass
for t in pwntools ropgadget ropper; do
  pip show $t >/dev/null 2>&1 || pip install $t
done

command -v one_gadget >/dev/null || gem install one_gadget

[ -d ~/tools/libc-database ] || git clone https://github.com/niklasb/libc-database ~/tools/libc-database
[ -d ~/tools/libc-database/db ] || (cd ~/tools/libc-database && ./get ubuntu debian)

[ -d ~/tools/pwndbg ] || (git clone https://github.com/pwndbg/pwndbg ~/tools/pwndbg && cd ~/tools/pwndbg && ./setup.sh)
```

### After automatic installation of the same tool fails twice

Stop retrying. Output structured manual installation steps (pip source / gem source / domestic git mirror / apt source) and ask the user to confirm.

## Routing context

**Upstream entry**: `skills/SKILL.md` (controller), `routing.md`
**Trigger condition**: Binary + identified vulnerability point. Need to write an exploit.

**Upstream Skills (use them first, then return to this Skill)**:
- Do not yet understand what the binary does → `reverse-engineering/`
- Need detailed static analysis → `ida-reverse/`
- Need quick reconnaissance to confirm architecture and protections → `radare2/`

**Downstream Skill (after obtaining a shell)**:
- Integrate into a complete attack chain (lateral movement, privilege escalation, persistence) → `attack-chain/`

**Submodule navigation**:
- Stack exploitation (ret2libc / ret2csu / one_gadget / stack alignment) → `references/stack-pwn.md`
- Heap exploitation (tcache / fastbin / unsorted / large bin / FILE struct) → `references/heap-pwn.md`
- Kernel pwn (kROP / SMEP-SMAP bypass / KASLR leak / modprobe_path) → `references/kernel-pwn.md`

## Notes

- **Do not stop after local success**: local libc, ASLR, and network conditions differ from remote conditions. Run at least 20 consecutive remote tests to verify stability.
- **Confirm the libc version**: identify it with leak + libc-database. Do not assume the Ubuntu 22.04 default libc.
- **Stack alignment is a common 64-bit trap**: `movaps xmm0, [rsp]` faults when rsp is not 16-byte aligned. Add an empty `ret` gadget.
- **Heap exploitation is highly sensitive to the glibc version**: tcache arrived in 2.27, safe-linking arrived in 2.32, and hooks were removed in 2.34. Each version has a different exploitation path.
- **Kernel pwn requires CPU flags first**: `+smep +smap +pku` in qemu startup parameters directly determines how to write the ROP chain.
- **One KASLR leak is enough**: after obtaining one kernel address, calculate every address from offsets. Do not leak repeatedly.

## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow rather than only read it?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
