# Evidence → Finding → Path evidence chain

> Inspired by the Z3r0 Evidence Plane and implemented as a **Markdown field contract**.  
> reverse-skill binds this feature to `docs-generator` report templates, redacted `field-journal` records, and reproducible commands.

## 1. Evidence (immutable observation)

Record each Evidence item in its own paragraph or table row:

```markdown
### E-{nnn}
- title:
- observed_at:
- source_type: command | screenshot | file | log | memory | network | manual
- source_ref: {path or command id}
- content_hash: {sha256 of artifact if file, else n/a}
- artifact_path: {relative path under case root when content_hash is recorded, else n/a}
- repro_command: |
    {exact command}
- raw_excerpt: |
    {redacted excerpt}
- linked_workitem: WI-{nnn} | n/a
- supersedes: E-{nnn} | none
```

**MUST**: Every Finding MUST cite at least one Evidence item. The `repro_command` must be runnable by a third party or mark the offline restriction.

**CLI helper** (writes to `work/<case>/evidence/E-*.md`):

```powershell
powershell -File skills/scripts/append-evidence.ps1 -CaseRoot work/<case> `
  -Id E-001 -Title "..." -ReproCommand "..." -Severity info -Status observed
```

When the Evidence is a case-local file, pass `-ArtifactPath` to record a SHA-256 fixity value and a relative artifact path. Review the complete case graph before handoff:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --verify-hashes --strict
```

The review is read-only. It checks scope fields, Evidence records, work item and timeline references, structured Findings, Paths, and artifact hash matches.

## 2. Finding (security or reverse-engineering conclusion)

```markdown
### F-{nnn}
- title:
- severity: critical | high | medium | low | info | n/a_re
- category: vuln | misconfig | design | reverse_algo | bypass | other
- status: candidate | validated | false_positive | accepted_risk
- evidence_ids: [E-001, E-002]
- location: {file:line | addr | url | class.method}
- impact:
- confidence: high | medium | low
- repro_steps:
  1.
  2.
- remediation: {or n/a for pure RE}
- optional_attack: {ATT&CK ID or empty}
```

**MUST**: `evidence_ids` must not be empty. When `status=validated`, confidence MUST NOT be low unless the record marks residual risk.

## 3. Path (attack path, call path, or solve path)

Use **Path** for every task type:

| Task | Path meaning |
|------|-----------|
| Penetration testing / attack chain | Attack path steps |
| Reverse engineering | Key call or data-flow steps |
| CTF | Solve steps |

```markdown
### P-{nnn}
- title:
- path_type: attack | callflow | solve
- start:
- goal:
- steps:
  1. action: — evidence: E-xxx — finding: F-xxx | none
  2. action: — evidence: E-xxx — finding: F-yyy | none
- residual_risks:
```

**MUST**: Each step must link to Evidence. An endpoint Finding that claims obtained privilege or data must have validated Evidence.

## 4. Location in reports

The `docs-generator` security report **MUST** contain:

1. Scope summary (link to the case `scope.md`)  
2. Evidence table or section  
3. Findings list (with evidence_ids)  
4. At least one Path (attack/call/solve)  
5. Timeline summary (optionally link the full text to `timeline.md`)

See the **Evidence Chain** section in `docs-generator/references/security-report-templates.md`.

## 5. field-journal hook

When recording a journal entry, **SHOULD** include:

- Up to three key Evidence IDs and the command  
- One core Finding  
- One reusable Path pattern in one sentence  

Keep complete sensitive content in the user project report. The journal **MUST** use redaction (`anonymization.md`).

## 6. Difference from Z3r0 (feature)

| Z3r0 | reverse-skill |
|------|----------------|
| Immutable PG rows + API | Markdown files + hash fields |
| UI review queue | Report + next-step menu + journal |
| Deep ATT&CK binding | Optional labels, no required UI |


## Validated sufficiency (Issue #77 / R4*)

Global bind rule remains: every Finding references **>=1** Evidence.

Promotion to status=validated is stricter (decision cookbook):

| status | Evidence bar |
|--------|----------------|
| preliminary / candidate | >=1 (unchanged) |
| **validated** | **SHOULD >=2 independent** Evidence (best: 1 static + 1 dynamic). A single Evidence item alone MUST NOT silently promote to validated — keep candidate/preliminary, or record residual_risk + human confirm. |
| blocked promotion | record Evidence E-insufficient-evidence |

Full recipes: [nalysis-decision-framework.md](analysis-decision-framework.md) (R4*, R1, R41, R44).
