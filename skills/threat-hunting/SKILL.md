---
name: threat-hunting
description: Use for blue-team threat hunting, detection engineering with Sigma/YARA, SIEM query design, and incident detection validation.
---

# Threat Hunting & Detection Engineering

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Confirm blue-team or hunting authorization and the data-source scope (SIEM, EDR exports)
2. `NOW`: State the hypothesis before you query. Do not churn alerts without one
3. `NEXT`: Tools and the data access method
4. `ACT`: hypothesis → query → validate → detection rule

## Use cases

- Threat hunting (hypothesis-driven)
- Sigma / YARA detection engineering
- Alert tuning and false-positive analysis
- With `malware-analysis/`: sample-side IOCs → detections in this skill
- With `digital-forensics/`: case artifacts → lateral-movement hunting

## Workflow

### 1. Build the hypothesis

```text
Example: attacker uses living-off-the-land for lateral movement
→ Data sources: Sysmon 1/3/10, Windows Security 4624/4648
→ Success criteria: unusual parent process or a rare account logon source
```

### 2. Query and stack

```text
□ Baseline: normal administrator behavior windows and hosts
□ Anomaly: new services, encoded PowerShell, unusual outbound
□ Correlate: same account logging on to several hosts in a short window
```

### 3. Write the rule

```yaml
# Sigma skeleton lives in malware-analysis; this skill focuses on:
# - False-positive surface
# - Data-source field mapping
# - Response playbook links
```

### 4. Validate

```text
□ Atomic tests (Atomic Red Team) only in an authorized lab
□ Replay historical logs to validate recall
```

## Toolchain

| Tool | Use |
|------|------|
| Sigma CLI / sigmac | Rule conversion |
| YARA | File/memory |
| SIEM (ELK/Splunk etc.) | Queries |
| osquery | Endpoint hunting |
| Atomic Red Team | Detection validation (lab) |

## References

- `references/hunting-loop.md`
- `../malware-analysis/references/yara-sigma-rules.md`
- `../digital-forensics/`

## Routing context

**Upstream**: MASTER R27
**Downstream**: confirmed intrusion → forensics; malicious samples → malware-analysis
**MUST NOT**: Run attack simulations in a production environment without authorization

## Completion self-check

- [ ] Hypothesis and conclusion are explicit
- [ ] Rules note false positives and data sources
- [ ] Checklist read
