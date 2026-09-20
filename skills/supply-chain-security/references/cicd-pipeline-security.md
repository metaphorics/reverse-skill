# CI/CD Pipeline Security Audit

## Pipeline Attack Surface

```text
Threat model (STRIDE):
□ Spoofing: forge builds, signatures, or origin
□ Tampering: modify source code, build artifacts, or dependencies
□ Repudiation: perform malicious operations without audit logs
□ Information disclosure: leak secrets through pipeline logs or build artifacts
□ Denial of service: exhaust CI resources or break the build
□ Privilege escalation: escape the runner or steal credentials
```

## Audit Checklist

### 1. Pipeline as Code Configuration

```yaml
# GitHub Actions audit points
# ❌ Dangerous pattern
on:
  pull_request_target:  # PR trigger with access to secrets
    types: [opened]

# ❌ Script injection
- run: echo "${{ github.event.issue.title }}"  # user input -> shell

# ❌ Unrestricted token permissions
permissions: write-all

# ✅ Safe pattern
on:
  pull_request:  # no secrets access
    types: [opened]

# ✅ Pin to a SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

# ✅ Least privilege
permissions:
  contents: read
```

### 2. Secret Management

```bash
# Scan secrets in commit history
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified

# Check Actions Secrets use
gh secret list
# Confirm: no hard-coded secrets, regular rotation, least privilege

# Runtime secret injection
# ✅ Use OIDC instead of long-lived secrets
# ✅ Expose secrets only to the steps that need them
```

### 3. Build Integrity

```bash
# Build provenance
# Generate a tamper-resistant build record (SLSA L2+)
slsa-provenance generate --source . --output provenance.json

# Artifact signing
cosign sign-blob --key cosign.key artifact.tar.gz

# Verification
cosign verify-blob --key cosign.pub --signature artifact.tar.gz.sig artifact.tar.gz
```

### 4. Runner Security

```text
□ Is a GitHub-hosted runner used? (Recommended because each run uses a new environment.)
□ Self-hosted runner: does it run in an isolated VM or container?
□ Has a fork PR run? (Self-hosted runners have very high risk.)
□ Does the runner have outbound network restrictions?
□ Could the build cache leak data across builds?
```

### 5. Dependency Download Security

```text
□ npm: is package-lock.json committed? Do not use --force / --legacy-peer-deps.
□ pip: is requirements.txt pinned? Do not use pip install <unverified source>.
□ Docker: is FROM pinned to a digest? Do not use the latest tag.
□ Go: is go.sum committed?
□ Private packages: does registry authentication use a short-lived token?
```

## Automated Pipeline Checks

```yaml
# .github/workflows/supply-chain.yml
name: Supply Chain Security
on: [push, pull_request]

jobs:
  sca:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: SBOM Generate
        run: |
          npm install -g @cyclonedx/cdxgen
          cdxgen -o sbom.json
      
      - name: OSV Scan
        run: |
          go install github.com/google/osv-scanner/cmd/osv-scanner@latest
          osv-scanner scan --sbom sbom.json --format sarif > osv-results.sarif
      
      - name: Trivy Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
          exit-code: 1
      
      - name: Secret Scan
        run: |
          docker run --rm -v $PWD:/src ghcr.io/gitleaks/gitleaks:latest \
            detect --source /src --verbose
      
      - name: Dependency-Track Upload
        run: |
          curl -X POST https://dtrack.example.com/api/v1/bom \
            -H "X-Api-Key: ${{ secrets.DTRACK_API_KEY }}" \
            -F "autoCreate=true" -F "project=myapp" -F "bom=@sbom.json"
```

Source: SLSA Framework, OWASP CI/CD Top 10, GitHub Security Lab
