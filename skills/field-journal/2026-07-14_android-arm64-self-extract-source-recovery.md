# 2026-07-14 Android ARM64 self-extracting program source recovery

## Scenario

Binary analysis, Android ARM64, self-extracting shell, and control-flow flattening

## Target summary

Recover source from a user-owned local `.sh` delivery package in read-only mode. Split out multiple compressed payload layers. Analyze the ARM64 main program and protection library. Recover business text and high-level pseudocode without running the target.

## Execution record

1. Create a read-only inventory of the input directory. Record sizes, magic bytes, and SHA-256 values. Do not read or record plaintext credentials.
2. Identify the first layer as a shell preamble followed by a bzip2 stream. Locate the exact offset by testing valid `BZh` streams.
3. Save the preamble, compressed stream, and extracted payload in an isolated output directory. Do not execute the payload.
4. Identify the second layer as an `__ARCHIVE_BELOW__` self-extracting script. Safely expand the tar.gz archive. Reject absolute paths, `..`, links, and device nodes.
5. Obtain an Android AArch64 PIE main program and an AArch64 shared library. Use pyelftools and Capstone to generate ELF headers, sections, symbols, imports, strings, and entry-point disassembly.
6. The protection library retained readable C++ symbols. Export pseudocode for each function. Confirm `/proc` scanning, `TracerPid`, three-level process termination, and background-thread behavior.
7. The `main` symbol was much longer than the length found by ordinary CFG analysis. This confirmed indirect-jump control-flow flattening.
8. Solve the jump table statically: `target = table_entry + fixed_delta`. Enumerate every unique real basic block.
9. Scan for isomorphic string decryptors. Identify the layout as a loop XOR key over the first N bytes followed by M bytes of ciphertext.
10. Run AArch64 constant propagation over each real basic block. Resolve indirect decryptor-call targets and the `x1` data source. Recover business text in batches.
11. Deliver full disassembly, function-by-function pseudocode, high-level semantic source, a Mermaid flowchart, and a formal report.
12. Recompute the original input hash. Confirm that the input is identical before and after analysis.

## Pitfalls

| Problem | Cause | Resolution | Time |
|---|---|---|---|
| PowerShell blocked direct bootstrap execution | The system blocked scripts | Use a one-time `powershell.exe -ExecutionPolicy Bypass -File ...`. Do not change the permanent policy | Low |
| radare2 bootstrap returned GitHub API 403 | API rate limiting or rejection, while the release page remained available | Get the official asset and page SHA-256 from the `releases/latest` redirect and `expanded_assets/<tag>`. Validate, then extract | Medium |
| winget Rizin silent and per-user installs did not land | The installer scope did not match | Stop retries after two failures. Use the verified official radare2 ZIP instead | Low |
| `r2pm -U` stayed at git clone for a long time | Network speed or recursive repositories | Stop the optional plugin path. Continue with `pdc` plus custom Capstone recovery | High |
| radare2 recognized only the front CFG of `main` | An indirect BR jump table ended normal analysis at the dispatcher | Enumerate real blocks from the jump-table formula. Do not rely on the default CFG | Medium |
| Direct string scanning found only a few paths | Each string used its own loop XOR | Extract the key and output lengths from the decryptor instructions. Replay the algorithm statically | Medium |

## Tool findings

- The Python 3.13 standard library safely handles bzip2 and tar.gz. `tarfile.extractall` is less safe than validating each member before writing it.
- pyelftools recovers ELF, DYNSYM, and RELA data. Capstone works well for ARM64 constant propagation and custom decryptor detection.
- radare2 6.1.8 `pdc` works for unobfuscated protection-library functions. It provides only partial pseudocode for a main function flattened with indirect BR jumps.
- A GitHub API 403 does not mean that official release assets are inaccessible. The release page can provide the tag, asset name, and SHA-256 value.

## Key code and commands

```python
# Generic loop-XOR text layout
key = blob[:key_length]
encrypted = blob[key_length:key_length + output_length]
plain = bytes(value ^ key[index % key_length]
              for index, value in enumerate(encrypted))
```

```python
# Static solution for an indirect jump table
targets = {
    (entry + fixed_delta) & 0xFFFFFFFFFFFFFFFF
    for entry in jump_table_entries
}
```

```powershell
# Read the latest tag when the API returns 403
curl.exe -sS -I '<official-release-url>/radareorg/radare2/releases/latest'
```

## Improvement suggestions for this package

- Add a target route for `.sh` self-extracting binaries disguised as shell scripts. Do not classify them as ordinary shell review.
- When the GitHub Release API returns 403, make the Windows bootstrap fall back to the release page and `expanded_assets`, with mandatory SHA-256 validation.
- Add a generic recovery script template for ARM64 jump tables plus loop XOR. This provides a low-dependency path without IDA.
- Preserve the session ID and poll when a tool call exceeds the foreground window. Do not lose a download or export task that still runs.

## Reusable patterns and script fragments

1. Scan for valid compressed streams instead of only searching for magic bytes. Test a full in-memory extraction at every candidate offset.
2. Always write self-extracting archives one member at a time with path validation. Never execute them or trust member paths.
3. When a symbol table declares a function much longer than the CFG length, check for an indirect BR or BLR table first.
4. Identify isomorphic decryptors in batches through the instruction combination `add x16,x1,#key_len`, `cmp w16,#output_len`, and `ldrb/eor/strb`.
5. Local constant propagation over flattened blocks usually recovers indirect function targets and string source addresses. Full de-flattening is not required first.

## Follow-up actions

- [x] Update the routing matrix
- [x] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation
- [x] Add the pitfall record
- [ ] No update needed

## Environment

- OS: Windows
- Tool versions: Python 3.13, radare2 6.1.8, pyelftools, Capstone
- Target platform/version: Android ARM64, NDK r17 / Clang 6.0.2

## Redaction check

- No software name, author name, real domain, real API endpoint, credential, fixed signing material, business package name, or local user path was recorded.
- No sample file or sample hash was attached.
- Only public tool names, versions, and generic algorithm patterns remain.

## Index synchronization

This record was added to the `_index.md` "Binary / firmware / CTF" category, and the statistics were updated.

---
<!-- [Community contribution] Ask the user whether to open a PR against the main repository after completion. See CONTRIBUTE-BACK.md for the process. -->
