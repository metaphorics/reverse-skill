---
name: browser-automation
description: |
  Unified automation entry. Covers browser automation (Playwright) and Windows desktop application automation (OpenReverse).
  Browser scenarios: open webpages, click, fill forms, scrape pages, take screenshots, automate login, and interact with pages for penetration testing.
  Desktop scenarios: operate GUI tools such as IDA/x64dbg, use Windows UI Automation, perform vision-driven interaction, and capture desktop application network traffic.
  Trigger keywords: browser automation, desktop automation, open webpages, fill forms, scrape pages, screenshots, automated login, Playwright, agent-browser, headless, OpenReverse, UIA, CUA, desktop operations, Windows automation.
---

# Desktop & Browser Automation

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Confirm that the current task matches this skill's scope
2. `NOW`: Read `../tool-index.md`; verify tool availability and actual paths
3. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths
4. `ACT`: Enter and execute step one of the "Workflow". Do not stop at confirmation

## Scope

Use this skill for the following scenarios:

### Browser scenarios (Playwright / agent-browser)

- Open a webpage and operate its elements (click, fill, submit)
- Scrape page content or take screenshots
- Automate login flows
- Interact with web pages during penetration testing (submit payloads, trigger XSS)
- Automate CAPTCHA-page handling
- Submit forms in batches

### Desktop application scenarios (OpenReverse)

- Operate Windows desktop applications (IDA Pro, x64dbg, Wireshark, and others)
- Use vision-driven interaction (CUA mode)
- Use structured UI operations (UIA mode)
- Observe desktop application network traffic (built-in mitmproxy)
- Automate the GUI of reverse-engineering tools
- Black-box test desktop software

### Tool division

| Scenario | Use |
|------|--------|
| Operate a webpage (inside a browser) | **Playwright / agent-browser** |
| Operate a desktop application (Windows GUI) | **OpenReverse** |
| Capture and analyze packets and HTTP requests | anything-analyzer or OpenReverse network lane |
| Debug JavaScript with breakpoints, hooks, or CDP | jshookmcp |
| Locate a signature algorithm and reproduce its environment | js-reverse |

Simple decision:
- Target is a webpage → Playwright
- Target is a Windows desktop application → OpenReverse
- Need both → Use them together

---

## Part 1: Browser automation (Playwright / agent-browser)

### Core workflow

```bash
# 1. Open the page
agent-browser open <url>

# 2. Get interactive elements (returns @e1, @e2... references)
agent-browser snapshot -i

# 3. Operate elements with references
agent-browser click @e1
agent-browser fill @e2 "text"

# 4. Close when done
agent-browser close
```

### Command reference

```bash
# Navigation
agent-browser open <url>
agent-browser close

# Page snapshot
agent-browser snapshot        # Full accessibility tree
agent-browser snapshot -i     # Interactive elements only (recommended)

# Interaction
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser type @e2 "text"
agent-browser press Enter
agent-browser scroll down 500

# Get information
agent-browser get text @e1
agent-browser get title
agent-browser get url

# Wait
agent-browser wait @e1
agent-browser wait 2000
agent-browser wait --load networkidle
```

### Notes

- You MUST run `agent-browser close` or the process leaks
- Run `snapshot` before an operation. Do not guess element references
- After submitting a form, use `wait --load networkidle` until the page settles

---

## Part 2: Desktop application automation (OpenReverse)

### Overview

[OpenReverse](https://github.com/zhexulong/openreverse) is a desktop interaction and evidence collection framework for AI agents. It supports:
- **UIA mode**: Windows UI Automation for structured desktop-control operations
- **CUA mode**: vision-driven interaction (Computer Use Agent) for complex GUIs
- **Network observation**: built-in mitmproxy proxy and local capture

### Choose an interaction mode

| Mode | Use when | Backend |
|------|---------|------|
| UIA | The target application has standard Windows controls (buttons, text boxes, lists) | Windows UI Automation API |
| CUA | The target application's UI is complex or uses non-standard controls (IDA disassembly view, custom-rendered interface) | Vision recognition + mouse and keyboard |

### Network observation mode

| Mode | Use when |
|------|---------|
| Proxy Lane | The target application can use a proxy (recommended) |
| Local Lane | The target application cannot use a proxy and needs local capture |

### Install and configure

```bash
# 1. Clone the project
git clone https://github.com/zhexulong/openreverse.git
cd openreverse

# 2. Install dependencies
npm install

# 3. Connect the Agent host (Claude Code / Codex / Zed)
npm run init:agents -- --target=all /path/to/project

# 4. Install the CUA runtime (when you need vision-driven mode)
npm run install:cua-runtime
npm run doctor:cua-runtime

# 5. Install network-observation dependencies (when you need packet capture)
npm run install:mitmproxy
npm run doctor:network
```

### Common combinations

| Need | Configuration |
|------|------|
| Operate only a desktop application | UIA or CUA, without a network lane |
| Operate a desktop application and capture packets | UIA/CUA + proxy lane |
| Operate a desktop application and capture locally | UIA/CUA + local lane |

### Reverse-engineering examples

```text
Scenario: automate IDA Pro for batch analysis

1. Open IDA Pro in OpenReverse CUA mode
2. Load the target binary automatically
3. Wait for analysis to finish
4. Use the UI to export the function list
5. Observe IDA network behavior at the same time with the network lane (such as Lumina requests)
```

```text
Scenario: automate x64dbg debugging

1. Start x64dbg in OpenReverse UIA mode
2. Load the target program
3. Set breakpoints
4. Run and observe register and memory changes
5. Save evidence with a screenshot
```

---

## On-Demand Bootstrap

### Automatic capability boundary

| Tool | Auto-installable | Install method | Notes |
|------|-----------|---------|------|
| Playwright | ✓ | npm + npx playwright install | Browser automation engine |
| agent-browser CLI | ✓ | npm install -g agent-browser | Browser operation CLI |
| Node.js | ✓ | winget | Prerequisite |
| OpenReverse | ✗ | Manual clone + npm install | Experimental stage with heavy dependencies |
| mitmproxy | ✗ | Manual install | OpenReverse network-observation dependency |

### Bootstrap triggers

- Playwright is missing for browser operations → run bootstrap automatically
- Desktop operation needs OpenReverse → guide the user through manual installation with full steps

### OpenReverse manual installation guide

If AI detects that desktop application automation is needed but OpenReverse is not installed:

```markdown
⚠️ **OpenReverse is required for desktop application automation**

**Installation steps**:
1. `git clone https://github.com/zhexulong/openreverse.git`
2. `cd openreverse && npm install`
3. `npm run init:agents -- --target=all <your project path>`
4. For vision mode: `npm run install:cua-runtime`
5. For network observation: `npm run install:mitmproxy`

**Verification**: `npm run doctor:cua-runtime` and `npm run doctor:network`
```

---

## Routing context

**Upstream entry**: `skills/SKILL.md` (controller), `routing.md`
**Use when**: Any task that needs automated browser or desktop application operations
**Downstream exit**:
- Analyze captured requests → `anything-analyzer` or `js-reverse`
- Debug or hook JavaScript → `jshookmcp`
- Reconstruct a signature algorithm → `js-reverse`
- Desktop application is a reverse-engineering tool → `ida-reverse/`

**Related modules**: `js-reverse` (browser operations may require JavaScript analysis), `ida-reverse/` (OpenReverse can automate the IDA GUI)


## Completion self-check (MUST pass before you claim completion)

- [ ] I executed every workflow step, not only read it
- [ ] I used real tool paths from `tool-index`
- [ ] I produced reproducible evidence (command/script/screenshot/report)
- [ ] I completed and wrote back the Checklist items required by RULES
