# Homelab K3s GitOps Agent

You are a homelab infrastructure agent managing a K3s cluster via Flux GitOps.

## Knowledge Base

Always read these docs first for context:
- `docs/Homelab.md` - Cluster overview and status
- `docs/Nodes/S740-Master.md` - Master node details
- `docs/Network/VLAN-Setup.md` - Network configuration
- `docs/Runbooks/Flux-Commands.md` - Flux GitOps commands
- `specs/README.md` - Service specifications index

## Speckit Integration

This repository uses speckit for service specifications. All deployed services have formal specs.

### Spec Structure

```
specs/
├── README.md                      # Spec index
├── _template/                     # Template for new specs
│   └── service-spec-template.md
└── NNN-service-name/
    └── spec.md                    # Service specification
```

### Specs vs Docs

| Content Type | Location |
|-------------|----------|
| Technical requirements | `specs/NNN-name/spec.md` |
| K8s resource definitions | `specs/NNN-name/spec.md` |
| Dependency mapping | `specs/NNN-name/spec.md` |
| User guides | `docs/Apps/name.md` |
| Troubleshooting guides | `docs/Apps/name.md` |
| Architecture diagrams | `docs/Apps/name.md` |

### Speckit Commands

```bash
# Find specs by keyword
/speckit.find <keyword>

# Create new spec for new service
/speckit.new <service-name>
```

### Creating a New Service

1. Create spec first: `cp -r specs/_template specs/NNN-service-name`
2. Fill in spec with requirements and K8s config
3. Create manifest in `clusters/homelab/apps/<service-name>.yaml`
4. Update kustomization
5. Create docs in `docs/Apps/<service-name>.md`

## Environment

```bash
export KUBECONFIG=~/.kube/config-s740
```

| Item | Value |
|------|-------|
| K3s Master | 10.10.10.10 |
| K3s API | https://10.10.10.10:6443 |
| GitOps | Flux v2.7.5 |
| GitHub Repo | marchi-lau/homelab |
| Apps Path | `clusters/homelab/apps/` |
| Docs Path | `docs/` |

## Capabilities

### 1. Deploy App

When asked to deploy an app:

1. **Create manifests** in `clusters/homelab/apps/<app-name>.yaml`
2. **Update kustomization** in `clusters/homelab/apps/kustomization.yaml`
3. **Git commit and push**
4. **Trigger Flux sync**: `flux reconcile kustomization apps --with-source`
5. **Verify**: `kubectl get pods -n <namespace> -w`
6. **Document** in `docs/Apps/<app-name>.md`

### 2. Check Status

```bash
kubectl get nodes
kubectl get pods -A
flux get all -A
```

### 3. Troubleshoot

```bash
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
flux logs
```

## Deployment Template

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: <app-name>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: <app-name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      containers:
        - name: <app-name>
          image: <image>
          ports:
            - containerPort: <port>
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: <app-name>
spec:
  type: NodePort
  ports:
    - port: <port>
      targetPort: <port>
      nodePort: <305xx>
  selector:
    app: <app-name>
```

## NodePort Allocation

| Port | App |
|------|-----|
| 30500-30599 | Apps |

## Git Workflow

- **Use plan mode** for new service deployments to improve accuracy
- **Create feature branches** for new services: `feature/<service-name>`
- Commit format: `deploy: <app>`, `remove: <app>`, `fix: <desc>`
- Push feature branch → Create PR → Merge to main → Flux syncs
- Use `flux reconcile kustomization apps --with-source` to force sync after merge

## MCP Services

MCP (Model Context Protocol) services are private and exposed only via Tailscale.

### Naming Convention

All MCP services MUST be prefixed with `mcp-`:
- Namespace: `mcp-<service-name>`
- Service: `mcp-<service-name>`
- Ingress hostname: `mcp-<service-name>`

### Ingress

MCP services use **Tailscale Ingress** (private, not public):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcp-<service-name>
  namespace: mcp-<service-name>
spec:
  ingressClassName: tailscale
  tls:
    - hosts:
        - mcp-<service-name>
  rules:
    - host: mcp-<service-name>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mcp-<service-name>
                port:
                  number: <port>
```

Access URL: `https://mcp-<service-name>.<tailnet>.ts.net`

### Local MCP Servers (.mcp.json)

MCP servers configured in `.mcp.json` should also use `mcp-` prefix:
- `mcp-cloudflare` - Cloudflare API (cache purge, DNS)
- `mcp-<name>` - Other MCP servers

| Ingress Type | Use Case |
|--------------|----------|
| `cloudflare-tunnel` | Public apps (homepage, n8n, etc.) |
| `tailscale` | Private MCP servers |

### MCP Client Configuration Rules

When configuring MCP clients in Claude Desktop or Claude Code (`.mcp.json`):

**ONLY change the domain/URL information.** Do NOT modify:
- Transport mechanism (e.g., `mcp-remote`, `supergateway`)
- Command structure or arguments format
- Header configuration patterns

Copy existing working configurations and only update the endpoint URL.

## Lessons Learned

### Synology NFS Permissions

When using `synology-nfs` storage class with non-root containers:

1. **Synology NFS Settings** must have:
   - Squash: **No mapping** (not "Map root to admin")
   - After changing, **restart NFS service** on Synology

2. **Even with "No mapping"**, non-root users may fail to access NFS volumes. Fix with:
   ```yaml
   spec:
     securityContext:
       fsGroup: <user-gid>  # e.g., 1001
     initContainers:
       - name: fix-permissions
         image: busybox:1.36
         command: ['sh', '-c', 'chmod -R 777 /data && chown -R <uid>:<gid> /data']
         volumeMounts:
           - name: data
             mountPath: /data
   ```

3. **Storage class selection**:
   - `synology-nfs`: Shared storage, survives node failure, needs permission fixes for non-root
   - `local-path`: Node-local storage, no permission issues, but data tied to specific node

### Tailscale Service Expose

- `tailscale.com/expose: "true"` annotation exposes services via Tailscale
- For **TCP services** (SSH), use Service annotation instead of Ingress
- For **multiple ports**, SSH tunneling is more reliable: `ssh -L 3000:localhost:3000 user@host`
- Tailscale Ingress is HTTP/HTTPS only

### Docker Cross-Platform Builds

When building on Apple Silicon (arm64) for K3s nodes (amd64):

```bash
docker buildx build --platform linux/amd64 -t <image>:<tag> --push .
```

- K3s nodes are **amd64**, Mac is **arm64** - images must match target platform
- Error `no match for platform in manifest` means wrong architecture
- Always use `--platform linux/amd64` for K3s deployments

### ghcr.io Private Images

ghcr.io images are **private by default**. To pull in K3s:

1. Create imagePullSecret:
   ```bash
   kubectl create secret docker-registry ghcr-secret \
     --namespace=<app-namespace> \
     --docker-server=ghcr.io \
     --docker-username=<github-user> \
     --docker-password=$(gh auth token)
   ```

2. Reference in deployment:
   ```yaml
   spec:
     imagePullSecrets:
       - name: ghcr-secret
   ```

### Flux Image Automation

For auto-deployment when source repo changes:

1. **Install controllers** (if not present):
   ```bash
   kubectl apply -f https://github.com/fluxcd/flux2/releases/download/v2.7.5/install.yaml --server-side
   ```

2. **GitRepository must use HTTPS + PAT** for write access (not SSH deploy key):
   ```yaml
   # clusters/homelab/flux-system/gotk-sync.yaml
   spec:
     secretRef:
       name: flux-system-pat  # Not flux-system (read-only deploy key)
     url: https://github.com/<user>/<repo>.git
   ```

3. **Create PAT secret**:
   ```bash
   kubectl create secret generic flux-system-pat \
     --namespace=flux-system \
     --from-literal=username=<github-user> \
     --from-literal=password=$(gh auth token)
   ```

4. **Required resources**:
   - `ImageRepository` - scans registry for new tags
   - `ImagePolicy` - selects which tag to use
   - `ImageUpdateAutomation` - commits updated tags to Git

5. **Deployment marker** for auto-update:
   ```yaml
   image: ghcr.io/org/repo:tag # {"$imagepolicy": "flux-system:policy-name"}
   ```
