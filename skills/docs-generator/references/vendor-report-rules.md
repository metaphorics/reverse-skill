# Vendor report rules (vendor structure overlay)

> Issue #65, item 2.
> **Extract structure and writing rules only. Do not copy vendor report text, charts, real IOC examples, or long passages.**
> This file is an **overlay**. It does not replace the task templates in `security-report-templates.md` or weaken §0 Evidence→Finding→Path.

Structure references (public examples, outline only):

| Flavor | Main reference | Scenario |
|--------|--------|------|
| `malware` | Huorong Security virus/technical analysis reports | Explicit ordinary trojan, white-on-black malware, phishing poisoning, or malicious sample |
| `apt` | Kaspersky Securelist / APT campaign reports (such as MATA) | APT, group campaign, multi-stage infection chain, or industry targeting |

Principle: **Keep templates focused.** Use only two full vendor flavors (`malware` / `apt`) plus Base elements and an **optional thin overlay** (such as `vuln` vulnerability technical analysis). Ordinary reverse engineering, penetration testing, CTF, and JS reports keep their task templates. Do not use a malware report by default. `vuln` **is not** a third default full flavor.

---

## 0. When to enable

When `docs-generator` creates a **security** report (reverse engineering, malware, penetration-test closeout, or an explicit request for a "professional report" or "vendor style"), it **MUST** read this file. Select a vendor flavor only when task Evidence or the user explicitly requires it. Otherwise use `flavor = null` and add only the general professional elements and the original task template.

| Signal | Flavor / Overlay |
|------|------------------|
| APT / group / campaign / multi-stage C2 / industry targeting / ICS / spear-phishing campaign | `apt` |
| Explicit malicious sample, trojan, credential theft, white-on-black malware, or impersonation site | `malware` |
| User explicitly requests vulnerability/patch/CVE technical analysis, or task Evidence concerns OS/component vulnerability research | `flavor = null` + **thin overlay `vuln`** (see §3b) |
| Ordinary APK/ELF/PE/Mach-O reverse engineering, algorithm analysis, firmware analysis, penetration testing, CTF, or JS signatures | `flavor = null`; use the original task template and the minimum general professional elements |

An explicit user request such as "use Kaspersky/APT style", "use Huorong/virus-report style", or "use vulnerability technical-analysis style" overrides automatic selection.
**Do not** put ordinary malware/APT/ordinary reverse-engineering tasks into the `vuln` outline by default.

---

## 1. General professional elements (Base)

Apply these Base elements by report type. Do not omit items marked **MUST**. Do not add flavor-specific items to unrelated tasks just to fill a template. When no applicable content exists, use `n/a` and explain why.

| # | Element | Requirement |
|---|------|------|
| G1 | Executive summary / overview | **MUST**: 3–8 sentences. State what was analyzed, the most severe conclusion, the impact, and recommended actions |
| G2 | Scope and authorization | **MUST**: link to case `scope.md` (see template §0.1) |
| G3 | Evidence→Finding→Path | **MUST**: see `security-report-templates.md` §0 and `skills/ops/evidence-finding-path.md` |
| G4 | IOC table | **MUST** for `malware` / `apt`; include for other tasks only when matching indicators exist |
| G5 | Recommendation / response | **MUST** for `malware` / `apt`: at least one executable recommendation. Other tasks follow the original task template |
| G6 | Appendix metadata | **SHOULD**: tool and version, sample hash, and complete reproduction commands |
| G7 | ATT&CK mapping | **MUST** under `apt`. Use `n/a` plus a reason when no technique applies. **SHOULD** for other tasks |

### 1.1 Minimum IOC table columns

```markdown
| Type | Value | Context | First/last seen | Source Evidence | Confidence |
|------|----|--------|---------------|----------|--------|
| file_sha256 / file_md5 / domain / ip:port / url / mutex / path / registry | … | Where found | YYYY-MM-DD / n/a | E-id | high/med/low |
```

### 1.2 Copyright and security boundaries

- Do not paste vendor PDF or webpage passages or figure captions as your analysis.
- Replace real tokens, internal URLs, and customer identifiers with placeholders.
- Do not output directly usable attack steps for an unauthorized target. Follow the case scope and RULES.

---

## 2. Flavor: `malware` (Huorong style, explicit selection)

**Narrative goal**: Let readers understand within five minutes what it is, how it arrived, what the sample did, how to respond, and which IOCs exist.

### 2.1 Recommended section order

```markdown
# [Title: one-sentence threat classification]

> Analysis date / analyst / sample identifier (hash)

## 1. Overview
(G1: discovery channel, disguise, core techniques, and whether the product can detect or remove it. Write n/a when unknown.)

## 2. Attack / infection flow
(Flowchart: Mermaid or step list. Link to Path `path_type=attack`.)

## 3. Sample analysis
### 3.1 Sample provenance
### 3.2 Static analysis
(**MUST** include import-table / basic-identity Evidence: E-imports or equivalent. See the radare2/ida/malware hard gate.)
### 3.3 Dynamic analysis / behavior
(Use n/a + reason when dynamic conditions are unavailable.)
### 3.4 Core findings (Findings table or numbered list, linked to evidence_ids)

## 4. Incident-response method
(Execute only within the authorized scope. Confirm scope first. Preserve samples, memory, process trees, network connections, and logs. Then isolate the host. After owner approval, terminate processes, isolate or remove files, check hosts and startup items, run a full scan, and verify. Do not delete files before preserving Evidence.)

## 5. Summary
(Risk reminders and prevention for ordinary users and operators.)

## 6. IOC information
(G4 table)

## 7. Evidence chain summary
(§0: E / F / P / Timeline. You may merge this with §3.4, but do not omit fields.)

## 8. Appendix
(Tool versions, reproduction commands, and script paths.)
```

### 2.2 Writing style

- Use Chinese by default for Chinese users. State conclusions first, then details.
- Organize static analysis by component or phase. Do not paste an unstructured long log.
- Each response step must be executable on its own. Do not fill space with vague advice such as "improve security awareness".

---

## 3. Flavor: `apt` (Kaspersky Securelist style)

**Narrative goal**: Explain the campaign story. State who attacked whom, when and with which chain, how the investigation progressed, how components worked together, and what defenders can detect.

### 3.1 Recommended section order

```markdown
# [Campaign/cluster name]: [one-sentence impact]

> Date / team / industry and regional scope (when known)

## 1. Executive summary
(G1: time window, victim profile, entry point, family/cluster attribution, duration, and most important conclusion.)

## 2. The infection chain
(Stages: delivery → exploit/loader → main payload → post-exploitation/credential theft. Mark unknown stages as “limited visibility”.
Link to Path. Add a chain diagram when useful.)

## 3. Incident investigation
(Investigation narrative: key turns, internal-network proxy/C2 features, and how scope expanded. Link to Timeline.)

## 4. Interesting findings
(3–7 non-obvious points. Link each to E-id / F-id when possible.)

## 5. Technical analysis
### 5.1 Component overview table (loader / trojan / stealer / …)
### 5.2 Behavior and configuration by component
### 5.3 Static points (including import-table, packing, and persistence Evidence)
### 5.4 Network and C2
(Add the ATT&CK table G7 when useful.)

## 6. Detection and mitigation
(Detection ideas / hunting clues / mitigation priorities. Do not use empty slogans.)

## 7. IOC
(G4, grouped by type.)

## 8. Evidence chain summary
(§0 fields.)

## 9. Appendix
(Sample list and hashes, tool versions, and public reference numbers. Do not copy external report text.)
```

### 3.2 Writing style

- Write the timeline and visibility limits honestly.
- Interesting findings are not a repeated overview. Write the anomalies that mattered in the investigation.
- Use a table for component analysis: role / persistence / C2 / dependencies. Then add details.

---

## 3b. Thin overlay: `vuln` (vulnerability technical analysis, optional)

> Issue #65 addition. The structure follows public OS/component vulnerability technical-analysis report outlines. **Extract the section outline only. Do not copy PoC requests, exploit details, or unauthorized attack steps from screenshots or report text.**
> This is **not** the third default full vendor flavor. Add it only for vulnerability research or an explicit user request.

**Narrative goal**: Let readers quickly see who is affected, how to confirm or reproduce it within authorization, the root cause and patch difference, and how to mitigate it.

### Recommended section order

```markdown
## 1. Vulnerability overview
### 1.1 Impact scope (versions/components/configuration prerequisites)
### 1.2 Vulnerability reproduction (authorized environment; a third party can repeat the steps; no weaponized tutorial tone)

## 2. Vulnerability analysis
### 2.1 Crash / exception analysis (Evidence: crash log, trigger condition)
### 2.2 Patch analysis (diff/guard conditions/fix point, linked to E-*)
### 2.3 PoC or trigger analysis (existing material within the authorized scope only; describe protocol/input-construction layers without more detail)

## 3. Protection advice
### 3.1 Mitigations (configuration/mitigation switches and so on)
### 3.2 Official patch and verification

## 4. Evidence → Finding → Path (merge into sections or use a separate table)
```

### Hard constraints

- **MUST** scope/authorization: Do not reproduce or extend a PoC against an unauthorized target
- **MUST** E/F/P: Link reproduction, crash, and patch conclusions to evidence_ids
- **MUST NOT** treat `vuln` as the default malware/APT shell
- **MUST NOT** copy exploit code or complete weaponized attack steps from external reports or screenshots
- IOC table: include only when network or file indicators exist. Otherwise use n/a or omit it

---

## 4. Connect to existing task templates

| Task template (`security-report-templates.md`) | Overlay method |
|------------------------------------------|----------|
| 1. Reverse-engineering report | Default `flavor = null`. Keep the original static/dynamic/reproduction outline and hard-gate Evidence such as the import table. Use §2 only for explicit malicious samples |
| 2. Penetration-testing report | `flavor = null`. Add applicable Base G1–G3. Align the attack path with §0 Path. Do not require IOC |
| 3. CTF Writeup | `flavor = null`. Keep the original challenge, solution approach, and reproduction structure. Do not require IOC/ATT&CK |
| 4. JS/Web signature reverse engineering | `flavor = null`. Use the original overview → location → algorithm → reproduction outline. Do not use malware sections |
| Malware / APT specialty | Explicitly select the `malware` or `apt` full outline |

**Conflict resolution**: §0 Evidence chain fields and the scope gate **always take priority**. A flavor changes only narrative order and the professional shell. It MUST NOT delete E/F/P.

---

## 5. Selection pseudocode

```
if user_requests_kaspersky or apt or threat_campaign:
    flavor = apt
elif user_requests_huorong or vir_report or explicit_malware:
    flavor = malware
else:
    flavor = null  # Original task template + applicable Base elements
overlay = null
if user_requests_vuln_tech_report or cve_patch_analysis:
    overlay = vuln  # thin only; never a third default full flavor
emit(base_report)
if flavor in (malware, apt):
    emit(report with flavor outline)
elif overlay == vuln:
    emit(report with vuln thin outline)
```

---

## 6. Completion checklist (self-check at the end of a report)

- [ ] A flavor or explicit "task template + minimum set" is selected
- [ ] G1 overview exists and is not empty prose
- [ ] §0 E/F/P fields are complete
- [ ] `malware` / `apt` report has an IOC table, or n/a plus a reason
- [ ] `malware` / `apt` report has executable advice or response steps
- [ ] A task without a flavor does not use malware/APT-only sections
- [ ] `vuln` is enabled only for vulnerability tasks. It includes the overview, analysis, protection outline, and E/F/P. It has no unauthorized PoC weaponization
- [ ] No vendor text is pasted. No placeholder/TODO remains
- [ ] Import-table and other hard-gate Evidence entered static or technical analysis when the task included binary analysis

---

## 7. Source register

- Kaspersky Securelist, “Updated MATA attacks industrial companies in Eastern Europe”: <https://securelist.com/updated-mata-attacks-industrial-companies-in-eastern-europe/110829> (structure reference; access date: 2026-08-11)
- Huorong Security public technical articles: <https://www.huorong.cn/> (site entry; access date: 2026-08-11. Record the exact article URL, title, and access date when you cite it.)
- Use ATT&CK technique IDs only as normalized mappings. This task's Evidence MUST support them. Do not import IOCs from an external report automatically.

---

## 8. Non-goals

- Do not maintain extra full templates for Mandiant, CrowdStrike, QiAnXin, or other vendors. The two flavors plus the optional thin overlay cover common needs.
- Do not promote `vuln` to a default full flavor alongside malware/apt.
- Do not crawl vendor sites to fill reports.
- Do not reduce the Evidence contract or authorization scope because of a flavor.
