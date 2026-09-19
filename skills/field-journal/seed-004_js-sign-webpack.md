# [Seed] JS signature reverse engineering (Webpack + AES + timestamp)

## Scenario category
JS signatures

## Goal summary
Recover the algorithm that generates the `sign` parameter for a Web application endpoint and reproduce it locally.

## Full execution path

1. Capture browser traffic → find a POST request with `sign` and `timestamp` parameters.
2. Search the JS source for `"sign"` → locate the Webpack chunk file.
3. Set a breakpoint where `sign` is assigned → hit it and inspect the call stack.
4. Trace the call stack → find the signature function in a Webpack module.
5. Analyze the signature logic: `sign = HmacSHA256(sorted_params + timestamp, secret_key)`.
6. Find the key source: it is hard-coded in another Webpack module.
7. Reproduce it locally in Node.js → the generated `sign` matches the browser value.
8. Verify it: use the reproduced `sign` to request the endpoint → receive normal data.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The search for `"sign"` returned too many results | Webpack compressed the variable names | Search for `sign=` or find the request in the network panel and trace its initiator | 15min |
| The breakpoint hit but the code was unclear | Webpack compression and variable-name obfuscation | Use Chrome Pretty Print and a SourceMap, if available | 10min |
| The local reproduction did not match | The parameter sort order was wrong | Check the source sort logic carefully (alphabetical keys plus special-character handling) | 30min |
| The timestamp precision was wrong | The server uses seconds, but the reproduction used milliseconds | Use `Math.floor(Date.now() / 1000)` | 5min |
| The key was hard to find | Another chunk imports the key with `require` | Print the key variable with `console.log` at the breakpoint | 10min |

## Toolchain findings

- The Chrome DevTools initiator column locates the signature function faster than a source search.
- Pretty Print plus breakpoints is more effective than reading compressed Webpack code directly.
- If a SourceMap (`.map` file) exists, use it to restore the original code.
- Node.js `crypto` can reproduce most signature algorithms directly.

## Key code / commands

```javascript
// Node.js reproduction
const crypto = require('crypto');

function generateSign(params, timestamp, secretKey) {
    // 1. Sort parameters alphabetically by key
    const sorted = Object.keys(params).sort().map(k => `${k}=${params[k]}`).join('&');
    // 2. Append the timestamp
    const message = sorted + '&timestamp=' + timestamp;
    // 3. HMAC-SHA256
    return crypto.createHmac('sha256', secretKey).update(message).digest('hex');
}

const params = { user_id: '123', action: 'query' };
const timestamp = Math.floor(Date.now() / 1000);
const secretKey = 'hardcoded_key_from_webpack';
console.log(generateSign(params, timestamp, secretKey));
```

## Improvement suggestions for this package

- Add guidance for handling dependencies between Webpack chunks to `js-reverse` `env-patching.md`.
- Add a quick reference for common signature algorithms (HMAC-SHA256 vs MD5 vs custom).

## Reusable patterns / script fragments

**Standard JS signature reverse-engineering flow**:
```text
1. Capture a request with a signature
2. Locate the signature function through the initiator or call stack
3. Analyze the signature logic (parameter sorting, concatenation, and encryption)
4. Find the key source (hard-coded value, endpoint response, or time derivation)
5. Reproduce it in Node.js
6. Compare and verify
```

**Common signature patterns**:
```text
- HmacSHA256(sorted_params, key) → most common
- MD5(params + salt + timestamp) → older systems
- AES(JSON.stringify(params), key) → encryption rather than a signature
- RSA sign → uncommon, usually in financial systems
```

## Evolution actions
- [ ] No update needed for the routing matrix
- [ ] No update needed for the bootstrap manifest
- [ ] No update needed for child skill documentation

## Environment information
- OS: Windows
- Tool versions: Chrome DevTools, Node.js 20+
- Target platform: Web (Webpack-bundled SPA)

## Redaction requirements
This seed entry is based on public technical patterns and does not involve a real target.

---
<!-- [Community contribution] Seed data. No PR needed. -->
