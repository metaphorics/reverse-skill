# Cortex-M virtual-disk update firmware with self-keyed rotate/XOR packaging

## Scenario

Binary and firmware reverse engineering

## Target summary

Analyze a Cortex-M debug-tool update package. Identify its custom packaging algorithm. Distinguish the application image in the update package from the USB Mass Storage bootloader resident on the device.

## Scope summary (redacted)

- auth_basis: own_system
- network_profile: authorized_target_only (the actual sample was local and offline)
- asset_types: [firmware_container, cortex_m_application, usb_msc_updater]

## Roles

- lead_role: lead
- specialists: [cre, cce, doc]

## Execution record

1. Measure the original package length, entropy, tail period, and block structure. Find that the file size is a multiple of 1 KiB and that the tail has a 7-byte period.
2. Start with Cortex-M vector-table constraints. Enumerate one-byte rotate/XOR relations and recover the first block.
3. Find that each 1 KiB block resets the rotation phase and that the first ciphertext byte can serve directly as that block's XOR mask.
4. Decode each block with `P[i] = ROR8(C[i], (3*i) mod 7) XOR C[0]`. Rebuild the original package byte by byte with the inverse transform.
5. Cross-check a second official firmware from the same series. The same format recovers a valid vector table, version string, and readable code. Every first plaintext byte is zero.
6. Infer the application base address from vector target addresses and file offsets. Confirm that the update package does not include a leading bootloader.
7. Combine the official instructions for entering the bootloader and emulating a USB drive. Rebuild the external MSC file-copy-to-Flash process. Mark internal bootloader details as inferred.
8. Test common CRC, STM32 hardware CRC, Adler, and additive checksums against the trailing 32-bit field. None match. Keep it as an unresolved integrity field.

## Evidence chain summary (redacted)

| E-id | source_type | Reusable command pattern | Related finding |
|---|---|---|---|
| E-001 | local_binary | block entropy, periodic tail, vector constraints | F-001 |
| E-002 | derived_algorithm | first-byte mask + ROR/XOR + round-trip | F-001 |
| E-003 | static_analysis | vector, string, and Thumb disassembly | F-002 |

## Finding and path summary

- top_finding: some high-entropy firmware packages use only self-keyed ROR/XOR obfuscation reset at each 1 KiB boundary. Do not classify them as standard encryption too early.
- path_type: solve/callflow
- path_one_liner: period and block structure → vector-table crib → first-block recovery → block-boundary reset → second-firmware cross-check → application/bootloader boundary → external MSC update flow

## Pitfalls

| Problem | Cause | Resolution | Time |
|---|---|---|---|
| First used the most common unrotated byte in each block as the mask. A few blocks still contained garbled text | The most common plaintext byte in a text-heavy block is not always zero | Compare first-byte models. The garbling disappeared and the result reproduced on the second firmware | Medium |
| A single whole-file XOR/rotate worked only at the start | The rotation phase and mask reset every 1 KiB | Split explicitly at `0x400` | Low |
| IDA and radare2 failed to start | No local IDA path and an abnormal r2 bootstrap installer | Use Python + Capstone to verify the Cortex-M entry point | Medium |
| Seeing `firmware_crc32` led to an assumption that the tail was standard CRC32 | The string is a metadata key and does not prove the package-tail parameters or coverage | Exclude common families systematically. Keep the algorithm unknown instead of forcing a name | Low |

## Tool findings

- Python works well for bit-transform enumeration, round trips, and cross-sample invariant checks.
- Capstone is enough to verify the Cortex-M vector entry and local control flow without IDA, Ghidra, or radare2.
- Recovered-string quality is a strong signal when comparing candidate mask models. Combine it with absolute pointers and disassembly instead of relying on readability alone.

## Key algorithm

```text
block_size = 0x400
mask = packed_block[0]
rotation(i) = (3 * i) mod 7
plain[i] = ROR8(packed[i], rotation(i)) XOR mask
```

The inverse transform uses `ROL8`. The validation standard is byte-for-byte equality between the encoded result and the original package.

## Improvement suggestions for this package

- Add a check for period reset at block boundaries during firmware-container identification in firmware-pentest.
- When a heuristic zero-byte crib fails on a few blocks, test a self-describing mask at the block head or tail first.
- When an update package contains only the application, clearly separate internal bootloader behavior from protocol-level behavior that is certain.

## Reusable patterns

1. Test common Flash and transport block sizes (256, 512, 1024, 2048, 4096) for period resets first.
2. Use the Cortex-M SRAM stack pointer and Thumb Reset Vector as a strong crib.
3. Run three checks for each candidate model: full-file round trip, second-sample reproduction, and consistent absolute-address references.
4. When a tail field does not match a common checksum, do not treat a variable name or string as algorithm evidence.

## Follow-up actions

- [x] Add the field-journal record
- [x] Update the field-journal index
- [ ] Update the routing matrix
- [ ] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation

## Environment

- OS: Windows
- Tool versions: Python 3.12, Capstone 5.0.6
- Target platform/version: Cortex-M3 / F1-compatible MCU application firmware

## Redaction check

- [x] No real domain, IP, credential, token, or PII
- [x] No local absolute path
- [x] No sample file or sample hash
- [x] Vendor, product, and version information generalized
