# BurpSuite MCP Full Control Extension

Full control of all core BurpSuite functions through the MCP protocol. Supports Windows / Linux (Kali) / macOS.

## Quick Start

### 1. Build the extension

**Windows**:
```cmd
cd burp-mcp-full
build.bat
```

**Linux / Kali / macOS**:
```bash
cd burp-mcp-full
chmod +x build.sh
./build.sh
```

The build script automatically detects JDK 21+, downloads dependencies (montoya-api 2025.5 / gson / nanohttpd), compiles the extension, adds the extension descriptor (`META-INF/extensions/burp-extension.properties`) to the jar, and packages a fat jar. Gradle is not required.

Output: `build/libs/burp-mcp-full.jar`.

### 2. Load the extension into Burp

```
Burp Suite → Extensions → Add → Java → Select build/libs/burp-mcp-full.jar
```

After loading, look for this message in Output:
```
[MCP] Server started on http://127.0.0.1:9876
```

### 3. Authentication (enabled by default since v2)

When the extension starts, it generates a random token and writes it to `~/.burp-mcp-token`. `mcp-bridge.js` reads this file automatically and sends an `Authorization: Bearer <token>` header with every request. No manual configuration is required.

When you need a fixed token, such as when several clients share one token, use:
- JVM parameter: `-Dburp.mcp.token=<token>`
- Environment variable: `BURP_MCP_TOKEN=<token>` (also used by the bridge)

All `/health`, `/tools`, and `/` (POST) requests require this header. Requests without it return 403. CORS allows only the `http://127.0.0.1` origin.

### 4. Configure the MCP client

Add the following stdio configuration to any MCP client (Claude Code / Kiro / Cursor / Cline / Windsurf):

```json
{
  "mcpServers": {
    "burpsuite": {
      "command": "node",
      "args": ["<path-to-this-directory>/mcp-bridge.js"]
    }
  }
}
```

### 5. Start using the extension

Tell the AI: "Analyze requests in Burp proxy history and find security vulnerabilities"

## Feature List

The extension exposes 78 tools. Common categories are listed below. See `getToolList()` in `src/main/java/com/burpmcp/McpHttpServer.java` for the full list, or access `GET http://127.0.0.1:9876/tools` with an Authorization header:

| Category | Tools |
|------|------|
| Proxy history | `proxy_history`, `proxy_detail`, `proxy_history_filtered`, `proxy_websocket`, `proxy_clear`, `search_history`, `highlight`, `annotate`, `compare` |
| Send requests | `send_request`, `send_to_repeater`, `repeater_send`, `repeater_modify_send`, `send_to_intruder` |
| Intruder attacks | `intruder_attack`, `intruder_attack_async`, `intruder_attack_wordlist`, `intruder_pitchfork`, `intruder_cluster_bomb`, `intruder_battering_ram`, `intruder_with_options`, `payload_process` |
| Scanning / crawling | `scan` (active/passive), `scan_active`, `scan_results`, `scan_issue_detail`, `crawl`, `sequencer` |
| Scope / Sitemap | `sitemap`, `target_info`, `get_scope`, `add_to_scope`, `remove_from_scope`, `add_issue` |
| Interception / rules | `intercept_toggle`, `register_http_handler`, `remove_http_handler`, `register_proxy_rule`, `remove_proxy_rule` |
| Encoding / decoding | `encode`, `decode`, `convert_request`, `export_request`, `generate_csrf_poc`, `extract_from_response`, `token_analysis` |
| Collaborator | `collaborator_generate`, `collaborator_poll` |
| Configuration | `export_config`, `import_config`, `set_upstream_proxy`, `set_dns_override`, `set_http2`, `cookie_jar`, `save_project`, `burp_version`, `extensions_list`, `log` |

> Scanning and crawling (`scan`, `scan_active`, `crawl`) require **Burp Professional**. Community Edition returns a clear license error. Manually added issues (`add_issue`) are written to the Site map.

## Key Tool Parameters

### `intruder_attack` — Automated enumeration attack

| Parameter | Description |
|------|------|
| `url_template` | URL template. The default placeholder is `@@`. |
| `placeholder` | Placeholder string. The default is `@@`. |
| `from` / `to` | Enumeration start and end values. |
| `pad_digits` | Number of zero-padding digits. `0` disables padding. |
| `method` | HTTP method. The default is `GET`. |
| `body_template` | Request body template with a placeholder. |
| `headers` | Request header object. |
| `success_length_not` | Match condition: the response length differs from this value. |
| `success_contains` | Match condition: the response body contains this string. |

### `scan` — Start an audit

| Parameter | Description |
|------|------|
| `url` | Target URL. Required. The URL is added to scope automatically. |
| `mode` | `active` (default) or `passive`. |

After starting a scan, use `scan_results` to poll issues and active audit status, including request count, error count, and insertion-point count.

### `register_proxy_rule` — Proxy request interception rule

| Parameter | Description |
|------|------|
| `url_contains` | Match condition: the URL contains this string. |
| `intercept` | `true` intercepts requests. `false` allows requests without interception. The default is `true`. |

Use `remove_proxy_rule` to unregister the rule. It uses `Registration.deregister()` to remove the rule from Burp.

## Examples

### View proxy history
```json
POST http://127.0.0.1:9876
{"tool": "proxy_history", "params": {"limit": 10, "url_filter": "personalblog"}}
```

### Send a request
```json
POST http://127.0.0.1:9876
{"tool": "send_request", "params": {"method": "GET", "url": "https://example.com/api/test"}}
```

### Automated enumeration attack (core feature)
```json
POST http://127.0.0.1:9876
{
  "tool": "intruder_attack",
  "params": {
    "url_template": "https://target.com/api/verify?code=@@",
    "method": "POST",
    "from": 0,
    "to": 999999,
    "pad_digits": 6,
    "success_length_not": 176,
    "headers": {"User-Agent": "Mozilla/5.0"}
  }
}
```

### Toggle interception
```json
POST http://127.0.0.1:9876
{"tool": "intercept_toggle", "params": {"enable": false}}
```

## Port Configuration

The default listener is `127.0.0.1:9876`. To change it, for example when it conflicts with the official PortSwigger MCP extension on the same port:

1. **Burp side**: Pass the JVM parameter `-Dburp.mcp.port=9877` when starting Burp, or set the `BURP_MCP_PORT=9877` environment variable.
2. **Bridge side**: Set `BURP_MCP_PORT=9877` and `BURP_MCP_HOST=127.0.0.1` in the MCP client configuration.

The two port settings must match. If Burp is not running or the port is unreachable, the bridge returns clear connection-error guidance for `tools/list` and `tools/call`.

## Troubleshooting

| Symptom | Troubleshooting |
|------|------|
| Burp Output does not show "[MCP] Server started" | The port may be in use or the extension may have failed to load. Check the Burp Errors panel. |
| The MCP client reports "Burp MCP not connected" | Confirm that Burp is running and the extension is loaded. Confirm that both port settings match. |
| A scan returns "requires Burp Professional" | This is expected. Community Edition does not support the Scanner API. |
| `remove_http_handler` / `remove_proxy_rule` has no effect | Confirm that the earlier `register_*` call returned `success=true`. |

## Source Build (Optional Gradle)

```bash
cd burp-mcp-full
gradle jar      # Gradle 8.7+ must be installed locally
# Output: build/libs/burp-mcp-full.jar
```

> We recommend `build.bat` / `build.sh`. These scripts have no dependencies and download the jars automatically. The Gradle path is a fallback only.
