#!/usr/bin/env bash
# quick-setup.sh — Kali 2026.1 one-step setup
# Run this script on a new Kali system to complete these steps:
#   1. Update the system
#   2. Install new Kali 2026.1 tools
#   3. Configure native Kali MCP
#   4. Install reverse-engineering tools not included by default
#   5. Refresh the tool index
#   6. Print the configuration report
#
# Usage:
#   sudo bash kali/scripts/quick-setup.sh [--skip-update] [--minimal]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Arguments ──────────────────────────────────────────────────────────────────────

SKIP_UPDATE=false
MINIMAL=false

for arg in "$@"; do
    case "$arg" in
        --skip-update) SKIP_UPDATE=true ;;
        --minimal) MINIMAL=true ;;
    esac
done

# ─── Colors ──────────────────────────────────────────────────────────────────────────

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

banner() { echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}\n"; }
ok() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
info() { echo -e "${CYAN}[i]${RESET} $*"; }

# ─── Check permissions ──────────────────────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash $0"
    exit 1
fi

# ─── Check Kali version ──────────────────────────────────────────────────────────────
banner "Check system version"

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    info "System: $PRETTY_NAME"
    info "Version: ${VERSION:-unknown}"
    info "Kernel: $(uname -r)"
else
    warn "Unable to detect the system version. Continuing..."
fi

# ─── System update ──────────────────────────────────────────────────────────────────

if [[ "$SKIP_UPDATE" != "true" ]]; then
    banner "System update"
    apt-get update -qq
    apt-get upgrade -y -qq
    ok "System updated"
else
    info "Skipped system update (--skip-update)"
fi

# ─── Install new Kali 2026.1 tools ──────────────────────────────────────────────────

banner "Install new Kali 2026.1 tools"

NEW_TOOLS_2026_1=(
    "adaptixc2"
    "atomic-operator"
    "fluxion"
    "gef"
    "metasploitmcp"
    "sstimap"
    "wpprobe"
    "xsstrike"
)

NEW_TOOLS_2025_4=(
    "evil-winrm-py"
    "hexstrike-ai"
)

for tool in "${NEW_TOOLS_2026_1[@]}" "${NEW_TOOLS_2025_4[@]}"; do
    if dpkg -l "$tool" &>/dev/null 2>&1; then
        ok "$tool installed"
    else
        info "Installing $tool ..."
        apt-get install -y -qq "$tool" 2>/dev/null && ok "$tool installed successfully" || warn "$tool installation failed (it may not be available in your configured repository)"
    fi
done

# ─── Install native Kali MCP ─────────────────────────────────────────────────────────
banner "Configure native Kali MCP"

MCP_TOOLS=("mcp-kali-server" "metasploitmcp" "hexstrike-ai")

for tool in "${MCP_TOOLS[@]}"; do
    if dpkg -l "$tool" &>/dev/null 2>&1; then
        ok "$tool installed"
    else
        info "Installing $tool ..."
        apt-get install -y -qq "$tool" 2>/dev/null && ok "$tool installed successfully" || warn "$tool installation failed"
    fi
done

# ─── Install AD/internal-network penetration tools ───────────────────────────────────

if [[ "$MINIMAL" != "true" ]]; then
    banner "Install AD/internal-network penetration tools"

    AD_TOOLS=("coercer" "netexec" "responder" "bloodhound" "certipy-ad")

    for tool in "${AD_TOOLS[@]}"; do
        if dpkg -l "$tool" &>/dev/null 2>&1; then
            ok "$tool installed"
        else
            info "Installing $tool ..."
            apt-get install -y -qq "$tool" 2>/dev/null && ok "$tool installed successfully" || warn "$tool installation failed"
        fi
    done
fi

# ─── Install reverse-engineering tools not included by default ───────────────────────

banner "Install reverse-engineering tools"

# jadx (not preinstalled in Kali. Download from GitHub)
if ! command -v jadx &>/dev/null; then
    info "Installing jadx (from GitHub Release) ..."
    bash "$SCRIPT_DIR/bootstrap-reverse.sh" jadx --skip-refresh 2>/dev/null && ok "jadx installed successfully" || warn "jadx installation failed"
else
    ok "jadx is available"
fi

# Node.js (required by some MCP servers)
if ! command -v node &>/dev/null; then
    info "Installing Node.js ..."
    apt-get install -y -qq nodejs npm && ok "Node.js installed successfully" || warn "Node.js installation failed"
else
    ok "Node.js is available: $(node -v)"
fi

# frida-tools
if ! command -v frida &>/dev/null; then
    info "Installing frida-tools ..."
    pip3 install --break-system-packages frida-tools 2>/dev/null && ok "frida-tools installed successfully" || warn "frida-tools installation failed"
else
    ok "frida is available"
fi

# ─── Configure MCP clients ──────────────────────────────────────────────────────────

banner "Configure MCP clients"

# Detect the actual user ($HOME may be /root under sudo)
REAL_USER="${SUDO_USER:-root}"
REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    REAL_USER="root"
    REAL_HOME="$(getent passwd root 2>/dev/null | cut -d: -f6 || true)"
fi
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    REAL_HOME="/root"
fi

MCP_CONFIG_DIR="$REAL_HOME/.claude"
MCP_CONFIG="$MCP_CONFIG_DIR/mcp.json"

if command -v jq &>/dev/null; then
    mkdir -p "$MCP_CONFIG_DIR"

    if [[ ! -f "$MCP_CONFIG" ]]; then
        echo '{"mcpServers":{}}' > "$MCP_CONFIG"
    fi

    # Register kali-server
    jq '.mcpServers["kali-server"] = {"command": "kali-server-mcp", "args": ["--port", "5000"]}' "$MCP_CONFIG" > /tmp/mcp-tmp.json && mv /tmp/mcp-tmp.json "$MCP_CONFIG"

    # Register metasploit-mcp
    jq '.mcpServers["metasploit-mcp"] = {"command": "metasploitmcp", "args": ["--transport", "stdio"]}' "$MCP_CONFIG" > /tmp/mcp-tmp.json && mv /tmp/mcp-tmp.json "$MCP_CONFIG"

    # Register hexstrike
    jq '.mcpServers["hexstrike"] = {"command": "hexstrike-ai", "args": []}' "$MCP_CONFIG" > /tmp/mcp-tmp.json && mv /tmp/mcp-tmp.json "$MCP_CONFIG"

    # Register jshook
    jq '.mcpServers["jshook"] = {"command": "npx", "args": ["-y", "@jshookmcp/jshook@0.3.4"], "env": {"JSHOOK_BASE_PROFILE": "search"}}' "$MCP_CONFIG" > /tmp/mcp-tmp.json && mv /tmp/mcp-tmp.json "$MCP_CONFIG"

    chown "$REAL_USER:$REAL_USER" "$MCP_CONFIG" "$MCP_CONFIG_DIR"
    ok "MCP configuration written to: $MCP_CONFIG"
else
    warn "jq is not installed. Cannot configure MCP automatically. Copy kali/mcp-kali-example.json manually"
    info "Install jq: apt install jq"
fi

# ─── Refresh tool index ──────────────────────────────────────────────────────────────

banner "Refresh tool index"

chmod +x "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh
sudo -u "$REAL_USER" bash "$SCRIPT_DIR/refresh-tool-index.sh" 2>/dev/null || bash "$SCRIPT_DIR/refresh-tool-index.sh"
ok "Tool index refreshed"

# ─── Print report ───────────────────────────────────────────────────────────────────

banner "Setup complete"
echo -e "${BOLD}✅ Kali 2026.1 reverse-skill routing package is configured${RESET}"
echo ""
echo "  Installation path: $(cd "$SCRIPT_DIR/../.." && pwd)"
echo "  MCP configuration: $MCP_CONFIG"
echo "  Tool index: $(cd "$SCRIPT_DIR/../.." && pwd)/skills/tool-index.md"
echo ""
echo "  Native Kali MCP:"
command -v kali-server-mcp &>/dev/null && echo "    ✓ mcp-kali-server" || echo "    ✗ mcp-kali-server"
command -v metasploitmcp &>/dev/null && echo "    ✓ metasploitmcp" || echo "    ✗ metasploitmcp"
command -v hexstrike-ai &>/dev/null && echo "    ✓ hexstrike-ai" || echo "    ✗ hexstrike-ai"
echo ""
echo "  New tools in 2026.1:"
for tool in "${NEW_TOOLS_2026_1[@]}"; do
    if dpkg -l "$tool" &>/dev/null 2>&1; then
        echo "    ✓ $tool"
    else
        echo "    ✗ $tool"
    fi
done
echo ""
echo "  Next steps:"
echo "    1. Tell your AI client to read kali/RULES-kali.md"
echo "    2. Or ask your AI: 'Read kali/RULES-kali.md and apply the configuration'"
echo "    3. Security and reverse-engineering tasks route automatically afterward"
echo ""
