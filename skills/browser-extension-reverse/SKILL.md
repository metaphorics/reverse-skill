---
name: browser-extension-reverse
description: Use for authorized reverse engineering of browser extensions (Chrome/Firefox) including manifest analysis, background workers, and extension-based credential or traffic logic recovery.
---

# Browser Extension Reverse Engineering

## ACTION REQUIRED (Do this immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Make sure that the target is a **browser extension** (crx/xpi/extracted directory), not regular web page JS (regular → `js-reverse/`)
3. `NEXT`: Extract the extension; read manifest
4. `ACT`: Permissions → Background scripts → Network/storage hooks

## When to Use

- Chrome/Edge MV2/MV3 extension analysis
- Firefox extensions
- Investigation of malicious extension IOC and extension poisoning in a supply-chain attack
- Recovery of signing/encryption/proxy logic implemented by extensions

## Workflow

### 1. Package

```text
□ Extract crx / Get the extension directory from the profile
□ manifest.json: permissions, host_permissions, background, content_scripts
□ Evaluate excessive permissions (<all_urls>, webRequest, debugger)
```

### 2. Logic

```text
□ Find service_worker / background entry points
□ Find content_script injection points and execution worlds (isolated)
□ Find keys in chrome.storage / IndexedDB
□ Same as `js-reverse`: Observe network traffic and message passing (runtime.sendMessage)
```

### 3. Dynamic Analysis

```text
□ Load the extracted directory in developer mode
□ Check for errors at chrome://extensions
□ Attach DevTools to the service worker
□ Use Frida/browser CDP (jshookmcp) if necessary
```

## Tools

| Tool | Use |
|------|------|
| Extraction/jq | manifest |
| Chrome DevTools | worker debugging |
| js-reverse tools | Detailed JS analysis |
| YARA | Rules for malicious extensions |

## References

- `references/extension-analysis.md`
- field-journal entries related to extension recovery
- `../js-reverse/` `../malware-analysis/`

## Routing Context

**Upstream**: MASTER R30  
**Downstream**: JS with complex obfuscation → `js-reverse`; supply-chain attack investigation → supply-chain / malware

## Task Completion Checks

- [ ] Did you list the permissions and entry scripts?
- [ ] Did you recover the key data flows?
- [ ] Checklist?