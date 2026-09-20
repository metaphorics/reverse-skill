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
        --bin)
            if [[ $# -lt 2 ]]; then
                printf 'ERR: --bin needs a path argument\n' >&2
                exit 1
            fi
            BIN="$2"; shift 2 ;;
        -*) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
        *) BIN="$1"; shift ;;
    esac
done

if [[ -z "$BIN" ]]; then
    printf 'Usage: %s --bin <path>\n' "$0" >&2
    exit 1
fi

if [[ ! -f "$BIN" ]]; then
    printf 'ERR: binary not found: %s\n' "$BIN" >&2
    exit 1
fi

# Capability names for bootstrap; the runtime executable may differ (alias exes).
ensure_tool() {
    local name="$1"
    local exe="${2:-$1}"
    if command -v "$exe" &>/dev/null; then
        return 0
    fi
    printf 'INFO: Cannot find %s. Trying automatic installation...\n' "$exe" >&2
    if [[ -x "$KALI_BOOTSTRAP" ]]; then
        bash "$KALI_BOOTSTRAP" "$name" --skip-refresh 2>/dev/null || true
    elif [[ -x "$LINUX_BOOTSTRAP" ]]; then
        bash "$LINUX_BOOTSTRAP" "$name" 2>/dev/null || true
    fi
    if ! command -v "$exe" &>/dev/null; then
        printf 'ERR: %s installation failed. Install it manually.\n' "$exe" >&2
        return 1
    fi
    printf 'INFO: %s installation succeeded\n' "$exe" >&2
}

printf '=== file ===\n'
if command -v file &>/dev/null; then
    file "$BIN"
else
    printf 'file: not installed, skipping magic identification\n'
fi

printf '=== runtime markers ===\n'
if command -v strings &>/dev/null; then
    markers=$(strings "$BIN" | grep -E 'go\.buildid|runtime\.main|rust_begin_unwind' | sed -n '1,5p' || true)
    if [[ -n "$markers" ]]; then
        printf '%s\n' "$markers"
    else
        printf 'no go.buildid / runtime.main / rust_begin_unwind markers\n'
    fi
else
    printf 'strings: not installed, skipping marker scan\n'
fi

ensure_tool "redress" "redress"
printf '=== redress info ===\n'
redress info "$BIN"

printf '=== redress packages ===\n'
redress packages "$BIN"

ensure_tool "goresym" "GoReSym"
printf '=== GoReSym (first 60 lines) ===\n'
GoReSym "$BIN" | sed -n '1,60p'
