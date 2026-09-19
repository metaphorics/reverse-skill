---
name: radio-sdr
description: Use for authorized RF/SDR security research including signal identification, replay feasibility study in shielded labs, and wireless protocol analysis outside classic Wi-Fi.
---

# RF / SDR Security Research

## ACTION REQUIRED (execute right after reading)

1. `NOW`: **Spectrum use and transmissions are strictly regulated by law.** Use only authorized bands, shielded rooms, and laboratory targets
2. `NOW`: The scope states the devices, the bands, and whether transmission is allowed (receive-only by default)
3. `ACT`: Receive-only identification → demodulation analysis → lab reproduction assessment

## Use cases

- Non-Wi-Fi RF such as wireless remotes and sensors (authorized)
- Protocol research such as ADS-B and remote controls (legal reception)
- Division of work with wifi-wireless: this skill covers **general SDR RF**; Wi-Fi attack and defense go to R29

## Workflow

```text
□ Confirm regulations and licenses
□ Receive only: identify the center frequency and the modulation
□ GNU Radio / URH analysis
□ Replay only in a shielded room with written permission
□ Conclusion focus: is unauthorized control possible / hardening advice
```

## Toolchain

| Tool | Use |
|------|------|
| RTL-SDR / HackRF (compliant) | RX/TX hardware |
| URH / GNU Radio | Analysis |
| Inspectrum | Signals |

## References

- `references/sdr-lab-rules.md`
- `../wifi-wireless/` `../ot-ics/` `../hardware-security/`

## Routing context

**Upstream**: MASTER R38
**MUST NOT**: Interfere with public communications; transmit without authorization

## Completion self-check

- [ ] Receive-only is the default and the regulatory boundary is recorded
- [ ] Checklist read
