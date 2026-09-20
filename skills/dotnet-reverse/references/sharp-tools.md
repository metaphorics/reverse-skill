# Red Team Sharp* Tool Analysis & Tool Installation Matrix & dnSpy MCP

## Red Team Sharp* Tool Analysis

Red team tools often use C# (the Sharp* series). Reverse engineering them is common: understand detection logic, change signatures, and extract embedded configuration.

### Common Sharp* Tool Quick Reference

| Tool | Function | Reverse Engineering Focus |
|------|------|-----------|
| **Rubeus** | Kerberos attacks (AS-REP roast / Kerberoast / S4U / pass-the-ticket) | The Rubeus project structure is fixed. Find the `Interop.*` P/Invoke sections to inspect native calls |
| **SharpHound** | BloodHound data collector | LDAP query logic and the set of collected attributes |
| **SharpShell / SharpWS** | Remote execution and lateral movement | WMI / WinRM calls and command obfuscation |
| **Seatbelt** | Information collection | The list of collected items and decision logic |
| **SharpRoast** | Kerberoasting | Ticket requests and parsing |
| **Inveigh / SharpSploit** | Man-in-the-middle attacks and general exploitation framework | Reflective loading and API call chains |

### General Analysis Workflow

```text
1. Open in dnSpyEx (usually not obfuscated; a few teams add ConfuserEx)
2. Inspect Program.Main or the entry-point command dispatch (Rubeus uses a switch(command) structure)
3. Find the implementation class/method for the target command
4. Inspect the P/Invoke section (the Interop.* namespace) — native API calls are here
5. Extract embedded resources (some tools embed configurations/templates)
6. If you need to change signatures (AV/EDR evasion): change command strings, API calls, and string constants
```

### Rubeus Structure Example

Rubeus uses command dispatch. Each subcommand has one class. To find the Kerberoasting logic:

```text
Entry point: Rubeus.CommandLineParser → parse args
Dispatch: switch(command) → "kerberoast" → execute Ask.TGS(...)
P/Invoke: Rubeus.Interop.Lsa* / Native.cs → native Kerberos API
Key: LsaCallAuthenticationPackage (KERB_RETRIEVE_TKT_REQUEST)
```

Change signatures (evasion): change the command string `"kerberoast"` to a custom name, change the `Rubeus` banner string, and change the P/Invoke call order.

### Embedded Configuration Extraction

Many loader/tools encrypt and embed C2, keys, and certificates in resources or fields:

```powershell
# View Resources in dnSpyEx (resource tree)
# Or use the command line
powershell -c "[System.Reflection.Assembly]::LoadFile('target.exe').GetManifestResourceNames()"
# After finding the resource, right-click it in dnSpyEx → Extract / Save
```

Runtime-decrypted configuration -> dynamically set a breakpoint at the decryption method return point and dump the plaintext (see `common-workflow.md`).

---

## Tool Installation Matrix

### Windows (preferred, dnSpyEx has a GUI)

```powershell
# Method A: Chocolatey
choco install dnspy ilspy de4dot detect-it-easy

# Method B: Manually download the release (recommended; version is controllable)
# dnSpyEx:    https://github.com/dnSpyEx/dnSpy/releases
# de4dot:     https://github.com/de4dot/de4dot/releases
# ILSpy:      https://github.com/icsharpcode/ILSpy/releases
# DIE:        https://github.com/horsicq/Detect-It-Easy/releases
# dnlib:      dotnet add package dnlib  (NuGet)
```

### Linux / macOS (no dnSpyEx GUI, use CLI)

```bash
# Decompile with the ILSpy CLI
dotnet tool install -g ilspycmd
ilspycmd target.exe -p -o outdir/         # Decompile to a directory

# de4dot cross-platform (requires mono or dotnet)
# Download the de4dot artifact .dll from the release and run it with dotnet
dotnet de4dot.dll target.exe -o target-clean.exe

# dnlib (scriptable; requires the dotnet SDK)
dotnet new console -o dnclean && cd dnclean
dotnet add package dnlib

# DIE CLI (diec)
# Linux: Install from https://github.com/horsicq/Detect-It-Easy
diec target.exe
```

### .NET Runtime Prerequisites

```bash
# Linux
sudo apt install dotnet-runtime-8.0        # or 6.0/7.0 depending on the target
# macOS
brew install --cask dotnet-sdk
```

> dnSpyEx (with an IL editor and debugger) has a Windows GUI version only. For .NET reverse engineering on Linux/macOS, use `ilspycmd` for decompilation and `dnlib` scripts for patching. There is no equivalent interactive debugging GUI. Use Windows first when you need to patch.

---

## dnSpy MCP Integration

The community already has multiple dnSpy MCP projects that expose dnSpy decompilation and IL inspection as MCP tools. AI can call them directly. This fully matches the MCP philosophy of reverse-skill.

### Mainstream dnSpy MCP projects

| Project | Features | Supported clients |
|------|------|------|
| **soufianetahiri/dnspy-mcp** | Core MCP Server that exposes decompile, IL inspection and other tools | Claude Code / Cursor |
| **AgentSmithers/DnSpy-MCPserver-Extension** | Runs as a dnSpyEx extension and integrates deeply with the GUI | Load in dnSpyEx |
| **malwarecakefactory/dnspy-mcp-extension** | 33 tools that cover the full triage → deobfuscation workflow | Full workflow automation |

### Register with the Claude MCP configuration

Install the dnSpyEx extension according to the relevant project README. Then register it in `~/.claude/mcp.json`. Use the command and args from the project README.

```json
{
  "mcpServers": {
    "dnspy": {
      "command": "dotnet",
      "args": ["path/to/dnspy-mcp.dll"]
    }
  }
}
```

After registration, the AI workflow for this skill is: When the user says "Analyze this .NET", route to `dotnet-reverse/`. Prefer the `dnspy_decompile` / `dnspy_inspect_il` tool interface. If that fails, switch to the GUI.

> dnSpy MCP is not a built-in bootstrap capability of reverse-skill. The user must install the extension and register it manually according to the project README. Consider adding it to `bootstrap-manifest.json` later.

---

## Community resource index

### Highly recommended

- **Washi blog** - .NET reverse engineering expert: https://blog.washi.dev/posts/misconceptions-about-dotnet/
  - Key point: **Do not rely too much on dnSpy's C# decompilation. Learn the IL editor.** This matches this project's IL-first principle.
- **dnSpyEx** - Actively maintained dnSpy branch: https://github.com/dnSpyEx/dnSpy
- **de4dot** - .NET deobfuscation: https://github.com/de4dot/de4dot
- **dnlib** - Metadata programming: https://github.com/dnlib/dnlib

### Practical tutorials

- Medium"De-obfuscating and reversing a .NET/C# spyware"- Practical info-stealer deobfuscation with dnSpy + de4dot
- YouTube"dnSpy Patch .NET EXEs & DLLs"- Step-by-step patching + keygen
- Look X forum .NET reverse engineering section - Search ".net reverse" / "dnSpy" / "ConfuserEx" for many practical posts, Nuitka reverse engineering, and AV/EDR evasion discussions
- Guided Hacking"Top 5 .NET Reverse Engineering Tools"- dnSpy still ranks first
- StackExchange / Reverse Engineering - Advanced questions such as `DynamicMethod` debugging

### Existing .NET resources in this repository (integration)

- `reverse-engineering/tools.md` `.NET Analysis` section — dnSpy/ILSpy tool quick reference + Codegate 2013 two-stage XOR+AES-CBC mode
- `reverse-engineering/field-notes.md` `.NET` section — tool notes
- `reverse-engineering/awesome-re-resources.md` — de4dot included
- `field-journal/seed-014_unity-il2cpp-reverse.md` — Unity IL2CPP (native side, complements the .NET managed layer)

.NET reverse engineering deep-dive content is consolidated in this module. Keep only quick-reference indexes in `reverse-engineering/`.
