---
name: api-security
description: Use for authorized security assessment of REST, GraphQL, WebSocket, or SOAP APIs, including discovery, authentication, authorization, rate-limit, and CI/CD testing.
---
# API Security Testing

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md`. Confirm that this skill's operations are routine and authorized.
2. `NOW`: Confirm that the current task is in scope for this skill.
3. `NEXT`: Read `../tool-index.md`. Verify tool availability and actual paths.
4. `NEXT`: If a tool is missing, call bootstrap. Do not guess paths.
5. `ACT`: Start at step 1 of the workflow and execute. Do not stop at confirmation.

> Covers all protocols: REST, GraphQL, WebSocket, SOAP.
> A 10-phase methodology, from discovery to CI/CD integration.

## Applicable Scenarios

- REST API security testing (OpenAPI/Swagger driven or blind)
- GraphQL security audit (introspection, batch queries, alias overload)
- WebSocket security testing
- JWT / OAuth 2.0 authentication testing
- BOLA/IDOR/BFLA broken access control detection
- API rate-limit bypass and DoS testing

## 10-Phase Test Workflow

### Phase 1: API Discovery and Reconnaissance

```text
Active discovery:
□ Vespasian: crawl with a headless browser → auto-generate an OpenAPI 3.0 / GraphQL SDL spec
□ Entropy --discover: extract endpoints from robots.txt + JS files
□ Kiterunner / ffuf: brute-force undocumented endpoint paths
□ Check common paths: /swagger.json, /openapi.json, /graphql, /api-docs

GraphQL introspection (three attempts in order):
  1. Standard introspection query
  2. Condensed query (bypasses a full WAF block)
  3. __schema { types { name } } only (minimal probe)
```

### Phase 2: Authentication Testing

```text
JWT analysis (jwt_tool / Burp):
□ alg:none attack: change the header to "alg":"none" and clear the signature
□ Key confusion: RS256 public key → HS256 symmetric key
□ Weak HMAC key brute force: jwt_tool -C -d wordlist.txt
□ Expired or tampered claims: modify exp/iat/sub/role claims
□ kid injection: ../../etc/passwd → HMAC signature bypass

OAuth 2.0:
□ redirect_uri manipulation → authorization code leak
□ CSRF through a missing state parameter
□ Token leak in the Referer header
□ Missing PKCE detection

GraphQL authentication:
□ Authentication bypass for mutations through GET requests (CSRF)
□ Authentication bypass through batch queries
```

### Phase 3: Authorization Testing (BOLA/IDOR/BFLA)

```text
BOLA (broken object-level authorization):
□ Iterate numeric IDs: /user/1 → /user/2 → /user/3
□ Iterate UUIDs
□ Iterate usernames or email addresses
□ Burp Autorize: two-session replay comparison

BFLA (broken function-level authorization):
□ Ordinary user calls an admin API
□ HTTP method switch: GET → PUT → PATCH → DELETE
□ API version downgrade: /v2/admin → /v1/admin
□ Bulk operation injection: {"users": [1,2,3]} → {"users": [1,2,3,admin_id]}

Tools: Burp Autorize, AuthMatrix, Entropy (malicious_insider persona)
```

### Phase 4: GraphQL Specialization

```text
Introspection leak → information exposure
Alias overload → 100+ alias DoS
Batch queries → 10+ concurrent query DoS
Field duplication → __typename × 500
Directive overload → recursive @skip/@include
Circular query → deeply nested introspection recursion
Field suggestions → information leak in error messages
GraphiQL/Playground exposure → publicly reachable IDE
GET mutation → CSRF risk
Tracing/debug mode → metadata leak

Tools: FireTail, Escape DAST, api.sh (Phases 1-3)
```

### Phase 5: REST Input Validation

```text
□ HTTP method switch: GET→POST→PUT→DELETE→OPTIONS→PATCH
□ Content-Type tampering: JSON→XML→multipart
□ NoSQL injection: {"username": {"$gt": ""}}
□ SSRF through URL parameters: webhook URL / avatar URL / import URL
□ XXE in XML endpoints
□ Parameter pollution: /api?role=user&role=admin
□ Mass assignment: add is_admin: true to the request body
```

### Phase 6: Business Logic and Differential Testing

```text
□ Entropy compare: diff v1 vs v2 API → status code changes / removed fields / latency regressions
□ Multi-role workflow test: admin/user/readonly permission matrix
□ Coupon / points / price manipulation
□ Race conditions: send concurrent requests to test TOCTOU
```

### Phase 7: WebSocket Testing

```text
□ Endpoint discovery
□ Message injection (injected payloads, prototype pollution)
□ Oversized message handling
□ Type confusion
□ Cross-site WebSocket hijacking (CSWH)
```

### Phase 8: Rate Limits and DoS

```text
□ Rate-limit bypass through headers: X-Forwarded-For, X-Real-IP
□ Path variants: /api/ → /api → /Api/ → /API/
□ Slowloris low-bandwidth exhaustion
□ GraphQL batch query deeply nested DoS
□ IP rotation test (ProxyCat proxy pool)
```

### Phase 9: Data Exposure

```text
□ Over-exposed responses: compare the API return with the UI display
□ Pagination enumeration: ?page=1&limit=10000
□ Information leak in error messages: stack traces / internal paths / SQL errors
□ GraphQL nested traversal to reach unauthorized data
□ OpenAPI spec exposes sensitive endpoints
```

### Phase 10: CI/CD Integration

```text
□ Entropy --ci --watch: auto-rerun when the spec changes
□ Escape DAST: block the build automatically at a severity threshold
□ Persist findings as regression tests
□ StackHawk (developer-first, ZAP core)
```

## Toolchain

| Tool | Purpose | Source |
|------|---------|--------|
| Vespasian | Traffic → OpenAPI/GraphQL spec | GitHub: praetorian-inc/vespasian |
| Entropy | LLM-generated attack scenarios, 5 personas | GitHub: arjinexe/entropy-chaos |
| Escape DAST | Business-logic security testing | escape.tech |
| api.sh | 8-phase all-protocol attack pipeline | GitHub: Sharon-Needles/api |
| FireTail | 12 GraphQL-specific tests | firetail.ai |
| jwt_tool | Full JWT testing | GitHub: ticarpi/jwt_tool |
| Burp Autorize | Two-session authorization comparison | Burp BApp Store |

## References

- `references/rest-graphql-testing.md` — REST + GraphQL deep testing
- `references/jwt-oauth-testing.md` — JWT + OAuth security testing


## Task Completion Self-Check (MUST pass before you claim completion)

- [ ] Did I execute every step of the workflow (not only read it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands / scripts / screenshots / report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
