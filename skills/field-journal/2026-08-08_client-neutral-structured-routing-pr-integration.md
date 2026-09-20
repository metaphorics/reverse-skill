# 2026-08-08 client-neutral structured-routing PR integration

## Scenario

Code audit, toolchain maintenance, and multi-platform routing

## Target summary

Review the incremental value of several high-conflict PRs. Refactor valuable parts into a client-neutral core, then integrate them.

## Scope summary (redacted)

- auth_basis: repository_owner_authorized
- network_profile: authorized_upstream_only
- asset_types: [source_repository, pull_request_refs, local_tests]

## Roles

- lead_role: lead
- specialists: [cae, doc]

## Execution record

1. Fetch PR refs from the remote. Compare each PR with the current mainline in an isolated worktree.
2. Judge incremental value first. Preserve source relationships with a merge parent, then resolve conflicts by meaning.
3. Decouple structured routing from client integration. Use JSON as the shared source of truth for PowerShell and Bash.
4. From large PRs, take only authorization gates and Bash parity. Exclude client-specific and generated assets.
5. Run the full routing, structural-gate, language-unit, syntax, and manifest checks.

## Evidence chain summary (redacted)

| E-id | source_type | Reusable command pattern | Related finding |
|------|-------------|----------------|--------------|
| E-001 | git diff | `git diff <main>...<pr-ref>` | F-001 |
| E-002 | regression | `test-routing.ps1` + coherence + smoke | F-001 |
| E-003 | unit tests | Python unittest + Node test + Bash parity | F-002 |

## Finding and path summary

- top_finding: client integration is not the core value of structured routing. A single source of truth and automatic gates are.
- path_type: callflow
- path_one_liner: any host → optional adapter → routing.json → cross-platform router → unified regression gates

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| A large PR mixed client inventories, GIFs, scripts, and documentation | The concerns were not separated | Merge only the smallest cross-platform subset | Medium |
| Bash and PowerShell routers each used hardcoded values | Two sources of truth inevitably drift | Make Bash read the same JSON through Python | Medium |
| The new pin gate failed first | The Kali manifest retained a floating source | Pin the manifest and make the real install command use the pin | Medium |
| Gradle wrapper download failed during TLS | External network handshake error | Record it and retry during final validation | Low |
| Bash CaseName could write outside the work root | Selective integration omitted a path constraint already present in PowerShell | Add an equivalent cross-platform check and a negative CI test | Medium |
| An authorized URL was marked offline | The Bash default did not match PowerShell | Set the network default to `authorized_target_only`; reserve offline for local samples | Low |
| INDEX passed on the development machine but failed in a clean clone | The generator scanned a local private module that Git ignored | Enumerate Git-tracked SKILL.md files only | Medium |

## Tool findings

A Git merge parent preserves the PR source relationship and still permits semantic deletion inside the merge commit. A supply-chain gate works only when manifest metadata and the real install command use the same fixed value.

## Key code and commands

```text
git merge --no-ff --no-commit <pr-ref>
powershell -File skills/scripts/test-routing.ps1
powershell -File skills/scripts/verify-routing-coherence.ps1
bash skills/scripts/master-route.sh --hint "case review evidence graph"
```

## Improvement suggestions for this package

Keep all client adapters behind a separate boundary. Do not put client configuration in a core routing PR. Split large PRs into core, adapters, demo assets, and documentation.

## Reusable patterns and script fragments

Structured-routing parity tests must cover ordinary routes, conflict-priority routes, and the latest new route. This prevents a platform entry point from falling behind.

Run an old/new A/B comparison on the same 163-case baseline. The old hardcoded implementation passed 137/163 (84.05%). The structured implementation passed 163/163 (100%). Only a quantified comparison on the same inputs proves a substantive refactor instead of file-count growth.

## Follow-up actions

- [x] Update the routing matrix
- [ ] Update the tool index
- [x] Update the bootstrap manifest
- [x] Update the child skill documentation
- [x] Add the pitfall record
- [ ] No update needed

## Environment

- OS: Windows (primary validation) plus Linux CI definition
- Tool versions: Git / PowerShell / Python 3 / Node.js / Bash
- Target platform/version: client-neutral repository core

## Redaction requirements

This entry contains no real target, credential, internal address, or personal identity information.

---
<!-- [Community contribution] Prepared for a mainline push as directed by the repository owner. -->
