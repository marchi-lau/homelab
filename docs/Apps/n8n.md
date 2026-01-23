# n8n Workflow Automation

Self-hosted workflow automation platform.

## Overview

| Property | Value |
|----------|-------|
| **URL** | https://n8n.marchi.app |
| **Namespace** | n8n |
| **Image** | n8nio/n8n:latest |
| **Storage** | 5Gi PVC (local-path) |
| **Timezone** | Asia/Hong_Kong |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Cloudflare Tunnel                           │
│                  n8n.marchi.app:443                          │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  K8s Cluster                                                    │
│                                                                 │
│   ┌─────────────────┐     ┌─────────────────┐                   │
│   │  Ingress        │────►│  Service        │                   │
│   │  cloudflare-    │     │  n8n:5678       │                   │
│   │  tunnel         │     │  ClusterIP      │                   │
│   └─────────────────┘     └────────┬────────┘                   │
│                                    │                            │
│                                    ▼                            │
│                           ┌─────────────────┐                   │
│                           │  Deployment     │                   │
│                           │  n8n            │                   │
│                           │  1 replica      │                   │
│                           └────────┬────────┘                   │
│                                    │                            │
│                                    ▼                            │
│                           ┌─────────────────┐                   │
│                           │  PVC            │                   │
│                           │  n8n-data       │                   │
│                           │  5Gi            │                   │
│                           └─────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Access

**Public URL:** https://n8n.marchi.app

First access will prompt for account creation.

---

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| N8N_HOST | 0.0.0.0 | Listen address |
| N8N_PORT | 5678 | Listen port |
| N8N_PROTOCOL | http | Internal protocol |
| WEBHOOK_URL | https://n8n.marchi.app/ | Public webhook URL |
| GENERIC_TIMEZONE | Asia/Hong_Kong | Timezone |
| NODE_ENV | production | Environment |

### Resources

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 1Gi |
| CPU | 100m | 1000m |

---

## Webhooks

n8n webhooks are accessible at:

```
https://n8n.marchi.app/webhook/<webhook-id>
https://n8n.marchi.app/webhook-test/<webhook-id>
```

External services (Slack, GitHub, etc.) can trigger workflows via these URLs.

---

## Manifest

Location: `clusters/homelab/apps/n8n.yaml`

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: n8n
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n-data
  namespace: n8n
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: n8n
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
        - name: n8n
          image: n8nio/n8n:latest
          ports:
            - containerPort: 5678
          env:
            - name: N8N_HOST
              value: "0.0.0.0"
            - name: N8N_PORT
              value: "5678"
            - name: N8N_PROTOCOL
              value: "http"
            - name: NODE_ENV
              value: "production"
            - name: WEBHOOK_URL
              value: "https://n8n.marchi.app/"
            - name: GENERIC_TIMEZONE
              value: "Asia/Hong_Kong"
          volumeMounts:
            - name: n8n-data
              mountPath: /home/node/.n8n
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "1Gi"
              cpu: "1000m"
      volumes:
        - name: n8n-data
          persistentVolumeClaim:
            claimName: n8n-data
---
apiVersion: v1
kind: Service
metadata:
  name: n8n
  namespace: n8n
spec:
  type: ClusterIP
  ports:
    - port: 5678
      targetPort: 5678
  selector:
    app: n8n
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n
  namespace: n8n
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: n8n.marchi.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: n8n
                port:
                  number: 5678
```

---

## Operations

### Check Status

```bash
# Pod status
kubectl get pods -n n8n

# Logs
kubectl logs -n n8n -l app=n8n -f

# Describe
kubectl describe pod -n n8n -l app=n8n
```

### Restart

```bash
kubectl rollout restart deployment/n8n -n n8n
```

### Update Image

1. Edit `clusters/homelab/apps/n8n.yaml`
2. Change image tag (e.g., `n8nio/n8n:1.70.0`)
3. Commit and push
4. Sync: `flux reconcile kustomization apps --with-source`

### Backup Data

```bash
# Get PVC info
kubectl get pvc -n n8n

# The data is stored on the node at /var/lib/rancher/k3s/storage/
# Backup via SSH:
ssh ubuntu@10.10.10.10 "sudo tar -czf /tmp/n8n-backup.tar.gz /var/lib/rancher/k3s/storage/pvc-*-n8n-data"
scp ubuntu@10.10.10.10:/tmp/n8n-backup.tar.gz ./
```

---

## Troubleshooting

### Pod CrashLoopBackOff

```bash
# Check logs
kubectl logs -n n8n -l app=n8n --previous

# Check events
kubectl get events -n n8n --sort-by='.lastTimestamp'
```

### 403 from Cloudflare

See [[Network/Cloudflare-Tunnel#Troubleshooting|Cloudflare Tunnel Troubleshooting]]

### Webhooks Not Working

1. Verify `WEBHOOK_URL` is set correctly
2. Check Cloudflare WAF isn't blocking webhook paths
3. Test with: `curl -X POST https://n8n.marchi.app/webhook-test/<id>`

---

## Related

- [[Homelab|Homelab Dashboard]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel]]
- [[Runbooks/Quick-Commands|Quick Commands]]

## External Links

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Docker Hub](https://hub.docker.com/r/n8nio/n8n)

## Tags

#homelab #n8n #automation #workflow #app
