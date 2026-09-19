# IDA Pro MCP Tool Quick Reference

> ida-pro-mcp 2.x tools are grouped by function, with common parameters and typical usage.
> Server name: `idapro`, tool prefix: `idapro_*`, runs in HTTP mode. The tool count changes by version (about 66, including `py_eval`).

---

## Startup and Session Management

### Server Startup

```powershell
# Start the MCP HTTP server (silent in the background; OK:<n>:reuse when healthy)
powershell -File "scripts/start.ps1"
# Output OK:<tool count> to indicate readiness (about 66, including py_eval)

# Open the target file (bypass schema validation)
powershell -File "scripts/open.ps1" -Path "C:\target.exe"
# Output OK:filename:session_id

# Add a timeout for large files/GUI programs
powershell -File "scripts/open.ps1" -Path "C:\big.exe" -TimeoutSeconds 600

# Skip automatic analysis (open quickly)
powershell -File "scripts/open.ps1" -Path "C:\huge.sys" -NoAutoAnalysis
```

### Session Tools

| Tool | Purpose | Example |
|------|------|------|
| `idapro_idb_list()` / HTTP `idb_list` | List all sessions | — |
| `idapro_idb_open()` / HTTP `idb_open` | Open a database (use `open.ps1` first) | Use a script for large files |
| `idapro_idb_save(path)` / HTTP `idb_save` | Save the database | Save analysis progress |
| `idapro_idb_current()` | Current bound session (if provided by the version) | — |
| `idapro_idb_switch(session_id)` | Switch sessions | When comparing multiple files |
| `idapro_idb_close(session_id)` | Close the session | Release resources |
| `idapro_server_health()` | Check server health | — |
| `idapro_server_warmup()` | Warm up subsystems | Before first use |

---

## Step 1: Global Overview

### survey_binary - Quick Overview

```
idapro_survey_binary(detail_level="minimal")
```

Returns:
- Architecture (x86/x64/ARM/MIPS)
- Entry point
- Total function count
- String statistics
- Segment information
- Import categories (encryption/network/file IO/registry)
- High xref popular functions

**detail_level options**:
- `"minimal"` — Quick overview (recommended first choice)
- `"standard"` — Includes more details
- `"full"` — Complete information

### Function list

```
# List all functions (paginated)
idapro_list_funcs(queries=[{"offset": 0, "limit": 50}])

# Filter by name
idapro_list_funcs(queries=[{"filter": "crypt", "offset": 0, "limit": 20}])
idapro_list_funcs(queries=[{"filter": "main", "offset": 0, "limit": 10}])
```

### Unified query

```
# Query imported functions
idapro_entity_query(kind="imports", filter="Create")

# Query strings
idapro_entity_query(kind="strings", filter="http")

# Query all named symbols
idapro_entity_query(kind="names", filter="")
```

---

## Decompilation and disassembly

### Decompilation (pseudocode)

```
# By function name
idapro_decompile(addr="main")
idapro_decompile(addr="sub_140001000")

# By address
idapro_decompile(addr="0x140001000")
```

### Disassembly

```
# Default instruction count
idapro_disasm(addr="main")

# Specify the instruction count
idapro_disasm(addr="0x401000", max_instructions=100)
```

### Combined analysis (recommended)

```
# Fetch all at once: pseudocode + strings + constants + callers + callees + basic blocks
idapro_analyze_function(addr="main", include_asm=false)

# Include assembly
idapro_analyze_function(addr="sub_401000", include_asm=true)
```

### Function summary

```
# Fetch function metrics in bulk (size, block count, xref count)
idapro_func_profile(queries=["main", "sub_401000", "sub_402000"])
```

---

## Cross-references and call graph

### Who references the target

```
# See who calls a function
idapro_xrefs_to(addrs=["sub_401000"])

# See who references a string/data
idapro_xrefs_to(addrs=["0x404000"])

# Batch query
idapro_xrefs_to(addrs=["CreateFileW", "ReadFile", "WriteFile"])
```

### Advanced xref query

```
# Specify direction and type
idapro_xref_query(addr="0x401000", direction="to")    # Who references me
idapro_xref_query(addr="0x401000", direction="from")  # Who do I reference
```

### List of called functions

```
idapro_callees(addrs=["main"])
```

### Call graph

```
# Start from main, depth 3
idapro_callgraph(roots=["main"], max_depth=3)

# Multiple starting points
idapro_callgraph(roots=["sub_401000", "sub_402000"], max_depth=2)
```

### Data-flow tracing

```
# Trace backward: Where does this value come from
idapro_trace_data_flow(addr="0x401050", direction="backward", max_depth=5)

# Trace forward: Where does this value flow
idapro_trace_data_flow(addr="0x401050", direction="forward", max_depth=5)
```

---

## Search

### String search (regex)

```
# Search URLs
idapro_find_regex(pattern="https?://", limit=20)

# Search file paths
idapro_find_regex(pattern="C:\\\\", limit=20)

# Search error messages
idapro_find_regex(pattern="error|fail|invalid", limit=30)

# Search keys/passwords
idapro_find_regex(pattern="key|password|secret|token", limit=20)
```

### Disassembly text search

```
# Search the disassembly listing
idapro_search_text(pattern="call    sub_")
idapro_search_text(pattern="xor     eax, eax")
```

### Byte-pattern search

```
# Exact bytes
idapro_find_bytes(patterns=["48 8B 05"], limit=10)

# With wildcards
idapro_find_bytes(patterns=["48 89 ?? 24 ??"], limit=10)

# Multiple patterns
idapro_find_bytes(patterns=["CC CC CC CC", "90 90 90 90"], limit=5)
```

### Advanced search

```
# Search immediate values
idapro_find(type="immediate", targets=["0xDEADBEEF"])

# Search string references
idapro_find(type="string", targets=["password"])
```

---

## Memory and data reading

### Read Raw Bytes

```
idapro_get_bytes(addrs=[{"addr": "0x401000", "size": 64}])
```

### Read Strings

```
idapro_get_string(addrs=["0x404000", "0x404100"])
```

### Read Integers

```
idapro_get_int(queries=[{"addr": "0x405000", "size": 4}])
```

### Read Global Variables

```
idapro_get_global_value(queries=["g_flag", "g_key_size"])
```

### Read Structures

```
idapro_read_struct(queries=[{"addr": "0x405000", "type": "HEADER"}])
```

### Search Structures

```
idapro_search_structs(filter="FILE")
```

---

## Modification Operations

### Add Comments

```
# Single comment
idapro_set_comments(items=[{"addr": "0x401000", "comment": "Decryption function entry"}])

# Batch comments
idapro_set_comments(items=[
    {"addr": "0x401000", "comment": "XOR decryption loop"},
    {"addr": "0x401050", "comment": "Key initialization"},
    {"addr": "0x4010A0", "comment": "Result validation"}
])

# Append comments (do not overwrite existing ones)
idapro_append_comments(items=[{"addr": "0x401000", "comment": "Additional: key length 16"}])
```

### Rename

```
# Rename function
idapro_rename(batch={"func": [
    {"addr": "sub_401000", "name": "decrypt_payload"},
    {"addr": "sub_402000", "name": "verify_license"}
]})

# Rename global variable
idapro_rename(batch={"global": [
    {"addr": "0x405000", "name": "g_encryption_key"}
]})

# Rename local variable
idapro_rename(batch={"local": [
    {"func": "decrypt_payload", "old": "v1", "name": "plaintext_buf"}
]})
```

### Patch Assembly

```
# NOP the detection code
idapro_patch_asm(items=[{"addr": "0x401050", "asm": "nop"}])

# Modify jump
idapro_patch_asm(items=[{"addr": "0x401060", "asm": "jmp 0x401080"}])

# Force return true
idapro_patch_asm(items=[
    {"addr": "0x401000", "asm": "mov eax, 1"},
    {"addr": "0x401005", "asm": "ret"}
])
```

### Patch Bytes

```
# Write bytes directly
idapro_patch(patches=[{"addr": "0x401050", "bytes": "9090909090"}])
```

---

## Type System

### Declare Structures

```
idapro_declare_type(decls=[{
    "name": "PacketHeader",
    "decl": "struct PacketHeader { uint32_t magic; uint16_t type; uint16_t length; uint8_t data[0]; };"
}])
```

### Apply Types

```
# Set the function prototype
idapro_set_type(edits=[{
    "addr": "sub_401000",
    "type": "int __fastcall decrypt(void *buf, int size, const char *key)"
}])

# Set the global variable type
idapro_set_type(edits=[{
    "addr": "0x405000",
    "type": "PacketHeader"
}])
```

### Infer Types

```
idapro_infer_types(addrs=["sub_401000", "sub_402000"])
```

### Query/View Types

```
idapro_type_query(queries=["Packet"])
idapro_type_inspect(queries=["PacketHeader"])
```

---

## Stack Frame Analysis

```
# View the function stack frame
idapro_stack_frame(addrs=["main", "sub_401000"])

# Declare stack variable
idapro_declare_stack(items=[{
    "func": "sub_401000",
    "offset": -0x20,
    "name": "local_buf",
    "type": "char [32]"
}])
```

---

## Signature Generation

```
# Generate a unique byte signature for an address
idapro_make_signature(addrs=["0x401000"])

# Generate a signature for the entire function
idapro_make_signature_for_function(addrs=["decrypt_payload"])

# Generate a signature for code that references an address
idapro_find_xref_signatures(addrs=["0x405000"])
```

---

## Base Conversion

```
# Hexadecimal → Decimal
idapro_int_convert(inputs=["0x401000"])

# Decimal → Hexadecimal
idapro_int_convert(inputs=["4198400"])

# Batch conversion
idapro_int_convert(inputs=["0xDEAD", "0xBEEF", "12345"])
```

> ⚠️ **Always use this tool for base conversion. Do not calculate it yourself!**

---

## Export and Scripting

### Export Functions

```
# JSON format
idapro_export_funcs(addrs=["main", "sub_401000"], format="json")

# C header file
idapro_export_funcs(addrs=["main", "sub_401000"], format="c_header")

# Function prototype
idapro_export_funcs(addrs=["main", "sub_401000"], format="prototypes")
```

### Execute Python Scripts

```
# Execute Python in the IDA context
idapro_py_eval(code="import idautils; print(list(idautils.Functions())[:10])")

# Get segment information
idapro_py_eval(code="import idc; print(idc.get_segm_name(0x401000))")

# Batch operations
idapro_py_eval(code="import ida_funcs; f=ida_funcs.get_func(0x401000); print(f.size())")
```

---

## Typical Analysis Workflow

### Malware Analysis

```text
1. survey_binary → Inspect imports (network APIs? encryption? registry?)
2. find_regex("http|socket|connect") → Find network-related strings
3. xrefs_to(network string address) → Find referencing functions
4. decompile(referencing function) → Inspect communication logic
5. trace_data_flow(encryption parameter, "backward") → Trace the key source
6. set_comments + rename → Annotate findings
```

### Registration Verification Cracking

```text
1. find_regex("serial|license|register|valid") → Find validation-related strings
2. xrefs_to(validation string) → Locate the validation function
3. analyze_function(validation function) → Understand the logic
4. callgraph(validation function, 2) → Inspect the call chain
5. patch_asm(conditional jump address, "jmp always_pass") → patch
```

### CTF Reverse Engineering

```text
1. survey_binary → Confirm the architecture and entry points
2. decompile("main") → Inspect the main logic
3. find_regex("flag|correct|wrong") → Find the decision point
4. trace_data_flow(decision_point, "backward") → Trace input transformations
5. Use Python to assist with calculation/decryption → Obtain the flag
```

### Vulnerability Analysis

```text
1. entity_query(kind="imports", filter="strcpy|sprintf|gets") → Find dangerous functions
2. xrefs_to(dangerous_function) → Find call sites
3. analyze_function(containing_function) → Inspect the context
4. stack_frame(function) → Confirm the buffer size
5. trace_data_flow(dangerous_argument, "backward") → Confirm user control
```

---

## Common Errors and Solutions

| Error | Cause | Solution |
|------|------|------|
| "No database bound" | No file is open | Run `open.ps1` |
| "Failed to open database" | The old database is locked | `open.ps1` automatically falls back to Temp |
| Schema validation failed | MCP client BUG | Use `open.ps1` instead of `idb_open` |
| Tool timed out | The tool is analyzing a large file | Add `-TimeoutSeconds 600` |
| "ERR:timeout" (start.ps1) | The server failed to start | Check the Python/idalib-mcp installation |
| Base conversion error | A manual calculation is incorrect | Use `idapro_int_convert` |
| Function name not found | The name is not exact | Search first with `list_funcs` + filter |
