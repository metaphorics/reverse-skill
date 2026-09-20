# [Seed] Web API unauthorized access + IDOR

## Scenario category
Penetration testing

## Goal summary
Black-box test a Web application REST API and find unauthorized access and IDOR vulnerabilities.

## Full execution path

1. Reconnaissance: scan with Nmap → find Nginx on port 443 and a backend API.
2. Directory discovery: fuzz with FFUF → find the `/api/v1/` path.
3. API enumeration: open `/api/v1/docs` → find exposed Swagger documentation.
4. Authentication analysis: register two test accounts, A and B.
5. Test IDOR: use account A's token to access account B's resource → success (horizontal broken access control).
6. Test unauthorized access: remove the Authorization header → some endpoints still return data.
7. Verify impact: confirm that the API can read any user's personal information (name, email, and phone number).
8. Collect evidence: save request and response screenshots, redact them, and prepare the report.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| FFUF was blocked by the WAF | The request rate triggered throttling | Lower the rate with `-rate 10` and add `-H "User-Agent: Mozilla/5.0..."` | 10min |
| Swagger documentation returned 404 | The path was not the standard `/swagger` | Try `/api/v1/docs`, `/api-docs`, and `/openapi.json` | 5min |
| IDOR test success was unclear | The response had no clear user identifier | Compare responses from both accounts and find the `user_id` difference | 15min |
| The SRC rejected the report | It included only screenshots and no full reproduction steps | Add the curl command and the complete request and response | 20min |

## Toolchain findings

- FFUF is faster than Gobuster, but control the rate to avoid a block.
- Exposed Swagger/OpenAPI documentation is a fast way to enumerate an API.
- Test IDOR with two accounts that you own. Do not access another person's data.
- An SRC report needs a reproducible curl command, not only screenshots.

## Key code / commands

```bash
# Directory discovery
ffuf -u https://target.example.com/api/v1/FUZZ -w /path/to/SecLists/Discovery/Web-Content/api/api-endpoints.txt -rate 10

# IDOR test
# Use account A's token to access account B's resource
curl -H "Authorization: Bearer <token_A>" https://target.example.com/api/v1/users/USER_B_ID

# Unauthorized-access test
curl https://target.example.com/api/v1/users/USER_B_ID
# If the response is 200 with data → unauthorized access
```

## Improvement suggestions for this package

- Add a dedicated API penetration-testing checklist to pentest-tools.
- The src-hunter IDOR playbook is useful, but it lacks guidance on judging IDOR impact scope.

## Reusable patterns / script fragments

**Three-step unauthorized API test**:
```text
1. Send a normal request with a token → record the normal response
2. Remove the token → check whether the API still returns data (unauthorized access)
3. Replace the token with another user's token → check whether the API allows access (broken access control)
```

**Quick IDOR verification**:
```text
1. Register two accounts, A and B
2. Get a resource ID for A and a resource ID for B
3. Use A's token to request B's resource ID
4. If the response contains B's data → confirm IDOR
```

## Evolution actions
- [ ] No update needed for the routing matrix
- [ ] No update needed for the bootstrap manifest
- [ ] No update needed for child skill documentation

## Environment information
- OS: Windows (local) → target Linux server
- Tool versions: FFUF 2.x, curl, Burp Suite
- Target platform: Web API (REST, JSON)

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real target.

---
<!-- [Community contribution] Seed data. No PR needed. -->
