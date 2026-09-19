---
name: docs-generator
description: |
  Creates task-oriented technical documentation with progressive disclosure. Use when writing READMEs, API docs, architecture docs, or Markdown documentation.
  Also use this skill at the END of any completed reverse-engineering, penetration testing, CTF, or security analysis task to generate a formal report in the user's project directory.
  Trigger keywords: write a report, write documentation, produce a report, writeup, technical documentation, report, documentation.
---

# Technical Documentation

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Confirm that the current task matches this skill's scope
2. `NOW`: Read `../tool-index.md`; verify tool availability and actual paths
3. `NEXT`: Call bootstrap when a tool is missing. Do not guess paths
4. `ACT`: Enter and execute step one of the "Workflow". Do not stop at confirmation

For writing style, tone, and voice guidance, use `Skill(ce:writer)` with **The Engineer** persona.

## Security and reverse-engineering report output

When a reverse-engineering, penetration-testing, CTF, or security-analysis task ends, this skill creates a formal technical document in the **user's project directory**.

### Trigger timing

1. A reverse-engineering task ends with core conclusions (algorithm reconstruction, signature bypass, bypass method, and so on)
2. A penetration test ends with vulnerabilities found and verified
3. A CTF challenge is solved and the flag is obtained
4. The user explicitly asks to "write a report/document/writeup"

### Template selection

| Task type | Use template |
|---------|---------|
| APK/binary/so reverse engineering | `references/security-report-templates.md` → reverse-engineering report |
| Penetration testing/vulnerability discovery | `references/security-report-templates.md` → penetration-testing report |
| CTF solution | `references/security-report-templates.md` → CTF Writeup |
| JS/Web signature reverse engineering | `references/security-report-templates.md` → signature reverse-engineering report |
| Malware / APT / virus analysis report | `references/security-report-templates.md` + **`references/vendor-report-rules.md`** |
| General technical documentation | `references/templates.md` → README / API documentation |

### Vendor report structure (Issue #65)

A formal security report **MUST** read `references/vendor-report-rules.md` (use its structure only, not vendor text). Select a vendor flavor only when task evidence or the user explicitly requires it. Ordinary reverse engineering and other tasks use `flavor = null`.

| Flavor / Overlay | Use when | Main outline |
|------------------|--------|------------|
| `malware` | Explicit malicious sample, trojan, white-on-black malware, or phishing poisoning | Huorong-style: overview → flow → sample analysis → incident response → IOC |
| `apt` | APT, campaign, group, multi-stage infection chain, or industry targeting | Kaspersky Securelist-style: summary → infection chain → investigation narrative → Interesting findings → technical analysis → detection and mitigation → IOC |
| `flavor = null` | Ordinary APK/ELF/PE/Mach-O reverse engineering, algorithm or firmware analysis, penetration testing, CTF, or JS signatures | Original task template + Base elements. Do not use malware/APT-only sections |
| thin `vuln` | User explicitly requests vulnerability, patch, or CVE technical analysis | Overview → impact/reproduction → crash and patch analysis → protection advice (overlay on null, not the third default full flavor) |

Principle: **Keep templates focused.** Use only two full vendor flavors. Use `vuln` only as an optional thin overlay. Do not create a third default full template.
Apply this with §0 Evidence→Finding→Path. The Evidence contract takes priority when they conflict.

### Output rules

- **Output location**: The user's current project directory, not the skill package directory
- **File-name format**: `YYYY-MM-DD_[type]-[short target name]-report.md`
- **When the project has a `docs/` directory**: Prefer that directory
- **Encoding**: UTF-8
- **Language**: Follow the user's conversation language. A Chinese conversation produces a Chinese report. An English conversation produces an English report

### Quality requirements

- Every code block must run directly or have clear context
- Do not leave placeholder/TODO text
- Key findings must have supporting evidence
- Reproduction steps must let a third party reproduce the result independently
- Replace sensitive information (real tokens, passwords, and internal URLs) with placeholders
- **MUST** include the Evidence → Finding → Path chain (see `../ops/evidence-finding-path.md` and template §0)
- **MUST** read `references/vendor-report-rules.md` and select `malware`, `apt`, or `flavor = null` (vulnerability tasks may add thin `vuln`). Without a flavor, output only the original task template and applicable Base elements. Do not require IOC or ATT&CK
- **SHOULD** cite the case `scope.md` / `timeline.md` (`../scripts/case-init.ps1`)

### Diagram integration

When generating a report, call the `diagram-generator` skill at suitable points to create diagrams:

| Report type | Suggested diagram | Diagram type |
|---------|---------|---------|
| Reverse-engineering report | Function-call graph, data-flow graph | Mermaid flowchart / sequenceDiagram |
| Penetration-testing report | Attack path graph, network topology | Mermaid flowchart / Graphviz |
| CTF Writeup | Solution-flow diagram | Mermaid flowchart |
| JS signature reverse-engineering report | Request-chain sequence diagram, algorithm flow diagram | Mermaid sequenceDiagram / flowchart |

Embed diagrams as Mermaid code blocks in the report Markdown so GitHub/GitLab can render them directly.

---

## Core Principles

### 1. Progressive Disclosure

Reveal information in layers:

| Layer | Content | User Question |
|-------|---------|---------------|
| 1 | One-sentence description | What is it? |
| 2 | Quick start code block | How do I use it? |
| 3 | Full API reference | What are my options? |
| 4 | Architecture deep dive | How does it work? |

**Warnings, breaking changes, and prerequisites go at the TOP.**

### 2. Task-Oriented Writing

```markdown
<!-- Bad: Feature-oriented -->
## AuthService Class
The AuthService class provides authentication methods...

<!-- Good: Task-oriented -->
## Authenticating Users
To authenticate a user, call login() with credentials:
```

### 3. Show, Don't Tell

Every concept needs a concrete example.

## Formatting Standards

- **Sentence case headings**: "Getting started" not "Getting Started"
- **Max 3 heading levels**: Deeper means split the doc
- **Always specify language** in code blocks
- **Relative paths** for internal links
- **Tables** for structured data with 3+ attributes

## Quality Checklist

- [ ] Code examples tested and runnable
- [ ] No placeholder text or TODOs
- [ ] Matches actual code behavior
- [ ] Scannable without reading everything
- [ ] Reader knows what to do next

## Anti-Patterns

| Problem | Fix |
|---------|-----|
| Wall of text | Break up with headings, bullets, code, tables |
| Buried critical info | Warnings/breaking changes at TOP |
| Missing error docs | Always document what can go wrong |

## Templates

For README, API endpoint, and file organization templates, see [references/templates.md](references/templates.md).

## Related Skills

- `Skill(ce:writer)` - Writing style, tone, and voice (load The Engineer persona)
- `Skill(ce:visualizing-with-mermaid)` - Architecture and flow diagrams


---

## On-Demand Bootstrap

This skill uses no external tools. It generates plain text. No bootstrap is needed.

When a report needs embedded diagrams, call the `diagram-generator/` skill.

---

## Routing context

**Upstream entry**: All security and reverse-engineering skills call this skill automatically after the task ends
**Trigger methods**:
- Automatic: run as step 9 of the behavior chain after the task ends
- Manual: The user says "write a report", "produce documentation", or "writeup"

**Related modules**:
- `apk-reverse/` — Generate a reverse-engineering report after APK reverse engineering
- `ida-reverse/` — Generate a reverse-engineering report after binary analysis
- `radare2/` — Generate a reverse-engineering report after CLI analysis
- `js-reverse/` — Generate a signature report after JS signature reverse engineering
- `reverse-engineering/` — Generate a reverse-engineering report after general reverse engineering
- `field-journal/` — Use report content as data for the evolution log

**Security report template**: `references/security-report-templates.md`
**Vendor report rules**: `references/vendor-report-rules.md` (flavor: malware | apt | null; optional overlay: vuln)
**General documentation templates**: `references/templates.md`


## Completion self-check (MUST pass before you claim completion)

- [ ] I executed every workflow step, not only read it
- [ ] I used real tool paths from `tool-index`
- [ ] I produced reproducible evidence (command/script/screenshot/report)
- [ ] The report includes Evidence / Finding / Path (ops contract)
- [ ] I completed and wrote back the Checklist items required by RULES
