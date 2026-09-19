# 2026-07-22 Electron Bytenode privileged update-chain analysis

## Scenario

Binary analysis, Electron, Bytenode, and update-chain security audit

## Target summary

Cross-layer reverse engineering was performed on a Windows x86 Electron desktop application. The analysis started with the NSIS installer, continued through ASAR and Bytenode JSC, and reached the native game SDK and remote-rendered page. The privilege boundary, IPC capabilities, and update-package trust model were confirmed.

## Execution record

1. Check the outer PE for `{electron_app}` with SHA-256, Authenticode, manifest, sections, overlay, and mitigation controls. Confirm the installer type and privilege level.
2. Expand the NSIS package read-only with 7-Zip. Locate the inner archive and rebuild the file inventory. Extract the original `app.asar` while preserving logical offsets, sizes, and per-file hashes.
3. Identify Electron 22.0.0, Node 16.17.1, and Bytenode 1.5.7 from `package.json`, runtime resources, and JSC strings. Separate the original extraction directory from an existing modified directory.
4. Use the sample's bundled Electron in `ELECTRON_RUN_AS_NODE=1` mode to load `main.jsc` and `preload.jsc`. This avoids host Node/V8 ABI incompatibility.
5. Mock Electron, network, file writes, archives, FFI, subprocesses, and exit behavior in a probe. Record window options, 21 main-process IPC handlers, 29 preload bridge members, and lifecycle callbacks.
6. Freeze a static asset snapshot of `{remote_ui_domain}`. Trace how the `updateUrl` returned by `https://{update_api_domain}/api/user/v1/check_ver` enters local `checkUpdates`.
7. Drive the update handler with a loopback HTTP fixture. Confirm URL receipt, download, extraction, and detached updater startup. Record the absent allowlist, hash, package-signature, and Authenticode checks separately as "not observed on the controlled path".
8. Review the exports, imports, strings, PE protections, signature, and key addresses of `{native_game_sdk}` statically. Distinguish ABI forwarding, callback FIFO, state watchdog, and third-party platform installation branches.
9. Describe service, driver, hosts, root-certificate, proxy, and platform-registry operations as conditional capabilities. State that a capability ran only when the call-chain evidence supports it. Do not infer execution from static capability alone.
10. Output a formal report, three data-flow diagrams, structured IOCs, reproduction commands, and an evidence index. Separate high-confidence static facts, controlled dynamic facts, and the validity boundary of the remote snapshot in the conclusion.

## Pitfalls

| Problem | Cause | Resolution | Time |
|---|---|---|---|
| Host Node could not load JSC directly | Bytenode bytecode binds to a specific V8/Node ABI | Run the probe in the sample Electron's RunAsNode mode | Medium |
| Timers and exit logic interfered after the probe started | The main process includes lifecycle callbacks, a watchdog, and `process.exit` | Add `--run-timeouts`. Mock timers, exit, and four classes of app callback | Medium |
| The update handler needed network, disk, and subprocess paths at once | Handler enumeration proves registration only, not data flow | Add an `--update-url` fixture and record parameters and side effects across the full chain | Medium |
| The analysis directory contained existing modified artifacts | A modified ASAR/JSC could pollute the original conclusion | Use only `{sample_dir}` and `{extracted_original_dir}` as original evidence sources | Low |
| Dual-signed DLL status was easy to misclassify | Each signature can have a different certificate, timestamp, and current validation state | Use `signtool verify /pa /all /v` for each signature | Low |
| Native strings suggested high-privilege system capabilities | Strings and imports do not prove that the current path ran | Combine xrefs and call chains. Mark the result as a conditional capability | Medium |
| The remote UI continued to change | The current chunk and API behavior were not permanent assets | Save dated resource snapshots, hashes, and fetch times | Low |

## Tool findings

- The sample's Electron is the most stable ABI container for executing Bytenode JSC. `ELECTRON_RUN_AS_NODE=1` runs a probe without starting the business GUI.
- Electron mocks must cover `app.whenReady/on/quit`, `BrowserWindow`, `ipcMain.handle/on`, `shell`, `session`, and `webContents`. Otherwise the registered surface is incomplete.
- Update-chain verification must record the input URL, request library, target file, extraction directory, and final `spawn` parameters to build an evidence chain from renderer to updater.
- PE signature audits must separately report that a certificate exists, that it is within its validity period, that it has a trusted timestamp, and that current chain validation succeeds.
- For a large third-party DLL, first partition capabilities with imports, exports, and strings. Then review high-risk service, network, certificate, and process-creation branches by address.

## Key code and commands

```powershell
$env:ELECTRON_RUN_AS_NODE = '1'
$env:__COMPAT_LAYER = 'RunAsInvoker'

& '{electron_exe}' '{probe_script}' '{main_jsc}' `
  --execute --exercise=all --run-timeouts --quiet `
  --out='{main_probe_json}'

& '{electron_exe}' '{probe_script}' '{main_jsc}' `
  --execute --exercise=all --run-timeouts `
  --update-url='http://127.0.0.1:{port}/update.zip' --quiet `
  --out='{update_probe_json}'

& '{electron_exe}' '{probe_script}' '{preload_jsc}' `
  --execute --exercise=bridge --quiet `
  --out='{preload_probe_json}'

signtool verify /pa /all /v '{native_game_sdk}'
```

## Improvement suggestions for this package

1. Add a Bytenode ABI decision tree to the Electron/JS reverse-engineering path. After host Node fails, try the target Electron RunAsNode mode first.
2. Add a generic Electron mock coverage matrix and an IPC registration/call consistency script.
3. Make the updater audit template check URL constraints, transport protocol, manifest signature, package hash, signature chain, archive traversal, and final execution parameters.
4. Add mandatory "conditional capability" and "observed behavior" columns to the report template. This reduces over-inference from imports and strings.

## Reusable patterns and script fragments

1. **Three-layer trust boundary**: original installer → original ASAR/JSC → remote page snapshot. Build a hash and timestamp at each layer.
2. **Separate registration and execution surfaces**: enumerate IPC and preload APIs first. Then call high-risk handlers with mock fixtures and capture side effects.
3. **Five-part update chain**: `source URL -> downloader -> archive path -> extractor -> executable`. Save evidence for every node.
4. **Native capability levels**: imports and strings are leads, xrefs and call chains are capability evidence, and real dynamic events are executed facts.
5. **Four-state signature model**: report signature existence, certificate validity, timestamp, and current trust validation separately.

## Follow-up actions

- [x] Add the pitfall record
- [x] Update the experience index
- [ ] Update the routing matrix
- [ ] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation

## Environment

- OS: Windows 11 x64
- Tool versions: Electron 22.0.0, Node 16.17.1, Bytenode 1.5.7, Python 3.12
- Target platform/version: Windows x86 / Electron desktop app

## Redaction requirements

This record keeps only generic versions, API path structure, scale, and analysis methods. The sample name, publisher, real domains, case directory, hashes, configuration keys, tokens, and user identifiers were replaced or omitted. No sample file is attached.

---
<!-- [Community contribution] Ask the user whether to open a PR against the main repository after completion. See CONTRIBUTE-BACK.md for the process. -->
