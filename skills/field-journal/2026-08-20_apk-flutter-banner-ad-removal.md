# 2026-08-20 Flutter APK server-driven ad removal (third-party counterfeit package)

## Scenario

APK reverse engineering and Flutter AOT patching

## Target summary

Remove server-driven banner and popup ads from a locally owned APK (`{target_app}` 1.0.8, a third-party counterfeit package), then produce a re-signed build.

## Scope summary (redacted)

- auth_basis: user's local file, modified for personal use
- network_profile: static analysis plus local build, with no external system activity
- asset_types: [android_apk, flutter_aot_libapp.so]

## Roles

- lead_role: lead
- specialists: []

## Execution record

1. Identify the target: `{target}.apk`, Flutter 3.4.4 (`libapp.so` 13MB) with 360 packer protection (`com.frezrik.jiagu.StubApp`; the real DEX is encrypted in a 2.58MB payload at the end of `classes.dex`).
2. Perform static reconnaissance: `apktool d` and `jadx` show no third-party ad SDK in the manifest. Scan `libapp.so` strings and find the server-driven ad system (`ad_slot_key`/`ad_show:`/`wcstream_*` slots and the `system/banner/bannerListByMAcct` API).
3. Build the toolchain: the prebuilt ARM64-Linux blutter package from Gitee does not run. Download the blutter-unmgr source. Build on Windows with MSVC (VS2026 BuildTools + cmake + ninja). Compile the `dartvm3.4.4_android_arm64` static library in about 15 minutes. Run `blutter.exe` on `libapp.so`. Output `pp.txt`, `objs.txt`, `asm/`, and Frida scripts.
4. Recover the ad system: class `qya` (ad model, 11 fields), `pya` (banner list), `GBg` (`Map<String,dynamic>` to `Map<String,List<qya>>` parser), all slot keys, and API endpoints.
5. Design the patch (v2 revision): use **equal-length string replacement** for 31 ad strings across 2 ABIs. Replace JSON keys with a garbage string so parsing returns null, slot keys with a garbage string so lookup fails, and reporting labels with a garbage string. **Keep API path strings unchanged**. The first version replaced them and caused a real-device 404 that stalled startup, as described in the last pitfall. The client stays internally consistent while the server contract breaks.
6. Adapt to string-table formats: the arm64 packed table is `[0x80|(len<<1)][chars]`; the armv7 object table is `[len*2 u32le][chars]`. Validate prefixes and replace long strings first to avoid substring overlap (`welfare_ad_top/welfare_ad`, `ad_click:/ad_click`).
7. Repackage: copy 1010 entries with Python zipfile, replace two `libapp.so` files, and remove old signatures. Run `zipalign -p 4`, then `apksigner` v1+v2+v3 with a debug keystore.
8. Verify: Blutter reanalysis of the patched `libapp.so` passes with the snapshot intact. `apksigner verify` passes. AAPT badging is unchanged. The ZIP diff contains only `libapp.so` and signatures. The APK contains zero remaining ad strings.
9. **Real-device runtime validation**: an arm64 device was used for installation. The main screen opened normally and ads disappeared. `logcat` confirmed zero Flutter exceptions, as detailed in the pitfalls.

## Evidence chain summary

| E-id | source_type | Reusable command pattern | Related finding |
|------|-------------|----------------|--------------|
| E-001 | blutter_out/pp.txt | `[pp+0x210a8] String: "wcstream_banner_top"` | F-001 |
| E-002 | patch script | `work/patch_libapp.py` | F-001 |
| E-003 | Blutter reanalysis | `python blutter.py <patched_dir> <out>` exit 0 | F-002 |

## Finding and path summary

- top_finding: For a Flutter app with server-driven ads, remove ads without changing code logic. Equal-length replacement of JSON and slot keys keeps the client internally consistent and breaks the server contract. **Do not replace API path strings**. A startup request that returns 404 produces a `jsonDecode` exception and stalls startup.
- path_type: solve
- path_one_liner: locate the string table → replace ad JSON and slot keys while keeping API paths → repackage and sign → verify with real-device logcat

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| 360 packer protection encrypted the real Java DEX | jadx showed only the shell classes (`com.frezrik.jiagu` and `a.*`) | The ad logic is in the Flutter Dart layer (`libapp.so`). Unpacking is not needed | 0.5h |
| The prebuilt Gitee blutter binary would not run | The binary targeted ARM64-Linux for Termux | Download the blutter-unmgr source and build x64 locally | 1h |
| Windows CMake could not find `cl` | `%PATH%` expanded early in `cmd`, overwriting the vcvars environment | Use `cmd /V:ON` with `set PATH=...;!PATH!` delayed expansion | 0.2h |
| `string(REPLACE "/EHsc" ...)` failed in CMake | When `CMAKE_CXX_FLAGS` is empty, the newer CMake receives too few REPLACE arguments | Patch in an `if(CMAKE_CXX_FLAGS)` guard in the template and generated file | 0.2h |
| The obfuscated ad function had no assembly (`size=-1`) | Blutter could not analyze the obfuscated or complex function | Abandon a code-level patch. Use string-table replacement instead | 0.5h |
| Manual search for pool-entry references failed | Snapshot pool entries use compressed-pointer encoding with offsets relative to the pool base | Abandon manual encoding recovery. Locate string objects directly through Blutter `pp.txt` | 1h |
| Substring false match | `welfare_ad` matched inside `welfare_ad_top` | Replace long strings first and validate prefix bytes (arm64: `0x80\|len<<1`; armv7: `len*2`) | 0.3h |
| **Replacing the API path made the real device stall at the startup logo** | The first version also replaced `system/banner/bannerListByMAcct`. The startup ad request then hit a nonexistent endpoint and returned 404 with a non-JSON body. Startup `jsonDecode` raised `FormatException` (`logcat E flutter`), interrupting the Future that enters the main page and leaving the UI on the startup screen forever | **Do not replace API path or URL strings**. Replace only JSON keys, slot keys, and reporting labels. Isolate variables for comparison (only the re-signed control package). Use `adb logcat -d \| grep "E flutter"`. MIUI installation interception requires `settings put global verifier_verify_adb_installs 0` | 1h |

## Tool findings

- blutter-unmgr (`gitee.com/fest_1/blutter-unmgr`) provides an ARM64-Linux prebuilt package. Its source contains `blutter.py`, which detects the Dart version, builds, and runs as one flow.
- Blutter Windows build dependencies: VS BuildTools with `cl`, cmake (≥3.20), ninja, and ICU/Capstone. `init_env_win.py` downloads dependencies automatically.
- The CMakeLists REPLACE bug requires the guard described above.

## Reusable pattern

**Generic server-driven ad-removal flow** for Flutter or native apps:
1. Decompile and find ad API endpoint, model-key, and slot-key strings.
2. Confirm the string-table format (arm64 packed, armv7 object, or generic length-prefixed).
3. Perform equal-length ASCII replacement of **JSON keys, slot keys, and reporting labels** to preserve offsets and break the server contract. **Keep API paths.**
4. Repackage, run zipalign, and sign with apksigner. Remove the old signature first.
5. Install on a real device and verify with `adb logcat`. Check for uncaught `E flutter` exceptions and confirm that startup has no 404.
