---
name: ida-reverse
description: |
  IDA Pro reverse engineering support skill. Use this skill when the user mentions reverse engineering, decompilation, analysis of binary files, PE, ELF, APK, DLL, or SO files, cracking, password finding, vulnerability analysis, malware analysis, or firmware analysis, or when the user needs analysis of exe, dll, so, elf, macho, sys, or similar files.

  Ensure to use this skill when the user wants to analyze any binary file, regardless of whether they explicitly mention "IDA" or "reverse engineering". This includes requests like "Look at this exe", "Analyze this dll", "Help me crack this", "Find the password", "How does this software register", etc.

  Use the bundled scripts (scripts/start.ps1, scripts/open.ps1) for deterministic server management and file opening — do NOT write ad-hoc PowerShell commands for these operations.
---

# IDA Pro reverse engineering skill

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` - confirm that this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task is within this skill's scope
3. `NEXT`: Read `../tool-index.md` and verify tool availability and actual paths
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess the path
5. `ACT`: Enter and execute the first step of the "workflow". Do not stop at the confirmation state

## Known issues and lessons learned (must read)

### Pitfalls

1. **Do not call `idb_open` (formerly `idalib_open`) directly through some AI client MCP integrations**
   - Some code AI client MCP clients have a BUG in the output schema validation for open-type tools
   - Error: `Structured content does not match the tool's output schema`
   - **Solution**: Use the `scripts/open.ps1` script to call the HTTP API directly and bypass the MCP validation layer
   - The current ida-pro-mcp 2.x tool names are `idb_open` / `idb_list` / `idb_save` and are no longer `idalib_*`
   - After the file opens, it returns a `session_id` (database). Subsequent tool calls must include this session

2. **Files in `C:\Windows\System32\` cannot be opened without permission**
   - idalib cannot read files in the System32 directory directly
   - **Solution**: `open.ps1` automatically detects the issue, copies the file to the `temporary directory` directory, and then opens it

3. **The server startup command blocks the conversation**
   - After `idalib-mcp` starts, it continuously writes INFO logs to the console
   - **Solution**: Use `scripts/start.ps1` (`-WindowStyle Hidden` starts it silently in the background)
   - The script waits for the service to become ready and then exits automatically. It does not block the conversation

4. **MCP server names cannot use hyphens**
   - The previous server name was `ida-pro-mcp`, which could cause tool registration problems
   - **Current configuration**: server name `idapro`, tool prefix `idapro_*`

5. **Remote HTTP vs Local Stdio**
   - `type:\"local\"` (stdio) mode: `idalib_open` also has schema validation problems
   - `type:\"remote\"` (HTTP) mode: Open the file directly with a script first, then use the MCP tools
   - **Current solution**: Remote HTTP mode

6. **PR #389 fixed some schema problems**
   - Author mrexodia merged the fix through PR #389 after issue #388
   - The fix corrected the structuredContent schema in HTTP mode, but some AI client-side code still has validation problems
   - The latest `main` branch version is installed

7. **idalib timeouts leave orphan worker process lock files**
   - After the first `open.ps1` timeout, the idalib Python worker child process may become an orphan and keep `.id0`/`.id1`/`.nam` locked
   - Any later tool or manual file drop into the IDA GUI reports "permission denied"
   - **Do not** use `taskkill /F /T` to kill the process tree. `/T` also kills the GUI `ida.exe` child process
   - **Solution**: `start.ps1` replaces the managed supervisor only when no process listens on the port, or when `tools/list` returns quickly without `py_eval` (old supervisor). If the RPC times out while 13337 still listens, treat it as busy and do not kill it. When `open.ps1` opens a database, it writes `opening.lock`. The watchdog must not use `-Force`
   - **Deadlock exception**: Use `-Force` to replace the supervisor only when `tools/list` fails continuously for more than 3 minutes (use the last-healthy timestamp, not the process creation time), there is no in-flight `opening.lock`, and the GUI does not occupy the port. Still do not kill `ida.exe`
   - **Fallback**: When `open.ps1` detects that an old database is locked, it automatically copies the database to Temp and adds a GUID prefix

8. **Opening with automatic analysis looks like a hang**
   - `idalib_open(run_auto_analysis=true)` may not return a response for a long time, but the back end continues to open and analyze the file
   - Previously, the user saw “PowerShell produced no output”, which could be mistaken for a script hang
   - **Current solution**: `open.ps1` adds `-TimeoutSeconds` and changes to a background request, foreground polling, and timed progress output
   - When polling finds that the session is ready, it returns early with `OK:filename:session_id`. On timeout, it returns `ERR:open_timeout_xxs`

9. **HTTP MCP exits silently after login**
   - Cursor/Claude `type: http` does not start the process on its behalf. The old scheduled task ran only once at login
   - `pythonw` has no console, and the Application log is also empty when it crashes
   - **Solution**: `start.ps1` reuses the process by default when it is healthy; `watchdog.ps1` checks it every minute; logs are in `%LOCALAPPDATA%\reverse-skill\ida-mcp\`
   - Install: `scripts/install-autostart.ps1`. If the HTTP client starts before the port is ready, refresh it once manually in the MCP panel

10. **Streamable HTTP GET `/mcp` can block the single-threaded supervisor**
   - Some HTTP MCP clients send a long-lived GET connection to `/mcp` (SSE). The stock `idalib_supervisor` uses an `HTTPServer` with `background=False` and processes only one request at a time
   - Result: `tools/list` times out, and the client marks `idapro` as error
   - **Solution**: `run-supervisor.py` changes the HTTP server to `ThreadingHTTPServer` and accepts GET `/mcp`; if the patch fails, skip it and still start the supervisor. When it is blocked, use `scripts/recover.ps1` (use `-Force` immediately)

### Workflow Principles

| Step | Action | Tool |
|------|--------|--------|
| 1 | Ensure that the HTTP server is running | `scripts/start.ps1` (no parameters) |
| 2 | Open the target binary file | `scripts/open.ps1 -Path "xxx.exe"` |
| 3 | Use the MCP analysis tools | Call `idapro_*` / HTTP tools directly (about 65, depending on the version) |
| 4 | Finish the analysis | The tools become available automatically |

## Script Resources

### start.ps1 — Start the MCP HTTP server

Path: `scripts/start.ps1`

- Automatically resolve `IDADIR` (environment variable / portable desktop path / common installation paths)
- Prefer the IDA bundled `Python314\python.exe -m ida_pro_mcp.idalib_supervisor`
- First probe `http://127.0.0.1:13337/mcp` by default. If it is healthy, output `OK:<n>:reuse` and exit
- If 13337 is listening but `tools/list` times out, output `WARN:busy` / `OK:busy:reuse` and **do not terminate it** (it cannot return a response while a database is opening or the GUI is using it)
- If `tools/list` **fails continuously for more than 3 minutes** (last-healthy timestamp) and there is no `opening.lock`, treat it as a deadlock. Output `INFO:deadlock` and replace the supervisor with `-Force`. An active `idb_open` and the GUI do not use this path
- Replace the managed supervisor only when no process listens on the port, `py_eval` is missing, or the deadlock above occurs; **never terminate `ida.exe` and do not use `taskkill /T`**
- If the GUI is using 13337, output `WARN:gui_busy` and exit. Do not start another supervisor
- On success, output `OK:<tool count>` (about 66 currently). On failure, output `ERR:timeout`
- supervisor log: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log`
- The server runs in the background and does not block the conversation

**Usage:**
```
powershell -File "<skill-root>\ida-reverse\scripts\start.ps1"
```

### watchdog.ps1 / recover.ps1 / install-autostart.ps1 — Keep-alive

- `watchdog.ps1`: Probe 13337. Reuse when healthy and refresh last-healthy. Reuse when the GUI / `open.ps1` has a database lock or when last-healthy is less than 3 minutes old and the server is busy. Run `start.ps1 -Force` only when `tools/list` fails continuously for more than 3 minutes
- `recover.ps1`: Run `start.ps1 -Force` immediately. Do not kill `ida.exe`. Use this when the HTTP client marks `idapro` as error
- `install-autostart.ps1`: Register the scheduled task `reverse-skill-ida-mcp` to run at logon and every minute
- Log: `%LOCALAPPDATA%\reverse-skill\ida-mcp\watchdog.log`

### open.ps1 — Open a binary file

Path: `scripts/open.ps1`

- Call `idb_open` directly through the HTTP API and bypass MCP schema validation
- Detect the System32 path and copy the file to a temporary directory automatically
- Remove old database files with the same name automatically (`.id0`/`.id1`/`.nam`/`.til`/`.i64`)
- If the old database is locked, use a fallback. Copy it to Temp with a GUID prefix and open it without an error
- Run the open request in the background to prevent a long synchronous wait from making the script unresponsive
- Support `-TimeoutSeconds`. Return `ERR:open_timeout_xxs` after the timeout and do not hang indefinitely
- Output `INFO:opening:elapsed/timeout seconds` every 10 seconds to show that analysis is still running
- On success, output `OK:filename:session_id`. Add the `(temp copy)` marker for a fallback
- Retry automatically with a Temp copy when the operation fails

**Usage:**
```
powershell -File "<skill-root>\ida-reverse\scripts\open.ps1" -Path "C:\path\to\file.exe"
```

**Optional parameters:**
```
# Set the SessionId
powershell -File "scripts\open.ps1" -Path "file.exe" -SessionId "my_session"

# Skip automatic analysis (recommended for large files)
powershell -File "scripts\open.ps1" -Path "large.exe" -NoAutoAnalysis

# Set a timeout to avoid long waits during automatic analysis
powershell -File "scripts\open.ps1" -Path "file.exe" -TimeoutSeconds 600
```

**Output rules:**
```
# Analysis in progress (output every 10 seconds)
INFO:opening:11/600s

# Opened successfully
OK:sample.exe:abcd1234

# Opened successfully, but fell back to a Temp copy because of the lock file
OK:1234abcd-sample.exe:abcd1234 (temp copy)

# Timeout limit reached
ERR:open_timeout_600s
```

**Test notes:**
- Testing shows that `Snipaste.exe` with automatic analysis takes about `324s` to return successfully. This means "analysis takes a long time" and not "the script is deadlocked"
- Therefore, for GUI programs or more complex samples, set `-TimeoutSeconds 600` explicitly first

## Core Tool List

### Overview Analysis (First Step)
- `idapro_survey_binary(detail_level="minimal")` - Quick overview: function count, string count, segment count, entry point, and import categories (encryption, network, and file I/O)
- `idapro_list_funcs(queries)` - List functions (pagination and name filtering)
- `idapro_list_globals(queries)` - List global variables
- `idapro_entity_query(kind, filter)` - Unified query: functions/globals/imports/strings/names

### Decompilation and Disassembly
- `idapro_decompile(addr)` - Decompile to pseudocode
- `idapro_disasm(addr, max_instructions=N)` - Disassemble
- `idapro_analyze_function(addr, include_asm=false)` - Perform combined analysis (pseudocode, strings, constants, callers, callees, and blocks)
- `idapro_func_profile(queries)` - Function profile metrics

### Cross-References and Data Flow
- `idapro_xrefs_to(addrs)` - Find references to target addresses
- `idapro_xref_query(addr, direction)` - Advanced xref query (filter by direction and type)
- `idapro_callees(addrs)` - List callees
- `idapro_callgraph(roots, max_depth)` - Call graph
- `idapro_trace_data_flow(addr, direction, max_depth)` - Trace data flow (forward/backward)

### Search
- `idapro_find_regex(pattern, limit)` - Search strings with a regular expression
- `idapro_search_text(pattern)` - Search text in the disassembly listing
- `idapro_find_bytes(patterns, limit)` - Search byte patterns (supports ?? wildcards)
- `idapro_find(type, targets)` - Advanced search (immediate values, strings, and references)

### Memory and Data
- `idapro_get_bytes(addrs)` — Read raw bytes
- `idapro_get_string(addrs)` — Read strings
- `idapro_get_int(queries)` — Read integer values
- `idapro_get_global_value(queries)` — Read global variable values
- `idapro_read_struct(queries)` — Read structure field values
- `idapro_search_structs(filter)` — Search structures

### Modification Operations
- `idapro_set_comments(items)` — Add comments (synchronize disassembly and decompilation in both directions)
- `idapro_append_comments(items)` — Append comments
- `idapro_rename(batch)` — Rename in batches (functions, globals, locals, and stack variables)
- `idapro_patch_asm(items)` — Patch assembly instructions
- `idapro_patch(patches)` — Patch bytes
- `idapro_define_func(items)` — Define functions
- `idapro_undefine(items)` — Remove definitions
- `idapro_define_code(items)` — Convert bytes to code

### Type System
- `idapro_declare_type(decls)` — Declare C structures, enumerations, and unions
- `idapro_set_type(edits)` — Apply types to functions, globals, and locals
- `idapro_infer_types(addrs)` — Infer types
- `idapro_type_query(queries)` — Query declared types
- `idapro_type_inspect(queries)` — View type details

### Stack Frames
- `idapro_stack_frame(addrs)` — View stack frame variables
- `idapro_declare_stack(items)` — Declare stack variables
- `idapro_delete_stack(items)` — Delete stack variables

### Signatures
- `idapro_make_signature(addrs)` — Generate unique byte signatures for addresses
- `idapro_make_signature_for_function(addrs)` — Generate a signature for a function
- `idapro_find_xref_signatures(addrs)` — Generate signatures for code that references addresses

### Debugger (requires ?ext=dbg)
- `idapro_open_file(file_path)` — Open a file in the GUI IDA instance
- The debugger tools are hidden by default. Enable them with the URL parameter `?ext=dbg`

### Session Management (ida-pro-mcp 2.x)
- `idapro_idb_open` / HTTP `idb_open` — ⚠️ We recommend using `open.ps1` to open it
- `idapro_idb_list` / HTTP `idb_list` — List all sessions
- `idapro_idb_save` / HTTP `idb_save` — Save the database
- Most analysis tools require the `database=<session_id>` parameter. Use the session from the `open.ps1` output

### Other
- `idapro_int_convert(inputs)` — Convert number bases. **You must use this. Do not calculate the base yourself.**
- `idapro_export_funcs(addrs, format)` — Export functions (json/c_header/prototypes)
- `idapro_py_eval(code)` — Execute Python in the IDA context
- `idapro_server_health()` — Check server health
- `idapro_server_warmup()` — Warm up subsystems (string cache, Hex-Rays, and others)

## Complete Reverse Engineering Workflow

### Step 1: Start the Server

**Path A — Headless idalib (requires a valid license)**
```
powershell -File "scripts/start.ps1"
```
Output `OK:<tool count>` (about 65 currently) to show that the server is ready.

**Path B — GUI + Plugin (when the idalib license fails or when interactive analysis is required)**
```
powershell -File "scripts/start-gui.ps1" -Path "C:\target.exe"
```
Or double-click the portable `Launch-IDA-Pro.cmd` to open the sample in IDA.

After `[MCP] ... port=13337` appears in the Output window, the MCP tool is ready.

See `LOCAL-SETUP.md` for the general integration steps.

### Step 2: Open the file

Headless:
```
powershell -File "scripts/open.ps1" -Path "C:\target.exe" -TimeoutSeconds 600
```
Output `OK:filename:session_id` to show success. The suffix `(temp copy)` means that the process automatically falls back to a temporary copy.

If `ERR:idalib_license:...` appears, use path B (GUI mode). Do not retry open.ps1 repeatedly.

GUI mode: Open the sample directly in IDA. You do not need open.ps1.

### Step 3: Global overview (including the hard import-table gate)
```
idapro_survey_binary(detail_level="minimal")
```
Focus on:
- Architecture (x86/x64/ARM)
- Entry points (main/WinMain/DllMain)
- Interesting strings (URLs, paths, error messages)
- **Import categories (MUST)**: cryptographic functions / network APIs / file operations / process injection / registry. Record them as Evidence (suggested id: `E-imports`). Use `idapro_entity_query(kind="imports")` or the imports section in the survey output.
- **DLL/SYS**: List the exports and imports side by side (Evidence `E-exports`).
- **.NET**: When no traditional IAT exists, write a summary of modules, metadata, and managed references into the E-imports semantic slot as an equivalent anchor.
- **Clean import table**: Note possible dynamic loading. Validate dynamic APIs with breakpoints.
- Popular functions (functions with high xref counts are usually key logic)

**Hard gate**: Before you write the imports view or category summary (or a valid equivalent anchor) to Evidence, MUST NOT proceed to the Step 4 in-depth conclusions and MUST NOT claim that the survey is complete. If the import table is empty or the query fails, still MUST record the failure. If IAT repair fails because of packer protection, MUST record `E-iat-repair-fail` and switch to dynamic debugging to capture APIs. Do not persist with static analysis. When the user requests a repeat of the import table/IAT check, MUST repeat the named step (feasibility gate when blocked: explain and confirm; if forced, set quality=unreadable). Do not switch to unrelated steps.

### Step 4: Examine key functions in depth
```
idapro_analyze_function(addr="key_function_name")
```
Or:
```
idapro_decompile(addr="function_name")
idapro_disasm(addr="function_name", max_instructions=50)
```

### Step 5: Data flow and cross-references
```
idapro_xrefs_to(addrs="key_address/string")
idapro_callgraph(roots=["key_function"], max_depth=3)
idapro_trace_data_flow(addr="key_address", direction="backward", max_depth=5)
```

### Step 6: Record and optimize
```
idapro_set_comments(items=[{"addr": "0x140001000", "comment": "your_understanding"}])
idapro_rename(batch={"func": [{"addr": "function_address", "name": "meaningful_name"}]})
```

### Step 7: Output the report
After the analysis is complete, generate `report.md` to record the findings and steps.

## Prompt Engineering Guidelines

1. **Do not calculate number bases manually** — Use `idapro_int_convert` whenever you need to convert a number
2. **Survey first, then analyze in depth** — Check the overview first, then perform targeted analysis
3. **Keep adding comments and renaming** — Update function names and variable names during the analysis to improve the accuracy of later analysis
4. **Track cross-references** — When you find interesting data or strings, use `xrefs_to` to see who references them
5. **When you encounter obfuscated code** — First perform preprocessing such as string decryption, import hash removal, and control-flow flattening removal
6. **C++ STL code** — Identify library functions with FLIRT/Lumina first, then analyze the business logic
7. **Do not use brute force** — Derive the solution from the disassembly and use simple Python for supporting calculations
8. **When you encounter "No database bound"** — No binary file is open. Run `open.ps1` first
9. **When you encounter "Failed to open database"** — An old database file may be locked. `open.ps1` automatically falls back to a Temp copy (the output contains the `(temp copy)` marker)
10. **When opening the GUI or complex samples with automatic analysis** — Add `-TimeoutSeconds 600` by default. Do not mistake a long `INFO:opening:...` message for a hung script

---

## Routing Context

**Upstream entry**: `skills/SKILL.md` (controller), `routing.md`
**Upstream alternative**: `radare2/` (if you do not want to open IDA, you can use r2 for quick reconnaissance first)
**Downstream exits**:
- Frida dynamic verification required → `reverse-engineering/tools-dynamic.md`
- Symbolic execution/angr required → `reverse-engineering/tools-dynamic.md`
- General reverse-engineering methodology required → `reverse-engineering/SKILL.md`

**Peer module**: `radare2/` (alternative when IDA is not available)

---

## On-Demand Bootstrap

The entry script for this skill is connected to the unified bootstrap system.

### Automation Scope

| Tool | Can install automatically | Installation method | Description |
|------|-----------|---------|------|
| idalib-mcp | ✓ | pip install (from GitHub) | Automatically install when `start.ps1` is missing |
| IDA Pro itself | ✗ | Commercial software. Install manually | Set the `IDADIR` environment variable to the installation directory |

### Installation steps (verified)

```cmd
# 1. Set the IDA path (replace it with your actual IDA installation directory)
setx IDADIR "<your IDA installation directory>"

# 2. Install ida-pro-mcp from GitHub (PyPI ida-mcp is another project. Do not install the wrong one!)
pip install git+https://github.com/mrexodia/ida-pro-mcp.git

# 3. Install the IDA plugin (select Streamable HTTP + Global + all clients)
ida-pro-mcp --install

# 4. Restart IDA Pro and open the target file
# The plugin listens on 127.0.0.1:13337

# 5. Verify
ida-pro-mcp --config
```

> ⚠️ **Note**: The `ida-mcp` package on PyPI (by author jtsylve) is another project, not the one we need.
> Install `mrexodia/ida-pro-mcp` from GitHub.

### Bootstrap trigger points

- `scripts/start.ps1`: Automatically call `bootstrap-reverse.ps1` when `idalib-mcp` is missing
- MCP registration: bootstrap automatically writes `idapro` to the Claude MCP configuration

### Prerequisites

- IDA Pro is installed and the `IDADIR` environment variable is set, or the default path in the script is correct
- We recommend using `ida-pro-mcp` in IDA's built-in Python314. It is already included in the portable version.
- Common local configuration:
  - User env `IDADIR` → IDA installation directory (contains `ida.exe`)
  - Optional `~\Tools\bin\idalib-mcp.cmd` / `ida-pro-mcp.cmd` wrapper
  - Keep only `idapro` as the client MCP server name → `http://127.0.0.1:13337/mcp`


## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow instead of only reading it?
- [ ] Did I write survey/imports to Evidence (E-imports or equivalent)? Do DLL/SYS files include E-exports? Did I record E-iat-repair-fail when IAT failed?
- [ ] If the user required the import table/IAT to be redone, did I repeat the same step?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the Checklist items required by RULES?
