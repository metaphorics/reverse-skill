#!/usr/bin/env bash
# ida-start.sh — Start IDA Pro MCP HTTP service (Linux version)
# Equivalent to the Windows ida-reverse/scripts/start.ps1 script

set -euo pipefail

# ─── Configuration (modify for your installation) ───────────────────────────────────

IDADIR="${IDADIR:-/opt/idapro}"
MCP_PORT="${IDA_MCP_PORT:-13337}"

# idalib-mcp executable path (usually in PATH after pip install)
MCP_SERVER_CMD="${IDA_MCP_SERVER:-ida-pro-mcp}"

# ─── Check ──────────────────────────────────────────────────────────────────────────

if [[ ! -d "$IDADIR" ]]; then
    echo "ERR: IDADIR does not exist: $IDADIR"
    echo "Set IDADIR to the IDA Pro installation directory"
    exit 1
fi

if ! command -v "$MCP_SERVER_CMD" &>/dev/null; then
    echo "ERR: $MCP_SERVER_CMD not found"
    echo "Run first: pip3 install git+https://github.com/mrexodia/ida-pro-mcp.git"
    exit 1
fi

# ─── Kill old process ───────────────────────────────────────────────────────────────

pkill -f "ida-pro-mcp" 2>/dev/null || true
sleep 1

# ─── Start service ──────────────────────────────────────────────────────────────────

echo "INFO: Starting IDA MCP HTTP service (port $MCP_PORT) ..."
export IDADIR

nohup "$MCP_SERVER_CMD" --port "$MCP_PORT" > /tmp/ida-mcp.log 2>&1 &
MCP_PID=$!

# ─── Wait for readiness ─────────────────────────────────────────────────────────────

TIMEOUT=45
ELAPSED=0

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    if nc -z 127.0.0.1 "$MCP_PORT" 2>/dev/null; then
        echo "OK: IDA MCP service is ready (PID=$MCP_PID, port=$MCP_PORT)"
        exit 0
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

echo "ERR: Timeout ${TIMEOUT}s. Service is not ready"
echo "View log: /tmp/ida-mcp.log"
exit 1
