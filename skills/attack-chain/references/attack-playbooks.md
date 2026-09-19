# Attack-chain playbook quick reference

> Select a playbook by target type. Each playbook defines the standard path from initial access to the objective.

---

## Playbook 1: External Web application → domain controller

```
1. Enumerate subdomains + scan ports
2. Identify the Web fingerprint → find components with known vulnerabilities
3. Exploit the vulnerability to obtain a Webshell / RCE
4. Perform internal-network reconnaissance (ipconfig/ifconfig, arp, net user)
5. Set up tunneling (frp/chisel/ssh)
6. Scan the internal network (live hosts, open ports)
7. Obtain credentials (mimikatz/hashdump/configuration files)
8. Perform lateral movement (PTH/WMI/PsExec)
9. Collect domain information (BloodHound)
10. Escalate domain privileges (Kerberoasting/DCSync/constrained delegation)
11. Obtain domain-controller privileges
```

**Key tool chain**: subfinder → httpx → nuclei → sqlmap/sstimap → frp → nmap → mimikatz → crackmapexec → bloodhound → certipy

---

## Playbook 2: Phishing → internal-network penetration

```
1. Collect target employee information (LinkedIn/Maimai)
2. Craft a phishing email (spoofed sender/legitimate subject)
3. Create a payload (macro document/LNK/ISO/HTML smuggling)
4. Send the phishing email
5. Wait for a callback (C2 beacon)
6. Perform local reconnaissance + privilege escalation
7. Extract credentials
8. Perform lateral movement
9. Establish persistence
10. Reach the objective
```

**Key tool chain**: theHarvester → gophish → msfvenom/cobalt-strike → mimikatz → bloodhound

---

## Playbook 3: Physical-access penetration → internal network

```
1. Perform physical reconnaissance (WiFi signal, access-control type, USB port)
2. Attack WiFi (Fluxion rogue access point / WPA cracking)
   Or deploy BadUSB (Rubber Ducky keyboard injection)
   Or deploy a network implant (Raspberry Pi / LAN Turtle)
3. Obtain an internal-network access point
4. Scan the internal network
5. Continue with steps 5-11 in Playbook 1
```

**Key tool chain**: fluxion/aircrack-ng → rubber-ducky → frp → nmap → crackmapexec

---

## Playbook 4: Cloud penetration testing

```
1. Discover cloud assets (subdomain → CNAME → cloud provider)
2. Enumerate storage buckets (public S3/OSS/Blob access)
3. SSRF → cloud metadata (169.254.169.254)
4. Obtain temporary credentials (AK/SK/Token)
5. Enumerate cloud APIs (IAM/EC2/Lambda/RDS)
6. Escalate privileges (PassRole/AssumeRole)
7. Perform lateral movement (across accounts/regions)
8. Access data
```

**Key tool chain**: subfinder → nuclei(ssrf) → aws-cli → pacu → ScoutSuite

---

## Playbook 5: Bug Bounty / SRC rapid checks

```
1. Perform asset reconnaissance (subdomains + ports + JS files)
2. Identify fingerprints → quickly validate known vulnerabilities (nuclei)
3. Discover parameters (arjun/paramspider)
4. Test each class:
   - IDOR/broken access control (change ID/change role)
   - SSRF (probe the internal network/cloud metadata)
   - SQL injection (sqlmap)
   - XSS (xsstrike)
   - File upload (bypass detection)
   - Business-logic vulnerabilities (payment/CAPTCHA/password reset)
5. Write the PoC + submit the report
```

**Key tool chain**: subfinder → httpx → nuclei → arjun → sqlmap → xsstrike → burpsuite

---

## Playbook 6: AD CS certificate attack

```
1. Find AD CS services (certipy find)
2. Identify vulnerable templates (ESC1-ESC8)
3. Request a malicious certificate
4. Authenticate as the target user with the certificate
5. Obtain the NTLM hash or TGT
6. Use DCSync to dump all credentials
```

**Key tool chain**: certipy → rubeus → mimikatz → secretsdump

---

## General decision matrix

| Current state | Next priority |
|---------------|---------------|
| Target domain only | Subdomain enumeration → port scan → Web fingerprinting |
| Web vulnerability found | Obtain shell → internal-network reconnaissance |
| Low-privilege shell available | Privilege escalation → credential theft |
| One internal-network host available | Set up tunneling → internal-network scan → lateral movement |
| Domain user credentials available | BloodHound → find attack paths |
| Domain admin hash available | DCSync → Golden Ticket |
| Cloud AK/SK available | Enumerate privileges → privilege escalation → data access |
| Phishing callback received | Local privilege escalation → credentials → lateral movement |
| Physical-access entry available | Internal-network scan → same as above |
