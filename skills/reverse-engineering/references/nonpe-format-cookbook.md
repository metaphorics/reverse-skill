# Non-PE / Multi-Format Agent Response Cookbook U–AV + AW–DN

> Alongside the PE Anti-Debugging Cookbook A–T (../anti-analysis.md): For each **file type**, provide "trigger → one-line action → Evidence".
> **Not** a second main workflow. After Triage identifies the type, jump to the corresponding skill + this table.
> Default: **authorized isolated lab / authorized samples and devices**. Write **detection and forensics** for system reimaging, BYOVD, and reflective injection. Do not write unauthorized destruction or exploitation tutorials.
> Record Evidence even if bypass or restoration fails. Do not silently treat it as "harmless".
>
> §1–§8 / U–AV = original rules (Issue #65). §9–§23 / AW–DN = extended rules (Issue #87, deduplicated + semantic enhancements + edge-case patches).

## 0. Routing Quick Reference

| Type Clue | Main skill | Table section |
|----------|----------|----------|
| .bat / .cmd / batch files | malware-analysis | §1, §19 |
| .ps1 / PowerShell | malware-analysis | §2, §20 |
| Office macros / VBA / XLM / .docm/.xlsm | malware-analysis | §3 (including DD OLE extraction, DJ XLM macros) |
| .docx/.xlsx/.pptx OOXML external links / DDE / .rtf OLE | malware-analysis | §10 (including DK RTF) |
| Web/frontend JS obfuscation, JSVMP | js-reverse | §4, §21 (including DE/DF) |
| .sys / kernel drivers | reverse-engineering/kernel-driver-reverse.md + cre | §5 |
| .dll focus | malware-analysis / re-agent-workflow | §6 (deduplicated with A–T) |
| APK / Magisk / hidden icons | apk-reverse | §7–§8, §23 |
| .pdf / PDF documents | malware-analysis | §9 |
| .wasm / WebAssembly | reverse-engineering | §11 |
| .jar/.class / Java bytecode | reverse-engineering | §12 |
| .exe(AutoIt) / .au3 | malware-analysis | §13 |
| .hta / HTML Application | malware-analysis | §14 |
| .wsf/.jse/.vbe | malware-analysis | §15 |
| .msi / Windows Installer | malware-analysis | §16 |
| .reg / registry scripts | malware-analysis | §17 |
| .vbs / VBScript | malware-analysis | §18 |
| Xposed/LSPosed modules | apk-reverse | §22 |
| ELF / Linux binaries | reverse-engineering | → elf-analysis.md, anti-analysis.md |
| Mach-O / macOS/iOS | reverse-engineering | → platforms.md |
| Python bytecode | reverse-engineering | → languages.md |

## 1. BAT/CMD (U V W)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **U** | Many SET single-character variables + %a%%b% concatenation, or ^ line continuation splits commands | Expand SET line by line. Restore the command list. You can use a batch deobfuscation tool. **Do not** treat it as "no action" before restoration | E-batch-deobf | P0 |
| **V** | Garbled text when opened, HEX header FF FE (UTF-16 LE BOM) | Confirm the BOM → convert to UTF-8, then parse; or chcp 65001 + type | E-batch-encoding | P2 |
| **W** | Large amounts of REM/:: and redundant GOTO/labels obscure the real logic | Remove comments; trace the real GOTO path; isolate execution and capture the actual cmd command log | E-batch-deadcode | P1 |

## 2. PowerShell (X Z)

> Keep the numbering convention of the proposer: **no-patch Y**.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **X** | Multiple layers of FromBase64String / Gzip / Compress / nested -replace | Decode **one layer at a time**; record each layer result separately; tools are optional (such as PowerDecode), or use manual/script methods if no tool is available | E-ps-decode-layer-N | P0 |
| **Z** | Reversed strings, fragments + concatenation, followed by Invoke-Expression/IEX | Restore the complete string; set a breakpoint on IEX or log the script block; put the plaintext command in Evidence | E-ps-string-restore | P1 |

## 3. VBA Macros / XLM (AA AB AC DD DJ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AA** | olevba/OLEDump shows only P-Code and the source stream is empty (VBA Stomping) | Use a P-Code decompilation tool; if incomplete, observe with Word/Excel macro debugging; state the limits clearly | E-vba-pcode | P0 |
| **AB** | Large amounts of Chr() concatenation or Base64 strings, possibly shellcode/nested scripts | Restore the string in the Immediate window or with a script; identify the type after decoding; monitor CreateObject/Shell dynamically | E-vba-str-decode | P1 |
| **AC** | Meaningless If 1=2, or self-modification with InsertLines/DeleteLines | Trace the true branch statically; set dynamic breakpoints on self-modification APIs and dump the modified macro | E-vba-selfmod | P2 |
| **DD** | olevba/oledump detects a VBA macro project (vbaProject.bin); extensions .docm/.xlsm/.pptm | Use oledump.py to check the OLE stream structure; use olevba to extract VBA source code and detect suspicious APIs; check automatic execution macros such as AutoOpen/Workbook_Open | E-office-vba | P0 |
| **DJ** | .xls/.xlsm contains Excel 4.0/XLM macros (hidden in cell formulas, not in a VBA stream); olevba detects XLM macro markers | Use olevba --xlm to extract XLM macro formulas; check the EXEC/CALL/REGISTER functions in hidden worksheets; use XLMMacroDeobfuscator to restore them through dynamic emulation | E-office-xlm | P0 |

## 4. JavaScript (AD AE AF)→ Main path js-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AD** | Custom bytecode array + while/switch interpreter (JSVMP) | Find the VM entry and opcode dispatch; log the dynamic trace; use both AST and dynamic analysis; see js-reverse DeepDive | E-js-vmp | P0 |
| **AE** | while(1){switch} + large string array indexes | Refactor with AST/Babel; restore strings from array indexes; wakaru and other tools are optional; **do not** paste the full PE ollvm-deobfuscation article | E-js-deobf | P0 |
| **AF** | debugger, console hijacking, performance.now timing differences, DevTools detection | Disable breakpoints; fix the time source; use a headless browser; patch the detection points; use an authorized page | E-js-anti-debug | P1 |

## 5. SYS Kernel Drivers (AG AH AI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AG** | DriverEntry is very short, and the logic is not in the entry point | Scan non-empty slots in MajorFunction[]; prioritize IRP_MJ_DEVICE_CONTROL/CREATE; put the address list in evidence | E-driver-irp-handlers | P0 |
| **AH** | DeviceIoControl / IOCTL dispatch exists | Build a control-code to handler-function table; mark METHOD_* and the buffer direction; document the user-mode communication surface | E-driver-ioctl | P0 |
| **AI** | The sample loads or deploys a known vulnerable driver or an abnormally signed driver (BYOVD pattern) | Compare it with **public** lists such as LOLDrivers; record the driver name, hash, and signature; analyze the **call intent**; **do not** expand the exploitation steps | E-driver-byovd | P1 |

See kernel-driver-reverse.md workflow; this table only adds agent action anchors.

## 6. DLL (AJ–AQ) — deduplicated against A–T / #72

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AJ** | DLL analysis only checked exports/EP and ignored TLS or DllMain | **Both TLS callbacks and DllMain must be checked**; the dynamic breakpoint order still follows the four-stage rocket (TLS→EP/DllMain→API→ExitProcess) | E-dll-tls-dllmain | P0 |
| **AK** | Export names look benign at first and malicious later, use wrong names, or do not match behavior | Cross-check the export table against actual calls; list abnormal exports | E-exports-anomaly | P0 |
| **AL** | The DLL has no exports or very few exports but is still loaded | Locate it from the entry point, strings, xrefs, and callers; do not stop because it has no exports | E-dll-noexport | P0 |
| **AM** | The static IAT lacks a DLL that is used only at runtime | **See A–T patch R** (Delay-Load / E-delay-import); do not repeat the long text here | E-delay-import | P0 pointer |
| **AN** | Export function parameters and the calling convention must be restored | Use cross-references and inspect registers and the stack at runtime; mark stdcall/fastcall and others | E-dll-export-abi | P1 |
| **AO** | DLL hijacking or side-loading is suspected | Check for DLLs with the same name in the application directory, the search path, and KnownDLLs; record legitimate program + abnormal DLL combinations | E-dll-sideload | P1 |
| **AP** | Clues indicate fileless mapping or reflective loading | Check memory features, loader behavior, and modules without paths; collect evidence in an authorized environment | E-dll-reflective | P1 |
| **AQ** | Risk is reduced only because the export name does not look malicious | **Do not judge safety from the export name alone**; also check section permissions, the entry point, strings, and dynamic behavior | E-dll-export-priority | P1 |

The DLL/SYS hard gates still apply: E-imports + E-exports (see re-agent-workflow).

## 7. Android device wiping / persistence (AR AS AT) → apk-reverse

> **Use only authorized samples, images, or test devices.** Detect, extract IOCs, and identify persistence paths. Do not cause damage.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AR** | Magisk modules/scripts contain database deletion, image flashing, batch rm of system partitions, or other **device-wiping commands** | Create a table of characteristic commands and module paths; mark high-risk destructive capability; do not execute device-wiping commands | E-android-wiper-cmd | P0 |
| **AS** | Loops with curl|sh, remote script downloads, or unusual C2 URLs | Extract URLs; check whether the downloaded content contains device-wiping commands; record temporary paths | E-android-wiper-backdoor | P0 |
| **AT** | /data/adb/service.d, post-fs-data.d, or suspicious /system/priv-app entries | List persistence scripts/APKs; add content summaries to the evidence chain | E-android-persistence | P1 |

## 8. Android transparent/hidden icons (AU AV) → apk-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AU** | The LAUNCHER icon is fully transparent, the label is empty, Theme.NoDisplay is used, the LAUNCHER category is absent, or the component is disabled | Use aapt dump badging + manifest; decompile and check icon pixels; add abnormal items to the evidence chain | E-android-hidden-icon-manifest | P0 |
| **AV** | The app is installed but has no desktop icon, has background traffic, starts automatically, requests high-risk permissions, or restores the icon dynamically | Compare pm list with the desktop; run dumpsys package; check broadcasts and device_admin; add behavior to the evidence chain | E-android-hidden-icon-behavior | P1 |

---

> **The rules in §9–§23 below extend Issue #87 (AW–DC).**
> Removed ELF (→ elf-analysis.md), Mach-O (→ platforms.md), and Python (→ languages.md) sections that duplicated existing files.

## 9. Malicious PDF documents (AW AX AY AZ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AW** | pdfid detects /JS, /JavaScript, /OpenAction, /AA, or /Launch count >0 (including obfuscated counts for hex-encoded names such as /4A#61#76#61...) | Use pdfid -e to count (compare plain vs obfuscated counts); extract suspicious objects with pdf-parser; use peepdf for interactive analysis and JS emulation | E-pdf-autoaction | P0 |
| **AX** | pdfid detects /EmbeddedFile >0; the object stream contains a cascaded filter chain such as FlateDecode/ASCIIHexDecode; or a hidden encoded payload exists in an /Annot object | Extract stream data with pdf-parser; decode multi-layer cascaded filters with peepdf (including AES-encrypted streams with security handler r5/r6); check Annotation objects; use file to identify the decoded result type | E-pdf-embedded | P0 |
| **AY** | Extracted PDF JS contains many eval, unescape, String.fromCharCode, and atob calls | Trace execution in the peepdf JS emulation environment; decode Base64/Hex/ROT13 layer by layer; use CyberChef as support | E-pdf-js-deobf | P1 |
| **AZ** | Abnormal PDF structure: /JBIG2Decode, a manipulated XREF table, or jumps in object numbers | Rename suspicious keywords with pdfid -d; check known CVE exploitation patterns; extract exploitation trigger conditions | E-pdf-exploit | P1 |

## 10. Office OOXML / DDE / RTF (BA BB DK) -> Complementary to §3 VBA

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BA** | After docx/xlsx/pptx ZIP extraction, word/_rels/ or xl/_rels/ contains suspicious external relationships (including remote template injection) | Check external links in *.rels; check vbaData.xml; extract embedded OLE objects; check abuse of protocol handlers (ms-msdt: / search-ms: / ms-officecmd:) | E-office-ooxml | P0 |
| **BB** | The document contains DDEAUTO or DDEEXEC field codes that execute external commands through the field | Scan with olevba --dde; extract DDE command parameters; check whether they point to PowerShell/external exe | E-office-dde | P0 |
| **DK** | The .rtf file contains embedded OLE objects (not OOXML and not a classic OLE compound document) | Extract embedded OLE objects with rtfobj; analyze object types with oleobj; check Equation Editor exploitation (CVE-2017-11882 and others); use file to identify extracted object types | E-rtf-ole | P0 |

## 11. WebAssembly (BC BD BE)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BC** | The file starts with the \x00asm magic bytes; or the JS code contains WebAssembly instantiation logic | Convert to text with wasm2wat; check the import section to identify host-environment import functions; generate pseudocode with wasm-decompile; check the Emscripten glue signature (__wasm_call_ctors) to determine whether JS compiled it | E-wasm-struct | P0 |
| **BD** | The WASM module has many functions with simple logic and function bodies split into tiny functions; or it contains meaningless block/loop nesting | Use diswasm to assess the function minimization level; perform in-depth analysis with the JEB Pro / IDA WASM plugin; dynamically trace execution logs | E-wasm-obfuscation | P1 |
| **BE** | The WASM module interacts with the browser through JS import/export functions and contains WebSocket, fetch, or WebGL calls | Analyze the JS glue code and the WASM module together; trace data exchange with browser DevTools; extract network communication URLs/domains | E-wasm-c2 | P1 |

## 12. Java JAR/Class (BF BG BH BI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BF** | When JD-GUI/jadx opens the JAR, class or method names are meaningless short strings (a.a.a / _0x prefix / numeric class names); or many while/switch control flows are obfuscated | Identify the obfuscator type (ProGuard / Allatori / ZKM); perform static deobfuscation with Java Deobfuscator; use dynamic debugging to trace key logic when the obfuscation is strong | E-java-obfuscation | P0 |
| **BG** | The JAR contains many Class.forName(), Method.invoke(), and Constructor.newInstance() calls; or a custom ClassLoader + defineClass() loads classes from byte arrays in memory; the import table appears harmless but dynamically loads malicious classes at runtime | Use javap -c -v to view reflection call details; trace Class.forName parameter strings; check the source of defineClass() byte arrays; set a breakpoint on Method.invoke during dynamic analysis | E-java-reflection | P0 |
| **BH** | The JAR contains .so (Linux/Android) or .dll (Windows) files; or it calls System.loadLibrary() | Extract native library files; use file to identify the format; move to a separate ELF/PE analysis process | E-java-native | P1 |
| **BI** | Extracted JAR/ZIP contains nested JAR/WAR/EAR archives; /resources or /assets contains high-entropy .dat/.bin/.img files | Recursively extract all nested archives; analyze entropy to identify encryption or compression; check META-INF/MANIFEST.MF and pom.xml | E-java-nested | P1 |

## 13. AutoIt (BJ BK BL DM)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BJ** | PE strings contain AutoIt / AU3 / EA05 / EA06 signatures, or the resource section contains an AutoIt script resource. Distinguish it from AutoHotKey. MITRE T1059.010 is shared by both. | Use autoit-ripper to extract the compiled script. Identify the encoding family. EA05 = AutoIt3.00 and EA06 = AutoIt3.26. After the EA06 header, extract the 8-byte decryption key and decrypt the payload. Restore the source code. | E-autoit-extract | P0 |
| **BK** | The extracted script contains many StringEncrypt/_StringEncrypt calls, or it uses Execute for dynamic execution with meaningless variable names. | Use myAutToExe for static decompilation. Identify anti-debugging techniques. Analyze the control flow after deobfuscation. | E-autoit-deobf | P1 |
| **BL** | The script contains RegWrite for registry persistence, FileInstall for file release, InetGet for network download, or Run/RunWait. | Mark the sensitive API call sequence. Analyze the InetGet URL. Trace the FileInstall release path. | E-autoit-malicious | P0 |
| **DM** | AutoIt acts as a loader and performs process hollowing: a CallWindowProc/EnumWindows callback plus shellcode injects a legitimate process such as regsvcs.exe, and it releases a .NET payload. Examples include DarkGate / Snake Keylogger / ArechClient2 patterns. | Check the call chain from DllCall/DllCallbackRegister to the kernel32 injection APIs. Extract the shellcode data. Identify the target process. Extract the .NET payload and analyze it separately. | E-autoit-hollowing | P0 |

## 14. HTA / HTML Application (BM BN BO)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BM** | HTML contains an HTA:APPLICATION tag, window.execScript, or a CreateObject call. | Check the HTA:APPLICATION properties such as Application and WindowState. Extract the VBS/JS from the script tag. | E-hta-bypass | P0 |
| **BN** | HTA starts through mshta.exe and then uses XMLHttpRequest / ActiveXObject to remotely download and execute a payload. | Extract the network request URL. Trace ActiveXObject creation such as ADODB.Stream. Restore the complete download and execution chain. | E-hta-download-chain | P0 |
| **BO** | HTA contains only one extremely long obfuscated string and executes it with eval / execScript. | Decode the Base64/Hex encoded payload. Use CyberChef to recursively detect the encoding type. Restore the payload. | E-hta-oneline | P1 |

## 15. WSF / JSE / VBE (BP BQ BR BS)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BP** | .wsf contains \<job\> and \<script language="..."\> tags and mixes JScript/VBScript/Python. | Split the code blocks by \<script language\>. Analyze each block under the rules for its language. | E-wsf-multi | P0 |
| **BQ** | .jse/.vbe starts with the #@~^ signature and uses Microsoft Script Encoder encoding. | Use screnc-decoder to decode it. If no tool is available, execute it dynamically and dump the decoded script. | E-jse-decode | P0 |
| **BR** | WSF contains multiple \<script\> blocks, a \<package\> reference to external resources, and a \<component\> reference to COM components. | Build a cross-block call graph. Trace function calls between \<script\> blocks. Restore the complete execution flow. | E-wsf-call-chain | P1 |
| **BS** | WSF uses WshShell.SendKeys to bypass UAC, WshShell.Run with a 0 window to hide execution, or WScript.Sleep for delay-based bypass. | Check whether simulated user actions bypass security prompts. Record the stealth execution parameters. | E-wsf-anti-detect | P1 |

## 16. MSI Installer Packages (BT BU BV)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BT** | The MSI file contains a CustomAction table with Binary / Script / DLL custom-action types. | Use msiexec /a or lessmsi to extract the contents. Check the CustomAction table. Extract the custom-action binary files. | E-msi-custom-action | P0 |
| **BU** | The MSI Binary table contains VBScript/JScript custom-action scripts. | Extract the script binary from the Binary table and decode it into a readable script. Analyze it under the VBS/JS rules. | E-msi-script | P1 |
| **BV** | MSI uses /quiet /passive /qn for silent installation, or uses ALLUSERS=1 for privilege escalation. | Record the installation command-line parameters. Analyze the permission settings in the Property table. Mark the silent-installation and privilege-escalation combination. | E-msi-privilege | P1 |

## 17. REG Registry Scripts (BW BX BY)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BW** | .reg writes to an automatic-start path such as HKCU\...\Run or HKLM\...\Run. | Extract all paths. Mark Run path entries as persistence. Record the complete paths and values. | E-reg-persistence | P0 |
| **BX** | .reg modifies HKCR\...\shell\open\command for file association, or HKCR\CLSID\{...}\InprocServer32 for DLL injection. | Check whether shell\open\command points to an unusual exe. Check the InprocServer32 DLL path. | E-reg-hijack | P0 |
| **BY** | Modify HKLM\...\Policies\System (UAC level), EnableLUA, ConsentPromptBehaviorAdmin with .reg | Check the default security settings before the change; analyze the effect on UAC; mark downgrade behavior | E-reg-uac-bypass | P1 |

## 18. VBScript (BZ CA CB CC DN)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BZ** | .vbs/.js is parsed by both VBScript and JScript; conditional compilation (@_win32) or cross-language execution | Separate the VBScript/JScript code blocks; parse each block; identify mixed execution logic | E-vbs-mixed | P1 |
| **CA** | The script contains CreateObject("WScript.Shell") / CreateObject("Shell.Application") / Scripting.FileSystemObject | Mark high-risk COM object calls; trace Run/Exec parameters; trace file paths created by FSO | E-vbs-com-abuse | P0 |
| **CB** | The script starts with the #@~^ signature and uses Microsoft Script Encoder encoding (VBS-specific) | Decode with screnc-decoder; if no tool is available, execute dynamically and dump the decoded script | E-vbs-encoded | P0 |
| **CC** | VBA/VBScript contains WScript.Shell.Run + cmd /c + PowerShell, followed by process injection | Trace the CreateObject COM object chain; analyze injection indicators in Run parameters; record the complete process creation chain | E-vbs-inject-chain | P0 |
| **DN** | VBScript/JScript uses WMI ActiveScriptEventConsumer for fileless persistence (no Startup folder or registry Run key) | Check WMI event subscriptions (__EventFilter + __FilterToConsumerBinding + ActiveScriptEventConsumer); extract the bound script content; mark fileless persistence | E-vbs-wmi-persist | P0 |

## 19. Advanced BAT/CMD obfuscation (CD–CI) → complements §1 U–W

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CD** | setlocal enabledelayedexpansion + !var! + dynamic variable name (!var_%i%!) | Expand each line after enabling delayed expansion; use Batch-Dump --expand for automatic expansion | E-bat-delayed-expand | P0 |
| **CE** | Uses type/more/findstr to read its own or a file's :stream ADS as an alternative data stream for execution | Check : suffix references (file.bat:payload); list ADS with dir /r; extract with type file:stream | E-bat-ads-hidden | P0 |
| **CF** | Many echo commands write line by line to a .tmp/.cmd temporary file, which is then executed with call | Extract all echo redirections to restore the temporary file content; monitor scripts created in temporary directories | E-bat-temp-gen | P1 |
| **CG** | for %%i in (...) do set var=%%i accumulates variables; for /f parses command output line by line | Expand the for loop line by line and record each assignment; serialize and restore the for /f results | E-bat-for-expand | P1 |
| **CH** | The main batch file receives parameters through %1 %*, and a parent process or downloader passes obfuscated commands | Check the call context and record the passed parameters; decode and restore Base64 parameters; restore the complete call chain | E-bat-param-call | P1 |
| **CI** | certutil -decode / powershell -Command / echo \| findstr combination decodes and executes content | Extract and decode Base64/Hex strings; check whether the decoded result is an executable script/PE | E-bat-encoded-exec | P0 |

## 20. Advanced PowerShell bypasses (CJ–CO, DL) → complements §2 X–Z

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CJ** | [Ref].Assembly.GetType('...AmsiUtils') / amsiInitFailed / GetTypes() and other AMSI bypasses (including hardware breakpoint bypasses: CPU debug registers, with no memory write/VirtualProtect) | Identify the bypass pattern (Patch / registry / environment variable / hardware breakpoint); confirm it dynamically; mark the bypass technique type | E-ps-amsi | P0 |
| **CK** | [PSConstraintLanguage] type operations or session state changes through DefaultRunspace bypass CLM | Identify the CLM bypass pattern; mark bypass-clm; analyze the execution context after the bypass | E-ps-clm-bypass | P0 |
| **CL** | [ScriptBlock]::Create / $ExecutionContext.InvokeCommand constructors; or overwrites ScriptBlock logging settings | Check whether the script disables logging; verify dynamically whether logging is bypassed | E-ps-sb-log-bypass | P1 |
| **CM** | IEX (New-Object Net.WebClient).DownloadString(...) or [Reflection.Assembly]::Load(FromBase64...) executes without a file | Extract the download URL and check domain/IP reputation; capture in-memory loaded code with PS logs; isolate the network and simulate it to extract the payload | E-ps-reflect-load | P0 |
| **CN** | Three or more nested encoding layers: outer Base64 → Gzip → XOR → plaintext (beyond the two-layer scope of §2 X) | Decode recursively to plaintext or until decoding cannot continue; record the intermediate state at each layer; automate with PowerDecode; add each layer result to the evidence chain | E-ps-multi-decode | P0 |
| **CO** | Set-Alias maps IEX to a one-character alias; Get-ChildItem variable: obtains variable values dynamically | Expand all alias mappings and replace them with the original command names; use AST analysis to restore variables | E-ps-alias-decode | P1 |
| **DL** | Script contains ntdll.dll EtwEventWrite patch (stomping) for silent telemetry. It is often combined with AMSI bypass | Check for EtwEventWrite address retrieval + memory patch (ret 0xC3). Check together with CJ AMSI bypass. Mark the dual-bypass combination | E-ps-etw-bypass | P0 |

## 21. Advanced JavaScript obfuscation (CP CQ DE DF) → complements §4 AD–AF

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CP** | JS uses Proxy objects to intercept property access + the Reflect API to call methods dynamically and bypass static analysis | Identify Proxy get/set/apply trap functions. Trace the actual target of Reflect.get. Mark dynamic interception behavior | E-js-proxy | P1 |
| **CQ** | JS contains an _0x... hexadecimal string array + a while(!![]) infinite loop + for+switch control flow (obfuscator.io feature) | Identify obfuscator.io features (string array+infinite loop). Use de4js / jsnice for automatic deobfuscation. Record the restored code as evidence | E-js-obfuscator | P0 |
| **DE** | JS body is a large bytecode array + a VM interpreter loop (multiple while/switch statements). The entry points to an eval/Function constructor. The business logic is completely unreadable (a deeper form of §4 AD) | Identify the VM entry function and trace the opcode→handler function mapping. Hook eval output during browser execution. Use JSimplifier for AST reconstruction. Record the opcode mapping table | E-jsvmp-deep | P0 |
| **DF** | JS uses eval to generate and execute new code at once, document.write to rewrite the page, or a Function constructor to generate a function body dynamically | Hook eval and the Function constructor to record generated code. Capture self-modifying content during browser execution | E-js-selfmod | P1 |

## 22. Xposed/LSPosed module analysis (CR–CX) → apk-reverse

> Analyze the **module itself** as the reverse-engineering target, not a tool-use scenario.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CR** | AndroidManifest.xml has no android:name entry Activity. meta-data specifies xposedmodule=true | Check assets/xposed_init to identify the entry class. Search for IXposedHookLoadPackage/ZygoteInit/CmdInit interface implementations | E-xp-entry | P0 |
| **CS** | Code contains XposedHelpers.findAndHookMethod / XposedBridge.hookMethod / findClass | Extract the first argument (target class) + second argument (target method) of findAndHookMethod. Build a target application list | E-xp-hook-targets | P0 |
| **CT** | Module uses DexClassLoader/PathClassLoader for dynamic loading, or Runtime.exec / ProcessBuilder to execute commands | Trace DexClassLoader constructor arguments. Extract dynamically loaded DEX files for separate analysis. Check exec command arguments | E-xp-dynamic-load | P0 |
| **CU** | Hook targets involve sensitive APIs such as payment, biometrics, SMS, contacts, location, or encryption keys | Classify the sensitivity of Hook target classes and methods. Mark payment, biometric, and SMS or contacts classes. Summarize the threat level | E-xp-sensitive-hooks | P0 |
| **CV** | Code contains XposedBridge detection evasion / Zygote injection trace removal / custom network communication | Check for stacktrace modification / removal of XposedBridge class references. Check independent network requests (OkHttp/Socket). Identify C2 targets | E-xp-anti-detection | P1 |
| **CW** | Code contains dynamic Resources replacement / View drawing interception / AccessibilityService declaration | Check AssetManager replacement / Resources.updateConfiguration. Check AccessibilityService configuration. Identify UI hijacking | E-xp-ui-hijack | P1 |
| **CX** | AndroidManifest.xml declares lsposed xposedscope meta-data, or code contains a package-name allowlist check | Parse the xposedscope target application range. Check for dynamic allowlist bypass (modify scope by reflection). Identify unauthorized global Hook access | E-xp-scope-bypass | P1 |

## 23. Deep Magisk module analysis (CY–DC, DG–DI) → complements §7 AR–AT

> §7 focuses on device bricking and destructive behavior. This section covers non-destructive but suspicious module behavior: installation script analysis, file release, Zygisk injection, detection evasion, persistence, privilege escalation, and lateral movement.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **DG** | Magisk module ZIP root directory contains config.sh / install.sh. META-INF/com/google/android/update-binary is a non-standard installer | Extract the on_install/print_modname/set_permissions functions from config.sh/install.sh. Check whether update-binary contains extra payloads. Mark pm install / dd block device / mount -o remount,rw operations | E-mg-install-script | P0 |
| **DH** | ZIP contains system/ / vendor/ / data/ directory structures, or boot-time scripts such as post-fs-data.sh / service.sh | Extract released file paths and identify whether APK files are released to /system/priv-app/. Check service.sh + post-fs-data.sh content to identify boot autostart/background keep-alive/C2 communication. Mark all operations that write to system partitions | E-mg-file-drop | P0 |
| **CY** | Module contains a zygisk/ directory (native libraries such as arm64-v8a.so), or config.sh declares IS_ZYGISK=true | Extract zygisk/ native libraries and analyze ZygiskModule callbacks (onLoad / preAppSpecialize / postAppSpecialize). Check JNI Hook use | E-mg-zygisk | P0 |
| **DI** | Module scripts write to /data/adb/service.d/ or /data/adb/post-fs-data.d/, or modify crontab/init.rc (a deeper form of §7 AT) | Extract the script content written to service.d + post-fs-data.d. Check logic that automatically infects other modules during uninstall (post-uninstall.sh / module directory monitoring). Check the protection mechanism triggered by magisk --remove-modules | E-mg-persistence | P0 |
| **CZ** | Module script contains resetprop to modify system properties, magiskhide, or DenyList, or integrates Shamiko (hides Zygisk itself), TrickyStore ( tampers with the certificate chain), or PlayIntegrityFork (fakes the Play Integrity API) | Extract all resetprop calls to identify modified properties (ro.debuggable / ro.build.tags, etc.); check whether DenyList hides itself; identify module-level anti-detection by Shamiko, TrickyStore, or PlayIntegrityFork | E-mg-anti-detect | P0 |
| **DA** | Module script contains setenforce 0 / mount -o rw,remount /system / chmod 777 on sensitive directories | Check SELinux operations (setenforce/chcon/restorecon); check system-partition mounts and dm-verity disabling; flag high-risk privilege escalation | E-mg-privilege | P0 |
| **DB** | Released APK/script contains curl/wget/HTTP client, or released APK requests INTERNET + READ_CONTACTS/SMS and other sensitive permissions | Extract network request target URLs/IPs; analyze released APK permission declarations; identify data exfiltration logic | E-mg-c2 | P0 |
| **DC** | Script iterates through the /data/adb/modules/ directory, modifies other module files, or writes a copy of itself to another module | Check module.prop for injected malicious commands; check whether other modules' service.sh files have appended malicious code; identify "parasitic" logic | E-mg-cross-infect | P0 |

---

## 24. Constraints (Global)

1. **Do not run the main flow in parallel**: Use re-agent-workflow and each skill as the phase gates.  
2. **Always record Evidence**: Include failures, partial restoration, and quality= labels.  
3. **Remove duplication with A–T**: Do not repeat PE anti-debugging; AM→R; add a DLL view for AJ without overturning the TLS rocket.  
4. **Missing tools**: Record n/a + a manual equivalent. Do not pretend to have used a commercial suite.  
5. **Authorization**: For destructive, injection, or driver-vulnerability cases, do defensive analysis and use evidence chain wording only.
6. **Remove duplicate extension rules**: ELF → elf-analysis.md; Mach-O → platforms.md; Python → languages.md. This table does not repeat rules for these formats.

## 25. Minimum P0 checks (when the type matches)

```text
□ bat/cmd → U(+ V/W when needed; advanced CD–CI)
□ ps1 → X(+ Z; advanced CJ–CO + DL ETW)
□ vba/xlm → AA + DD + DJ(+ AB/AC)
□ office ooxml/rtf → BA + DK(+ BB if DDE is suspected)
□ js heavily obfuscated → AD or AE(+ AF; advanced CP/CQ/DE/DF)
□ sys → AG + AH(+ AI if BYOVD is suspected)
□ dll → AJ + AK/AL; Delay-Load uses R
□ apk tampering/hiding → AR/AS or AU(+ AT/AV)
□ pdf → AW + AX(+ AY/AZ)
□ wasm → BC(+ BD/BE)
□ jar/class → BF + BG(+ BH/BI)
□ autoit → BJ + BL + DM(+ BK)
□ hta → BM + BN(+ BO)
□ wsf/jse/vbe → BP + BQ(+ BR/BS)
□ msi → BT(+ BU/BV)
□ reg → BW + BX(+ BY)
□ vbs → CA + CB + CC + DN(+ BZ)
□ xposed module → CR + CS + CT + CU(+ CV–CX)
□ deep magisk → DG + DH + CY + DI + CZ + DA(+ DB/DC)
```
