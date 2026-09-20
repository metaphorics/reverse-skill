# 2026-08-08 open PR value triage and safe integration

## Scenario

Other, repository maintenance, and contribution review

## Target summary

Synchronize the upstream mainline while preserving uncommitted worktree content. Review several open PRs. Safely integrate low-risk contributions with high reuse value into the local mainline.

## Execution record

1. Check the remote, branch lag, and worktree changes.
2. Isolate user changes with stash. Fast-forward to the latest mainline. Restore and verify the changes.
3. Fetch open PR refs. Compare commits, file scopes, and three-way merge results.
4. Classify contributions containing only redacted field-journal records as low-risk candidates.
5. For core-script PRs, check conflicting files, change size, and duplicate mainline implementations.
6. Merge four journal PRs, recalculate the index once, and run smoke plus routing coherence.

## Pitfalls

| Problem | Cause | Resolution |
|---|---|---|
| Pulling mainline overwrote local index changes | Upstream and the worktree both modified `_index.md` | Isolate with stash, fast-forward, then restore |
| Old PR index counts overwrote each other | Several PRs used the same old baseline | Merge content files, then recalculate the index once |
| A large PR looked valuable but could not merge directly | The mainline had advanced and core scripts had content conflicts | Pause it. Require a rebase and focused tests |

## Reusable patterns

- Separate documentation from executable code first. Then rank by reuse value, conflict surface, and test evidence.
- For journal-only PRs, separate content merging from index coordination.
- For core-infrastructure PRs, treat a conflict as more than a text problem. Recheck behavioral equivalence.

## Verification results

- smoke: all passed
- routing coherence: all passed
- user worktree content: fully restored with no conflicts

## Redaction review

No credentials, private targets, user identities, or internal URLs are included.
