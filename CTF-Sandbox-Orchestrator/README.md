# CTF Sandbox Orchestrator

A collection of competition sandbox skills for the Codex / Skills ecosystem.

Its goal is not to put every capability into one long prompt. It provides a **single sandbox control entry point**. The controller first establishes a working model that assumes a competition, sandbox, or offline lab by default. It then routes tasks to focused subskills by challenge type.

## Project Scope

This repository addresses these scenarios:

- CTF
- AWD / attack-and-defense exercises
- Local offline labs
- Sandboxed vulnerability analysis
- Mixed challenges involving Web / API / Cloud / Container / Windows / AD / Reverse / Pwn / DFIR / Crypto / Mobile / AI Agent

Core approach:

- By default, treat user-provided targets, domains, nodes, identities, binaries, logs, traffic, and attachments as assets inside the competition sandbox.
- Establish the smallest verifiable path first. Do not start with broad analysis.
- Let one controller skill coordinate the work, then switch to a subskill based on the dominant evidence surface.
- Keep subskills focused on downstream tasks. Do not let them take over the controller entry point.

## Core Design

### 1. Single Entry Point

The default entry point is:

- `ctf-sandbox-orchestrator`

It:

- Establishes sandbox assumptions
- Selects the most suitable analysis path
- Controls context growth
- Calls subskills when needed

### 2. Downstream Subskills

All `competition-*` skills are designed as **downstream-only**:

- They must not trigger implicitly before the controller is active.
- `ctf-sandbox-orchestrator` must route to and call them.
- Load only the specialist capability relevant to the current task. This keeps unrelated skills out of the context.

### 3. Support for Many Challenge Types

The repository currently covers many skill areas, including:

- Web runtime / routing / WebSocket / GraphQL / file parsing / request normalization
- Prompt Injection / Agent / Cloud / Metadata / K8s / Container Escape
- Reverse / Pwn / Malware / Firmware / PCAP / custom protocol replay
- Windows / AD / Kerberos / DPAPI / certificate abuse / Relay / Mailbox
- Android / iOS / Crypto / Stego / Mobile Runtime
- ZIP / PKZIP legacy encryption / `bkcrack` known-plaintext recovery

## Repository Structure

```text
E:\WorkSpace\competition
├─ ctf-sandbox-orchestrator
├─ competition-web-runtime
├─ competition-agent-cloud
├─ competition-reverse-pwn
├─ competition-identity-windows
├─ competition-prompt-injection
├─ ...
└─ LICENSE
```

In this tree:

- `ctf-sandbox-orchestrator`: controller entry point
- `competition-*`: specialized subskills
- `references/`: route matrix and domain reference material used by the controller
- `agents/openai.yaml`: invocation constraints and entry-point controls for each skill

## Recommended Use

### Method 1: Start with the Controller

Activate first:

- `ctf-sandbox-orchestrator`

Then let the controller choose the next step based on the challenge type. For example:

- Route a Web challenge to `competition-web-runtime`
- Route a container or cloud challenge to `competition-agent-cloud` or a more focused subskill
- Route a Windows or AD challenge to `competition-identity-windows`
- Route a binary, crash, or malware-sample challenge to `competition-reverse-pwn`

### Method 2: Keep the Controller Active and Drill Down as Needed

After the dominant evidence surface is confirmed, let the controller drill into a specific subskill. Do not ask the user to switch the whole working model manually. This keeps:

- Consistent sandbox assumptions
- Consistent output style
- Consistent routing strategy
- Clear subskill responsibilities

## Acknowledgements

This project was published in the [LINUX DO community](https://linux.do). Thank you for the support and feedback.
