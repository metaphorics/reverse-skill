# reverse-skill identity statement (compared with Z3r0)

> This file defines **who we are**. It adopts Z3r0 ideas about evidence, scope, roles, and timelines, but **does not** become the Z3r0 platform.

## We are

| Dimension | reverse-skill |
|------|----------------|
| Form | **Skill routing package** — methods and tool bootstrap for any AI client (Claude/Cursor/Codex…) |
| Entry | `RULES.md` → `MASTER-ROUTING` / `master-route.ps1` → child skill |
| Tool source of truth | `tool-index.md` + `bootstrap-manifest.json` (use local paths; do not guess) |
| Evolution | `field-journal/` writes back redacted experience |
| Outputs | Markdown reports + local `work/<case>/` case workspace (gitignored) |
| Deployment | `git clone` is enough; no required PG/UI/Docker pool |

## We are not

| Z3r0 has | reverse-skill **deliberately does not** |
|---------|---------------------------|
| React operations console | ❌ |
| FastAPI control plane + WebSocket sessions | ❌ |
| PostgreSQL evidence database | ❌ |
| LightRAG service | ❌ |
| Docker host pool / noVNC control proxy | ❌ (may **document** an optional sandbox profile) |
| Multi-agent process runtime | ❌ (only **role → skill mapping + handoff protocol**) |

## What we learn from Z3r0 (reduced implementation)

| Idea | reverse-skill form |
|------|-------------------|
| Authorization and project boundaries | `ops/scope-contract.md` → one `scope.md` per case |
| Evidence→Finding→Path | `ops/evidence-finding-path.md` + report templates |
| Expert roles | `ops/role-map.md` (Lead/cie/cpe/cre…→ skill) |
| Replayability | Append to `work/<case>/timeline.md` |
| WorkItem/coverage | `workitems.md` + coverage checks |
| Complete sandbox tools | `ops/sandbox-profile.md` vs bootstrap-manifest |
| Outbound controls | `network_profile` field (offline/lab/authorized) |

## Features (must keep)

1. **Three-axis routing + PRIMARY fast path** (target type / intent / toolchain)  
2. **On-demand bootstrap** across Windows/Kali/Linux/macOS  
3. **MCP-friendly** (IDA/Burp/jshook/anything-analyzer)  
4. **Redacted field-journal evolution**  
5. **Execution discipline**: ACTION REQUIRED / completion checks / no false stops  

## Healthy relationship with Z3r0

```text
Z3r0 = red-team operating system / team collaboration platform
reverse-skill = Agent security-work router + manual

Optional future: connect this package's skill content to Z3r0 sandbox-local skills
Current: the package works after `Z3r0`-free installation with zero dependencies
```

## Relationship with the “800+ community micro skills”

- **Do not** use a submodule for a large skill library (poisoning surface and maintenance cost are covered in `skill-supply-chain.md`)  
- **Maintain** `references/community-security-skills.md` as an index and borrowing guide  
- **Use** `domain-coverage-map.md` to show that deep skills plus routing beat fragmented skill stacks  
- External skill installation: apply AST10 thinking and trust only curated sources (such as Trail of Bits curated)  
