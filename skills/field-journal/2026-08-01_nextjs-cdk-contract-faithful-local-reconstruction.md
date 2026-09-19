# Contract-faithful local reconstruction of a Next.js CDK order center

> - Date: 2026-08-01
>
> - Scenario: web, API, and JS reverse engineering with local reconstruction
>
> - Redaction: the target domain and port use standard placeholders. Credentials, CDKs, order identifiers, and private paths keep only their categories, not their original values.

## Scenario

Web, API, and JS reverse engineering

## Target summary

Build a four-source evidence chain for a Next.js single-page order center. Use an entry snapshot, static bundle, runtime page, and public OpenAPI. Without connecting to real payment, worker, or check services, rebuild a runnable local project with the same information architecture, browser request shapes, response projections, and order-state semantics.

## Scope summary (redacted)

- auth_basis: the user supplied the entry point and requested analysis plus a matching local implementation
- network_profile: read-only review of the public entry point and public OpenAPI. Build and acceptance checks point to loopback addresses.
- asset_types: [web, frontend_js, public_openapi, screenshot, local_source]
- fixture_profile: synthetic CDK, synthetic credential, synthetic payment link, deterministic worker/check/payment adapters

## Roles

- lead_role: lead
- specialists: [cre, doc]

## Execution record

1. Freeze the entry HTML, response headers, public OpenAPI, and SHA-256. Reuse existing static packages and browser evidence.
2. Extract routes, request-body fields, headers, Storage keys, polling intervals, conditional rendering, and state vocabulary from the main page bundle.
3. Model the internal legacy API and public v1 API separately. Give each its own serializer to prevent shared DTO field drift.
4. Use full-page runtime screenshots, the DOM, and computed CSS to recover desktop geometry, mobile breakpoints, card hierarchy, control states, and copy baselines.
5. Build a canonical domain model, CDK ledger, and deterministic state machine. Adapt external capabilities through `CHECK_FN`, `PAYMENT_PROVIDER`, and `WORKER_GATEWAY` fixture adapters.
6. Reduce credentials and payment links at request time to a summary, type, and safety notice. Do not provide a raw-value slot in the persistent model.
7. Run contract tests for single, batch, detail, cancel, resubmit, pagination, dual authorization, and OpenAPI documentation.
8. Verify visuals with desktop and mobile browser screenshots. Build delivery evidence with a production build, endpoint smoke tests, secret scanning, and extraction rechecks.

## Evidence chain summary (redacted)

| E-id | source_type | Reusable command pattern | Related conclusion |
|------|-------------|----------------|----------|
| E-001 | network/file | `curl -D headers -o page https://{target_domain}/<entry>; shasum -a 256 page` | Framework entry point and timestamp baseline |
| E-002 | frontend_js/openapi | `rg 'sessionStorage|/api/|productType|customerToken' {formatted_chunk}`; `jq '{info,paths,securitySchemes}' openapi.json` | Legacy requests, state, browser storage, and v1 contract |
| E-003 | runtime_visual/local_qa | `chromium --headless ...; screenshot + DOMRect`; `npm test && npm run build && BASE_URL=... npm run smoke` | Desktop/mobile geometry, conditional rendering, and local contract closure |

## Finding and path summary

- top_finding: the internal legacy API and public v1 API share business semantics, but their request fields, authorization entry points, and response projections differ. Reconstruction needs one domain model and two boundary serializers.
- path_type: callflow
- path_one_liner: form input -> page field mapping -> legacy Route Handler -> canonical service -> fixture adapter/ledger -> legacy serializer -> polling render

## Pitfalls

| Problem | Cause | Resolution | Time |
|------|------|---------|------|
| Building endpoints from route names alone left page fields blank | Legacy and v1 response fields were not the same DTO | Infer serializers from bundle property reads. Test both boundaries separately | About 45 minutes |
| Initial and bound page states were mixed together | Many cards, notices, buttons, and lists render conditionally | Freeze the unbound baseline first. Then build an interaction matrix by CDK and order state | About 30 minutes |
| The batch endpoint needed to express partial success and ledger consistency together | Raising one item error to a batch error lost the original per-item result semantics | Parse each item first. Within one store mutation, emit created, duplicate, and failed in order. Validate the ledger once at the end and write atomically | About 35 minutes |
| OpenAPI required fields and property names were ambiguous | OpenAPI and internal page calls evolved independently | Keep the specification fields. Recognize a compatible alias at the boundary. State the decision basis in the report | About 15 minutes |
| Visual similarity looked close, but vertical error kept accumulating | Small differences in card padding, line height, and gaps compounded | Constrain full-page height, main-column width, and key DOMRects. Recheck screenshots section by section | About 40 minutes |
| Fixture notices changed the matching first screen | Implementation notes entered the product UI directly | Keep the UI at the evidence baseline. Put fixture notes in the README. Keep inputs deterministic | About 15 minutes |

## Tool findings

- Property-read locations in a static bundle recover response DTOs better than endpoint paths alone.
- Separate legacy and v1 serializers preserve both page compatibility and public API stability.
- A `fullPage` screenshot needs viewport width, total page height, and DOMRects. Pixel similarity alone overstates font anti-aliasing differences.
- Batch orders should retain per-item created, duplicate, and failed results. Keep deduplication, capacity reduction, and ledger validation in one mutation, then perform one atomic file replacement.
- Secret scanning must cover source, the runtime store, test logs, and the final extracted archive, not only the Git worktree.

## Key code and commands

```bash
# Static call surface and state fields
rg -n 'customerToken|productType|upiExpiresAt|customerResubmitCount|sessionStorage' {formatted_chunk}

# Public API structure
jq '{openapi,info,paths:(.paths|keys),security:.components.securitySchemes}' openapi.json

# Local quality gates
npm run lint
npm test
npx tsc --noEmit
npm run build
BASE_URL=http://127.0.0.1:{port} npm run smoke
```

## Improvement suggestions for this package

1. Add a legacy UI API and public API dual-serializer checklist to `js-reverse`.
2. Add a visual-baseline geometry table and initial, bound, and order-state matrix to the report template.
3. Add batch partial success with atomic write, dual-authorization OR, OpenAPI schema versus actual response consistency, and delivery-package extraction scanning to the QA template.

## Reusable patterns and script fragments

1. **Four-source cross-check**: use the entry snapshot to locate the version, the static bundle to recover the call surface, the runtime to recover conditional rendering, and OpenAPI to recover the public contract.
2. **One core, two projections**: keep state and ledger consistency in the canonical domain. Keep boundary fidelity in the legacy and public serializers.
3. **Initial state before state matrix**: lock the unbound first screen, then verify bound, created, in-progress, completed, canceled, and resubmitted states.
4. **Request-time reduction**: convert raw input to SHA-256, type, and mask immediately after it enters the service. Let logs and the store receive reduced values only.
5. **Second delivery-package check**: extract the archive into a new directory, reinstall, test, and build again. Do not let worktree residue hide defects.

## Follow-up actions

- [ ] Update the routing matrix
- [ ] Update the tool index
- [ ] Update the bootstrap manifest
- [ ] Update the child skill documentation
- [x] Add the pitfall record
- [ ] No update needed

## Environment

- OS: macOS
- Tool versions: Node.js 24, Next.js 16.2.12 App Router, React, TypeScript 5.9.3, Chrome/Playwright
- Target platform/version: Next.js App Router / React / OpenAPI 3.1

## Final acceptance record

- ESLint, TypeScript 5.9.3, and the Next.js 16.2.12 production build passed.
- Node tests: 8/8 passed.
- HTTP smoke tests: 15 contract groups passed.
- Playwright: 11 state and viewport screenshots and 10 assertion groups passed. The browser console and page errors were empty.
- The 1440 px initial page and baseline were both 1440×1294. RGB MAE was 2.301148, with 0.945085 of pixels within the 5-per-channel threshold.

## Redaction review

- [x] Target domain replaced with `{target_domain}`
- [x] Original CDK, order number, Token, Cookie, JWT, and payment link were not written
- [x] Real IP, port, and local private path were not written
- [x] Commands use `{port}` and placeholders
- [x] Delivery experience keeps methods, structure, and validation patterns only

---
<!-- [Community contribution] Ask the user whether to open a PR against the main repository after completion. -->
