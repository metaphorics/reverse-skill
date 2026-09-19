---
name: supply-chain-security
description: Use for software supply-chain security assessment covering SBOM, SCA, CI/CD pipelines, container images, build integrity, dependency provenance, and vulnerability reachability.
---
# Supply Chain Security Testing

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md`. Confirm that this skill's operations are routine and authorized.
2. `NOW`: Confirm that the current task is in scope for this skill.
3. `NEXT`: Read `../tool-index.md`. Verify tool availability and actual paths.
4. `NEXT`: If a tool is missing, call bootstrap. Do not guess paths.
5. `ACT`: Start at step 1 of the workflow and execute. Do not stop at confirmation.

> Covers SBOM, SCA, CI/CD pipelines, and dependency provenance.
> Regulatory drivers include the US executive order on SBOM, Chinese national standards, and EU CRA.

## Applicable Scenarios

- Software supply-chain security assessment
- Open-source dependency vulnerability scanning and verification
- CI/CD pipeline security audit
- Container image security analysis
- Third-party component compliance review
- Build artifact provenance and integrity verification

## Six-Layer Supply-Chain Governance Framework

```text
Layer 1: Source trust assessment -> review upstream repositories, maintainers, and release history
Layer 2: Build pipeline integration -> CI/CD security gates and signature verification
Layer 3: Artifact distribution integrity -> signatures, checksums, and SBOM attachment
Layer 4: Runtime protection -> container scanning and admission control
Layer 5: Continuous monitoring -> real-time CVE tracking and vulnerability reachability analysis
Layer 6: Incident response -> supply-chain attack response and rollback strategy
```

## Workflow

### 1. SBOM Generation and Audit

```text
Generate an SBOM:
□ CycloneDX format: cdxgen -> bom.json
□ SPDX format: sbom-tool generate
□ Syft: syft <image|dir> -o spdx-json

Audit points:
□ Check for unknown or unauthorized dependencies
□ Check for deprecated or unmaintained packages
□ Check for license conflicts
□ List direct dependencies versus transitive dependencies
□ Check the release timeline and maintainer status for each component
```

### 2. Software Composition Analysis (SCA)

```bash
# OSV-Scanner (free, maintained by Google)
osv-scanner scan -r . --format json

# OWASP Dependency-Track (continuous enterprise monitoring)
docker run -p 8080:8080 dependencytrack/apiserver
# -> Upload the SBOM -> auto-match NVD/OSV/GitHub Advisory

# Snyk (commercial)
snyk test --all-projects
snyk monitor  # continuous monitoring

# Trivy (container + dependency + IaC)
trivy fs .          # filesystem scan
trivy image nginx   # container image
trivy config .      # IaC configuration
```

### 3. Vulnerability Reachability Verification

```text
An SCA alert does not equal actual risk. Most SCA tools report only about 15% of alerts as reachable.

Verification steps:
1. Use Dependency-Track or Trivy to obtain the CVE list.
2. Filter for vulnerabilities with CVSS >= 7.0.
3. Analyze reachability for CVEs with a PoC.
   - Code Property Graph slicing: trace the path from user input to the vulnerable function.
   - DEPTEX method: EPD (Execution Path Dominance) + LLM semantic verification.
4. Verify the PoC in an isolated environment.
5. Rank reachable vulnerabilities by actual impact and set remediation priority.
```

Tool references:
- CodeQL: GitHub code queries -> data-flow analysis
- Snyk Code: reachability marking
- DEPTEX: LLM-assisted context-aware risk assessment

### 4. CI/CD Pipeline Security

```text
Security checkpoints:
□ Code commit -> pre-commit hook: gitleaks (secret scanning)
□ PR stage -> SCA scan (Trivy/OSV-Scanner)
□ Build stage -> artifact signing (cosign)
□ Push stage -> SBOM attachment (syft + attest)
□ Deploy stage -> admission control (OPA/Kyverno + image scanning)
□ Runtime -> continuous vulnerability monitoring (Dependency-Track)

Pipeline security:
□ Audit Pipeline as Code (GitHub Actions / GitLab CI configuration injection)
□ Isolate runners (prevent malicious builds from escaping the container)
□ Manage secrets (Actions Secrets / Vault; never hard-code secrets)
□ Review third-party Actions (pin a commit SHA, not a tag)
```

### 5. Container Image Security

```bash
# Dockerfile audit
hadolint Dockerfile

# Image scan (multiple layers: OS + application dependencies + configuration)
trivy image --severity HIGH,CRITICAL nginx:latest

# Minimal base image
# Prefer: distroless -> alpine -> slim -> avoid latest
docker scout quickview nginx:latest

# Image signing
cosign sign --key cosign.key myimage:tag
cosign verify --key cosign.pub myimage:tag
```

### 6. Third-Party Dependency Review

```text
New dependency Checklist:
□ Maintenance status: were there commits in the last six months? Is the maintainer active?
□ Security history: has malicious code ever been inserted?
□ Dependency tree: how many transitive dependencies does it add?
□ License: is it compatible with the project license?
□ Alternatives: is a safer alternative available (Snyk Advisor / Socket.dev score)?

Risk assessment matrix:
  High maintenance x few dependencies x compatible license -> low risk
  Low maintenance x many dependencies x license conflict -> high risk
```

## Toolchain

| Tool | Purpose | Source |
|------|---------|------|
| OWASP Dependency-Track | Continuous enterprise SCA | `docker pull dependencytrack/apiserver` |
| OSV-Scanner | Free SCA (OSV.dev ecosystem) | `go install github.com/google/osv-scanner` |
| Trivy | Image + dependency + IaC scanning | `apt install trivy` |
| Syft | SBOM generation | `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh` |
| cdxgen | CycloneDX SBOM generation | `npm install -g @cyclonedx/cdxgen` |
| Cosign | Container signing | `go install github.com/sigstore/cosign/v2/cmd/cosign` |
| Gitleaks | Secret and credential scanning | `go install github.com/gitleaks/gitleaks/v8` |
| Snyk | Commercial SCA + reachability | `npm install -g snyk` |
| CodeQL | Code queries + data flow | Built into GitHub Actions |

## References

- `references/sbom-sca-methodology.md` — SBOM + SCA methodology
- `references/cicd-pipeline-security.md` — CI/CD pipeline security audit


## Task Completion Self-Check (MUST pass before you claim completion)

- [ ] Did I execute every step of the workflow (not only read it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands / scripts / screenshots / report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
