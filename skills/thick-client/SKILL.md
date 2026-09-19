---
name: thick-client
description: Use for authorized security testing of desktop thick clients including local storage, update channels, IPC, traffic, and client-side trust boundaries.
---

# Thick Client Security Testing

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md`.
2. `NOW`: Confirm that the target is a desktop thick client (Win/macOS/Linux GUI or companion service), not a Web-only target.
3. `NOW`: Run case-init. Record the installer source and test account in scope.
4. `NEXT`: Prepare tools (Burp upstream proxy, process monitor, and reverse-engineering tools).
5. `ACT`: Map the trust boundary. Test the local surface, network surface, and update or supply-chain surface.

## Applicable Scenarios

- Client/server applications and Electron, Qt, .NET WinForms, or WPF clients
- Local configuration or credential storage, IPC, and named pipes
- Research into bypassing client-enforced checks (authorized)
- Automatic update channels and code-signature verification

## Workflow

### 1. Build the Boundary Map

```text
□ Process tree, child processes, drivers, and services
□ Listening ports and outbound domains
□ Sensitive local paths: %APPDATA%, Keychain, and the registry
```

### 2. Local Attack Surface

```text
□ Plaintext configuration, hard-coded keys, and debug switches
□ DLL hijacking and search order (Windows)
□ Database file (SQLite) permissions and encryption
□ IPC: who can connect? Is authentication enforced?
```

### 3. Network Surface

```text
□ System proxy or application-specific TLS
□ Certificate pinning -> combine mobile or JavaScript methodology with Frida
□ API broken access control: management interfaces hidden by the client
```

### 4. Reverse-Engineering Verification

```text
□ .NET -> dotnet-reverse; native -> ida/ghidra; Electron -> asar + js-reverse
```

## Toolchain

| Tool | Purpose |
|------|------|
| Process Monitor / API Monitor | Behavior |
| Burp / mitmproxy | Traffic |
| dnSpy / IDA / Ghidra | Reverse engineering |
| Sysinternals | Windows surface |
| asar / nexe detection | Electron |

## References

- `references/thick-client-checklist.md`
- `../dotnet-reverse/` `../ida-reverse/` `../js-reverse/` `../api-security/`

## Routing Context

**Upstream**: MASTER R32
**Downstream**: protocol-only work `protocol-reverse`; supply-chain updates `supply-chain-security`

## Task Completion Self-Check

- [ ] Did I draw the trust boundary?
- [ ] Did I cover both local and network surfaces?
- [ ] Is the Checklist complete?
