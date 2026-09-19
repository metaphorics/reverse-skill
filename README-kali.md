# Kali Linux Entry (Quick Link)

> **See [kali/README-kali.md](kali/README-kali.md) for full details.**
> This file is the quick Kali entry at the repository root. It avoids duplicate maintenance with the main text under `kali/`.

## AI: Execute after reading

```text
1. Detect the package root (the directory containing README.md and skills/)
2. Read kali/README-kali.md → then read and execute kali/RULES-kali.md
3. bash kali/scripts/refresh-tool-index.sh
4. Use the shared task routing with Windows: skills/MASTER-ROUTING.md and skills/ops/ (scope gate)
5. Report the configuration result to the user
```

## Humans: Start in 30 Seconds

```bash
cd /path/to/reverse-skill
bash kali/scripts/refresh-tool-index.sh
# See kali/README-kali.md for detailed bootstrap and MCP instructions
```

## Relationship to the Main Package

| Content | Location |
|---------|----------|
| Shared skills, routing, and ops | `skills/`, `RULES.md` |
| Kali scripts and manifest | `kali/scripts/` |
| Full Kali documentation | **[kali/README-kali.md](kali/README-kali.md)** |

General AI guidance remains in [README_AI.md](README_AI.md). The Kali branch redirects to this directory's documentation.
