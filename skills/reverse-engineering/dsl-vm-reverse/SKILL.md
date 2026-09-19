---
name: dsl-vm-reverse
description: Reverse JavaScript-based custom DSL/VM interpreters, non-standard WASM-like runtimes, and risk-control engines. Use when analyzing IIFE or switch-based opcode dispatchers, extracting instruction tables, recovering bytecode semantics, capturing VM state at runtime, or reconstructing execution flow.
---

# 🔄 DSL Custom Virtual Machine Reverse Engineering (DSL VM Reverse Engineering)

## ACTION REQUIRED (Execute immediately after reading)

1. `NOW`: Confirm that the current task concerns a custom JS opcode VM / risk-control engine, not standard WASM or ordinary webpack
2. `NOW`: Run `case-init` until `scope.md` is ready; use `offline` / `lab` for offline samples
3. `ACT`: Start file classification from Phase 1 of "3. General Reverse Engineering Workflow". Do not stop at the directory.

> Use this to reverse engineer a custom WASM virtual machine / risk-control engine implemented in JavaScript

---

## Contents

- [1. Scope](#1-scope)
- [2. DSL VM Identification Features](#2-dsl-vm-identification-features)
- [3. General Reverse Engineering Workflow](#3-general-reverse-engineering-workflow)
- [4. Opcode Extraction and Classification](#4-opcode-extraction-and-classification)
- [5. Runtime Capture Methods](#5-runtime-capture-methods)
- [6. Common Status Codes](#6-common-status-codes)
- [7. Skill Self-Check List](#7-skill-self-check-list)

---

## 1. Scope

Use this skill when the target file has **any of the following features**:

| # | Feature | Description |
|---|------|------|
| 1 | Starts with IIFE + many single-letter variable names | `!function(){var U=void 0,y=parseInt,E0=Function,...}` |
| 2 | Contains `DG()` or a similar function with a switch-case loop | Main interpreter loop. `d[7]&31` decodes the opcode. |
| 3 | Large file (500KB+) with a zero-byte ratio < 1% | Non-standard WASM. Pure JS. |
| 4 | Contains `C[number]` constant table references | `C[9][xxx]` function table / string table |
| 5 | Minified code on one line | 583KB on one line. Obfuscated variable names. |

### Exclusion Rules

| Condition | Not for this skill | Use instead |
|------|-----------|------|
| File starts with `\x00asm` | Standard WASM binary | `reverse-engineering/languages.md` |
| File contains the WASM magic number in `Uint8Array([0,97,115,109])` | Embedded WASM | Extract .wasm, then convert it for IDA/Ghidra |
| Standard Webpack bundle (`function(e,t,n){...}`) | Regular JS | `js-reverse/` |
| Zero-byte ratio > 20% | WASM binary | `reverse-engineering/languages.md` |

---

## 2. DSL VM Identification Features

### Code Features

```javascript
// Feature 1: IIFE entry point, single-letter variable maps to numeric constants
!function(){
    var U=void 0, y=parseInt, E0=Function, AN=Uint8Array;
    var E=15, l=10, m=12, x=16, S=13, $=11;
    // Map numeric constants to variable names to replace the original numbers
    ...
}

// Feature 2: Interpreter main loop DG()
function DG(C, d, ...) {
    var d = [];  // Array simulates the WASM stack/locals
    for (d[7] = x; d[7] !== U;) {
        var aE = d[7] & 31;         // Lower 5 bits = opcode
        var O = d[7] >> 5 & 31;      // Upper 5 bits = sub-operation
        switch (aE) {
            case 0: /* ... */ d[7] = 612; break;
            case 1: /* ... */
            // ... N cases
        }
    }
}

// Feature 3: Constant table C[9] stores function indexes and strings
// C[9][0] = ["pc"]      → Function parameter description
// C[9][667] = "string"  → String constant
// C[9][x] = number      → Function index

// Feature 4: W(C[index], null, ...) call pattern
// W = Function.prototype.call.bind(call)
// All built-in functions are called through the C[index] index

// Feature 5: Instruction encoding format
// d[7] = opcode(bit 0-4) | subop(bit 5-9) | operand(bit 10+)
```

### Opcode Encoding Format

Each instruction is encoded as a 32-bit integer:

```
bit 0-4:   opcode (0-N)
bit 5-9:   sub-operation (0-31)
bit 10-31: operand/immediate value

Decode:
  aE = d[7] & 31        → opcode
  O  = d[7] >> 5 & 31   → sub-operation
  d[other] = d[7] >> 10  → operand
```

---

## 3. General Reverse Engineering Workflow

### Phase 1: File Classification (5 minutes)

```bash
# Check whether this is a DSL VM
python3 << 'EOF'
with open('target.js', 'rb') as f:
    head = f.read(100)

# 1. Check the WASM magic number
if head[:4] == b'\x00asm':
    print("Standard WASM binary")
    exit()

# 2. Check the proportion of zero bytes
data = open('target.js', 'rb').read()
zero_pct = data.count(b'\x00') / len(data) * 100
print(f"Zero-byte ratio: {zero_pct:.1f}%")

if zero_pct > 20:
    print("WASM binary")
elif head[:2] == b'!f':
    # Check the single-letter variable pattern
    if b'var U=void 0' in head or b'U=void 0,y=parseInt' in head:
        print("→ DSL VM!")
    else:
        print("Regular JS IIFE")
EOF
```

### Phase 2: Variable Mapping Extraction (10 minutes)

```python
import re

with open('target.js', 'r', errors='replace') as f:
    s = f.read()

# Extract the var X=number mappings from the first 2000 characters
mappings = re.findall(r'var\s+(\w+)\s*=\s*(\d+)', s[:2000])
print('Constant mappings:')
for name, val in mappings:
    print(f"  {name:4s} = {val:3d} (0x{int(val):02x})")
```

### Phase 3: Opcode Extraction and Classification (15 minutes)

```python
# 1. Extract all cases
all_cases = re.findall(r'case\s+(\d+):', s)
unique = sorted(set(int(c) for c in all_cases))

print(f"Total cases: {len(all_cases)}")
print(f"Unique opcodes: {len(unique)}: {unique}")

# 2. Classify each opcode
for op in unique:
    idx = s.find(f'case {op}:')
    snippet = s[idx:idx+200]
    if 'd[7]=' in snippet:
        op_type = 'BRANCH'
    elif 'return' in snippet:
        op_type = 'RETURN'
    elif 'W(C[' in snippet:
        op_type = 'CALL'
    elif 'new' in snippet:
        op_type = 'ALLOC'
    elif 'try' in snippet or 'catch' in snippet:
        op_type = 'EXCEPTION'
    else:
        op_type = 'ARITH/STORE'
    print(f"  opcode {op:2d}: {op_type}")
```

### Phase 4: Constant Table Analysis (30 minutes)

```python
const_refs = re.findall(r'C\[9\]\[(\d+)\]', s)
unique_refs = sorted(set(int(x) for x in const_refs))

print(f"C[9] references: {len(unique_refs)} indices")
print(f"Range: {min(unique_refs)} - {max(unique_refs)}")

# Analyze the context of each reference
for ref in unique_refs[:20]:
    idx = s.find(f'C[9][{ref}]')
    ctx = s[max(0,idx-50):idx+80]
    clean = ''.join(c if c.isprintable() else ' ' for c in ctx)
    print(f"  C[9][{ref}] → {clean}")
```

### Phase 5: Exported Function Tracing (1-2 hours)

Exported functions such as `getToken` are located through the following paths:

```
1. Find AWSCInner.register() or a similar registration call
2. Identify the registered module and factory function
3. Find the object returned by the factory function → location of the exported function definition
4. If the function name is not in the JS → store the bytecode in the C[9] constant table
5. Trace the call chain:
   AWSCInner._modules['fy'].getToken()
   → W(C[function index], null, ...)
   → DG() interpreter executes the encoded instruction sequence
```

### Phase 6: Runtime Injection (if static analysis alone is not enough)

```javascript
// Inject a minimal AWSC-compatible environment
const fakeEnv = {
    AWSCInner: {
        _modules: {},
        register(name, moduleName, factory) {
            this._modules[moduleName] = factory();
        }
    }
};

// Execute DSL VM code
dslVmCode();

// Obtain exports
const token = fakeEnv.AWSCInner._modules['fy'].getToken({});
```

---

## 4. Opcode Extraction and Classification

### Reference Opcode Table (Based on Existing Cases)

| Opcode | Operation Type | Features |
|--------|---------|------|
| 0 | **BRANCH** | Unconditional jump with `d[7]=xxx` |
| 1 | **CALL** | Embedded function call with `W(C[Y],null,function(){...})` |
| 2 | **ARITH** | Variable assignment with `d[4]=0`, `d[7]=72` |
| 3 | **ARITH** | Comparison operations with `d[0]=d[1][C[x]]`, `d[5]=d[0]<d[3]` |
| 4 | **STORE** | Property access or existence check with `d[8]=d[5]in d[4]` |
| 5 | **ARITH** | `d[8]=d[4]-d[8]` Arithmetic operation |
| 6 | **RETURN** | `return gV`, `throw` Return or throw an exception |
| 7 | **ALLOC** | `d[6]=[]`, `d[6][C[8]](...)` Push operation |
| 8 | **BRANCH** | `d[7]=d[k]?512:425` Conditional branch |
| 9 | **STRING** | `d[6][C[t]]=d[m]`, `new fh(...)` Regular expression |
| 10 | **ALLOC** | Prepare function arguments and create the call stack |
| 11 | **STRING** | `new fh("\\s",d[5])` Regular expression matching |
| 12 | **STORE** | `P[d[9]]=d[4][C[H]](d[3])` Data transfer |
| 13 | **CALL** | `C[9][113]=d[9]` Module initialization |
| 14 | **STRING** | `d[8]=d[9]+d[m]` String concatenation |
| 15 | **RETURN** | `return EL;` Function return |
| 16 | **ALLOC** | `var r,P,Z,B...` Declare local variables |
| 17 | **ALLOC** | `(Z=[])[C[8]](69,T,445)` Static array initialization |
| 18 | **TABLE** | Initialize the function table and type table |
| 19 | **EXCEPTION** | `try{for(var RK=x;...` Try-catch loop |
| 20 | **DOM** | `Is[d[o]]` DOM operation |
| 21 | **STORE** | Safely access global or object properties |
| 22 | **STRING** | `new fh(r,v)` String or regular expression processing |
| 23 | **BRANCH** | `try...catch` Safe access and conditional branch |
| 24 | **CALL** | `W(C[2],null,8,z,FL)` Multi-argument function call |
| 25 | **EXCEPTION** | `try{...}catch(C){...}` Catch an exception and branch |

---

## 5. Runtime Capture Methods

### Method A: Selenium + Native CDP Events (Recommended, Highest Success Rate)

```python
from selenium import webdriver

driver = webdriver.Chrome()

# Inject AV/EDR evasion
driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {
    "source": r"""
        Object.defineProperty(navigator, 'webdriver', {get: () => false});
        Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3,4,5]});
        Object.defineProperty(navigator, 'languages', {get: () => ['zh-CN','zh','en']});
    """
})

# Send native CDP mouse events
driver.execute_cdp_cmd("Input.dispatchMouseEvent", {
    "type": "mousePressed",
    "x": 549.5, "y": 441.2,
    "button": "left", "buttons": 1,
    "clickCount": 1, "pointerType": "mouse"
})
```

### Method B: Playwright Headless Browser

```javascript
const { chromium } = require('playwright');

async function run() {
    const browser = await chromium.launch();
    const page = await browser.newPage();

    // Intercept network requests
    await page.route('**/api/**', async route => {
        await route.continue_();
    });

    await page.goto('https://target-page.com');

    // Wait for DSL VM initialization
    await page.waitForFunction(() => {
        return window.AWSCInner &&
               window.AWSCInner._modules &&
               window.AWSCInner._modules['fy'];
    });

    // Execute the operation
    await page.mouse.move(500, 400);
    await page.mouse.down();
    // ... operation sequence
    await page.mouse.up();
}
```

### Option C: Pure protocol validation (very low success rate)

> Tokens generated by the DSL VM are usually strongly bound to the browser context (TLS JA3 fingerprint, IP, Cookie, request headers, and other data). After the tokens leave the browser, the server can detect a context mismatch. **Do not use the pure protocol approach**.

---

## 6. Common status codes

| Code | Meaning | Action |
|------|------|------|
| 0 | **Validation passed** ✅ | Extract sessionId + sig |
| 300 | **Risk-control block** | Blocked. Validation cannot pass |
| 8778 | **Validation failed. Retry required** | Retry the operation |
| 8776 | **Operation too fast. Retry required** | Add a delay, then retry |
| 69634 | **General failure** | Check that the parameters are correct |

---

## 7. Skill self-check list

- [ ] Did I identify the DSL VM (IIFE + single-letter variables + DG() interpreter)?
- [ ] Did I extract the variable mapping table (`var X=number`)?))
- [ ] Did I extract and classify the opcode list?
- [ ] Did I analyze the reference range of the constant table C[9]?
- [ ] Did I locate the export function registration point?
- [ ] When static analysis was not enough, did I try the runtime injection approach?
- [ ] After I completed the task, did I write back to field-journal?
- [ ] Did I find a new tool or a new scenario? If yes, update routing.md

---

## Route registration

| Type | Route |
|------|------|
| **Target type**: WASM / DSL VM / custom instruction set | `reverse-engineering/dsl-vm-reverse/SKILL.md` |
| **User intent**: "DSL VM / risk-control engine reverse engineering" | This skill |
| **Toolchain**: Playwright / Selenium CDP | Browser injection approach |

### Path cross-reference

```
DSL VM reverse-engineering path:
  reverse-engineering/dsl-vm-reverse/ → Phase 1-6 workflow
  ↓ If runtime data needs to be captured
  browser-automation/ → Playwright/Selenium CDP
  ↓ If the API protocol layer needs to be analyzed
  js-reverse/ → Observe→Capture→Rebuild
```
