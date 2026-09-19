# examples/ctf-demo — Full Workflow Example

> This directory demonstrates the standard reverse-skill workflow: **routing → authorization gate → timeline → evidence chain → report**.
> The content is a fictional CTF lab example. It shows the workflow only.

## Workflow demonstration

```text
1. User task: "Analyze this CTF pwn challenge. It has a stack overflow in gets()."
2. Routing: master-route.ps1 -Hint "CTF pwn stack overflow" → PRIMARY R17 (pwn-chain)
3. Authorization: case-init.ps1 -Hint ... -CaseName ctf-demo -AuthGranted → scope.md
4. Execution: append the timeline, record evidence E-001/E-002, and update workitems
5. Output: report (docs-generator) + redacted field-journal entry
```

## Files

| File | Description |
|------|-------------|
| `scope.md` | Case scope (auth granted / target / network_profile) |
| `timeline.md` | Append-only timeline |
| `workitems.md` | Work items and coverage |
| `evidence/` | Example evidence records (E-001 reproduction command, E-002 crash output) |
| `report/` | Example final report structure |

## Real use

```powershell
# Initialize a real case for an authorized target.
powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/case-init.ps1 `
  -Hint "your task" -CaseName my-case -AuthGranted -TargetUrl "https://target/" `
  -NetworkProfile authorized_target_only

# Append evidence.
powershell -File skills/scripts/append-evidence.ps1 -CaseRoot work\my-case `
  -Id E-001 -Title "..." -ReproCommand "..."
```

> Put a real case in `work/<case>/`. Git ignores this path to reduce data-leak risk. This example remains tracked for reference.
