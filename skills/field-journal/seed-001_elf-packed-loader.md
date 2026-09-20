# [Seed] ELF self-extracting loader reverse engineering

## Scenario category
Binary analysis

## Goal summary
Analyze an ARM64 ELF self-extracting loader disguised as a `.sh` script. Recover its decompression algorithm and payload injection flow.

## Full execution path

1. Use the `file` command to confirm the real type (ELF, not a shell script).
2. Inspect program headers with `readelf -l` → find that the third PHDR was deliberately corrupted (filled with `0x0a`).
3. Get the architecture (AArch64), entry point, and compiler information with `rabin2 -I`.
4. Load the file in IDA/Ghidra → start analysis at the entry point.
5. Identify the LZSS decompression loop (bitstream operations plus sliding-window copying).
6. Identify the `mmap` → decompression → `mprotect` → jump injection flow.
7. Rewrite the decompressor in Python and dump the payload.
8. Analyze the payload (it references `/proc/self/exe`, which indicates a process injector).

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| readelf could not parse the file | The third PHDR was deliberately filled with `0x0a` | Ignore the damaged PHDR and inspect only the first two LOAD segments | 10min |
| IDA decompilation was unreadable | ARM64 bit operations were dense, and Hex-Rays optimization was poor | Switch to the disassembly view and analyze manually | 30min |
| The Python decompressor produced wrong output | The `pop_bit` refill path returned the wrong value (`adcs` vs `adds`) | Compare with the assembly carefully. During refill, return bit31 of the newly loaded word | 2h |
| The payload entry offset was uncertain | The meaning of the `entry_offset` field in the data table was unclear | Trace `br mmap_base + 0x14` in the loader and confirm that the entry is at `+0x14` | 20min |

## Toolchain findings

- The `file` command comes first. Never trust a filename extension.
- `rabin2 -I` tolerates more damaged input than `readelf` and can process a damaged PHDR.
- For code with dense ARM64 bit operations, a decompiler is less useful than direct assembly analysis.
- The Python `struct` module and a hand-written decompressor are a standard way to analyze custom compression.

## Key code / commands

```bash
# Confirm the file type
file LinYuDriverLoader4.9.sh
# ELF 64-bit LSB executable, ARM aarch64

# Inspect program headers
readelf -l binary 2>/dev/null | head -20

# Extract compressed data
dd if=binary bs=1 skip=$((0xa6a24)) count=1981 of=compressed.bin

# Calculate the file offset
# vaddr 0x3d66bc → file_offset = 0x3d66bc - 0x330000 = 0xa66bc
```

```python
# LZSS decompressor core (simplified)
def decompress(data):
    shift_reg = 0x80000000
    # ... bitstream reads plus literal/match branches
```

## Improvement suggestions for this package

- Add more features for identifying custom compression algorithms to `elf-analysis.md`.
- Add cache-maintenance instructions (`dc cvau` / `ic ivau`) to the ARM64 syscall table.
- Add a general method for rewriting assembly algorithms in Python.

## Reusable patterns / script fragments

**Standard pattern for identifying a self-extracting ELF**:
```text
Entry point → small initialization → call decompression function → mmap(RW) → decompress into mmap region → mprotect(RX) → jump
```

**General ARM64 bitstream-reading pattern**:
```text
lsl w4, w4, #1    # Shift left (extract the highest bit into carry)
cbz w4, refill    # If the value is empty, load a new 32-bit value from input
```

## Evolution actions
- [x] Updated child skill documentation (`elf-analysis.md` now includes this material)
- [ ] No update needed for the routing matrix
- [ ] No update needed for the bootstrap manifest

## Environment information
- OS: Linux/Android ARM64 target
- Tool versions: IDA Pro / Ghidra + radare2
- Target platform: Android ARM64 (AArch64)

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real target.

---
<!-- [Community contribution] Seed data. No PR needed. -->
