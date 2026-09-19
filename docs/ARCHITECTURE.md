# System Architecture

## Complete Behavior Chain Flowchart

```mermaid
flowchart TD
    Start([User submits a security or reverse-engineering task]) --> Detect{Trigger keyword matches?}
    Detect -->|yes| ReadRouting[Read SKILL.md + routing.md]
    Detect -->|no| Normal([Normal conversation])
    
    ReadRouting --> RouteMatch{Does the routing matrix match?}
    RouteMatch -->|no match| ProposeNew[Propose a new skill<br/>Follow CONTRIBUTING.md]
    RouteMatch -->|match| CheckJournal[Check field-journal<br/>for similar experience]
    
    CheckJournal --> CheckTools[Read tool-index.md<br/>confirm tool status]
    CheckTools --> ToolOK{Are the tools available?}
    
    ToolOK -->|missing| Bootstrap[Run bootstrap-reverse.ps1<br/>install automatically]
    ToolOK -->|available| Execute[Enter the skill workflow]
    
    Bootstrap --> BootOK{Did installation succeed?}
    BootOK -->|yes| Execute
    BootOK -->|no| Guide[Provide structured guidance<br/>wait for manual action]
    Guide --> UserConfirm([User confirms installation])
    UserConfirm --> Execute
    
    Execute --> TaskDone{Is the task complete?}
    TaskDone -->|no| Execute
    TaskDone -->|yes| ReviewCase[Run case-review<br/>validate the evidence graph]
    ReviewCase --> GenReport[Run docs-generator<br/>generate the report and diagrams]
    
    GenReport --> WriteJournal[Write to field-journal<br/>retain the experience]
    WriteJournal --> UpdateIndex[Update the index, routing, and manifest]
    UpdateIndex --> Output([Output the final result])
```

## Skills Module Relationship Diagram

```mermaid
flowchart LR
    subgraph RoutingLayer[Routing layer]
        SKILL[SKILL.md<br/>control entry]
        Routing[routing.md<br/>routing matrix]
    end

    subgraph ReverseAnalysis[Reverse engineering]
        APK[apk-reverse<br/>APK reverse engineering]
        IDA[ida-reverse<br/>IDA Pro]
        R2[radare2<br/>CLI analysis]
        RE[reverse-engineering<br/>general methods]
        BinDiff[binary-diff<br/>symbol migration]
        PatchDiff[patch-diff-exploit<br/>N-day weaponization]
    end

    subgraph Exploitation[Exploitation]
        Pwn[pwn-chain<br/>reverse engineering to exploitation]
        Firmware[firmware-pentest<br/>full firmware workflow]
    end

    subgraph PenetrationTesting[Penetration testing]
        Pentest[pentest-tools<br/>toolchain and workflow]
        SrcHunter[src-hunter<br/>19 playbooks]
        EDR[edr-bypass-re<br/>EDR evasion]
    end

    subgraph WebBrowser[Web and browser]
        JS[js-reverse<br/>JavaScript signature reverse engineering]
        Browser[browser-automation<br/>Playwright and OpenReverse]
    end

    subgraph Infrastructure[Infrastructure]
        Bootstrap[bootstrap-reverse.ps1<br/>on-demand bootstrap]
        Discovery[ToolDiscovery.ps1<br/>tool discovery]
        ToolIndex[tool-index<br/>status index]
    end

    subgraph OutputLayer[Output layer]
        Docs[docs-generator<br/>report generation]
        Diagram[diagram-generator<br/>diagram generation]
        Review[case-review<br/>evidence graph audit]
        Journal[field-journal<br/>experience retention]
    end

    subgraph External[External]
        CTF[CTF-Sandbox-Orchestrator<br/>40+ subskills]
    end

    SKILL --> Routing
    Routing --> APK & IDA & R2 & RE & BinDiff & PatchDiff
    Routing --> Pentest & JS & Browser & Pwn & Firmware & EDR
    Routing --> CTF

    Pentest --> SrcHunter
    APK -->|.so routing| IDA
    APK -->|.so routing| R2
    PatchDiff -->|write PoC| Pwn
    Firmware -->|find crash| Pwn
    Pwn -->|combine| Pentest
    EDR -->|delivery stage| Pentest
    JS -->|browser operations| Browser
    
    Bootstrap --> Discovery --> ToolIndex
    
    APK & IDA & R2 & Pentest & JS -->|task complete| Review
    Review --> Docs
    Docs --> Diagram
    Docs --> Journal
```

## Bootstrap Process

```mermaid
flowchart TD
    Need[Missing tool detected] --> ReadManifest[Read bootstrap-manifest.json]
    ReadManifest --> Kind{What is the installation type?}
    
    Kind -->|github-release-zip| GH[Download and extract ZIP<br/>from a GitHub release]
    Kind -->|pip-package| Pip[pip install]
    Kind -->|npm-mcp| NPM[Start with npx<br/>and register MCP]
    Kind -->|npm-global| Global[npm install -g<br/>and run postInstall]
    Kind -->|winget-package| Winget[winget install]
    Kind -->|local-http-mcp| HTTP[Register the URL<br/>and start the service]
    
    GH & Pip & NPM & Global & Winget & HTTP --> Verify{Is the tool available?}
    Verify -->|yes| AddPath[Add to PATH<br/>refresh tool-index]
    Verify -->|no| Manual[Provide manual installation guidance]
    
    AddPath --> Continue([Continue the task])
    Manual --> Wait([Wait for user confirmation])
```

## Penetration Testing Loop

```mermaid
flowchart TD
    Init[Initialize: define target, scope, and tools] --> Loop

    subgraph Loop[Core loop]
        Align[1. Re-align with the target] --> Review[2. Review known findings]
        Review --> Decide[3. Decide the next operation]
        Decide --> Risk{4. Apply risk control}
        Risk -->|low, medium, or high| Exec[5. Execute the operation]
        Risk -->|critical| Ask[Request user approval]
        Ask -->|approved| Exec
        Exec --> Record[6. Record the result]
        Record --> Check{7. Perform a self-check}
        Check -->|continue| Align
        Check -->|complete| Done
    end

    Done[8. Complete the checks] --> Report([Generate the final report])
```

## Automatic Evolution Mechanism

```mermaid
flowchart LR
    Task([Complete the task]) --> WriteLog[Write to field-journal<br/>record pitfalls, solutions, and code]
    WriteLog --> UpdateIdx[Update _index.md<br/>classify by scenario]
    UpdateIdx --> CheckUpdate{Does the system need an update?}
    
    CheckUpdate -->|route missing| FixRoute[Update routing.md]
    CheckUpdate -->|tool changed| FixTool[Refresh tool-index]
    CheckUpdate -->|new tool| FixManifest[Update bootstrap-manifest]
    CheckUpdate -->|no update needed| Done([Complete])
    
    FixRoute & FixTool & FixManifest --> Done

    NewTask([Next similar task]) --> ReadIdx[Read _index.md]
    ReadIdx --> Reuse[Reuse existing experience<br/>avoid repeated pitfalls]
```

## Multi-Platform Support Architecture

```mermaid
flowchart TD
    subgraph Shared["Shared layer (platform neutral)"]
        Skills[skills/<br/>SKILL.md + routing.md + references]
        CTF[CTF-Sandbox-Orchestrator/<br/>40+ subskills]
        Journal[field-journal/<br/>experience retention]
        Docs[docs-generator + diagram-generator]
    end

    subgraph Windows["Windows platform layer"]
        WinScripts[skills/scripts/*.ps1<br/>PowerShell scripts]
        WinManifest[bootstrap-manifest.json<br/>winget + GitHub ZIP]
        WinRules[RULES.md<br/>Windows rules]
    end

    subgraph Kali["Kali Linux platform layer"]
        KaliScripts[kali/scripts/*.sh<br/>Bash scripts]
        KaliManifest[kali/scripts/bootstrap-manifest.json<br/>apt + pip + GitHub tar]
        KaliRules[kali/RULES-kali.md<br/>Kali rules]
    end

    Skills --> WinScripts & KaliScripts
    CTF --> WinScripts & KaliScripts
    Journal --> WinScripts & KaliScripts

    WinScripts --> WinManifest
    KaliScripts --> KaliManifest

    WinRules --> Skills
    KaliRules --> Skills
```

### Platform Selection Logic

| Environment | Rules file | Scripts | Package management |
|------|--------------|-----------|--------|
| Windows | `RULES.md` | `skills/scripts/*.ps1` | winget / GitHub release ZIP |
| Kali Linux | `kali/RULES-kali.md` | `kali/scripts/*.sh` | apt / pip / npm / GitHub tar.gz |

### Kali Edition Features

- **Many tools are preinstalled**: nmap, sqlmap, hashcat, hydra, metasploit, radare2, binwalk, and burpsuite need no bootstrap.
- **Unified apt management**: No winget or manual ZIP extraction is required.
- **Native Bash**: The scripts have no PowerShell dependency.
- **Standard paths**: `/usr/bin/`, `/opt/`, and `~/tools/` avoid drive-letter and space issues.

## File Reading Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant AI as AI client
    participant R as RULES.md / RULES-kali.md
    participant SK as SKILL.md
    participant RT as routing.md
    participant TI as tool-index.md
    participant FJ as field-journal
    participant SUB as Subskill
    participant BS as Bootstrap
    participant DOC as docs-generator

    U->>AI: Submit a security task
    AI->>R: Read routing rules
    AI->>SK: Read the control entry
    AI->>RT: Match the route
    AI->>FJ: Find similar experience
    AI->>TI: Confirm tool status
    alt Tool missing
        AI->>BS: Install automatically (.ps1 or .sh)
        BS-->>AI: Return the result
    end
    AI->>SUB: Enter the workflow
    AI-->>U: Return the task result
    AI->>DOC: Generate the report
    AI->>FJ: Write back the experience
    AI-->>U: Complete
```
