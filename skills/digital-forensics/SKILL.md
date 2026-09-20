---
name: digital-forensics
description: Use for authorized digital forensics including memory dumps, disk timelines, PCAP investigation, artifact triage, and IR evidence preservation.
---

# Digital Forensics & IR Artifacts

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` or the organization IR authorization note
2. `NOW`: Confirm this is **forensics/attribution**, not offensive scanning
3. `NOW`: Open a case. Prefer read-only copies of evidence (write-protect the original media)
4. `NEXT`: tool-index; Volatility and similar tools often need manual setup
5. `ACT`: Preserve hashes → build the timeline → examine key artifacts

## Use cases

- Memory dump analysis (Volatility 3 v2.28.2)
- Disk / E01 / dropped-file timelines
- PCAP attribution and protocol reconstruction (pair with `protocol-reverse/`)
- Host artifacts: Prefetch, Shimcache, Event Log, browser history
- IR IOC extraction (pair with `malware-analysis/` / `threat-hunting/`)

## Workflow

### 1. Preservation

```text
□ Compute SHA256; record the time zone and the acquisition command
□ Work on copies; keep the original read-only
□ Write chain-of-custody notes into the timeline
```

### 2. Memory

```bash
vol -f mem.dmp windows.info
vol -f mem.dmp windows.pslist
vol -f mem.dmp windows.netscan
vol -f mem.dmp windows.cmdline
```

### 3. Host artifacts

```text
□ Event logs: Security / PowerShell / Sysmon
□ Persistence: Run keys, services, scheduled tasks, WMI
□ Execution traces: Amcache, Prefetch, BAM
```

### 4. Network

```text
□ tshark: summarize sessions and DNS
□ Export suspicious streams → protocol-reverse or malware C2 analysis
```

## Toolchain

| Tool | Use |
|------|------|
| Volatility 3 v2.28.2 | Memory |
| Timeline Explorer / Plaso | Super timeline |
| tshark | PCAP |
| Eric Zimmerman toolset | Windows artifacts |
| Autopsy / FTK Imager | Disk |

## References

- `references/forensics-triage.md`
- `../malware-analysis/` `../threat-hunting/` `../protocol-reverse/`

## Routing context

**Upstream**: MASTER R25
**Downstream**: deep sample analysis → malware-analysis; detection rules → threat-hunting

## Completion self-check

- [ ] Hashes and the copy policy are preserved
- [ ] Timeline is reproducible
- [ ] IOCs are redacted and graded
- [ ] Checklist read
