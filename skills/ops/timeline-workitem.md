# Timeline + WorkItem / Coverage

> Replayable operations record (Z3r0 timeline concept) + coverage checks (WorkItem concept).  
> Keep everything under **`work/<case>/`** (gitignored). Do not place it in the skill package body.

## Directory convention

```text
work/<case>/
  scope.md           # contract (ops/scope-contract.md)
  timeline.md        # append-only; do not change historical entries
  workitems.md       # work items and coverage
  evidence/          # raw artifacts (screenshots, pcap, logs)
  notes/
  report/            # final report draft or copy
```

Initialize:

```powershell
powershell -File skills\scripts\case-init.ps1 -Hint "full pentest" -CaseName "acme-2026"
```

## timeline.md format

Append each record **only**:

```markdown
## {ISO-8601} | {role} | {phase}
- action:
- command_or_ref:
- result_summary:
- artifacts: []      # relative paths under this case
- evidence_ids: []   # E-xxx when promoted
- decision_delta: [] # only decisions changed since the previous transition
- carry_forward_refs: [scope.md] # unchanged authoritative state is referenced, not re-serialized
- next:
```

**MUST NOT** delete or rewrite an existing `##` time block. Correct it with a new entry + `corrects: {timestamp}`.

### Decision delta boundary

`scope.md`, `workitems.md`, and existing Evidence form the current authoritative state. `timeline.md` records transitions and does not copy a full snapshot.

- Each real stage or turn transition **MUST** write `decision_delta`. List only decisions that changed from the previous state and affect later actions. Write `[]` when nothing changed.
- An unchanged route, auth, scope, network profile, tool capability, hypothesis, or Evidence **MUST NOT** be expanded for handoff. Reference the authoritative file or entry in `carry_forward_refs`.
- A consumer **MUST** parse `carry_forward_refs` first, then apply `decision_delta` to the work context. Treat the delta as an incomplete state.
- A genuine decision boundary exists only when at least two materially different, evidence-supported branches exist and user choice changes the next action. Continue deterministic transitions directly. Do not restate context to create a menu.

Representative transition: For `Triage -> Static`, when auth/scope/route stay unchanged, record only `decision_delta: [phase=triage->static]`. Use `carry_forward_refs: [scope.md, evidence/E-triage.md]` to inherit the remaining state.

## workitems.md template

```markdown
# Work Items

| ID | title | role | targets | surface | status | evidence | notes |
|----|-------|------|---------|---------|--------|----------|-------|
| WI-001 | Port scan edge | cie | {ip} | network | done | E-001 | |
| WI-002 | Auth bypass check | cpe | /api/login | web | blocked | | need creds |

status: pending | in_progress | blocked | done | cancelled

## Coverage
- [ ] Recon complete for in_scope assets
- [ ] Critical/High candidates triaged
- [ ] Validated findings have Evidence
- [ ] Path documented (attack/call/solve)
- [ ] Timeline continuous (no silent gaps >1 major phase)
- [ ] Report exported via docs-generator
- [ ] field-journal written (anonymized)
```

## attack-chain / pentest hooks

| Skill | MUST |
|-------|------|
| `attack-chain/` | Multi-stage tasks create a case directory. Update workitems + timeline at each stage end. |
| `pentest-tools/` | Add at least one timeline entry after each tool batch. Create an Evidence draft for each finding. |
| Other RE skills | Recommend a timeline. Complete the Evidence chain before reporting. |

## Features

- Agent-friendly plain text that supports diff and review  
- Cross-reference tool-index command paths  
- No WebSocket live stream dependency. Paste the timeline into a report when needed.  
