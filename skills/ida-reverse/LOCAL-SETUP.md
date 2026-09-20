# IDA ↔ reverse-skill integration (portable)

This page gives general steps. It does not contain the absolute path of any machine. The local readiness report remains in `LOCAL-READINESS.md` in the repository root (already in gitignore).

## Target state

| Item | Convention |
|----|------|
| IDA installation directory | Environment variable `IDADIR` (the directory contains `ida.exe` or `ida.dll`) |
| HTTP MCP | `http://127.0.0.1:13337/mcp` |
| Client server name | Keep only **`idapro`** (do not register `ida-pro-mcp` at the same time) |
| Start | `scripts/start.ps1` (`--unsafe`, without `?ext=dbg`) |
| Open a database | Prefer `scripts/open.ps1` for large files. Do not call `idb_open` directly through some clients. |

Two MCP names that point to the same 13337 register the tools twice and compete with the idalib worker for the port.

## Installation

```powershell
setx IDADIR "<your IDA installation directory>"

# You must use mrexodia/ida-pro-mcp. Do not install PyPI's ida-mcp.
python -m pip install "git+https://github.com/mrexodia/ida-pro-mcp.git"

# Activate idalib. Adjust the path for your local IDA installation.
python "<IDADIR>\idalib\python\py-activate-idalib.py" -d "<IDADIR>"

# Install the plugin and configure the client.
python -m ida_pro_mcp --install --transport streamable-http --scope global
```

## Start and keep alive

An MCP entry with `type: http` does not start the process for you. When 13337 is not listening, all clients report error.

| Script | Function |
|------|------|
| `scripts/start.ps1` | If healthy, output `OK:<n>:reuse` and refresh last-healthy. If the port is listening but RPC times out, treat it as busy and do not kill it. Replace the managed supervisor only when no process is listening, `py_eval` is missing, or tools/list fails continuously for more than 3 minutes and no `opening.lock` exists. Never kill `ida.exe`. |
| `scripts/watchdog.ps1` | Check every minute. Reuse when healthy. Reuse when the GUI or `open.ps1` is opening a database or when last-healthy is less than 3 minutes old. Use `-Force` only after tools/list fails continuously for more than 3 minutes. |
| `scripts/recover.ps1` | Restart the supervisor with `-Force` immediately (do not kill `ida.exe`). Use this when the HTTP client marks `idapro` as error. |
| `scripts/install-autostart.ps1` | Register the scheduled task `reverse-skill-ida-mcp` (at login and every minute) |
| `scripts/start-gui.ps1` | Open the GUI plugin when the idalib license fails |
| `scripts/open.ps1` | Call `idb_open` directly over HTTP and bypass schema validation in some clients |

Logs: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log` and `watchdog.log`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\start.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\open.ps1" -Path "C:\path\to\target.exe" -TimeoutSeconds 600
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\install-autostart.ps1"
```

If the GUI uses 13337 but does not return a response for a short time, `start.ps1` outputs `WARN:gui_busy` and exits. This prevents it from killing the IDA that is under analysis.

## Clients

Point all clients to Streamable HTTP: `http://127.0.0.1:13337/mcp`, with server name `idapro`.

Open a new session after you change the configuration. If the port is not listening when Cursor starts, Cursor will **not reconnect automatically** after the service starts. Refresh the service manually in the MCP panel.

## Known Notes

1. System32 file: `open.ps1` copies to a temporary path (output includes `(temp copy)`)
2. Do not call `idb_open` directly through MCP from some clients
3. `start.ps1` prioritizes `python -m ida_pro_mcp.idalib_supervisor` because it is more stable than the `.cmd` wrapper
4. When the formal installation and the desktop portable package coexist, use `IDADIR`
5. Do not add `?ext=dbg` (debugger tools are not exposed by default)
