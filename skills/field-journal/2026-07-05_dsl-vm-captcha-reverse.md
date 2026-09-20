---
name: dsl-vm-captcha-reverse-2026-07-05
description: Full reverse engineering of a captcha system, including the JS frontend modules and the DSL VM risk-control engine
metadata:
  type: project
  tags: [captcha, reverse, dsl-vm, wasm, frontend]
  date: 2026-07-05
  status: completed
---

# Full reverse engineering of a captcha system

## Scenario

The target was a large captcha system. The goal was to understand its complete operation and validation flow.

## Target components

- **nc.js** (72KB), the Webpack-bundled slider core (9 modules)
- **fireyejs.js** (583KB), the DSL VM interpreter (26 custom opcodes)
- **awsc.js** (9KB), the module loader
- **secaptcha.js** (72KB), the WASM C build output (emscripten)
- **et_f.js** (262KB), another DSL VM-style file

## Technical approaches verified

### Approach A: Selenium + CDP drag (recommended)

Send native mouse events with CDP `Input.dispatchMouseEvent` and complete the validation in a real browser.

- Success rate: high
- Dependencies: Chrome + Selenium/Playwright

### Approach B: Playwright headless browser runner

Load the DSL VM and module loader in Playwright. Expose the token through an HTTP API.

- Success rate: medium (depends on the WASM initialization environment)

### Approach C: Direct requests protocol validation

Call the API endpoints directly through HTTP requests.

- Success rate: **very low** (the token is tightly bound to the browser TLS, IP, and fingerprint)
- Not recommended

## Key findings

1. **The token cannot be used outside the browser**. The server checks context consistency when it receives a token from the DSL VM, including TLS JA3, IP, Cookie, and Referer.

2. **fireyejs.js is a DSL VM, not a WASM binary**. The 583KB pure-JS implementation is a custom virtual machine. An interpreter loop executes encoded instructions through 26 opcodes.

3. **All 9 nc.js modules were reverse engineered**. This includes API endpoints, the slider UI, interaction logic, the ncSessionID algorithm, and localization.

4. **secaptcha.js is the actual WASM build output**. It is 72KB and uses SharedArrayBuffer + Atomics. Emscripten compiled the C code.

## Pitfalls

1. A test appkey does not trigger real validation. The appkey from a real page is required.
2. `initialize` must return a specific status code to select slider mode. `success` only confirms session creation.
3. A JSONP request URL event in the performance log may be incomplete because of the way the script tag is injected.
4. Exported function names do not exist in the DSL VM file because the VM encodes them. The module registry exposes the real exports.

## Reusable patterns

- **DSL VM reverse engineering**: `case extraction → opcode classification → constant-table analysis → function tracing → export extraction`
- **Common captcha architecture**: `entry JS → module loader (WASM/DSL) → API layer → frontend UI → server validation`
- **Native CDP event bypass**: `Input.dispatchMouseEvent` bypasses detection without relying on WebDriver

## Toolchain

- Selenium + CDP: browser automation and native mouse events
- Playwright: headless browser and route interception
- Python requests: direct API calls (validation failed)
- Node.js + Playwright: runner service

## File structure

```
project-root/
├── slider_v3.py                # Improved CDP drag
├── protocol_v2.py               # Direct protocol version (validation failed)
├── phase3_final.py              # Complete Playwright capture
├── monitor_inject.js            # Page monitoring hook
├── runner/                      # Node.js runner
├── captured_js/                 # Captured JS files
├── hook_data/                   # Data captured by the hook
├── wasm_output/                 # WASM extraction output
└── COMPLETE_REVERSE_REPORT.md   # Full reverse-engineering report
```

## References

- [[dsl-vm-reverse]], the DSL VM reverse-engineering skill document
