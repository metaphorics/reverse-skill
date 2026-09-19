# Modern web-lab friction → skill hardening

> - Date: 2026-07-18
> - Scenario: legal public lab (PortSwigger-style scanner-eval / OWASP Juice Shop demo)
> - Redaction: no real business-domain exploitation details

## Conclusion for the next agent

**A failed compromise does not mean the package is invalid.** The next agent must deliver a surface map, sink list, gate reason, and `Evidence(observed|validated)`. Failures must enter the timeline and feed back into the playbook.

## Pitfalls

| Pitfall | Symptom | Fix or discipline |
|----|------|-----------|
| case-init authorization was polluted | After `-AuthGranted`, status became a strange string | Only pending, granted, denied, and unknown are allowed. `PSBoundParameters` must check AuthStatus |
| lab_only was not ready | `ready_for_act` was false when network=lab_only | `lab_only + granted + assets → ready` is the required condition |
| Windows curl `[]` | `bad range in position` | The fix is **`curl.exe --globoff`** |
| append-evidence special characters | Quotes or XML in RawExcerpt caused an error | Block indentation and control-character removal are required |
| Public demo returned 503 | Juice Shop Heroku was down | Local Docker or another legal target is the fallback. Repeated retries are not useful |
| DOM XSS false positive | An innerHTML sink was reported as validated | A 200 response with a non-numeric body is required before exploitation. Otherwise the result stays observed |
| agent-browser reference expired | click failed | A new snapshot is required after the page changes |

## Reusable patterns

1. Surface → sink → chain (see `pentest-tools/references/client-side-lab-playbook.md`)
2. For inventory-style `innerHTML = fetchBody`, the sink must be proven first, followed by a search for a 200 response with a non-numeric body
3. The two proofs are static rg sink search and agent-browser evaluation

## Toolchain

- case-init / case-guard / append-evidence / smoke
- agent-browser (CDP)
- curl --globoff

## Environment

- Windows + PowerShell 5.1
- Docker Desktop daemon may not be ready
