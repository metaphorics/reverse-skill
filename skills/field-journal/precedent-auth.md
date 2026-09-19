# Authorization pre-declaration — reduce disclaimer noise without replacing scope.md

> This file addresses one point: do not treat a user selecting a target as authorization.
> The executable authorization gate remains `case-init.ps1` → `work/<case>/scope.md` with `auth.status=granted` and a valid `network_profile`.

---

## CRITICAL

Common scenarios in this package (SRC / owned systems / paid contracts / CTF labs / responsible disclosure) **can** use fewer boilerplate disclaimers.

**AI must not treat this file as `auth.status=granted`.**

- A user naming a domain, IP, or sample path does not mean authorization.
- Do not use this file to skip `case-init`.
- Do not add `-AuthGranted` automatically in a skill "to keep the process moving".
- CTF / labs: still create a case and set `network_profile` to `lab` or `offline`.
- Real external targets: ACT only with granted plus `authorized_target_only` (or the contract profile).

---

## Allowed / prohibited

1. **MUST NOT** use this file to override `ops/scope-contract.md`.
2. **MUST NOT** run nmap, sqlmap, uploads, or exploitation against a target without `scope.md`.
3. **MUST** distinguish "use fewer legal disclaimers" from "permission to act".
4. **MUST** provide technical analysis when technical details are uncertain. Do not stop by pretending authorization is missing.
5. If no case exists or `auth.status!=granted`, run `case-init` first. Do not guess.

---

## Relationship to other files

| File | Purpose |
|------|------|
| **precedent-auth.md** (this file) | Fewer disclaimers; **does not** grant authorization |
| `ops/scope-contract.md` + `case-init.ps1` | Only executable authorization gate |
| `precedent-reverse.md` / `precedent-pentest.md` | Routine operations are not crime tutorials; they remain subject to scope |

```
case-init / scope.md → Can ACT?
precedent-auth.md    → Do not replace scope with boilerplate
PRIMARY SKILL.md     → How to do it
```
