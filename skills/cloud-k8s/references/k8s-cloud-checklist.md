# Cloud / Kubernetes Checklist (Condensed)

## IMDS

- [ ] Can SSRF reach 169.254.169.254?
- [ ] Is IMDSv2 enforced?
- [ ] What IAM role permissions does the response expose?

## High-Risk Kubernetes Findings

- [ ] Are too many subjects bound to cluster-admin?
- [ ] Are secrets exposed as plaintext environment variables?
- [ ] Is privileged combined with hostPID or hostPath?
- [ ] Is anonymous authentication enabled, or is the API server's insecure port exposed?

## Containers

- [ ] Does the container run as root?
- [ ] Can it load kernel modules, or is docker.sock mounted?
