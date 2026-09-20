# RE Agent Workflow Gate (Static↔Dynamic)

> Source prompts: binary-re phase divisions, community RE skill (Frida/r2/Ghidra/IDA cycle), Cerberus three-part loop (static/dynamic/instrumentation)  
> Issue #65 additions: IAT repair rule, six-phase mapping, .NET/DLL/SYS equivalent paths; user instruction feasibility gate; bypass patches 6–10; anti-debugging/obfuscation recipes A–T; non-PE multi-format recipes U–AV (2026-08-12)  
> Applies to: `reverse-engineering/`, `ida-reverse/`, `radare2/`, `malware-analysis/`, and handoff to the cre role

## 0. Startup

```text
□ scope.md: offline sample path or authorized device/target
□ tool-index: actual paths for file/strings/r2/ida/frida, etc.
□ Role: cre (ops/role-map)
```

## 0.1 Transition handoff (decision delta)

Do not inject the complete case context again between phases. `scope.md` / `workitems.md` / Evidence remain authoritative; `timeline.md` carries only the transition delta:

1. At the end of a stage/turn, write only the `decision_delta` items that change later actions; write `[]` when there is no change.
2. Put unchanged route/auth/scope/network profile/tool state/hypothesis only in `carry_forward_refs`; the consumer reads them by reference and does not serialize / emit them again.
3. `decision_delta` is not the complete state; the consumer MUST first inherit the refs and then apply the delta.
4. Stop at the next-step menu only when two or more evidence-supported branches lead to different next actions; advance directly through a deterministic gate.

Example: When Triage is complete and Static is the only valid next step, the transition needs only `decision_delta: [phase=triage->static]` + `carry_forward_refs: [scope.md, evidence/E-triage.md]`.

## 0.5 User instruction feasibility gate (Issue #65)

**Principle**: Follow the user's **goal**, not the user's **step order**. Before skipping a step, state the prerequisite and ask for confirmation; perform confirmed mandatory steps and label Evidence quality honestly.

| Situation | Agent MUST |
|------|------------|
| The user wants to do X, and the current state can produce **valid** Evidence | Perform X and update Evidence |
| The user wants to do X, but a **known blocking prerequisite** exists (for example: packing is confirmed and the static IAT is unreadable) | **Do not** pretend to complete a meaningful IAT check; ① State the blocker in one sentence; ② Give the recommended order (unpack/fix the IAT first, or capture the API dynamically); ③ **Ask the user to confirm** whether to "still force a check of the current import table" or "follow the recommended order" |
| The user clearly **forces** the current step (for example, check the IAT before unpacking) | Perform it and record Evidence. MUST label `quality=unreadable` / `packed` (or an equivalent label); **Do not** conclude from this that there is "no network capability" |
| The user accepts the recommended order | Perform the prerequisite step first. Then perform X automatically or when requested again; **Do not** use the prerequisite step (such as unpacking) to **pretend** that the "import table check is complete" |

**Relation to "redo X"**: Redoing X still means redoing the named step (or its confirmed result from a valid prerequisite discussion). Do not replace it with an unrelated step. Unpacking is a **prerequisite** for the import table, not a **replacement** for the import table.

Typical conflict: The user says "do not unpack first, check the import table first" for a packed sample → the packer often changes the import directory or encrypts the descriptors, so the static table is decorative and meaningless → follow the "blocking prerequisite" row in this table. Do not unpack silently and pretend to perform the check. Do not silently provide the decorative table as a completed check.

## 1. Triage (5–15 minutes - mandatory starting point)

```text
□ Calculate the sample hash (MD5/SHA256) → unique ID
□ Identify the file type: EXE / DLL / SYS / ELF / Mach-O / .NET / scripts (bat/ps1/vba) / JS / APK, etc.
□ Non-PE/script/APK/driver specialization: see §3.4 and `references/nonpe-format-cookbook.md` (U–AV)
□ file / DIE / entropy / packer indicators (PEiD / DIE / Exeinfo, etc.)
□ Architecture: x86 / x64 / ARM; compiler-language clues (VC++ / Delphi / .NET / Go / Rust)
□ Packer-type clues: UPX / ASPack / VMProtect / Themida / unknown obfuscation
□ Use strings / rabin2 -z to find overlooked items
□ MUST identify import/export anchors (see “Import Table Hard Gate and Equivalent Paths” below); if the user jumps ahead and the sample is packed → go to §0.5 first
□ Output: E-triage (MUST include an imports or equivalent-anchor classification summary, with a quality label where applicable) + hypothesis list
```

**Phase gate (Triage → Static/Dynamic)**: Before E-triage records imports **or** a summary of valid equivalent anchors, the Agent MUST NOT enter Dynamic (unless it has recorded IAT repair failure and selected a dynamic bypass. See §1.2). It MUST NOT claim that "basic triage is complete". When parsing fails, it MUST still write the failed output to Evidence. It MUST NOT skip the step. When the user requests "redo the import table check", it MUST redo imports/the equivalent step itself (or first complete the prerequisite from the §0.5 discussion). Do not replace it with another analysis step and pretend that it is complete.

### 1.1 Import table hard gate and equivalent paths

| Sample Type | MUST Anchor (Evidence) | Description |
|----------|----------------------|------|
| Native PE/ELF/Mach-O (IAT readable) | `E-imports` / `E-triage-imports`: import classification summary | `rabin2 -i` / IDA imports / equivalent |
| DLL / SYS / shared library | **Pair** `E-imports` + `E-exports` (`rabin2 -i` + `rabin2 -E`) | Export table priority equals import table priority (external entry points) |
| .NET managed (no traditional IAT) | **Equivalent path**: dnSpy/IL/metadata/assembly references and sensitive API summary → still write to the `E-imports` or `E-triage-imports` semantic slot | **Do not** skip the hard gate because there is no IAT. Viewing with dnSpy = native "check the import table" |
| Import table parsing fails / is empty / packed and obfuscated table | Still record the failure or obfuscated-table output as Evidence and mark `quality` | Do not skip silently. Do not use an obfuscated table to support a capability denial conclusion |

**Clean import table warning (MUST remind)**: If the import table is "too clean" (only basic DLLs such as kernel32/ntdll and almost no business APIs), strongly suspect dynamic loading with `LoadLibrary` + `GetProcAddress` → note the suspicion in Evidence and **SHOULD** switch to Dynamic memory API capture. Do not claim "no network/file capability" based only on the static IAT.

**High-risk API combinations (Patch 8 · SHOULD)**: When the import table is too long, output **malicious combination clusters** first and filter out pure system basics. Examples (not exhaustive):

- High-risk cluster: `FindWindowA/W` + `WriteProcessMemory` + `CreateRemoteThread` (injection)
- High-risk cluster: `CryptEncrypt` / `CryptAcquireContext` + many `FindFirstFile` / `DeleteFile` calls (ransomware tendency)
- High-risk cluster: `InternetOpen` / `WinHttp` / `URLDownloadToFile` + persistence APIs (`RegSetValue` / `CreateService`)
- `CreateFile` / `ReadFile` alone and similar calls are usually benign noise unless they occur with the clusters above

### 1.2 Unpacking and IAT Handling (High-Risk Branch · Issue #65)

```text
Branch A: Unpacked / .NET managed
  → Go directly to §2 Static (.NET uses equivalent anchors)

Branch B: Packed / heavily obfuscated
  Step 1: Try unpacking (automatic unpacker / manually find the OEP) — perform this only with authorization and in an isolated environment
  Step 2: Try to repair the IAT
    Tools: x86 → ImportREC (or equivalent); x64 → Scylla (or equivalent). Do not persist with ImportREC on 64-bit samples.
    Case B1: Repair succeeds and parsing works → record E-imports (after repair) → §2 Static
    Case B2: ImportREC/Scylla reports an error, the sample cannot run after repair, or the IAT is all garbled (VMP/encrypted packer)
      → [IAT repair hard rule]Stop static IAT repair immediately
      → MUST record E-iat-repair-fail (command, tool, failure symptoms, decision to switch to dynamic analysis)
      → Go directly to §3 Dynamic: API breakpoints / hardware execution breakpoints / memory search to capture imports
      → This does not count as “skipping the import table”: the import-table path was attempted and Evidence was recorded
    Case B3 (Patch 6): The program crashes on double-click or causes a blue screen after unpacking and repairing the IAT (the file may perform CRC/size self-checks)
      → Stop trying to repair the file statically; record E-self-check-crash or merge it into E-iat-repair-fail
      → Switch to §3 Dynamic: set breakpoints on CreateFile / GetFileSize / hash-related APIs to locate the check bypass point
```

**IAT repair rule (MUST)**: Try automatic or semi-automatic repair first. If the repair tool reports an error or the program cannot run after repair, **stop immediately** spending time on the static import table and switch to dynamic debugging. Use API breakpoints (such as `bp CreateFile` / key network APIs) to capture imported functions at run time.

## 2. Static (Basic Static Anchors → Deep Analysis)

| Tool | When |
|------|------|
| radare2 / rabin2 | For fast function/import/string analysis (imports MUST be completed in Triage or failure must be recorded in an alternate path) |
| IDA / Ghidra (MCP or headless) | For deep analysis, cross-references, and types. Recheck import classification during the survey stage |
| jadx / dnSpy | Android / .NET |
| OLLVM documentation | Suspected control-flow flattening |

```text
□ Confirm that E-imports / E-triage already contains import-table Evidence or an equivalent anchor (if missing, add it first; do not defer it)
□ For DLL/SYS: confirm that E-exports has been recorded
□ Group sensitive APIs and cluster high-risk combinations (Patch 8)
□ Check hard-coded domain names/IPs/URLs; check whether the resource section hides a Payload
□ Locate key functions (encryption/checks/network/authorization) → write the address/symbol to Evidence
□ If one path fails → switch tools (IDA↔r2↔Ghidra)
□ Time box (Patch 9 · SHOULD by default): if static deep analysis finds no key path after about 15 minutes → force a switch to §3 Dynamic (the user/task may override the duration)
```

**Without MCP**: You can export decompilation text for analysis (based on the P4nda0s reverse-skills / IDA-NO-MCP approach). Still write the Evidence path.

## 3. Dynamic (Cross-Validation Loop)

Core concept: **Static provides clues → dynamic verification → verification stalls → return to static review** (there is no fixed single order).

### 3.0 Breakpoint Startup Sequence (Patches 7 + 10 · MUST Order)

Before starting the sample in a user-mode debugger (such as x64dbg), set breakpoints in advance using the "four-level rocket" sequence (names can vary slightly by architecture or tool, but the order does not change):

1. **TLS callback** breakpoint (it may run before the debugger reaches the EP)
2. **Entry point EP** breakpoint
3. **Sensitive API** breakpoints (such as `CreateRemoteThread` / network / file writes)
4. **Fallback**: `ExitProcess` / process exit path breakpoint (Patch 10) - if anti-debugging causes immediate exit, **do not restart at once**; dump memory immediately, write the pre-crash image path to Evidence, and use it to recover strings and data

```text
□ Frida / x64dbg / gdb / emulator: verify static assumptions
□ Set breakpoints in advance according to §3.0, then run; single-step through the stack/registers (white-box)
□ Monitor behavior: sandbox / Procmon / RegShot (black-box)
□ IAT repair failure / self-check crash sample: use hardware execution breakpoints or memory search to force API capture; use CreateFile/GetFileSize to check CRC
□ Anti-debugging/anti-Frida → reverse-engineering/anti-analysis
□ Android: generate root-detection / SSL-pinning bypass scripts as needed, **only on authorized devices**
□ Crash logs drive the next round of hooks (adaptive loop)
□ Timebox (Patch 9 · SHOULD default): If single-step tracing reaches about 200 instructions without clues of malicious behavior → force a return to static string search/change the anchor (overridable)
```

### 3.1 Sandbox / Dynamic no-behavior emergency branch (MUST)

```text
No behavior or immediate exit / infinite sleep
  → Check anti-debugging / anti-VM routines (CPUID, high-precision timing, sandbox traits, etc.)
  → Try bypassing with hardware breakpoints, patching detection points, or switching to a physical machine/higher-fidelity environment
  → Record “no behavior + suspected anti-VM” in Evidence; do not write “the sample is harmless” without conditions
```

### 3.2 Time-box strategy (Patch 9 · SHOULD)

| Stage | Default threshold (can be overridden by the user or task) | Action |
|------|------------------------------|------|
| Deep Static analysis has no critical path | ~15 minutes | Switch to Dynamic |
| Dynamic single-stepping makes no progress | ~200 instructions | Return to Static strings/cross-references and re-anchor |
| Any path fails repeatedly | Record Evidence, then change tools or use a bypass | Do not loop on the same failed method |


### 3.3 Anti-debugging / obfuscation bypass quick reference (Issue #65 Patch A–T · high frequency)

See `reverse-engineering/anti-analysis.md` Agent response playbook A–T for the complete index and action details. This section lists only **P0 required checks + common transitions**. Use an **authorized isolated lab** by default; patching/changing flags is not an unauthorized production action.

| Trigger | Preferred action (summary) | Evidence |
|----------|------------------|----------|
| `cpuid` followed by jz/jnz (A) | lab: change flags or patch to follow the real branch; record the detection point address | `E-anti-debug-cpuid` |
| `rdtsc` + sub/cmp (B) | bp rdtsc or hook the time source; do not treat unlimited looping or a sandbox timeout as "harmless" | `E-anti-debug-rdtsc` |
| PEB BeingDebugged / NtGlobalFlag (K) | Use ScyllaHide or edit the PEB manually; patch the conditional jump | `E-anti-debug-peb` |
| `NtQueryInformationProcess` DebugPort/Flags/Object (P) | Use ScyllaHide / hook the return value; record the class parameter | `E-anti-debug-ntqip` |
| Very few imports but rich behavior → API hashing (N) | bp GetProcAddress; resolve the hash references back to the IDA injection ID | `E-api-hash` |
| No strings but network/file behavior exists → string encryption (I) | Find the decode routine xref; dump after decryption and map it back | `E-string-decrypt` |
| Has a signature but the source is suspicious (F) | SigCheck: valid/revoked/time; **do not lower** the threat level when invalid | `E-sig-forge` |
| Standard strings has no IOC → try wide characters (T) | `strings -el` / UTF-16LE; Alt+A unicode | `E-wide-strings` |
| Debugger name strings / Toolhelp scan (C) | bp the CreateToolhelp32Snapshot chain | `E-anti-debug-procscan` |
| AddVectoredExceptionHandler + deliberate exception (D) | bp VEH registration; analyze the handler | `E-anti-debug-veh` |
| int3 / DR0–DR7 (M) | patch int3; use software breakpoints or ScyllaHide to hide hardware BPs | `E-anti-debug-bp` |
| Multiple PE headers/overlapping sections (G) | Map the sections based on their actual layout + entropy; do not trust section names | `E-pe-anomaly` |
| File end > section total Overlay (J) | Extract overlay; file/entropy; find loading offset xref | `E-overlay` |
| .rsrc unusually large/high-entropy RT_RCDATA (Q) | Extract resources; FindResource chain + decrypt dump | `E-rsrc-payload` |
| DLL loads only at runtime (R) | Check Delay Import; bp delay-load helper | `E-delay-import` |
| while+switch star-shaped CFG (H) | **See** `ollvm-deobfuscation.md`; use the dynamic path if the plugin fails | `E-cff` |
| Constant-true/constant-false branches (S) | **See** ollvm / symbolic execution; treat dynamic results as authoritative | `E-opaque-pred` |
| `/proc/self/status` TracerPid (L) | **Linux/ELF**; hook or patch; the Windows main path is not required | `E-anti-debug-tracerpid` |

**Constraint**: Record Evidence even when bypass fails; do not write "the sample is harmless" when anti-debugging triggers an exit. See the anti-analysis cookbook section for complete A–T and P2 (E compile time, O junk instructions).

### 3.4 Non-PE / multi-format bypass (Issue #65 patch U–AV · routing)

Complete index: `reverse-engineering/references/nonpe-format-cookbook.md`. This section lists only **type → entry**; action details are in the cookbook / corresponding skill.

| Type | Jump | P0 Evidence anchor (example) |
|------|------|---------------------------|
| BAT/CMD | cookbook §1 + malware | `E-batch-deobf` |
| PowerShell | cookbook §2 + malware | `E-ps-decode-layer-N` |
| VBA macros | cookbook §3 + malware | `E-vba-pcode` |
| Strongly obfuscated JS / JSVMP | **js-reverse** + cookbook §4 | `E-js-vmp` / `E-js-deobf` |
| SYS drivers | kernel-driver-reverse + cookbook §5 | `E-driver-irp-handlers` / `E-driver-ioctl` |
| DLL focus | cookbook §6 (AM≡A–T **R**) | `E-dll-tls-dllmain` / `E-exports` |
| Android rooted devices/hidden icons | **apk-reverse** + cookbook §7–8 | `E-android-wiper-*` / `E-android-hidden-icon-*` |

**Constraint**: Do not create a separate "six-stage non-PE"; use the division of work with §3.3 A–T (PE anti-debugging vs multi-format). Use an authorized lab; describe rooted devices/BYOVD/reflection as detection and forensics. 


## 4. Synthesis (IOC / attack chain / report)

### Decision quality overlay (Issue #77)

Before closing Synthesis, apply [analysis-decision-framework.md](../../ops/analysis-decision-framework.md) **P0 checklist**: R41 grounded claims, R4* validated sufficiency, R1 confidence->dynamic, R2 hypothesis exit, R43 deadlock replan (under feasibility gate), R8/R23 no default malice/IOC. Multi-module -> R50; anti-analysis effort -> R51 + A-T cookbook.

Blindspots (Rust/Go/VMP/injection/OLE/PDF/agent-meta): [analysis-blindspot-cookbook.md](../../ops/analysis-blindspot-cookbook.md) R52-R81 — detection-oriented; not a parallel master flow.



```text
□ Finding: algorithm/check logic/exploitable point / behavior conclusion
□ Path: attach E-* to the callflow or solve steps
□ IOC: network fingerprint + host fingerprint (list if available; otherwise n/a + reason)
□ Report docs-generator (select the malware/apt/null/vuln overlay by task) + optional diagram
□ Optional: formalize as YARA / Snort·Suricata rules
□ Redact the field-journal
```

## 5. Six-stage practical mapping (Issue #65 mind map → this file)

| Practical stage | Section in this file | Hard gate / strict rule |
|----------|------------|-------------|
| 1 Rapid initial triage | §0–§1 Triage | Hash, architecture, file type, check packer; imports/equivalent anchors; §0.5 instruction gate |
| 2 Unpacking and IAT | §1.2 | IAT strict rule; failure/self-check crash → Evidence → Dynamic |
| 3 Basic static anchors | §2 Static | High-risk API combinations; SHOULD use a time box |
| 4 Deep cross-validation | §3 Dynamic | Four-level breakpoint sequence; no-behavior contingency; time box; §3.3 A–T; §3.4 U–AV type routing |
| 5 Extract IoC and attack chain | §4 Synthesis | IOC + Kill Chain / Path |
| 6 Archive and rule conversion | §4 + docs-generator / YARA | Structured report; rules optional |

## 6. Difference from heap RE skill plugins

- This package uses **stage gates + tool-index** and does not enable Hex-Rays **unsafe fully automated execution** plugins by default  
- Dynamic instrumentation uses **offline/lab** network_profile by default  
- IAT/import table: **attempt + record** takes priority over endless static analysis or silent skipping  
- User instructions: **target first + prerequisite agreement**. Do not use irrelevant steps as a substitute for the requested steps