---
name: binary-diff
description: |
  Cross-version symbol migration and binary diff. Use this when you have symbols or reverse-engineering results from an old version and need to migrate them quickly to a new version.
  Applicable scenarios: derive missing kernel PDB data from old-version symbols, migrate function names in batches after a program update, and quickly locate new offsets after an application update.
  Core method: Use an LLM for structured difference comparison with programmatic input and output. The cost is very low (about 1 yuan for 200 functions).
  Trigger keywords: symbol migration, bindiff, cross-version, missing PDB, function offset migration, symbol migration, binary diff, version comparison.
---

# Cross-Version Symbol Migration (Binary Diff)

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm that this skill operation is an authorized routine operation
2. `NOW`: Confirm whether the current task is within this skill's scope
3. `NEXT`: Read `../tool-index.md` and verify tool availability and actual paths
4. `NEXT`: Call bootstrap when a tool is missing. Do not guess the path
5. `ACT`: Enter the first step of the "Workflow" and execute it. Do not stop at the confirmation state

## Scope

Use this skill when the task matches one of the following scenarios:

1. **Missing PDB data for a kernel or driver** — You have symbols for an old version of ntoskrnl.exe, Microsoft has removed the new PDB, and you need to derive addresses for non-exported functions in the new version from the old symbols
2. **Symbol migration after a program update** — You reverse engineered a program before, the program was updated, and you do not want to reverse engineer it again. Migrate the old results in batches
3. **Protection mechanism update** — You have complete reverse-engineering results for the old version and need to quickly locate the new offset of the same function in the new version
4. **Any binary comparison scenario with "old-version symbols + no symbols for the new version"**

### Division of work with other skills

| Scenario | What to use |
|------|--------|
| Reverse engineer a binary from zero | `ida-reverse/` or `radare2/` |
| Migrate old-version results to a new version | **This skill** |
| Compare two completely different binaries | BinDiff / Diaphora (traditional tools) |

### Core advantages

Compared with traditional methods:

| Plan | Cost for 200 functions | Time | Accuracy |
|------|--------------|------|--------|
| Open two IDA windows and compare manually | Free but time-consuming | Several hours | High |
| BinDiff automatic matching | Free | Fast | Medium (fails when structural changes are large) |
| Give everything to the Agent (CC/Codex) | 50-100 yuan | Slow | High |
| **This skill (LLM batch comparison)** | **~1 yuan** | **~10 seconds/function** | **High** |

## Core Principle

```text
Old version function (signed)          Same function in new version (unsigned)
    ↓                              ↓
Export disassembly + pseudocode          Export disassembly + pseudocode
    ↓                              ↓
    └──────── LLM structural comparison ────────┘
                    ↓
         Output YAML (symbol mapping table)
                    ↓
         Parse programmatically → apply in batches to the new IDB
```

Key points:
- The prompt uses a fixed template and is populated programmatically
- The input and output formats are fixed and are parsed programmatically
- The LLM only needs to compare two code segments and identify their correspondence
- The time and token costs are very low

## Prompt Template

### Standard Comparison Prompt

```text
I have disassembly outputs and procedure code of the same function.

This is the function for reference:

**Disassembly for Reference**
```c
{disasm_for_reference}
```

**Procedure code for Reference**
```c
{procedure_for_reference}
```

This is the function you need to reverse-engineering:

**Disassembly to reverse-engineering**
```c
{disasm_code}
```

**Procedure code to reverse-engineering**
```c
{procedure}
```

What you need to do is to collect all references to "{symbol_name_list}" in the function you need to reverse-engineering and output those references as YAML.

Example:
```yaml
found_vcall: # This is for indirect call to virtual function or virtual function pointer fetching.
  - insn_va: '0x180777700' # Always be the instruction with displacement offset
    insn_disasm: call [rax+68h] # Always be the instruction with displacement offset
    vfunc_offset: '0x68'
    func_name: ILoopMode_OnLoopActivate
  - insn_va: '0x180777778' # Always be the instruction with displacement offset
    insn_disasm: mov rax, [rax+80h] # Always be the instruction with displacement offset
    vfunc_offset: '0x80'
    func_name: INetworkMessages_GetNetworkGroupCount

found_call: # This is for direct call to non-virtual regular function.
  - insn_va: '0x180888800'
    insn_disasm: call sub_180999900
    func_name: CLoopMode_RegisterEventMapInternal
  - insn_va: '0x180888880'
    insn_disasm: call sub_180555500
    func_name: CLoopMode_SetSystemState

found_funcptr: # This is for non-virtual regular function pointer.
  - insn_va: '0x180666600' # Must load/reference the function pointer target address
    insn_disasm: lea rdx, sub_15BC910 # Must load/reference the function pointer target address
    funcptr_name: CLoopMode_OnClientPollNetworking

found_gv: # This is for reference to global variable.
  - insn_va: '0x180444400'
    insn_disasm: mov rcx, cs:qword_180666600 # Must load/reference the global variable
    gv_name: g_pNetworkMessages
  - insn_va: '0x180333300'
    insn_disasm: lea rax, unk_180222200 # Must load/reference the global variable
    gv_name: s_EventManager

found_struct_offset: # This is for reference to struct offset. NOTE THAT virtual function pointer should not be here! virtual function pointer should ALWAYS be in found_vcall !
  - insn_va: '0x1801BA12A' # Always be the instruction with displacement offset
    insn_disasm: mov rcx, [r14+58h] # Always be the instruction with displacement offset
    offset: '0x58'
    size: 8
    struct_name: CResourceService
    member_name: m_pEntitySystem
```

If nothing found, output an empty YAML. DO NOT output anything other than the desired YAML. DO NOT collect unrelated symbols.
```

### Variable Description

| Variable | Source | Description |
|------|------|------|
| `{disasm_for_reference}` | Old-version IDA export | Disassembly with symbols |
| `{procedure_for_reference}` | Old-version IDA export | Pseudocode with symbols |
| `{disasm_code}` | New-version IDA export | Disassembly without symbols |
| `{procedure}` | New-version IDA export | Pseudocode without symbols |
| `{symbol_name_list}` | Extracted from the old version | List of symbols to locate in the new version |

## Workflow

### Complete Process

```text
Step 1: Prepare data
  - Load the old binary into IDA (with PDB/symbols)
  - Load the new binary into IDA (without symbols)
  - Find identical anchor functions in both versions (exported functions, string references, etc.)

Step 2: Export in batches
  - Export from the old version: the anchor functions' disassembly + pseudocode (with symbol names)
  - Export from the new version: the same anchor functions' disassembly + pseudocode (without symbol names)

Step 3: LLM comparison
  - Fill the data into the prompt template
  - Call the LLM API (recommended: deepseek for large volumes at low cost; switch to gpt for very large functions)
  - Parse the returned YAML

Step 4: Apply the results
  - Apply the symbol mappings in the YAML to the new IDB in batches
  - Rename in batches with idapro_rename or an IDAPython script

Step 5: Iterate
  - Functions migrated in the first round become new anchors
  - Enter these functions and continue comparing internal calls
  - Repeat until all target functions are covered
```

### Anchor Selection Strategy

| Anchor Type | Reliability | Description |
|---------|--------|------|
| Exported function | Highest | Name stays the same, address may change |
| String reference | High | String content stays the same, reference location may change |
| Constant/magic number | Medium | Feature value stays the same |
| Code pattern | Medium | Function structure is similar, but all addresses change |

### Batch Processing Recommendations

- Compare 1 function at a time to avoid context overflow
- Use deepseek for medium functions (<200 lines)
- Use gpt-4o or claude for very large functions (>500 lines)
- Use concurrent calls to increase speed (10-20 concurrent calls)
- Cache results to avoid duplicate calls

## Output Format

### 5 YAML Output Symbol Types

| Type | Meaning | Key fields |
|------|------|---------|
| `found_vcall` | Virtual function call (indirect call) | `vfunc_offset`, `func_name` |
| `found_call` | Direct function call | `insn_va`, `func_name` |
| `found_funcptr` | Function pointer reference | `insn_va`, `funcptr_name` |
| `found_gv` | Global variable reference | `insn_va`, `gv_name` |
| `found_struct_offset` | Structure offset reference | `offset`, `struct_name`, `member_name` |

### Actions After Parsing

```text
found_call → idapro_rename(addr=call_target, name=func_name)
found_vcall → idapro_set_comments(addr=insn_va, comment="vcall: {func_name} @ +{offset}")
found_funcptr → idapro_rename(addr=funcptr_target, name=funcptr_name)
found_gv → idapro_rename(addr=gv_addr, name=gv_name)
found_struct_offset → idapro_set_comments(addr=insn_va, comment="{struct_name}.{member_name}")
```

## Typical Scenario Examples

### Scenario 1: ntoskrnl.exe Has No PDB

```text
Existing: ntoskrnl.exe 10.0.26100.2000 + complete PDB
Target: ntoskrnl.exe 10.0.26100.2605 (PDB removed)
Requirement: locate the new address of PspSetCreateProcessNotifyRoutine

Steps:
1. Load both versions into IDA
2. Find the exported function PsSetCreateProcessNotifyRoutine (present in both versions)
3. In the old version, it calls PspSetCreateProcessNotifyRoutine (with symbols)
4. In the new version, it calls sub_140822108 (without symbols)
5. The LLM immediately recognizes: sub_140822108 = PspSetCreateProcessNotifyRoutine
6. Apply in batches
```

### Scenario 2: Migration After Application Update

```text
Existing: complete reverse-engineering results for target.exe v1.0 (200+ functions named)
Target: target.exe v1.1 (all symbols lost)
Requirement: migrate 200 function names in batches

Steps:
1. Export the disassembly and pseudocode for all named functions from the old version
2. Find corresponding anchors in the new version through exported functions and strings
3. Call the LLM in batches for comparison
4. Parse YAML and batch rename
5. Iterate deeper
```

## LLM Selection Recommendations

| Model | Suitable scenario | Cost | Speed |
|------|---------|------|------|
| DeepSeek V3 | Small functions (<200 lines), batch processing | Very low | Fast |
| GPT-4o | Very large functions, complex control flow | Medium | Fast |
| Claude Sonnet | Medium to large functions, require reasoning | Medium | Fast |
| Claude Opus | Highly complex functions, require deep understanding | High | Slow |

Recommended strategy: Use DeepSeek by default. Automatically upgrade when the context limit is exceeded or results are inaccurate.

## Notes

- **Do not send the entire binary to the LLM** - Compare one function at a time
- **Anchors must be reliable** - If the anchor is wrong, all later work is wasted
- **Manually sample-check the results** - The LLM is not 100% accurate. Verify critical symbols
- **Cache intermediate results** - Avoid repeated calls and wasted tokens
- **Note the context limit** - Very large functions (>1000 lines of disassembly) need to be split or processed with a large-context model

---

## On-Demand Bootstrap

### Tool Dependencies

| Tool | Use | Can install automatically |
|------|------|-----------|
| IDA Pro | Export disassembly/pseudocode | ✗ (commercial software) |
| Python | Run scripts and call APIs | ✓ |
| PyYAML | Parse YAML returned by the LLM | ✓ (pip install pyyaml) |
| LLM API | Perform comparison | API key required |

### Description

The core of this skill does not depend on installing heavy tools. It mainly depends on:
- IDA Pro is already available (managed with `ida-reverse/` skill)
- Python + requests/httpx (call the API)
- An LLM API endpoint

---

## Routing Context

**Upstream Entry**: `skills/SKILL.md` (main control), `routing.md`
**Trigger Conditions**: An old version of symbols or reverse engineering results requires migration to a new version
**Downstream Exit**:
- Open the binary first → `ida-reverse/`
- Perform reconnaissance to confirm version differences quickly → `radare2/`

**Related Modules at the Same Level**: `ida-reverse/` (IDA handles both data export and symbol application)


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow instead of only reading it?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence such as commands, scripts, screenshots, or reports?
- [ ] Did I complete and write back the Checklist items required by RULES?
