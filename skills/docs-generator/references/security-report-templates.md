# Security, reverse-engineering, and penetration-testing documentation templates

This file provides documentation templates for reverse engineering, penetration testing, vulnerability analysis, and other security projects. After the task is complete, AI creates a document in the user's project directory and uses the matching template.

---

## 0. Evidence chain (all security reports MUST include this)

> Full contract: `skills/ops/evidence-finding-path.md`
> Case directory: `work/<case>/` (`case-init.ps1`)

The report body **MUST** include these sections. You may merge them into "Core findings", but do not omit fields:

### 0.1 Scope summary

- Link to `scope.md`: `auth` / `in_scope` / `network_profile`
- No scope means you MUST NOT claim that the task is complete

### 0.2 Evidence

At least one record with these fields: `E-id` / `source_ref` / `repro_command` / `content_hash|n/a`

### 0.3 Findings

Each record: `F-id` / `severity|n/a_re` / `evidence_ids` / `confidence` / `location` / `status`

### 0.4 Path

At least one `P-id`: `path_type=attack|callflow|solve`. Steps may link to E/F

### 0.5 Timeline summary

Link to `timeline.md` or embed the key 3–10 appended records

---

---

## 0.6 Vendor structure overlay

> Full rules: `references/vendor-report-rules.md` (Issue #65)
> **MUST** read and select this structure when generating a formal security report. **Extract structure only. Do not copy vendor text or IOC examples.**

| Flavor / Overlay | Scenario | One-line outline |
|------------------|------|------------|
| `malware` | Explicit malicious sample, ordinary trojan, or white-on-black malware | Huorong-style: overview → flow → sample analysis → incident response → IOC |
| `apt` | APT, campaign, group, multi-stage chain | Kaspersky-style: summary → infection chain → investigation → Interesting findings → technical analysis → detection and mitigation → IOC |
| `flavor = null` | Ordinary reverse engineering, penetration testing, CTF, or JS signature | This task template + applicable Base elements |
| thin `vuln` | Explicit vulnerability, patch, or CVE technical analysis | Overview → impact/reproduction → crash and patch analysis → protection advice |

**General element summary (G1–G7)**: G1 executive summary MUST · G2 Scope MUST · G3 E/F/P MUST · G4 IOC only in `malware`/`apt` MUST · G5 recommendations in `malware`/`apt`/`vuln` MUST · G6 appendix SHOULD · G7 ATT&CK in `apt` MUST

Use `vendor-report-rules.md` for selection and section order. When it conflicts with §0.1–0.5, the **Evidence contract takes priority**.

## 1. Reverse-engineering report template

```markdown
# [Target name] reverse-engineering report

> Analysis date: YYYY-MM-DD
> Analyst: [AI / human]
> Toolchain: [jadx / IDA / radare2 / Frida / ...]

## 1. Target overview

| Attribute | Value |
|------|---|
| File name | |
| File type | APK / ELF / PE / Mach-O / ... |
| Size | |
| MD5 | |
| SHA256 | |
| Package name/entry point | |

## 2. Analysis objective

<!-- Core question that this reverse-engineering task must answer -->

## 3. Static analysis

### 3.1 Basic information
<!-- Architecture, compiler, protection, and string features -->

### 3.1.1 Import table / dependencies (MUST for binaries)
<!-- Write the E-imports / E-triage-imports summary. Record failures in Evidence. Do not skip them -->

### 3.2 Key functions/classes
<!-- List the key logic that you located, with code snippets -->

### 3.3 Encryption/signature algorithm
<!-- When encryption is involved, describe the algorithm, key source, and parameter construction -->

## 4. Dynamic analysis

### 4.1 Hook records
<!-- Targets and results of Frida / xposed / other hooks -->

### 4.2 Runtime behavior
<!-- Network requests, file operations, and process behavior -->

## 5. Core findings

<!-- List key conclusions by number -->

1. ...
2. ...
3. ...

## 6. Reproduction steps

<!-- Let others reproduce your analysis result -->

```bash
# Key commands
```

## 7. Open issues

<!-- Points that are not fully resolved -->

## 8. Attachments

<!-- Hook scripts, decryption code, screenshots, and so on -->
```

---

---

## 1b. Malware / APT report (vendor flavor)

When the task is malware analysis, a virus report, or APT/campaign analysis, **do not** submit only the "reverse-engineering" outline above. Ordinary reverse-engineering tasks keep the original template and do not select a vendor flavor automatically:

1. Read `vendor-report-rules.md` and select `malware` or `apt`
2. Output sections in the selected order
3. Still **MUST** include the §0 Evidence chain. The `malware` / `apt` flavor also **MUST** include an IOC table
4. Static analysis of a binary sample **MUST** include import-table Evidence, matching the radare2/ida/malware hard gate

## 1c. Vulnerability technical-analysis report (thin `vuln` overlay)

When the task covers an **OS/component vulnerability, patch comparison, or CVE technical analysis**, or the user explicitly requests a "vulnerability technical-analysis report":

1. Read `vendor-report-rules.md` §3b. Use the thin `vuln` section order, **not** the full malware/apt flavor
2. **MUST** include: impact scope, authorized reproduction or explicit n/a, crash/root cause or patch-difference Evidence, and protection/patch advice
3. **MUST** include §0 Evidence→Finding→Path
4. **MUST NOT** extend a PoC on an unauthorized target or copy weaponized details from external exploits

## 2. Penetration-testing report template

```markdown
# [Target] penetration-testing report

> Test date: YYYY-MM-DD
> Test scope: [URL / IP / application name]
> Authorization status: [Authorized / CTF / learning environment]

## 1. Executive summary

<!-- Summarize in one paragraph: what was tested, what was found, and the risk level -->

## 2. Test scope

| Item | Details |
|------|------|
| Target | |
| Test type | Black-box / gray-box / white-box |
| Test time | |
| Tools | |

## 3. Findings summary

| # | Vulnerability name | Risk level | Status |
|---|---------|---------|------|
| 1 | | High/Medium/Low/Informational | Verified/Pending confirmation |

## 4. Vulnerability details

### 4.1 [Vulnerability name]

**Risk level**: High / Medium / Low

**Description**:

**Impact**:

**Reproduction steps**:

1. ...
2. ...
3. ...

**Evidence**:

```
<!-- Request/response/screenshot/payload -->
```

**Remediation advice**:

## 5. Attack path

<!-- Draw the path when a complete attack chain exists -->

```
Entry → reconnaissance → exploitation → privilege escalation → objective achieved
```

## 6. Tools and environment

| Tool | Version | Use |
|------|------|------|
| | | |

## 7. Remediation summary

| Priority | Advice |
|--------|------|
| P0 | |
| P1 | |
| P2 | |

## 8. Appendix

<!-- Complete payloads, scripts, configuration files, and so on -->
```

---

## 3. CTF Writeup template

```markdown
# [Competition name] - [Challenge name] Writeup

> Category: Web / Reverse / Pwn / Crypto / Misc / Forensics
> Difficulty: Easy / Medium / Hard
> Score: N pts
> Solve time:

## Challenge description

<!-- Original challenge description -->

## Solution approach

### Step 1: Reconnaissance
<!-- What did you observe? -->

### Step 2: Vulnerability/breakthrough
<!-- What key point did you find? -->

### Step 3: Exploitation
<!-- How did you exploit it? -->

## Key code/payload

```python
# exploit code
```

## Flag

```
flag{...}
```

## Pitfalls

<!-- Wrong paths that you tried -->

## Knowledge points

<!-- Knowledge used by this challenge for later review -->
```

---

## 4. JS/Web signature reverse-engineering report template

```markdown
# [Site/application] signature-parameter reverse-engineering report

> Analysis date: YYYY-MM-DD
> Target endpoint: [URL]
> Signature field: [field name]

## 1. Target request

```http
POST /api/xxx HTTP/1.1
Host: example.com

param1=xxx&sign=<target field>
```

## 2. Location process

### 2.1 Breakpoint/hook method
<!-- How did you find the signature-generation location? -->

### 2.2 Call stack
<!-- Key call chain -->

## 3. Algorithm reconstruction

### 3.1 Algorithm type
<!-- HMAC-SHA256 / AES / custom / ... -->

### 3.2 Parameter construction
<!-- Which fields participate in the signature, sort rules, and separators -->

### 3.3 Key source
<!-- Hard-coded / returned by endpoint / derived from timestamp / ... -->

## 4. Local reproduction code

```javascript
// Node.js reproduction
```

## 5. Verification result

<!-- Compare the signature generated by the reproduction code with the real request -->

## 6. Anti-crawling/risk-control notes

<!-- Rate limits, device fingerprints, environment checks, and so on -->
```

---

## 5. Documentation output rules

### Output location

- Output documents to the **user's current project directory** by default, not the skill package directory
- File-name format: `YYYY-MM-DD_[type]-[short target name]-report.md`
- If the user's project has a `docs/` directory, prefer that directory

### Output timing

AI calls this skill automatically at these times:

1. A reverse-engineering task is complete and has produced core conclusions
2. A penetration test is complete and vulnerabilities are found and verified
3. A CTF challenge is solved and the flag is obtained
4. The user explicitly asks to "write a report/document"

### Quality requirements

- Every code block must run directly or have clear context
- Do not leave placeholder/TODO text. If a section is incomplete, mark it "to be added" and explain why
- Key findings must have supporting evidence (command output, screenshot description, or code snippet)
- Reproduction steps must let a third party reproduce the result independently
