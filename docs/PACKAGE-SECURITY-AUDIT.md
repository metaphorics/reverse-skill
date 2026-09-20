# reverse-skill Package Security Audit (Executable Surface)

> 2026-09-03 review: The audit now covers Git objects, payload identity, symbolic links, binary allowlists, pinned GitHub Actions, and Gradle Wrapper verification. See [Repository security review — 2026-09-03](SECURITY-REVIEW-2026-09-03.md).

> Date: 2026-08-02
> Scope: executable scripts and bootstrap manifests in `skills/**/scripts`, `skills/scripts`, `kali/scripts`, and `burp-mcp-full`
> **Excluded**: teaching payload documents such as `src-hunter` and payloader. Their DROP and injection examples describe methods and do not execute automatically.

## Conclusion (Overall Assessment)

| Level | Assessment |
|------|------|
| **Backdoor, active database deletion, or disk formatting** | **Not found** |
| **Piped download and execution (`curl\|sh` or `IEX DownloadString`)** | **Not found** |
| **Hard-coded cloud keys or private keys** | **Not found**. The `sk-` and `BEGIN RSA` strings in documents are detection examples. |
| **Residual supply-chain risk** | **Partly hardened from medium-low to low**. `@latest` references are pinned. GitHub downloads support **manifest SHA256 and API digest** checks. |

**Overall assessment: the executable skill scripts contain no identified injected backdoor or one-step database deletion. Dangerous deletions stay within temporary tool-reinstall directories or case-output directories.**

### 2026-07-18 Hardening (This Commit)

| Item | Action |
|----|------|
| jshookmcp | `@latest` → `@0.3.4` |
| pentestswarm | `@latest` / Docker `:latest` → `@v0.1.0` / `:v0.1.0` |
| jadx | Pin `v1.5.6` and `assetSha256` |
| apktool | Pin `v3.0.2` and `assetSha256` |
| Bootstrap PS/sh | Run `Assert-DownloadedFileIntegrity` or `verify_sha256` after download. Prefer the manifest hash, then the GitHub `digest`. Delete the file and stop on failure. |
| Release without a pinned hash | Installation remains possible, but print **WARN** and the actual SHA256. |

### 2026-08-02 Security Fixes

| Item | Fix |
|----|------|
| Kali quick setup | Resolve the sudo user's home with `getent` and remove `eval`. |
| Frida process listing | Use a `frida-ps` argument array and remove inline Python string construction. |
| Burp MCP token | Use an atomic replacement with a restricted temporary file. Set POSIX file permissions to `0600`. |
| Burp MCP bridge | Parse MCP newline messages and reconnect when Burp starts. |
| Anything Analyzer MCP | Enable bearer authentication by default during bootstrap. Register credentials through an optional host adapter. |
| IDA MCP startup | Stop old processes one at a time. Avoid multi-PID argument expansion errors. |

## Scan Method

Search executable extensions (`.ps1`, `.sh`, `.py`, `.js`, and `.java`) for:

- `Invoke-Expression` / `IEX` / `FromBase64String` / `DownloadString`
- `curl|bash` / `wget|sh` piped execution
- `DROP DATABASE|TABLE`, `rm -rf /`, and `Remove-Item ... C:\Windows`
- Reverse-shell patterns (`/dev/tcp` misuse and `TcpClient` callbacks)
- Hidden-window startup, followed by a purpose review

Second pass: manually read the download and deletion paths in `bootstrap-reverse.ps1` and `.sh`, `mcp-bridge.js`, and the diagram and cryptography Python scripts.

## Findings

### 1. Deletion Operations (Expected Cleanup, Not Database Deletion)

| Location | Behavior | Risk |
|------|------|------|
| `bootstrap-reverse.ps1` `Expand-ArchiveIntoDirectory` | Delete the target installation directory before reinstalling. Delete `%TEMP%\reverse-bootstrap-*`. | Limited to tool installation paths, not user databases. |
| `bootstrap-reverse.ps1` anything-analyzer | On failure, run `Remove-Item node_modules`, then `pnpm install`. | Limited to the cloned tool repository. |
| `apk-reverse/scripts/decode.*` | Clean the jadx or apktool output directory for the task. | Limited to the task root. |
| `case-init.ps1` | Clean temporary directories. | Temporary paths only. |
| `bootstrap-reverse.sh` | Clean equivalent temporary and installation paths. | Same limitation. |

**No executable logic targets `C:\`, system directories, or arbitrary database connection strings with `DROP` or `TRUNCATE`.**

### 2. Network Behavior (Tool Bootstrap, Not C2)

| Location | Behavior | Description |
|------|------|------|
| `bootstrap-reverse.ps1` | Fetch releases from `api.github.com` and download ZIP or JAR files with `Invoke-WebRequest`. | The repository name comes from a **manifest allowlist**. |
| `bootstrap-reverse.sh` | Use `curl`, `git clone`, `pipx`, and `npm`. | Same allowlist applies. |
| `mcp-bridge.js` | Send HTTP requests only to `127.0.0.1:9876` for Burp. | Local loopback only. |
| `ToolDiscovery.ps1` | Probe `http://host:port/mcp`. | Health check. |
| `kali/.../tool-discovery.sh` | Run `(echo >/dev/tcp/$host/$port)`. | **Port probe**, not a reverse shell. |

### 3. Hidden Windows

| Location | Purpose |
|------|------|
| `bootstrap-reverse.ps1` `Start-Process ... -WindowStyle Hidden` | Start `pnpm dev` for anything-analyzer in the background. |
| `ida-reverse/scripts/start.ps1` | Start IDA-related processes that must remain in the background. |

These forms start services. The audit found no hidden malicious payload download.

### 4. Dangerous Text in Documents and Payloads (Not Automatic Execution)

The **Markdown and JSON teaching materials** in `pentest-tools/src-hunter` and `attack-chain` contain SQL injection, `DROP`, and log-cleanup examples from **red-team methodology**.

`bootstrap` and `master-route` do **not** execute these examples automatically. AI or a human selects them within an **authorized scope**.

See these constraints:

- `ops/scope-contract.md`
- `ops/skill-supply-chain.md`
- `field-journal/precedent-*.md`

### 5. Residual Supply-Chain Risk (Recommended Follow-Up Hardening, Not a Confirmed Backdoor)

| Item | Risk | Recommendation |
|----|------|------|
| `bootstrap-manifest.json` entries `@jshookmcp/jshook@0.3.4` and `pentestswarm@v0.1.0` | Tag drift and supply-chain poisoning exposure | Pin version numbers and checksums. |
| GitHub release ZIP without SHA256 verification | Replacement releases can remain undetected | Add `assetSha256` to the manifest and verify it during bootstrap. |
| Default `npm install -g` and `pip` sources | Inherent dependency-ecosystem risk | Install only manifest capabilities. Use a private source or a lock in production. |

## Executable Script Inventory (Audit Baseline)

```
skills/scripts/*.ps1|*.sh + lib/ToolDiscovery.ps1
skills/apk-reverse/scripts/*
skills/radare2/scripts/*
skills/ida-reverse/scripts/*
skills/browser-automation/scripts/*
skills/diagram-generator/scripts/*.py
skills/case-review/scripts/*.py
kali/scripts/*
burp-mcp-full/mcp-bridge.js (+ Java extension source)
```

## Recommended Ongoing Checks

```powershell
# Quick executable-surface scan (example)
rg -n "Invoke-Expression|FromBase64String|DownloadString|rm -rf /|DROP DATABASE" skills/scripts skills/*/scripts kali/scripts burp-mcp-full -g "*.ps1" -g "*.sh" -g "*.py" -g "*.js"
```

Run this inventory again before merging an executable script for a new skill. Markdown method changes do not require this check.

## Sign-Off

- Audit execution: local static scan and manual review of key paths.
- Result: no backdoor or automatic database deletion. Supply-chain hardening remains a follow-up improvement.
