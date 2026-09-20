# SBOM + SCA Methodology

## SBOM Standard Comparison

| Standard | Format | Ecosystem | Recommended scenario |
|------|------|------|---------|
| SPDX | JSON/YAML/tag-value | Linux Foundation, Yocto | License compliance first |
| CycloneDX | JSON/XML | OWASP, Kubernetes | Security analysis first |
| SWID | XML | ISO standard | Enterprise asset management |

## SBOM Generation Toolchain

```bash
# cdxgen: generate a CycloneDX SBOM from source
cdxgen -o bom.json -t cyclonedx

# Syft: generate from a container or filesystem
syft nginx:latest -o spdx-json > sbom.spdx.json

# SBOM-Tool: Microsoft toolchain
sbom-tool generate -b ./build -bc ./src -pn MyApp -pv 1.0
```

## SCA Tool Comparison

| Tool | Free | Speed | Database | Reachability |
|------|:--:|------|--------|:--:|
| OSV-Scanner | ✅ | Very fast | OSV.dev | ❌ |
| Trivy | ✅ | Fast | Multiple sources | ❌ |
| Dependency-Track | ✅ | Medium | NVD+OSV+GitHub | ❌ (requires plugin) |
| Snyk | ❌ | Medium | Proprietary | ✅ |
| CodeQL | ✅ | Slow | Code-level | ✅ |

## Vulnerability Priority Strategy

```
CVSS >= 9.0 + public PoC + reachable -> P0, fix immediately
CVSS >= 7.0 + PoC + reachable -> P1, fix this week
CVSS >= 7.0 + no PoC or unreachable -> P2, fix in the next iteration
Other findings -> follow the normal process
```

## Three-Step Manual Verification

```bash
# 1. Confirm the version (do not trust SBOM fields blindly)
# In a container: dpkg -l | grep <package>
# Node: cat node_modules/<pkg>/package.json | jq .version
# Python: pip show <package>

# 2. Confirm the vulnerability
# Search CVE: https://osv.dev / https://nvd.nist.gov
# Check the affected version range
# Find the GitHub Advisory or oss-security mailing list entry

# 3. Verify the impact
# Search public PoCs: GitHub/Exploit-DB
# Analyze exploitation conditions: does it require authentication, local access, or a specific configuration?
# Verify in an isolated environment: docker run --rm -it vulnerable-image bash
```

## Continuous Monitoring

```yaml
# Daily SBOM update and scan
schedule:
  - cron: "0 6 * * *"  # every day at 6:00
    steps:
      - cdxgen -o bom.json
      - osv-scanner scan --sbom bom.json
      - trivy fs --exit-code 1 --severity CRITICAL .
```

Source: OWASP CycloneDX, SPDX, Google OSV, CISA SBOM Guidance
