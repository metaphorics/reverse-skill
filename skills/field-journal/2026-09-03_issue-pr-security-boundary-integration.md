# 2026-09-03 multi-issue and PR security-boundary integration

## Scenario

Maintain a public security-skill routing repository. The local main worktree contains extensive user changes and trails the remote. At the same time, review several open PRs, resolve historical issues, add features, publish a security review, and close the GitHub status and cross-platform CI loop.

## Reusable patterns

1. **Isolate the dirty worktree**: fetch the remote first, then create an independent worktree from `origin/main`. Run all PR merges, conflict resolution, tests, and commits in the isolated directory.
2. **Preserve PR ownership**: merge accepted PR heads as merge-commit parents on the integration branch. After the final fast-forward push to main, GitHub marks the corresponding PRs merged or closed automatically.
3. **Freeze state**: record every PR head SHA before merging. Fetch again before pushing. Require the remote main to remain equal to the review baseline. Verify that every accepted PR head is an ancestor of the final HEAD.
4. **Review under AV isolation**: for payload documentation that Defender may quarantine, do not rely on worktree files. Use `git show :path` or Git index blobs for hash, link, and content-boundary checks.
5. **Separate reference and executable content**: passive Markdown and JSON payloads may remain, but executable scripts must not reference them. CI fixes the corpus hash, binary allowlist, symbolic links, dangerous patterns, and full-SHA GitHub Actions.
6. **Do not merge feature PRs blindly**: run the original PR tests, then check cross-instance state, path and port isolation, and new mainline constraints. This run found that an IDA keepalive file was not isolated by port and corrected it in the merge commit.
7. **Close issues with evidence**: return each issue to a traceable conclusion first, then close it as completed, duplicate, or not planned. Do not omit the explanation in the name of batch cleanup.

## Pitfalls

| Problem | Cause | Resolution |
|---|---|---|
| GitHub showed a PR as mergeable, but merging into the latest mainline caused a semantic conflict | The PR base was stale and several PRs changed the same CI or routing file | Simulate the merge locally, resolve against the latest single source of truth, and rerun the full tests |
| AV deletion of payload worktree files caused ordinary scans to miss them | Markdown extensions can still match signature rules | Read Git index blobs and never skip a file because it cannot be read from the worktree |
| A Binary Ninja MCP source looked official | The MCP project is a community GPL plugin, not an official Vector 35 component | State the source, review commit, bridge version, and loopback binding clearly in the skill |
| Git Bash could not model the Linux Python-to-Bash subprocess exactly | Windows CreateProcess resolves the system `bash.exe` or WSL first | Run Bash syntax and direct contracts locally. Use Ubuntu/macOS CI as the final authority |

## Verification

- Routing regression: 175/175
- Windows PowerShell 5.1 and PowerShell 7: P0, encoding, evidence, IDA, and smoke all passed
- Python: case review, documentation links, and repository security all passed
- Bash: syntax, case workflow, and the new Binary Ninja route passed
- GitHub: Windows, Ubuntu, macOS, and Gradle Wrapper Validation all passed
- Open issues and PRs on the remote: 0

## Environment

- OS: Windows
- Git: isolated worktree plus PR-head ancestor verification
- CI: Windows, Ubuntu, macOS
- Data handling: public repository metadata and redacted method records only
