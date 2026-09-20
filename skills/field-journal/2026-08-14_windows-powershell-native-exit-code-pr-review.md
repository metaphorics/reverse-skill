# 2026-08-14 Windows PowerShell native-command exit-code PR review

## Scenario

Other, toolchain, supply-chain bootstrap scripts, and open PR review

## Target summary

Evaluate a bootstrap-script PR from a fixed source and commit. Verify that it remains fail-closed on Windows PowerShell 5.1 without wrongly rejecting a valid checkout.

## Scope summary (redacted)

- auth_basis: repository maintainer authorized review of a public PR and submission of a review
- network_profile: public code-hosting platform; read-only during evidence collection, review submitted after the conclusion was confirmed
- asset_types: [public source code, CI results, Windows PowerShell bootstrap script]

## Roles

- lead_role: lead
- specialists: [supply-chain-reviewer, windows-compatibility-reviewer]

## Execution record

1. Pin the PR head commit. Read the change, discussion, CI, and target script. Do not review a moving target.
2. Split the security goal into six items: fixed source, fixed commit, atomic replacement, dirty-directory rejection, lockfile installation, and platform compatibility.
3. Confirm that the single manifest source, staged checkout, dirty-tree fail-closed behavior, and frozen lockfile are sound design directions.
4. Locate the checkout verification function. Run the native command and the pipeline version with `Select-Object` separately in Windows PowerShell 5.1.
5. Observe that both executions return the same commit text, but the pipeline version reads `$LASTEXITCODE` as `-1`. This wrongly rejects a valid checkout.
6. Run the supply-chain test script. Confirm that the failure occurs before the expected dirty-tree assertion. Exclude a problem in the test fixture itself.
7. Submit a changes-requested review on the PR. Require saving the native-command exit code before processing output and add Windows PowerShell 5.1 validation.
8. Redact and write back the reproduction method and review criteria for later PowerShell bootstrap-script reviews.

## Evidence chain summary (redacted)

| E-id | severity | status | source_type | Reusable command pattern | Related finding |
|------|----------|--------|-------------|----------------|--------------|
| E-001 | info | observed | command | `powershell.exe -NoProfile -Command "& git -C {install_dir} rev-parse HEAD; $LASTEXITCODE"` | F-001 |
| E-002 | medium | validated | command | `powershell.exe -NoProfile -Command "& git -C {install_dir} rev-parse HEAD \| Select-Object -First 1; $LASTEXITCODE"` | F-001 |
| E-003 | medium | validated | command | `powershell.exe -NoProfile -File skills/scripts/tests/test-bootstrap-supply-chain.ps1` | F-001 |

## Finding and path summary

- top_finding: In Windows PowerShell 5.1, reading `$LASTEXITCODE` after native-command output enters the object pipeline can return `-1`. Even when the output commit exactly matches the pinned value, this triggers a false checkout verification failure.
- path_type: callflow
- path_one_liner: `git rev-parse` succeeds → output enters `Select-Object` → `$LASTEXITCODE` changes → the fail-closed branch wrongly rejects the valid checkout

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| All existing CI passed but Windows still regressed | CI covered newer PowerShell and Bash, not Windows PowerShell 5.1 native-command pipeline semantics | Use `powershell.exe` for a minimal reproduction and the full supply-chain test | About 20 minutes |
| Identical commit text was judged inconsistent | Verification depended on output and a later read of `$LASTEXITCODE` | Save the exit code immediately after the native command. Normalize output separately | About 10 minutes |
| A clean PR display looked mergeable | `mergeable` describes Git merge state, not target-runtime compatibility | Gate base freshness, the platform matrix, and local reproduction separately | About 5 minutes |

## Tool findings

- GitHub API works for pinning the PR head and reading CI and commit status. Bind the review record to the verified commit.
- `powershell.exe` and `pwsh` are not interchangeable test entry points. Scripts for Windows PowerShell 5.1 must run in that host.
- `$LASTEXITCODE` is mutable session state. A later pipeline or command can destroy the native-command meaning before a delayed read.

## Key code and commands

```powershell
# Capture native-command output first, then save the exit code immediately.
$output = & git -C $CheckoutPath rev-parse HEAD 2>$null
$gitExitCode = $LASTEXITCODE
$resolvedCommit = [string]($output | Select-Object -First 1)

if ($gitExitCode -ne 0 -or $resolvedCommit.Trim() -ne $PinnedCommit) {
    throw "Checkout verification failed"
}
```

## Improvement suggestions for this package

- Add a `powershell.exe` 5.1 test job to PRs that modify PowerShell bootstrap scripts. Do not cover them with `pwsh` only.
- Add a supply-chain checklist item that asks whether the native-command exit code is saved before the next command.
- Before merge, check the PR head, the latest-main difference, and target-platform tests. Do not replace runtime validation with GitHub's clean state.

## Reusable pattern

Use three stages for every PowerShell native command: execute and capture output, save `$LASTEXITCODE` immediately, then parse output with the PowerShell pipeline. Error decisions may use the saved exit code only.

## Follow-up actions

- [ ] Update the routing matrix
- [ ] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation
- [x] Add the pitfall record
- [ ] No update needed

## Environment

- OS: Windows
- Tool versions: Windows PowerShell 5.1, Git 2.x
- Target platform/version: PowerShell-compatible bootstrap script, public PR head commit

## Redaction check

- [x] No real domain, IP, credential, Token, Cookie, or PII
- [x] Local installation path replaced with `{install_dir}`
- [x] No user project file or private repository content attached

---
<!-- [Evolution statistics] Completed projects in this package: 18 | New patterns this time: 1 | Toolchain issues fixed this time: 0 -->
<!-- [Community contribution] The user authorized writing this redacted experience back through a separate PR. -->
