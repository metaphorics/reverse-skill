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

# Kali-only bootstrap serves Linux-only release assets; macOS and generic
# Linux must use the Linux/macOS bootstrap's manual-install path instead.
# Mirrors is_kali in skills/scripts/bootstrap-reverse.sh.
is_kali() {
    [[ -f /etc/os-release ]] || return 1
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            ID_LIKE=*|id_like=*) continue ;;
            ID=*|id=*)
                case "$line" in
                    *[Kk][Aa][Ll][Ii]*) return 0 ;;
                esac
                ;;
        esac
    done < /etc/os-release
    return 1
}

# Capability names for bootstrap; the runtime executable may differ (alias exes).
ensure_tool() {
    local name="$1"
    local exe="${2:-$1}"
    if command -v "$exe" &>/dev/null; then
        return 0
    fi
    printf 'INFO: Cannot find %s. Trying automatic installation...\n' "$exe" >&2
    # Scripts are invoked via bash, so test readability, not the exec bit (tracked 100644).
    if [[ -f "$KALI_BOOTSTRAP" ]] && is_kali; then
        bash "$KALI_BOOTSTRAP" "$name" --skip-refresh 2>/dev/null || true
    elif [[ -f "$LINUX_BOOTSTRAP" ]]; then
        bash "$LINUX_BOOTSTRAP" "$name" 2>/dev/null || true
    fi
    # Bootstrap runs in a child shell, so its PATH changes are lost here.
    # Re-adopt the tool from the known install locations before the recheck.
    local tools_root="${REVERSE_SKILL_TOOLS_DIR:-$HOME/tools}"
    local dir pkgdir
    for dir in "$tools_root" "$tools_root/bin"; do
        pkgdir="$dir/$name"
        if [[ -d "$pkgdir" ]]; then
            case ":$PATH:" in
                *":$pkgdir:"*) ;;
                *) PATH="$pkgdir:$PATH" ;;
            esac
        fi
        if [[ -d "$pkgdir/bin" ]]; then
            case ":$PATH:" in
                *":$pkgdir/bin:"*) ;;
                *) PATH="$pkgdir/bin:$PATH" ;;
            esac
        fi
    done
    export PATH
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

# awk consumes the full stream; an early-output filter could SIGPIPE
# the producer under pipefail.
printf '=== runtime markers ===\n'
markers=""
if command -v strings &>/dev/null; then
    markers=$(strings "$BIN" | grep -E 'go\.buildid|runtime\.main|rust_begin_unwind' || true)
    if [[ -n "$markers" ]]; then
        printf '%s\n' "$markers" | awk 'NR<=5'
    else
        printf 'no go.buildid / runtime.main / rust_begin_unwind markers\n'
    fi
else
    printf 'strings: not installed, skipping marker scan\n'
fi

# Classify the runtime from the markers collected above before touching the
# Go-only tools. redress and GoReSym parse Go build metadata and misreport
# Rust binaries, so run them only for non-Rust inputs; a stripped binary with
# no markers falls through to the Go tools. Go markers win over the
# rust_begin_unwind string when both are present.
is_rust=0
if [[ "$markers" == *rust_begin_unwind* ]]; then
    is_rust=1
fi
if [[ "$markers" == *go.buildid* || "$markers" == *runtime.main* ]]; then
    is_rust=0
fi

if [[ "$is_rust" -eq 0 ]]; then
    ensure_tool "redress" "redress"
    printf '=== redress info ===\n'
    redress info "$BIN"

    printf '=== redress packages ===\n'
    redress packages --std --vendor "$BIN"

    ensure_tool "goresym" "GoReSym"
    # awk consumes the full stream; an early-output filter could SIGPIPE
    # under pipefail once GoReSym emits more than 60 lines.
    printf '=== GoReSym (first 60 lines) ===\n'
    GoReSym "$BIN" | awk 'NR<=60'
else
    printf 'INFO: skipping redress/GoReSym: Rust runtime detected, Go-only tools not applicable\n' >&2
fi
