---
name: hardware-security
description: Use for authorized hardware and embedded interface security research including UART/JTAG discovery, debug pad triage, secure boot overview, and offline firmware extraction support.
---

# Hardware / Embedded Interface Security

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Confirm authorization for physical access and confirm device ownership.
2. `NOW`: Follow ESD and power safety. Use read-only probes by default.
3. `NEXT`: Work with firmware-pentest for image analysis.
4. `ACT`: Identify the enclosure and debug interfaces -> consoles -> extraction.

## Applicable Scenarios

- UART, JTAG, and SWD debug-port discovery
- Boot logs, root shell, and boot interruption
- Flash extraction after authorized teardown
- Feasibility assessment for secure boot or encrypted Flash (prefer non-destructive actions)

## Workflow

```text
□ Disassemble the authorized device. Photograph and label test points.
□ Use a multimeter to find GND/VCC/TX/RX. Check 1.8/3.3/5V logic levels.
□ Use USB-TTL for read-only logs. Record the baud rate.
□ JTAG: enumerate IDCODE. Assess whether it is locked.
□ Extract the image -> hand it to firmware-pentest / ghidra.
```

## Toolchain

| Tool | Purpose |
|------|------|
| USB-TTL / logic analyzer | UART |
| J-Link / CMSIS-DAP | Debugging |
| bus pirate / flipper (lab) | Multiple protocols |
| binwalk / flashrom | Extraction |

## References

- `references/debug-interface-triage.md`
- `../firmware-pentest/` `../ot-ics/`

## Routing Context

**Upstream**: MASTER R34
**MUST NOT**: Disassemble without authorization or damage another person's device.

## Task Completion Self-Check

- [ ] Did I record interface levels and the pinout diagram?
- [ ] Did I preserve the image hash?
- [ ] Is the Checklist complete?
