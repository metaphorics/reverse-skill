# OLLVM Deobfuscation / Obfuscator-LLVM Deobfuscation

> OLLVM decryption workflow for APK .so files, ELF binaries, and control-flow flattening scenarios.
> Tool and variant information is based on a survey of active community projects in 2026, not training memory.
> Applies to Android NDK protection, CTF reverse engineering, packed .so analysis, and commercial obfuscator countermeasures.

---

## 0. Quick decision: Which tool should I use?

Based on your environment and your assessment of the target obfuscation type, select the matching option:

| Your situation | First choice | Alternative | Description |
|---------|---------|------|------|
| You have IDA Pro 7.5-7.7 + Hex-Rays and want one-click deflattening | **obpo-plugin** | d810-ng | obpo uses microcode + data flow + hybrid execution and gives the best results, but it is a cloud plugin (requires a network connection, core is closed source) |
| You have IDA Pro (any recent version) and want an all-in-one local deobfuscator | **d810-ng** | Original D-810 | Local, open source, integrates Z3, and supports multiple OLLVM/Tigress/Hodur/Approov variants |
| You have Binary Ninja | **ollvm-breaker** | — | Designed for Android .so work (such as libvdog protection samples) |
| You have neither IDA nor BN, use scripts only, and target x86/x64 | **ollvm-unflattener** (Miasm) | angr deflat | Uses Miasm symbolic execution and processes multiple layers with BFS |
| You have neither IDA nor BN, use scripts only, and target x86/x64 | **ollvm-unflattener** (Miasm) | angr deflat | Uses Miasm symbolic execution and processes multiple layers with BFS |
| You need pure Python symbolic execution for a CTF scenario | **angr** Deobfuscator | Triton | Does not depend on a GUI and supports scripting |
| The target is an ARM64 .so and you do not have IDA | **deollvm** (Unicorn) | angr | ARM64 deflat based on Unicorn |
| You encounter BR obfuscation (indirect branches) | **DeObfBR** | Set the data segment to read-only | BR obfuscation in the Goron/Arkari style can be countered simply by setting the data segment to read-only |
| You encounter Tigress obfuscation | d810-ng `UnflattenerSwitchCase`/`UnflattenerTigressIndirect` | — | d810-ng includes a Tigress-specific unflattener |

> **Key recommendation:** Use **d810-ng** first (local, actively maintained, and supports many variants). Use **obpo-plugin** when a cloud service is available for the best results. If both fail, use **angr/Miasm** symbolic execution for custom processing.

---

## 1. Modern OLLVM variant ecosystem (2026 community survey)

OLLVM is no longer just the original 2017 repository. The following obfuscator branches are active now. **Before decryption, identify the target variant** because the countermeasures differ greatly between variants:

### 1.1 Obfuscator branch lineage

| Variant | Base LLVM | New features compared with original OLLVM | Countermeasure points |
|------|----------|----------------------|---------|
| **Obfuscator** (original) | 3.3~4.0 | sub + bcf + fla (three basic passes) | Standard tools can handle it |
| **Hikari** | 6~8 | Anti Class Dump, Function Call Obfuscate, Function Wrapper, Indirect Branching, Split BB, String Encryption | First decrypt strings and repair indirect jumps |
| **Hikari-LLVM15** | 15~19 | + Anti Debugging, Anti Hook, Constant Encryption | Now closed source. Constant Encryption increases the difficulty of static analysis |
| **goron** | 7~10 | Indirect Branch/Call/GlobalVariable | ⚠️ Goron-style indirect obfuscation can be defeated by simply setting the data segment to read-only |
| **Arkari** (komimoe/Hikari) | 14~latest | Based on goron and actively maintained | Like goron, setting the data segment to read-only provides partial resistance |
| **Pluto** | 14 | MBA Obfuscation, Random CF, Split BB, **Trap Angr** (designed to break angr) | ⚠️ The Trap Angr pass makes angr symbolic execution fail. Use another tool or bypass the trap |
| **Polaris** (formerly Pluto) | 16 | Alias Access, Indirect Branch/Call, String Encryption, Merge Function, Linear MBA, Dirty Bytes Insertion, Function Splitting, Junk Insertion | Combines Hikari and Pluto. It is the most difficult case and requires layered handling |
| **O-MVLL** | open-obfuscator | Python-driven pass manager; Anti Hooking, Arithmetic(MBA), BB Duplicate, CF Breaking, Function Outline, Indirect Branch/Call, Opaque Constants | Commonly used for modern Android hardening. Python configuration is easy to customize |
| **amice** (Rust) | Rust implementation | Full set + VM Flatten, Instruction Virtualization, Delayed Offset Loading, Parameter Aggregation | Includes VM virtualization. Restore the VM handler instead of using simple deflat |
| **VMP family** (SmallVmp/VMPilot/xVMP/VMPacker) | — | Instruction virtualization | **Not in the OLLVM category**. It requires VM reverse engineering. See VM-specific tools |

### 1.2 Key indicators

- **Trap Angr** (Pluto/Polaris): If angr crashes or the path count explodes during execution, suspect that the target uses the Trap Angr pass → switch to d810-ng or the Unicorn dynamic method
- **Goron/Arkari indirect jumps**: If the dispatcher uses an indirect jump (BR x8 rather than switch), first try to set the related data segment to read-only. The indirect jump targets often then become statically solvable
- **Constant Encryption** (Hikari-LLVM15/Polaris/O-MVLL): The constants are decrypted at run time, so static analysis alone cannot show their real values → use Unicorn to dynamically execute the decryption stub
- **VM Flatten** (amice): The control flow becomes a VM dispatch loop. **Do not treat it as ordinary fla**. First identify the VM handler table

---

## 2. OLLVM Obfuscation Type Detection

OLLVM's three core pass identification features:

### 2.1 Control Flow Flattening (`fla`)

**IDA View Features:**
- The function entry first jumps to a single dispatcher block
- The main logic is split into multiple basic blocks. Each block jumps back to the dispatcher at its end
- The dispatcher uses a **state variable** to select the next block to execute
- A large `switch` structure has no logical relation between cases

```
Original:             OLLVM flattened:
  block_A               entry -> dispatcher
  block_B                 ↓
  block_C              state_machine:
                         switch(state):
                           0 → block_A
                           1 → block_B
                           2 → block_C
```

**Variant forms identified by d810-ng:**
- O-LLVM: switch / if-chain + state variable
- Tigress: `m_jtbl` (switch-case) or `m_ijmp` (indirect jump, requires `goto_table_info` configuration)
- Hodur (PlugX): Nested `while(1)` state machine with `jnz state, #CONST`, **with no switch dispatcher**
- Approov: `while(v8 != C)`, status constants are concentrated in `0xF6000–0xF6FFF`

### 2.2 Bogus Control Flow (Bogus Control Flow / `bcf`)

- Insert an **unreachable bogus branch** between each real branch
- Protect bogus branches with an **opaque predicate**. The condition is always true or always false, but static analysis cannot prove it directly.
- Add large amounts of dead code to increase function size

```c
// Classic opaque predicate: x(x+1) is always even, but the compiler cannot prove it
if (x * (x + 1) % 2 == 0) {
    // Actual logic
} else {
    // Unreachable dead code
}
```

### 2.3 Instruction Substitution (Instruction Substitution / `sub`) → MBA

- Replace simple arithmetic or bitwise operations with equivalent complex expressions (MBA, Mixed Boolean-Arithmetic)

```
a + b  →  (a ^ b) + 2*(a & b)
a ^ b  →  (a | b) - (a & b)
a - b  →  a + (~b) + 1
```

### 2.4 Quick Classification Table

| Obfuscation type | IDA features | Main countermeasures |
|---------|---------|------------|
| fla (flattening) | Huge switch + dispatcher | obpo / d810-ng / deflat |
| bcf (bogus control flow) | Unreachable branches + dead code | d810-ng opaque predicate removal / symbolic execution |
| sub/MBA | Complex arithmetic expressions | d810-ng MBA simplifier / SiMBA (Z3) |
| fla + bcf + sub | All of them, with extreme expansion | **Layered deobfuscation (bcf first, then fla, then sub)** |

---

## 3. Detailed Review of Mainstream Tools (Active Community Projects)

### 3.1 obpo-plugin — Strongest results, cloud plugin

> [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) · 629⭐ · Active in 2026-06

A Hex-Rays **microcode** pseudocode optimizer. It uses **data-flow tracking + program slicing + concolic execution** to reconstruct flattened control flow. The community considers its results among the strongest.

**Key features:**
- Operates at the microcode layer and directly optimizes decompiler output. It does not modify ASM.
- Supports IDA 7.5.0 / 7.6.0 / 7.7.0 + Hex-Rays
- Architectures: ARM, ARM64, x86, x86_64, PowerPC, PowerPC64, MIPS (7.6/7.5)
- **Cloud plugin**: The target function binary is uploaded to obpo-server for processing. The core is closed source, and the plugin is free and open source.
- The server is maintained at the owner's expense. The timeout is 600s. **Do not use multiple threads or make malicious calls.**

**Installation and use:**
```text
1. Download obpo_plugin.py and the obpoplugin directory
2. Copy them to the IDA plugins path
3. Restart IDA and open the target binary
4. Locate the dispatcher block in the CFG. It usually looks like this:
   [See the screenshot at assets/dispatchblock.png in the repository]
5. Right-click → OBPO → Mark and process function
6. Refresh the decompiler after processing finishes
7. Continue marking new dispatcher blocks as the decompilation changes (iterate to process nested fla)
```

**Applicable scenarios and limits:**
- ✅ Standard and nested fla, good results
- ⚠️ Requires network access. Use caution with sensitive samples (unreleased internal vulnerabilities, commercial secrets) because the binary uploads
- ⚠️ The server may go down. It depends on author maintenance
- ❌ Cannot solve all obfuscation (the author states this explicitly)

### 3.2 d810-ng — Preferred local all-in-one option

> [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) · 223⭐ · Updated 2026-06-26

Modern maintained and refactored version of D-810 (Next Generation). Runs locally, is open source, and integrates the **Z3 SMT** solver. It has the broadest variant coverage.

**Core capabilities (organized from the d810-ng README):**

*Instruction-level optimization:*
| Category | Description |
|------|------|
| MBA simplification | `(a+b)-2*(a&b) => a^b`, Z3-verified DSL rules |
| Hacker's Delight | Bit-operation equivalences (from the book Hacker's Delight) |
| O-LLVM patterns | Dedicated MBA patterns for Obfuscator-LLVM |
| Constant folding | 22 constant simplification rules |
| Predicate simplification | Opaque predicate removal (setz/setnz/lnot/smod) |
| Z3 rules | Use SMT solving when template matching fails |
| Hodur-specific | MBA patterns for PlugX (Hodur) malware |

*Control-flow Unflattener (by target obfuscation type):*
| Unflattener | Target | Description |
|------------|------|------|
| `Unflattener` | O-LLVM | Standard switch/if-chain + state variable |
| `UnflattenerSwitchCase` | Tigress | Tigress switch-case dispatch (`m_jtbl`) |
| `UnflattenerTigressIndirect` | Tigress | Tigress indirect jumps (`m_ijmp`), requires `goto_table_info` configuration |
| `HodurUnflattener` | Hodur (PlugX) | Nested `while(1)` + `jnz state, #CONST`, no switch |
| `BadWhileLoop` | Approov | `while(v8 != C)`, state constants at 0xF6000–0xF6FFF |
| `UnflattenerFakeJump` | General | Remove always-true and always-false conditional jumps |
| `SingleIterationLoopUnflattener` | Residual | Clean up single-iteration loops with `INIT == CHECK` and `UPDATE != CHECK` |
| `UnflattenControlFlowRule` (experimental) | General | CFG unflattener based on path emulation |

**Installation and Use:**
```text
1. clone d810-ng
2. Install the dependencies, including Z3
3. Copy them to the IDA plugins directory
4. Press Ctrl-Shift-D in IDA to load the plugin
5. Select the rule sets to apply in the GUI
6. Apply them to the target function
```

**Why choose d810-ng instead of the original D-810:**
- The original D-810 receives less maintenance
- d810-ng has CI tests, refactored code, and new Tigress/Hodur/Approov-specific unflatteners
- It integrates Z3 and falls back to SMT solving when template matching fails, with a higher success rate

### 3.3 ollvm-unflattener — Miasm symbolic execution, script only

> [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) · 265⭐ · Active in 2026-06

Based on the **Miasm** symbolic execution engine. It does not depend on IDA or BN and uses only a Python command line.

**Features:**
- Use Miasm symbolic execution to recover the original control flow. This differs from the purely static method of MODeflattener.
- **BFS multi-level processing**: Automatically follow calls from the target function and recursively deobfuscate
- Supports Windows/Linux x86/x64
- Outputs a new deobfuscated binary

**Installation and Use:**
```bash
git clone https://github.com/cdong1012/ollvm-unflattener.git
cd ollvm-unflattener
pip install -r requirements.txt   # miasm, graphviz, keystone-engine

# Basic usage
python unflattener -i <input.bin> -o <output.bin> -t <function_addr> -a
# -a: Automatically follow calls for multi-level processing
```

**Applicable:** No IDA, x86/x64 target, and a need for batch script processing.

### 3.4 ollvm-breaker — Binary Ninja in Practice

> [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) · 441⭐

Use **Binary Ninja** to deflatten. The repository includes the Android protection sample `libvdog.so` as a test case. It has fixed the JNI_OnLoad, crazy::GetPackageName, prevent_attach_one, and other functions.

**Applicable:** Binary Ninja users and Android .so work.

### 3.5 deollvm — ARM64 Unicorn

> [GeT1t/deollvm](https://github.com/GeT1t/deollvm) · 34⭐ · 2026-04

Based on **Unicorn**, this tool deflattens ARM64 OLLVM. It is an alternative for processing ARM64 .so files without IDA.

### 3.6 DeObfBR — BR obfuscation focus

> [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) · 96⭐ · 2026-06-25

Remove **BR obfuscation** (indirect branch obfuscation, Goron/Arkari style).

**⚠️ Simple countermeasure (from awesome-ollvm):** Goron/Arkari-style indirect-related obfuscation can be countered simply by **setting the data segment to read-only**. Indirect jump targets often depend on writable data segments at run time. After you set the segment to read-only, you can solve them statically.

### 3.7 angr - General-Purpose Framework for Symbolic Execution

```python
import angr

proj = angr.Project("target.so", auto_load_libs=False)
cfg = proj.analyses.CFGFast()
func = proj.kb.functions[0x12345]

# Built-in Deobfuscator
deob = proj.analyses.Deobfuscator(func=func)
deob.normalize()
```

**⚠️ Pluto/Polaris Trap Angr pass:** These two variants add traps to disrupt angr symbolic execution. If angr shows path explosion or errors, suspect that the target uses Trap Angr -> switch to d810-ng or the Unicorn dynamic method.

---

## 4. Complete Deobfuscation Workflow (by Scenario)

### 4.1 General Decision Tree

```
Target binary
  ↓
1. Identify the OLLVM variant (see clues in Section 1.2)
  ├── Original OLLVM / Hikari / O-MVLL  → standard fla/bcf/sub
  ├── Pluto / Polaris                → Watch for Trap Angr; avoid angr
  ├── Goron / Arkari                 → Try read-only data segments first, then handle BR
  ├── Tigress                        → d810-ng Tigress unflattener
  ├── Hodur (PlugX)                  → d810-ng HodurUnflattener
  └── amice (including VM)           → Not just fla; restore the VM handler
  ↓
2. Choose tools (see the decision table in Section 0)
  ├── IDA + network access + non-sensitive sample → obpo-plugin
  ├── IDA + local                    → d810-ng
  ├── Binary Ninja                   → ollvm-breaker
  ├── No GUI + x86/x64               → ollvm-unflattener (Miasm)
  ├── No GUI + ARM64                 → deollvm (Unicorn) / angr
  └── Pure symbolic execution / CTF  → angr
  ↓
3. Remove obfuscation in layers (the order matters)
  a) First remove opaque predicates (bcf)   → d810-ng opaque predicate removal
  b) Then remove control-flow flattening (fla) → unflattener
  c) Finally simplify MBA (sub)       → d810-ng MBA simplifier / SiMBA
  ↓
4. Verify
  ├── Did the function size decrease significantly?
  ├── Did the CFG change from a star/radial shape to a chain/tree shape?
  └── Does a Frida hook verify that the key function logic is correct?
```

### 4.2 Dedicated Deobfuscation for Android NDK .so Files

Android NDK-compiled .so files protected by OLLVM are the most common case in APK reverse engineering.

**Step 1 - Extract the .so file:**
```bash
adb pull /data/app/~~/lib/arm64/libnative.so
# Or extract directly from the APK: unzip target.apk -d out/ ; find out -name "*.so"
```

**Step 2 - Identify OLLVM and Its Variants:**
```bash
readelf -a libnative.so | grep -E "Size|text"   # .text is unusually large but has few functions → likely OLLVM
# Open it in IDA and inspect function features:
#   Huge switch → fla
#   Unreachable branches → bcf
#   Complex arithmetic → sub/MBA
#   Indirect branch BR x8 → Goron/Arkari; try making the data segment read-only
#   while(1) + jnz state → Hodur; use d810-ng HodurUnflattener
```

**Step 3 - Deobfuscate in Layers:**
```
a) bcf: d810-ng opaque predicate removal  (or let obpo handle it automatically)
b) fla: d810-ng Unflattener / obpo-plugin / deollvm(ARM64)
c) sub: d810-ng MBA simplifier
```

**Step 4 - Verify Dynamically with Frida:**
```javascript
// Trace the OLLVM state variable to help deflat determine its address
const target = Module.findBaseAddress("libnative.so");
console.log("[+] libnative.so @", target);

// Hook at the dispatcher entry and observe the state-change sequence
Interceptor.attach(target.add(0x1234), {  // dispatcher offset
    onEnter(args) {
        // Read the state variable (determine the register/stack location from decompilation)
        console.log("[state]", this.context.x8);  // Assume state is in x8
    }
});
```

### 4.3 Quick Deobfuscation for CTF Scenarios

CTF tasks usually have tight time limits. Use the fastest path first:

```python
#!/usr/bin/env python3
"""CTF OLLVM quick deflat with angr"""
import angr

proj = angr.Project("challenge", auto_load_libs=False)
cfg = proj.analyses.CFGFast()

# Find the largest functions (most likely to be obfuscated)
funcs = sorted(cfg.functions.values(), key=lambda f: f.size, reverse=True)[:5]
for func in funcs:
    print(f"[*] {func.name} @ {hex(func.addr)} size={hex(func.size)}")
    try:
        deob = proj.analyses.Deobfuscator(func=func)
        deob.normalize()
        print(f"    [+] deobfuscated")
    except Exception as e:
        print(f"    [-] failed: {e}")
        # angr failed → suspect Trap Angr → switch to d810-ng / Unicorn
```

---

## 5. Simplify MBA Expressions

### 5.1 Common OLLVM MBA Patterns

```python
# These equations are the simplification targets for expressions generated by the OLLVM sub pass
"(a | b) + (a & b)"        # → a + b
"(a | b) - (a & b)"        # → a ^ b
"(a ^ b) + 2*(a & b)"      # → a + b
"(a | b) & ~(a & b)"       # → a ^ b
"~(~a & ~b)"               # → a | b (De Morgan)
```

### 5.2 Tool Selection

| Tool | Method | Use Case |
|------|------|------|
| **d810-ng MBA simplifier** | Batch processing in IDA, verified with Z3 | First choice, integrated into the decompilation workflow |
| **SiMBA** (`pip install simba-simplifier`) | Command line/library | Pure expression simplification and batch processing |
| **Arybo** | Symbolic bit vectors | Many MBA expressions |
| **Direct Z3 solving** | SMT | Most general, when template matching fails |

```python
# SiMBA example
from simba import simplify_mba
exprs = ["(a | b) + (a & b)", "(a ^ b) + 2*(a & b)"]
for e in exprs:
    print(f"{e}  →  {simplify_mba(e)}")
```

---

## 6. Complete Deobfuscation Case Script

```bash
#!/bin/bash
# OLLVM deobfuscation pipeline (2026 community tools)
# Applies to ELF/.so files protected with standard OLLVM / Hikari / O-MVLL

BINARY=$1

echo "[*] Stage 0: Basic analysis and variant identification"
file $BINARY
readelf -h $BINARY 2>/dev/null | head -5
echo "    → Confirm the variant in IDA (see Section 1)"

echo "[*] Stage 1: d810-ng local deobfuscation (preferred)"
echo "    IDA → Ctrl-Shift-D load d810-ng"
echo "    Check: MBA + Opaque predicate + Unflattener"
echo "    Apply to target functions"
echo "    Save IDB"

echo "[*] Stage 2: obpo-plugin (if d810-ng is insufficient and network access is available)"
echo "    IDA → right-click dispatcher → OBPO → Mark and process"
echo "    ⚠️ Do not use with sensitive samples (uploads the binary to a cloud service)"

echo "[*] Stage 3: fallback without IDA (x86/x64)"
echo "    python unflattener -i $BINARY -o deobf.bin -t <func_addr> -a"

echo "[*] Stage 4: ARM64 .so fallback without IDA"
echo "    deollvm (Unicorn) or angr Deobfuscator"

echo "[+] Done. Reanalyze and verify in IDA."
```

---

## 7. Common Pitfalls (Community Field Summary)

| Problem | Cause | Solution |
|------|------|---------|
| angr path explosion/abnormal exit | Pluto/Polaris **Trap Angr** pass | Switch to d810-ng or the Unicorn dynamic method |
| obpo-plugin cannot connect | The server is maintained at the owner's expense and may go down | Use local d810-ng. You can open an issue in the obpo repository |
| Goron/Arkari indirect jump deflat fails | The dispatcher uses BR x8 instead of switch | Set the data segment to read-only first. Then use DeObfBR |
| Functions remain disordered after d810-ng processing | OLLVM customized the pass parameters and seed | Use symbolic execution to remove opaque predicates first. Then unflatten |
| Nested fla (multi-layer flattening) is not fully cleared in one run | obpo/d810-ng clears only one layer per run | **Iterative processing**: Mark each new dispatcher |
| ARM64 .so reports an error with deflat | The old deflat script supports x86 only | Use d810-ng / obpo (supports ARM64) / deollvm |
| Hikari strings are not visible | String Encryption pass | Use Unicorn to emulate the decryption stub. Dump the decrypted strings |
| amice target deflat is completely ineffective | It contains VM Flatten / Instruction Virtualization | **It is not OLLVM fla**. Restore the VM handlers. See VM reverse engineering |
| Hodur(PugX) sample has no switch dispatcher | Nested while(1) + jnz state | Use d810-ng **HodurUnflattener**. Do not use the standard Unflattener |
| The state constants in the Approov sample show no clear pattern | The constants are concentrated at 0xF6000–0xF6FFF | Use the d810-ng **BadWhileLoop** unflattener |
| obpo was used by mistake on a sensitive sample | The binary is uploaded to a cloud service | For confidential or unpublished vulnerability samples, **use local tools only** (d810-ng/angr) |
| Frida hook on an OLLVM function hangs | Changing the state variable causes an infinite loop | Add a conditional breakpoint at the dispatcher entry to limit the execution count |

---

## 8. Tool quick reference (2026 community activity)

| Tool | Platform | Method | Stars/Price | Last update | Open source | Notes |
|------|------|------|---------|---------|------|------|
| **obpo-plugin** | IDA | microcode+concolic (cloud) | 629 | 2026-06 | Open-source plugin/closed-source core | Most effective. Requires a network connection |
| **ollvm-breaker** | Binary Ninja | BN API | 441 | 2026-06 | ✅ | Android .so in practice |
| **ollvm-unflattener** | CLI | Miasm symbolic execution | 265 | 2026-06 | ✅ | x86/x64, multi-layer BFS |
| **d810-ng** | IDA | microcode+Z3 | 223 | 2026-06 | ✅ | **Preferred local tool**, broad variant coverage |
| **DeObfBR** | — | BR obfuscation specialist | 96 | 2026-06 | ✅ | Goron/Arkari indirect branches |
| **IDA_Ollvm-unflattener** | IDA | Miasm plugin version | 90 | 2026-04 | ✅ | IDA plugin wrapper for ollvm-unflattener |
| **deollvm** | CLI | Unicorn | 34 | 2026-04 | ✅ | ARM64 specialist |
| **angr** | CLI | Symbolic execution | — | Active | ✅ | General purpose. Constrained by Trap Angr |
| **SiMBA** | CLI/library | MBA simplification | — | — | ✅ | Expression simplification |
| **Triton** | CLI | Symbolic execution + taint | — | Active | ✅ | Dynamic symbolic execution |

---

## 9. Reference Links

**Obfuscators (for understanding adversary objectives):**
- [obfuscator-llvm/obfuscator](https://github.com/obfuscator-llvm/obfuscator) — Original OLLVM
- [HikariObfuscator/Hikari](https://github.com/HikariObfuscator/Hikari) — Hikari
- [komimoe/Hikari](https://github.com/komimoe/Hikari) — Arkari (based on goron, LLVM 14+)
- [amimo/goron](https://github.com/amimo/goron) — goron
- [bluesadi/Pluto](https://github.com/bluesadi/Pluto) — Pluto
- [za233/Polaris-Obfuscator](https://github.com/za233/Polaris-Obfuscator) — Polaris (formerly Pluto)
- [open-obfuscator/o-mvll](https://github.com/open-obfuscator/o-mvll) — O-MVLL
- [fuqiuluo/amice](https://github.com/fuqiuluo/amice) — OLLVM passes implemented in Rust
- [lich4/awesome-ollvm](https://github.com/lich4/awesome-ollvm) — **Overview of the variant ecosystem (read this first)**

**Deobfuscation tools:**
- [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) — Top cloud plugin
- [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) — First choice for local use
- [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) — Miasm pure scripts
- [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) — Binary Ninja
- [GeT1t/deollvm](https://github.com/GeT1t/deollvm) — ARM64 Unicorn
- [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) — Tool for BR obfuscation
- [maskelihileci/IDA_Ollvm-unflattener](https://github.com/maskelihileci/IDA_Ollvm-unflattener) — IDA plugin version
- [angr](https://angr.io/) — Symbolic execution framework
- [SiMBA](https://github.com/tech-srl/simba) — MBA simplification

**Academic and Blog Resources:**
- [Quarkslab: Deobfuscation: Recovering an OLLVM-protected program](https://blog.quarkslab.com/deobfuscation-recovering-an-ollvm-protected-program.html) — Classic deflat principles
- [MODeflattener](https://github.com/mrT4ntr4/MODeflattener) — Static deflat (comparison for ollvm-unflattener)

> Related documents: [[anti-analysis.md]] (complete anti-debugging and anti-analysis list), [[tools-advanced.md]] (advanced tool set), [[elf-analysis.md]] (ELF file analysis), [[ai-assisted-re.md]] (AI-assisted reverse engineering)
