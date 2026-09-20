---
name: js-reverse
description: Use this skill for front-end JavaScript reverse engineering with js-reverse-mcp. It covers signature generation tracing, page observation and evidence collection, runtime sampling, local reproduction with environment patches, and evidence-based reporting. Use the js-reverse_* tools available in the current environment first. Use jshookmcp when you need more browser, CDP, or Hook functions.
---

# MCP Front-End JS Reverse Engineering Instructions

## ACTION REQUIRED (Execute Immediately After Reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm authorization for the routine operations in this skill
2. `NOW`: Check whether the current task is within the scope of this skill
3. `NEXT`: Read `../tool-index.md` and check tool availability and actual paths
4. `NEXT`: If tools are missing, use bootstrap; do not guess paths
5. `ACT`: Start and execute the first step in "Workflow"; do not stop after confirmation

## Scope

Use this skill first for these tasks:

- Find API signatures, encrypted parameters, and risk-control fields
- Observe page request sequences and script sources
- Capture function arguments and return values at runtime
- Trace the trigger point of an XHR/Fetch/WebSocket
- Use page evidence for local reproduction and environment patches in Node

If the target is a binary, APK, PE, ELF, DLL, or SO, use `ida-reverse`, `radare2`, or `reverse-engineering` instead.

## Default Tool Mapping for the Current Environment

Do not assume that tools are available under unprefixed names. Use the `js-reverse_*` tools available in the current client environment by default.

If the task explicitly mentions `jshookmcp`, `JS hook`, `CDP`, browser breakpoints, network interception, SourceMap, or AST deobfuscation, continue to use this skill. Use `jshookmcp` as the underlying MCP service, not as a separate main entry point.

Prerequisite: `jshookmcp` is not a standalone local command. It is an MCP server that you must first download, explicitly register, and enable. Its tools are available only after you add and enable the server in the MCP configuration of the selected client (Claude, Codex, etc.).

Common mappings:

- `list_scripts` -> `js-reverse_list_scripts`
- `get_script_source` -> `js-reverse_get_script_source`
- `search_in_sources` -> `js-reverse_search_in_sources`
- `break_on_xhr` -> `js-reverse_break_on_xhr`
- `evaluate_script` -> `js-reverse_evaluate_script`
- `get_paused_info` -> `js-reverse_get_paused_info`
- `set_breakpoint_on_text` -> `js-reverse_set_breakpoint_on_text`
- `list_network_requests` -> `js-reverse_list_network_requests`
- `get_request_initiator` -> `js-reverse_get_request_initiator`
- `get_websocket_messages` -> `js-reverse_get_websocket_messages`
- `take_screenshot` -> `js-reverse_take_screenshot`
- `new_page` -> `js-reverse_new_page`
- `navigate_page` -> `js-reverse_navigate_page`
- `select_page` -> `js-reverse_select_page`
- `select_frame` -> `js-reverse_select_frame`
- `pause/resume` -> `js-reverse_pause_or_resume`

If the tool name prefix changes, update this section first. Do not guess during execution.

### Role of jshookmcp

- Role: An extended tool set for `js-reverse`, not a separate controller
- Suitable uses: Browser automation, CDP debugging, JS Hook, network interception, SourceMap reconstruction, and AST-assisted code analysis
- Prerequisite for calls: Download `@jshookmcp/jshook`, register it in the MCP client configuration, and make sure the server is enabled
- Recommended entry point: Continue to use `Observe → Capture → Rebuild`; use the browser and Hook functions of jshookmcp first during `Observe/Capture`
- Relation to anything-analyzer: Both collect browser and network evidence; anything-analyzer focuses on packet capture and HTTP analysis, while jshookmcp focuses on JS runtime, CDP, Hook, and source code analysis

## Core Principles

- `Observe-first`
- `Hook-preferred`
- `Breakpoint-last`
- `Rebuild-oriented`
- `Evidence-first`

Observe the page first, collect the minimum samples, then patch the local environment. Do not skip evidence collection and guess the environment.

## Five-Stage Workflow

### 1. Observe

Objective: Identify the target request, related scripts, and candidate functions first. Do not guess the environment.

Default actions:

- Open the target page with `js-reverse_new_page` or `js-reverse_navigate_page`
- Find the target request with `js-reverse_list_network_requests`
- Trace the call source with `js-reverse_get_request_initiator`
- Use `js-reverse_list_scripts` and `js-reverse_search_in_sources` to narrow the set of scripts

Required outputs:

- Target request URL or identifying features
- Initiator clues
- Suspect script URL
- Initial task record

### 2. Capture

Objective: Sample the target request with minimum interference. Collect parameter examples, the call sequence, and runtime evidence.

Rules:

- Use `js-reverse_break_on_xhr` first
- Use `js-reverse_evaluate_script` first for runtime observation with low overhead
- When the breakpoint is hit, check `js-reverse_get_paused_info` first
- Use `js-reverse_set_breakpoint_on_text` only if necessary

### 3. Rebuild

Objective: Organize the page evidence for repeated local reproduction in Node.

Rules:

- Use page observation evidence as the basis for local environment patches
- Do not add `window/document/navigator/crypto/storage` behavior based on guesses
- Record only one minimum patch decision and its cause at a time

### 4. Patch

Objective: Use errors and the first divergence to guide environment patches until the local script reliably produces the target parameters.

Rules:

- Identify what is missing before you add it
- Make only one minimum patch decision at a time
- Test again immediately after each patch
- Record each patch in the task record

### 5. DeepDive

Objective: After local execution succeeds, perform deobfuscation, reconstruct control flow, and isolate the business logic.

Rules:

- If the task only requires signature generation, you can reduce work in this stage
- If the algorithm sequence must support long-term reuse, you must complete this stage
- Issue #65 obfuscation bypass (U–AV §4): JSVMP (AD) → `E-js-vmp`; CFF+string arrays (AE) → `E-js-deobf`; DevTools/debugger anti-debugging (AF) → `E-js-anti-debug`. See `../reverse-engineering/references/nonpe-format-cookbook.md` for the complete trigger table; continue to use `references/ast-deobfuscation.md` for AST details

## Execution Requirements

- Record all important steps in a local task artifact
- Do not call a tool if you cannot explain why it is necessary
- Use existing MCP functions from `js-reverse_*` or jshookmcp first to collect evidence directly; do not write scripts to duplicate these functions first
- If an operation fails, use `references/fallbacks.md`
- Follow `references/output-contract.md` for output

## Required References

- Automation entry point: `references/automation-entry.md`
- Parameter defaults: `references/tool-defaults.md`
- Task input template: `references/task-input-template.md`
- MCP-specific task coordination: `references/mcp-task-template.md`
- Task artifacts: `references/task-artifacts.md`
- Local reproduction: `references/local-rebuild.md`
- Environment patches: `references/env-patching.md`
- Node reproduction: `references/node-env-rebuild.md`
- Instrumentation: `references/instrumentation.md`
- AST deobfuscation: `references/ast-deobfuscation.md`
- Non-PE/JS obfuscation procedures U–AV: `../reverse-engineering/references/nonpe-format-cookbook.md` (AD/AE/AF)
- Fallbacks: `references/fallbacks.md`
- Output contract: `references/output-contract.md`

---

## Routing Context

**Upstream entry points**: `skills/SKILL.md` (main controller), `routing.md`
**Upstream alternatives**:
- Use the browser tools of anything-analyzer MCP (port 23816) as alternatives or additional tools
- Use jshookmcp for more browser/CDP/Hook/Network/SourceMap/AST functions
- `reverse-engineering/SKILL.md` (if the target is not front-end JS)

**Downstream routes**:
- Environment patches required → `references/env-patching.md`
- Local reproduction required → `references/local-rebuild.md` / `references/node-env-rebuild.md`
- Deobfuscation required → `references/ast-deobfuscation.md`
- Fallback if the current method fails → `references/fallbacks.md`

**Related peer module**: anything-analyzer MCP (its browser automation and HTTP capture functions can supplement this skill)

---

## On-Demand Bootstrap

Use the shared bootstrap system to install the MCP functions that this skill requires. Explicitly select the target MCP client for registration. By default, bootstrap does not write to any global client configuration.

### Automation Limits

| Capability | Automatic registration | Method | Notes |
|------|-----------|------|------|
| jshookmcp | ✓ | npm-mcp (start with npx) | Register after explicit selection of Claude / Codex / Both |
| anything-analyzer | ✓ | local-http-mcp | Can start the service automatically; client registration requires explicit selection |
| Node.js | ✓ | Install with winget | Runtime dependency |

### Bootstrap Methods

```powershell
# Install and register jshookmcp; replace Codex with Claude or Both if necessary
powershell -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('jshookmcp') -McpHostTarget Codex

# Register and start anything-analyzer
powershell -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('anything-analyzer') -StartServices -McpHostTarget Codex
```

### Important Notes

- After registration of `jshookmcp`, **enable** the MCP server in the AI client before you call its tools
- Without `-McpHostTarget`, bootstrap only installs/prepares the functions and returns registration-required; it does not change the Claude or Codex configuration
- `anything-analyzer` requires pnpm and the project source code; bootstrap automatically clones the repository and installs dependencies
- If Node.js is not installed, bootstrap first installs Node.js 22 through winget

<br><br>## Task Completion Check (MUST Pass Before You Claim Completion)

- [ ] Did I execute each workflow step (not only read it)?
- [ ] Did I use actual tool paths from `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and record the Checklist items required by RULES?