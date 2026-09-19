# General scope contract (hard task-start gate)

> **MUST**: Every security, reverse-engineering, or penetration-testing task MUST create `scope.md` under the current user's analysis project at `work/<case>/` before **ACT**.
> Without scope, allow only document and routing reads. **MUST NOT** actively scan, hook, or exploit targets.
> You may copy this template. Keep field names as English keys for script checks.

## How to initialize

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 -Hint "<one-sentence task>" -CaseName "my-case"
# Default output: work/<case>/scope.md and related files in the current analysis project
# When calling the skill from another directory, specify: -ProjectRoot "C:\path\to\analysis-project"

# Valid local offline sample: auth granted + offline + explicit sample → ready_for_act=true
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 `
  -Hint "offline apk" -CaseName "my-sample" -Preset offline-sample -Sample ".\app.apk"
```

Linux / macOS / Kali:

```bash
bash skills/scripts/case-init.sh --hint "<one-sentence task>" --case-name "my-case"
# Default output: work/<case>/scope.md and related files in the caller's analysis project
# When calling from another directory, specify: --project-root "/path/to/analysis-project"

# Valid local offline sample
bash skills/scripts/case-init.sh \
  --hint "offline apk" --case-name "my-sample" \
  --preset offline-sample --sample ./app.apk
```

`-PackageRoot` / `--package-root` remains a compatibility parameter. New workflows SHOULD use `ProjectRoot` / `--project-root` to identify the case artifact owner.

## Complete scope.md template

```markdown
# Case Scope

## meta
- case_id: {YYYYMMDD-short}
- created: {ISO-8601}
- operator: {name or local}
- project_root: {caller analysis project}
- primary_skill: {from master-route}
- lead_role: lead   # see ops/role-map.md
- specialist_roles: []  # e.g. cie, cpe, cre

## auth
- status: granted | pending | denied
- basis: written_contract | bug_bounty_scope | ctf_public | own_system | lab_only
- evidence_of_auth: {ticket/path or "CTF public" or "owner-operated"}
- MUST NOT proceed if status != granted

## in_scope
- assets: []          # hosts, domains, APK paths, binaries, URLs
- surfaces: []        # web, mobile, binary, network, api
- activities: []      # recon, reverse, exploit_validate, report

## out_of_scope
- assets: []
- activities: []      # e.g. DoS, phishing real users, data exfil

## network_profile
- mode: offline | lab_only | authorized_target_only | unrestricted_lab
- notes: |
    offline = no external packets (static or local sample)
    lab_only = lab/VM IPs only
    authorized_target_only = in_scope assets only
- MUST NOT use unrestricted against production without written auth

## deliverables
- report: true
- field_journal: true
- diagrams: true
- timeline: true

## constraints
- timebox: {}
- stealth: low | medium | high
- data_handling: anonymize | no_user_pii

## signoff
- ready_for_act: false
- checklist:
  - [ ] auth.status = granted
  - [ ] in_scope.assets non-empty OR offline sample path set
  - [ ] network_profile.mode chosen
  - [ ] out_of_scope reviewed
```

## Routing hook (AI MUST execute)

```text
RULES / MASTER-ROUTING / SKILL:
  1) master-route → PRIMARY
  2) platform-native case-init or write scope.md by hand
  3) auth not granted → STOP; allow only adding authorization material
  4) ready_for_act = true → open PRIMARY SKILL.md → ACT
```

`case-guard -Force` / `case-guard --force` is a compatibility parameter. **MUST NOT** bypass the hard gates for `auth.status`, valid scope, network profile, or `ready_for_act`.

## network_profile quick reference

| mode | Allowed | Forbidden |
|------|------|------|
| `offline` | Static analysis, local files, simulation | Any external connection, public RPC |
| `lab_only` | Lab/CTF target network | Production or unauthorized IPs |
| `authorized_target_only` | In-scope list | Assets outside the list |
| `unrestricted_lab` | Isolated lab network with written authorization | Production internet |

## Features

- Plain Markdown, **no database**  
- Independent of `tool-index` / bootstrap: scope controls whether you may target, and tool-index controls which tool you use  
