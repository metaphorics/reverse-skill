# 2026-08-17 reverse-skill

## Scenario

Toolchain and environment, bootstrap-stage defect repair

## Target summary

Repair three defects hidden by successive failures in the local bootstrap process. The tool index reported the radare2 main analyzer `r2` as unavailable. Multiple test scripts hardcoded `powershell` subprocess calls and failed on machines with only PowerShell 7+. That failure hid a pin-gate StrictMode property-access bug.

## Scope summary (redacted)

- auth_basis: own_system (this repository)
- network_profile: offline / no external target activity
- asset_types: [local repository and tool reference]

## Roles

- lead_role: lead
- specialists: [bootstrap, test-infra]

## Execution record

1. Follow section 0 of `README_AI.md` for bootstrap. `refresh-tool-index.ps1` generates `tool-index.md` with 37 tools.
2. Read `tool-index.md` and find the anomaly: `r2` (the radare2 main analyzer) is `no`, while `rabin2`, `rasm2`, `radiff2`, `rahash2`, `rax2`, and `r2pm` in the same directory are all `yes`.
3. List `C:\Users\{username}\Tools\radare2\bin`. Confirm `r2.bat` (21 bytes, content `@"%~dp0\radare2" %*`) and `radare2.exe` exist, but **`r2.exe` does not**.
4. Read `lib/ToolDiscovery.ps1:131-141`. The `r2` fallbacks search only for `r2.exe`, so they miss `r2.bat` and `radare2.exe`. Compare `jadx`, `apktool`, and `analyzeHeadless`, which already define fallbacks for `.bat` tools.
5. Repair the `r2` fallbacks with `r2.bat` and `radare2.exe` paths. Cover `%USERPROFILE%\Tools\radare2\bin`, the root directory, and `C:\Tools\`. Keep the original `r2.exe` fallback for other machines.
6. Rerun `refresh-tool-index.ps1`. `r2` becomes `yes`, with path `r2.bat`, version `radare2 6.2.0`, and source `FallbackPath`.
7. Run `smoke.ps1`. It still fails because `verify-routing-coherence` exits 1. Run verify directly. Find hardcoded `& powershell` at `verify-routing-coherence.ps1:257`. This host has only `pwsh` 7.6.4 and no `powershell`.
8. Search all `.ps1` files for `powershell\s(-NoProfile|-ExecutionPolicy|-File|-Command)`. Find more than 20 hardcoded `& powershell` subprocess calls in 5 scripts: 7 in verify, 18 in test-p0-friction, 1 in test-routing, and 1 in case-init. The rest are comment examples.
9. Find that `smoke.ps1:31-46` already uses `$SmokeHostExe`, preferring the current process path, then `pwsh`, then the Windows PowerShell path. Extract this verified logic into the shared `Resolve-ReverseHostExe` function. Create `lib/HostRuntime.ps1` with this order: current process, `pwsh`, `powershell`, then `%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`.
10. Dot-source `HostRuntime.ps1` in four child scripts and define `$HostExe`. Replace `& powershell -NoProfile -ExecutionPolicy Bypass -File` with `& $HostExe -NoProfile -ExecutionPolicy Bypass -File`. Separately change `test-p0-friction.ps1:244` from `cmd /c "powershell ..."` to `cmd /c "`"$HostExe`" ..."`, because paths may contain spaces.
11. Rerun smoke. Verify passes 257 checks but exposes another failure at `verify-routing-coherence.ps1:414`: under `Set-StrictMode -Version Latest`, the pin gate reads nonexistent properties such as `$cap.pinnedVersion`. This is a pre-existing bug that the PowerShell failure had hidden.
12. Repair line 414. Convert `$cap` to a hashtable (`$capMap`). Indexing a missing key returns `$null` without an error. Keep the pin-gate semantics unchanged.
13. Rerun smoke. All checks pass (`VERIFY_EXIT=0 / PARSE 11/11 / ROUTE 9/9`).
14. Run `test-routing.ps1`. It passes 166/166.
15. Run `test-p0-friction.ps1`. Most checks pass, but lines 343 and 364 hit `Start-Process -FilePath 'powershell.exe'`. The earlier search pattern `powershell\s+(-NoProfile...)` missed the `powershell.exe` literal.
16. Search `powershell\.exe`. Confirm that only the two `Start-Process` calls in test-p0-friction are hardcoded. The other matches are compatibility lookups or fallback paths. Replace both with `Start-Process -FilePath $HostExe`.
17. Rerun `test-p0-friction.ps1`. It passes (`FAIL_COUNT=0`). All three suites are green.

## Evidence chain summary (redacted)

> This repair concerns the repository's own bootstrap. It has no external target activity and produces no evidence files under a case directory. The following reproducible validation commands are equivalent evidence.

| E-id | severity | status | source_type | Reusable command pattern | Related finding |
|------|----------|--------|-------------|----------------|--------------|
| E-r2 | info | validated | command | `pwsh -File skills/scripts/refresh-tool-index.ps1` then the `r2` line in `tool-index.md` is `yes` | F-r2 |
| E-smoke | info | validated | command | `pwsh -File skills/scripts/smoke.ps1` → `OVERALL: ALL PASS` | F-host |
| E-route | info | validated | command | `pwsh -File skills/scripts/test-routing.ps1` → `166/166 ALL PASS` | F-host |
| E-p0 | info | validated | command | `pwsh -File skills/scripts/test-p0-friction.ps1` → `OVERALL: ALL PASS` | F-host |

## Finding and path summary

- top_finding: Three defects hid one another. The `r2` fallback missed the `.bat` entry. Hardcoded `powershell` then stopped verify. That failure hid the pin-gate StrictMode property-access bug. The compatibility search also missed the `powershell.exe` literal.
- path_type: solve
- path_one_liner: unify subprocess entry through `Resolve-ReverseHostExe` with current-process priority, add `.bat` and `radare2.exe` fallbacks for `r2`, and safely access optional PSCustomObject properties through a hashtable

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| The tool index marked `r2` as `no`, while other r2 tools in the same directory were `yes` | `ToolDiscovery.ps1` searched only for `r2.exe`. The Windows radare2 distribution uses an `r2.bat` wrapper for `radare2.exe` and has no `r2.exe` | Add `r2.bat` and `radare2.exe` fallback paths | Short |
| Smoke still failed because verify exited 1 | Verify hardcoded `& powershell`. The host had only pwsh 7+ and no `powershell` | Create `lib/HostRuntime.ps1` with `Resolve-ReverseHostExe`. Replace four scripts with `& $HostExe` | Medium |
| Verify failed again at line 414 after the PowerShell repair | A pre-existing bug hidden by the line-257 PowerShell failure accessed missing properties under StrictMode | Convert `$cap` to `$capMap` and use indexing | Short |
| test-p0-friction failed again at lines 343 and 364 | `Start-Process -FilePath 'powershell.exe'` was hardcoded. The earlier search pattern missed the literal | Search `powershell\.exe` and use `$HostExe` | Short |
| test-p0-friction printed many `Exception: case-init.ps1:54` lines | Test 14b intentionally uses an invalid CaseName to trigger the case-init exception | No action. The final `FAIL_COUNT=0` is the pass condition | — |

## Tool findings

- **Windows radare2 distribution**: the main program is `radare2.exe`. `r2.bat` (`@"%~dp0\radare2" %*`) is its batch wrapper. **`r2.exe` does not exist**. A tool scan that checks only `r2.exe` reports a false negative. `rabin2.exe` and `rasm2.exe` in the same directory are independent `.exe` files and can be probed normally.
- **PowerShell 7+ only environment**: this host has pwsh 7.6.4 at `C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe`, but **no `powershell` or `powershell.exe`**. Every `& powershell ...` subprocess call fails directly in this environment.
- **StrictMode property access**: under `Set-StrictMode -Version Latest`, reading a missing PSCustomObject property throws. Hashtable indexing of a missing key returns `$null`, which is safe for gates with many optional properties.
- **Compatibility-search blind spot**: `powershell\s+(-NoProfile...)` catches only the `& powershell -File` form. It misses `Start-Process -FilePath 'powershell.exe'` and `cmd /c "powershell ..."`. Compatibility scans must cover both `powershell\s` and `powershell\.exe`.

## Key code and commands

```powershell
# lib/HostRuntime.ps1, unified PowerShell subprocess entry with current-process priority
function Resolve-ReverseHostExe {
    [CmdletBinding()] [OutputType([string])] param()
    $hostExe = $null
    try { $p = (Get-Process -Id $PID -ErrorAction Stop).Path; if ($p -and (Test-Path -LiteralPath $p)) { $hostExe = $p } } catch { }
    if (-not $hostExe) { $c = Get-Command pwsh -ErrorAction SilentlyContinue; if ($c -and $c.Source) { $hostExe = $c.Source } }
    if (-not $hostExe) { $c = Get-Command powershell -ErrorAction SilentlyContinue; if ($c -and $c.Source) { $hostExe = $c.Source } }
    if (-not $hostExe -and $env:SystemRoot) { $f = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'; if (Test-Path -LiteralPath $f) { $hostExe = $f } }
    if (-not $hostExe) { throw 'No usable PowerShell host executable found.' }
    return $hostExe
}

# ToolDiscovery.ps1 r2 fallbacks, add .bat and .exe entries
Fallbacks = @(
    @{ Type = 'command'; Value = 'r2' },
    @{ Type = 'command'; Value = 'radare2' },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\r2.bat') },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\radare2.exe') },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\r2.exe') }
    # ... root and C:\Tools mirrors
)

# verify-routing-coherence.ps1:412, safe pin-gate property access
foreach ($cap in $mc.capabilities) {
    $capMap = @{}
    foreach ($prop in $cap.PSObject.Properties) { $capMap[$prop.Name] = $prop.Value }
    if (-not $capMap['canAutoInstall']) { continue }
    $hasPin = ($capMap['pinnedVersion'] -or $capMap['pinnedCommit'] -or $capMap['pinPolicy'])
    # ... switch ($capMap['bootstrapKind']) ...
}
```

## Improvement suggestions for this package

- **Script compatibility scans**: in `verify-routing-coherence.ps1` or a separate lint, scan subprocess calls in every `.ps1`. Reject bare `powershell` and `powershell.exe`. Require `Resolve-ReverseHostExe`. This run used manual grep and missed the `powershell.exe` case.
- **`.bat` tool-catalog convention**: on Windows, `jadx`, `apktool`, `r2`, and `analyzeHeadless` use `.bat` wrappers around `.exe` files. Give each tool both `.bat` and matching `.exe` fallbacks.
- **pwsh-only CI matrix**: if `windows-latest` does not preinstall Windows PowerShell 5.1, this class of bug will surface. `smoke.ps1` already uses `$SmokeHostExe`, but the child scripts did not reuse it.
- **PSCustomObject traversal under StrictMode**: for checks with loose object schemas, consistently convert to a hashtable before access, or provide a `Get-SafeProp` helper.

## Reusable patterns and script fragments

- `Resolve-ReverseHostExe`: when a script needs a child PowerShell process, dot-source `lib/HostRuntime.ps1`, then call `& $HostExe -NoProfile -ExecutionPolicy Bypass -File <script> ...`. This supports pwsh-only, powershell-only, and mixed environments.
- `$capMap` conversion: copy PSCustomObject properties into a hashtable, then use index access to avoid missing-property exceptions under StrictMode.
- `r2.bat` → `radare2.exe` forwarding: `r2.bat -v` returns `radare2 6.2.0`, proving that the wrapper forwards arguments and can be used as the catalog entry.

## Follow-up actions

- [x] Update the tool index (`r2` becomes yes, path `r2.bat`)
- [x] Add `skills/scripts/lib/HostRuntime.ps1`
- [x] Repair `ToolDiscovery.ps1` r2 fallbacks
- [x] Repair the hardcoded PowerShell call and pin-gate StrictMode in `verify-routing-coherence.ps1`
- [x] Repair hardcoded PowerShell calls in `case-init.ps1`, `test-routing.ps1`, and `test-p0-friction.ps1`
- [ ] Update the routing matrix (none)
- [ ] Update the bootstrap manifest (none)
- [x] Add the pitfall record (this entry)

## Environment

- OS: Windows (win32)
- Shell/host: pwsh 7.6.4 (`C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe`); no `powershell` or `powershell.exe` on this host
- radare2: 6.2.0 +1 abi:132 @ windows-x86_64 (installed at `C:\Users\{username}\Tools\radare2\bin\`)
- Repository root: `D:\Sources\reverse-skill`

## Redaction requirements

This repair concerns the repository's own scripts. It has no real target domain, IP, or credential, so no redaction is needed.

## Index synchronization (last step before commit)

After writing this journal, update `_index.md`:
1. Add one line to the "Toolchain and environment" section.
2. Add this file to "High-frequency success patterns" for unified PowerShell subprocess entry.
3. Add this file to "Entity inverted index" for reverse-skill bootstrap scripts.
4. Update the total count and last-updated date.

---
<!-- [Evolution statistics] Completed projects in this package: 19 | New patterns this time: 1 (unified Resolve-ReverseHostExe subprocess entry) | Toolchain issues fixed this time: 3 (r2 fallback / hardcoded powershell / pin-gate StrictMode) -->
<!-- [Community contribution] This repair fixes a repository bootstrap defect and qualifies as a repair PR under CONTRIBUTING.md. Ask the user whether to submit it. -->
