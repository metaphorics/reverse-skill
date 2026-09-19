---
name: ot-ics
description: Use for authorized OT/ICS security assessment covering Purdue model zoning, PLC/SCADA exposure, industrial protocol discovery, and safe passive-first evaluation.
---

# OT / ICS Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` — **a mistake in an OT environment can cause physical harm**
2. `NOW`: The written authorization must state the site, the network segments, and whether active scanning or register writes are allowed
3. `NOW`: Run case-init. Default to **passive-first**. Do not write to PLCs before `ready_for_act`
4. `NEXT`: Read tool-index. Most OT tools need manual installs and an isolated lab network
5. `ACT`: Asset and zone identification → exposure surface → read-only verification

## Scope of use

- OT/SCADA/DCS security assessments (authorized)
- Purdue model zoning and cross-zone channels
- Protocol exposure such as Modbus/DNP3/S7/EtherNet/IP
- Engineering stations, HMIs, historians, jump hosts
- IT/OT convergence boundaries (firewall rules, data diodes)

## Safety rules (MUST)

```text
MUST NOT without explicit permission:
- Write coils/registers on PLCs
- High-rate scan production OT across the network
- Interrupt Safety Instrumented System (SIS) related paths
Prefer: read-only identification, traffic mirroring, offline firmware/config analysis
```

## Workflow

### Phase 1 — Zones and assets

```text
□ Purdue L0–L5 sketch: field devices → control → supervisory → site DMZ → enterprise
□ Asset inventory: PLC/RTU/HMI/engineering station/historian/jump host
□ Protocol and port baseline (authorized segments only)
```

### Phase 2 — Passive and read-only

```text
□ SPAN/mirrored PCAP → protocol-reverse / Wireshark OT dissectors
□ Offline audit of configs and project files (TIA/RSLogix exports and similar)
□ Record default passwords and plaintext protocols (unauthenticated Modbus) as a Finding, do not write values
```

### Phase 3 — Limited active (authorized only)

```text
□ Low-rate identification, inside maintenance windows
□ Read-only function codes first
□ Evidence at every step. Stop and report immediately on anomalies
```

### Phase 4 — Firmware and patch surface

```text
□ Controller firmware versions → CVE mapping (never blind-flash firmware)
□ Pair with firmware-pentest for offline image analysis
```

## Toolchain

| Tool | Purpose | Caution |
|------|------|------|
| Wireshark OT dissectors | Passive parsing | Mirrored traffic |
| Nmap NSE (limited) | Identification | Rate and time window |
| Claroty/Nozomi and similar | Asset discovery | Commercial / on site |
| PLC vendor engineering software | Config audit | Offline first |
| binwalk / Ghidra | Firmware | Offline |

## References

- `references/ot-safe-assessment.md`
- `../firmware-pentest/` `../protocol-reverse/` `../network` via pentest-tools

## Routing context

**Upstream**: MASTER R28  
**Downstream**: deep firmware work `firmware-pentest`, protocols `protocol-reverse`, IT lateral movement `windows-ad`/`attack-chain`  
**Peers**: do not hit OT with ordinary web scans or default parameters

## Task completion self-check

- [ ] Is the passive/read-only default recorded with the authorization boundary?
- [ ] Are writes to control loops avoided (unless explicitly allowed)?
- [ ] Does each Finding state the physical or process impact?
- [ ] Checklist and journal updated?