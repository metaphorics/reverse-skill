---
name: cloud-k8s
description: Use for authorized cloud, container, and Kubernetes security assessment including metadata SSRF, IAM misconfig, container escape paths, and cluster RBAC review.
---

# Cloud / Container / Kubernetes Security

## ACTION REQUIRED (run immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md`. **Written authorization is required for cloud and Kubernetes testing.**
2. `NOW`: Run case-init and define scope. State account boundaries and prohibited destructive actions.
3. `NOW`: Confirm that the target is cloud metadata, a container, Kubernetes, or IAM. Do not treat it as an ordinary Web scan. Use `pentest-tools/` for ordinary Web scans.
4. `NEXT`: Read tool-index. You often install kubectl, aws, and gcloud manually.
5. `ACT`: Start with identity and exposure. Do not scan the entire network by default.

## Applicable Scenarios

- Cloud metadata SSRF (169.254.169.254 / IMDS)
- Excessive IAM permissions, public storage buckets, or incorrect security groups
- Docker or containerd escape-path assessment
- Kubernetes RBAC, Secrets, Admission, and supply-chain images
- Container image vulnerabilities (can link to `supply-chain-security/`)

## Workflow

### Phase 1 - Identity and Boundaries

```text
□ Current identity: cloud AK/SK, Kubernetes SA, or node SSH?
□ Scope: one account, one cluster, or one namespace
□ Network profile: authorized_target_only
```

### Phase 2 - Cloud Control Plane

```bash
# Example (replace for the vendor; MUST run within the authorized account)
aws sts get-caller-identity
aws s3 ls
# Use the corresponding identity command for Azure or GCP
```

```text
□ Public buckets or incorrect ACLs
□ Metadata: IMDSv1 versus v2; SSRF chain
□ Role assumption (PassRole) and lateral movement
```

### Phase 3 - Containers

```text
□ Is the container privileged? Does it use hostPath or hostNetwork?
□ Capabilities (such as SYS_ADMIN)
□ Writable host paths -> escape candidates
□ Image history and known CVEs -> Trivy
```

### Phase 4 - Kubernetes

```bash
kubectl auth can-i --list
kubectl get pods,secrets,svc -A
kubectl get clusterrolebindings
```

```text
□ SA token mounts and permissions
□ Missing dangerous admission webhooks
□ Exposed etcd or dashboard
□ Does the network policy allow traffic by default?
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|------|------|
| kubectl | Cluster interaction | Manual |
| trivy | Image and IaC | Bootstrap `trivy` when available |
| kube-bench / kubeaudit | CIS and configuration | Manual |
| pacu / scoutsuite | Cloud audit (authorized) | Manual |
| nuclei | Known cloud vulnerability templates | Bootstrap nmap/nuclei ecosystem |

## References

- `references/k8s-cloud-checklist.md`
- CTF comparison: `../../CTF-Sandbox-Orchestrator/competition-agent-cloud/`
- `../supply-chain-security/` `../pentest-tools/`

## Routing Context

**Upstream**: MASTER R23
**Downstream**: node shell obtained -> `attack-chain` / `windows-ad`; image vulnerability -> supply-chain
**MUST NOT**: Scan other public-cloud tenants without authorization.

## Task Completion Self-Check

- [ ] Did I limit work to the authorized account or cluster?
- [ ] Does each finding include reproduction and impact?
- [ ] Did I avoid destructive actions?
- [ ] Did I write the report and journal entry?
