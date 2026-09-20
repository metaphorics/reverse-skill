# 2026-06-29 burp-mcp-full full test and repair

## Scenario

BurpSuite extension development and testing

## Target summary

Run a full runtime availability test of the burp-mcp-full extension (Burp Suite Professional MCP Full Control, 63 tools). Found and fixed 3 bugs and 1 bridge-layer race condition.

## Execution record

1. Static validation: check that the Java dispatch table, `getToolList()`, and bridge `buildToolDefinitions` contain the same 63 tools.
2. Build: use `build.bat` to package the fat JAR automatically (JDK 21, montoya-api 2025.5, gson 2.11.0, nanohttpd 2.3.1).
3. Load: load the extension in Burp Suite Professional 2026.4.2 and confirm `[MCP] Server started`.
4. Runtime test: call `127.0.0.1:9876` directly with a Node HTTP client in five batches:
   - Batch 1: 30 read-only, codec, and query tools with no side effects
   - Batch 2: network send tools (`send_request` / `repeater` / `intruder`) against scanme.nmap.org
   - Batch 3: 7 Intruder variants (`attack`/`async`/`wordlist`/`pitchfork`/`cluster_bomb`/`battering_ram`/`with_options`) with a small enumeration
   - Batch 4: scope, configuration, rule, handler, `add_issue`, and `compare`
   - Batch 5: `crawl` plus `proxy_clear`
5. Find and fix 3 bugs. Regression validation passes.

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| `scan()` always reports request_count 0 | `AuditConfiguration` does not accept a seed URL, and the code omitted `addRequest` | Parse the host, port, and path from the URL. Build a GET `HttpRequest` and pass it to `activeAudit.addRequest()` | 2 hours, including validation |
| `send_to_intruder()` reports `HttpRequest must have an HttpService` | `HttpRequest.httpRequest(raw)` uses an overload without a service | Add `buildRequestWithService()`. Parse host, port, and HTTPS from the Host header with a regex. Build an `HttpService`, then call `httpRequest(HttpService, raw)` | 20 minutes |
| `set_upstream_proxy()` throws a null-pointer NPE when a parameter is missing | `params.get("proxy_host")` returns null, then `.getAsString()` throws the NPE | Check for null. If `params.has("proxy_host")` is false, return a clear error | 5 minutes |
| mcp-bridge.js async race: the fourth of four rapid requests loses its response | `process.exit(0)` on stdin close kills unfinished HTTP requests | Add a pending counter and `stdinClosed` flag. Exit only after all requests finish | 1 hour, including mock tests |
| curl `HTTP_CODE=000` cannot probe the port | The sandbox blocks curl on the local host | Use the Node HTTP module for the probe | 5 minutes |
| Wrong Montoya API Audit package path | Online Javadoc suggested that Audit was under the scanner package | Decompile the real montoya-api-2025.5.jar with `javap`. Confirm that Audit is under the scanner.audit package | 30 minutes |
| File encoding caused Edit matching to fail | UTF-8 with BOM Chinese content displayed in the terminal with the wrong encoding layer | Use Python replacement with `utf-8-sig` | 10 minutes |

## Tool findings

- In montoya-api 2025.5, Audit is `burp.api.montoya.scanner.audit.Audit`, not `scanner.Audit`.
- The `AuditConfiguration` factory does not accept a seed URL. Add the seed with `Audit.addRequest(HttpRequest)`.
- `HttpRequest.httpRequest(raw)` without a service works for Repeater, but Intruder requires an `HttpService`.
- `Intruder.sendToIntruder(HttpRequest)` requires a request with an attached service.
- `api.burpSuite().version()` methods `major()`, `minor()`, and `build()` changed from deprecated to removed in 2025.5. Use `buildNumber()`, `edition()`, or `toString()` instead.
- `send_request` uses `http.sendRequest()` and does not enter proxy history.
- The local sandbox blocks curl. Use Node HTTP for probes.
- The IDA MCP port is not fixed at 13337. It increments between instances. The Burp MCP port is configurable through a system property or environment variable and remains fixed for the instance.

## Key code and commands

### Full test script pattern
```javascript
const http = require('http');
function call(tool, params={}, timeoutMs=30000) {
  return new Promise((resolve) => {
    const body = JSON.stringify({tool, params});
    const req = http.request({hostname:'127.0.0.1',port:9876,path:'/',method:'POST',
      headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(body)}}, (res)=>{
      let d=''; res.on('data',c=>d+=c); res.on('end',()=>{ try{resolve(JSON.parse(d));}catch(e){resolve({__raw:d.slice(0,200)});} });
    });
    req.on('error', e => resolve({__err: e.message}));
    req.on('timeout', () => { req.destroy(); resolve({__timeout:true}); });
    req.setTimeout(timeoutMs);
    req.write(body); req.end();
  });
}
```

### buildRequestWithService (core repair)
```java
private HttpRequest buildRequestWithService(String rawRequest) {
    java.util.regex.Matcher m = java.util.regex.Pattern.compile(
            "(?im)^Host:\\s*([^:\r\n]+)(?::(\\d+))?\\s*$").matcher(rawRequest);
    if (!m.find()) return HttpRequest.httpRequest(rawRequest);
    String host = m.group(1).trim();
    boolean isHttps = rawRequest.contains("https://") || rawRequest.contains(":443");
    int port = m.group(2) != null ? Integer.parseInt(m.group(2))
              : (isHttps ? 443 : 80);
    HttpService svc = HttpService.httpService(host, port, isHttps);
    return HttpRequest.httpRequest(svc, rawRequest);
}
```

### Bridge-layer race repair (mcp-bridge.js)
```javascript
let pending = 0;
let stdinClosed = false;
rl.on('line', async (line) => { ... pending++; ... finally { pending--; if (stdinClosed && pending === 0) process.exit(0); } });
rl.on('close', () => { stdinClosed = true; if (pending === 0) process.exit(0); });
```

### scan() seed repair
```java
// Build a GET seed request from the URL and pass it to audit
java.net.URL u = new java.net.URL(url);
String host = u.getHost();
boolean isHttps = "https".equalsIgnoreCase(u.getProtocol());
int port = u.getPort() > 0 ? u.getPort() : (isHttps ? 443 : 80);
String path = (u.getPath() == null || u.getPath().isEmpty()) ? "/" : u.getPath();
String pathQuery = u.getQuery() != null ? path + "?" + u.getQuery() : path;
HttpService svc = HttpService.httpService(host, port, isHttps);
HttpRequest seedReq = HttpRequest.httpRequest(svc,
    "GET " + pathQuery + " HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n");
activeAudit.addRequest(seedReq);
```

## Improvement suggestions for this package

- The routing matrix already covers BurpSuite MCP. No change is needed.
- `burpsuite-mcp-guide.md` now has a changelog entry with the 3 repairs, bridge repair, and full validation result.
- The tool table now includes the Scanner `scan` mode parameter and the Intruder `send_to_intruder` Host header requirement.
- No bootstrap entry is needed. The `build.bat` compilation script is self-contained.
- The IDA MCP port is not fixed. Record this in the MCP service management table.

## Reusable patterns and script fragments

- The 63-tool availability test pattern above applies to regression tests for any HTTP-based MCP extension.
- The `buildRequestWithService` pattern parses an HttpService from a Host header. Use it wherever the Montoya API builds an `HttpRequest` and `HttpService` from a raw request.

## Follow-up actions

- [x] Update the routing matrix. The route was already covered.
- [ ] Update the tool index. It uses `.template`, so no update is needed.
- [ ] Update the bootstrap manifest. No new tool was added.
- [x] Update the child skill documentation. Add the changelog entry to `burpsuite-mcp-guide.md`.
- [x] Add the pitfall record. This entry is the record.
- [ ] No update needed

## Environment

- OS: Windows 11 Pro for Workstations 10.0.26200
- Tool versions: JDK 21.0.11+10 / Burp Suite Professional 2026.4.2 (20260402000047704)
- Target platform: montoya-api 2025.5 / gson 2.11.0 / nanohttpd 2.3.1
- Test target: scanme.nmap.org (authorized test site)

## Redaction requirements

The target is the public scanme.nmap.org test site. No redaction is needed. The record contains no real domain, IP, token, or username.

## Index synchronization (last step before commit)

After writing this journal, update `_index.md`:

1. Add one line to the matching scenario category with the date and keywords.
2. Update the cumulative count and the "last updated" date.

---
<!-- [Community contribution] Ask the user whether to open a PR against the main repository after completion. See CONTRIBUTE-BACK.md for the process. -->
