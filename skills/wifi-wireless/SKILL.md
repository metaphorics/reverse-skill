---
name: wifi-wireless
description: Use for authorized wireless security assessment including Wi-Fi capture, WPA handshake analysis, rogue AP detection research, and lab-only deauth testing.
---

# Wi-Fi / Wireless Security

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Read precedent-pentest. **Wireless attacks carry high legal risk.** You must have written authorization and a physical scope
2. `NOW`: The scope states the target SSID/BSSID/site. Do not scan neighbor networks
3. `NEXT`: Confirm the adapter monitor-mode capability
4. `ACT`: reconnaissance → capture → analysis (lab first)

## Use cases

- Authorized Wi-Fi security assessment
- WPA/WPA2 handshake capture and offline evaluation
- Rogue AP / evil-twin hotspot detection research
- Enterprise wireless isolation and captive-portal security

## Workflow

```text
□ iwconfig / airmon-ng to enter monitor mode (legal environment)
□ airodump-ng to lock the target BSSID channel
□ Handshake or PMKID capture (target only)
□ hashcat/aircrack to evaluate password policy offline
□ Report: encryption type, isolation, portal bypass, recommendations
```

## Toolchain

| Tool | Use |
|------|------|
| aircrack-ng suite | Capture/evaluation |
| hcxdumptool / hcxtools | PMKID |
| hashcat | Password evaluation |
| Wireshark | Management-frame analysis |

## References

- `references/wireless-lab-rules.md`
- `../pentest-tools/` `../attack-chain/` (close-range section)

## Routing context

**Upstream**: MASTER R29
**MUST NOT**: Deauth without authorization; operate against non-target customer networks

## Completion self-check

- [ ] Target BSSID is strictly locked
- [ ] The report includes hardening recommendations
- [ ] Checklist read
