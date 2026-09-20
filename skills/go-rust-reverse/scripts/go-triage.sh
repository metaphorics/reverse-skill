#!/usr/bin/env bash
# go-triage.sh — Go/Rust binary triage (file + redress info + GoReSym)
# Equivalent to go-triage.ps1 for Windows
#
# Usage:
#   bash go-triage.sh --bin <path>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KALI_BOOTSTRAP="$(cd "$SCRIPT_DIR/../../../kali/scripts" 2>/dev/null && pwd)/bootstrap-reverse.sh"
LINUX_BOOTSTRAP="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd)/bootstrap-reverse.sh"

BIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bin) BIN="$2"; shift 2 ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) BIN="$1"; shift ;;
    esac
done

if [[ -z "$BIN" ]]; then
    echo "Usage: $0 --bin <path>" >&2
    exit 1
fi

if [[ ! -f "$BIN" ]]; then
    echo "ERR: binary not found: $BIN" >&2
    exit 1
fi

# Capability names for bootstrap; the runtime executable may differ (alias exes).
ensure_tool() {
    local name="$1"
    local exe="${2:-$1}"
    if command -v "$exe" &>/dev/null; then
        return 0
    fi
    echo "INFO: Cannot find $exe. Trying automatic installation..." >&2
    if [[ -x "$KALI_BOOTSTRAP" ]]; then
        bash "$KALI_BOOTSTRAP" "$name" --skip-refresh 2>/dev/null || true
    elif [[ -x "$LINUX_BOOTSTRAP" ]]; then
        bash "$LINUX_BOOTSTRAP" "$name" 2>/dev/null || true
    fi
    if ! command -v "$exe" &>/dev/null; then
        echo "ERR: $exe installation failed. Install it manually." >&2
        return 1
    fi
    echo "INFO: $exe installation succeeded" >&2
}

echo "=== file ==="
if command -v file &>/dev/null; then
    file "$BIN"
else
    echo "file: not installed, skipping magic identification"
fi

echo "=== runtime markers ==="
if command -v strings &>/dev/null; then
    if strings "$BIN" | grep -m5 -E 'go\.buildid|runtime\.main|rust_begin_unwind'; then
        true
    else
        echo "no go.buildid / runtime.main / rust_begin_unwind markers"
    fi
else
    echo "strings: not installed, skipping marker scan"
fi

ensure_tool "redress" "redress"
echo "=== redress info ==="
redress info "$BIN"

echo "=== redress packages ==="
redress packages "$BIN"

ensure_tool "goresym" "GoReSym"
echo "=== GoReSym (first 60 lines) ==="
GoReSym "$BIN" | head -n 60
