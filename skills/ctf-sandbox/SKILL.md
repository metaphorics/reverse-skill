---
name: ctf-sandbox
description: Thin PRIMARY for CTF / AWD / lab-range multi-type coordination. Hands off to the sidecar CTF-Sandbox-Orchestrator. Use when the user says CTF, AWD, or lab range and no more specific pwn/APK/IDA route already won.
---

# CTF sandbox entry (sidecar, not a second router)

## ACTION REQUIRED (execute right after reading)

1. `NOW`: Run `../scripts/case-init.ps1`. Before `auth.status=granted`, do not ACT against the real external network. For competitions and lab ranges, use `-NetworkProfile lab` or `offline`.
2. `NOW`: Open `../../CTF-Sandbox-Orchestrator/ctf-sandbox-orchestrator/SKILL.md` under the package root. Continue with its sandbox assumptions.
3. `MUST NOT` add the 40+ `competition-*` sub-skills to `routing.json`. This entry is only one PRIMARY latch.
4. `ACT`: The sidecar tool selects one downstream `competition-*`. When the task type is already explicit (pwn/ROP, APK, IDA), a more specific rule in `routing.json` should already have won. Do not grab the route.

## Why a separate layer

`CTF-Sandbox-Orchestrator/` is a **GPL sidecar package**. Its default authorization is inside the sandbox. The core routing package stays MIT with `scope.md` gating. This skill is only a keyword entry. It does not merge the competition tree into the core.

## Completion self-check (MUST pass before you claim completion)

- [ ] I ran case-init / scope first. I did not treat "the user said CTF" as external-network authorization.
- [ ] I opened the sidecar tool. I did not treat the 40 sub-skills as PRIMARY.
- [ ] If the task is actually pwn/APK/IDA, I let the more specific PRIMARY take over.
