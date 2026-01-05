# Monitoring Stack

Prometheus + Grafana monitoring for the K3s homelab cluster.

## Overview

| Property | Value |
|----------|-------|
| **Grafana URL** | https://grafana.marchi.app |
| **Namespace** | monitoring |
| **Helm Chart** | kube-prometheus-stack |
| **Chart Version** | 72.9.1 |
| **Prometheus Storage** | 5Gi PVC |
| **Grafana Storage** | 1Gi PVC |
| **Retention** | 7 days |

---

## Architecture

```
                     Cloudflare Tunnel
                  grafana.marchi.app:443
                           |
                           v
+---------------------------------------------------------+
|  K8s Cluster - monitoring namespace                     |
|                                                         |
|   +-------------+     +--------------+                  |
|   |  Ingress    |---->|  Service     |                  |
|   |  cloudflare-|     |  grafana:80  |                  |
|   |  tunnel     |     |  ClusterIP   |                  |
|   +-------------+     +------+-------+                  |
|                              |                          |
|                              v                          |
|   +--------------------------------------------------+  |
|   |                    Grafana                        | |
|   |                    (Visualization)                | |
|   +---------------------------+----------------------+  |
|                               |                         |
|                               v                         |
|   +--------------------------------------------------+  |
|   |                    Prometheus                     | |
|   |                    (Metrics Storage)              | |
|   +---------------------------+----------------------+  |
|                               |                         |
|              +----------------+----------------+        |
|              v                v                v        |
|   +--------------+ +---------------+ +--------------+   |
|   | node-exporter| |kube-state-    | |ServiceMonitors|  |
|   | (Node metrics)| |metrics       | |(K8s metrics)  |  |
|   +--------------+ +---------------+ +--------------+   |
+---------------------------------------------------------+
```

---

## Components

| Component | Status | Purpose | Memory |
|-----------|--------|---------|--------|
| **Prometheus** | Enabled | Metrics storage & scraping | ~300MB |
| **Grafana** | Enabled | Visualization & dashboards | ~150MB |
| **node-exporter** | Enabled | Host/node metrics | ~30MB |
| **kube-state-metrics** | Enabled | K8s object metrics | ~50MB |
| **Prometheus Operator** | Enabled | CRD management | ~50MB |
| **Alertmanager** | Disabled | Not needed for homelab | - |
| **kubeEtcd** | Disabled | K3s uses SQLite | - |
| **kubeControllerManager** | Disabled | K3s bundles components | - |
| **kubeScheduler** | Disabled | K3s bundles components | - |

**Total estimated RAM:** ~580MB

---

## Access

### Grafana

**URL:** https://grafana.marchi.app

**Default credentials:**
- Username: `admin`
- Password: `admin`

> **Warning:** Change the default password on first login!

### Built-in Dashboards

Dashboards are organized in the **Kubernetes** folder:

- Kubernetes / API server
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Multi-Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Namespace (Workloads)
- Kubernetes / Compute Resources / Node (Pods)
- Kubernetes / Compute Resources / Pod
- Kubernetes / Compute Resources / Workload
- Kubernetes / Kubelet
- Kubernetes / Networking / Cluster
- Kubernetes / Networking / Namespace (Pods)
- Kubernetes / Networking / Namespace (Workload)
- Kubernetes / Networking / Pod
- Kubernetes / Networking / Workload
- Kubernetes / Persistent Volumes
- Node Exporter / Nodes
- Node Exporter / USE Method / Cluster
- Node Exporter / USE Method / Node
- Prometheus / Overview
- CoreDNS
- Grafana Overview

---

## Configuration

### Resource Limits

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Prometheus | 100m | 500m | 256Mi | 512Mi |
| Grafana | 50m | 200m | 128Mi | 256Mi |
| node-exporter | 10m | 100m | 24Mi | 64Mi |
| kube-state-metrics | 10m | 100m | 32Mi | 128Mi |
| Prometheus Operator | 50m | 200m | 64Mi | 128Mi |

### Prometheus Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| Retention | 7 days | Metrics history |
| Retention Size | 2GB | Max storage |
| Scrape Interval | 60s | Reduced for lower CPU |
| Storage | 5Gi | PVC size |

---

## Operations

### Check Status

```bash
# All monitoring pods
kubectl get pods -n monitoring

# HelmRelease status
flux get helmrelease -n monitoring

# Prometheus targets (port-forward)
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Then visit http://localhost:9090/targets

# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f
```

### Force Sync

```bash
flux reconcile helmrelease kube-prometheus-stack -n monitoring
```

### Restart Components

```bash
# Restart Grafana
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring

# Restart Prometheus (StatefulSet)
kubectl rollout restart statefulset/prometheus-prometheus-prometheus -n monitoring
```

### Check Storage

```bash
# PVC status
kubectl get pvc -n monitoring

# Prometheus storage usage
kubectl exec -n monitoring prometheus-prometheus-prometheus-0 -- df -h /prometheus
```

---

## K3s-Specific Notes

K3s has several differences from standard Kubernetes that affect monitoring:

1. **No etcd metrics:** K3s uses SQLite backend, so etcd monitoring is disabled
2. **Bundled control plane:** Controller manager, scheduler, and proxy run as a single process
3. **Metric endpoints:** Not exposed by default; only kubelet and API server metrics available

---

## Troubleshooting

### Grafana 403 from Cloudflare

See [[Network/Cloudflare-Tunnel#Troubleshooting|Cloudflare Tunnel Troubleshooting]]

You may need to add a WAF exception rule for `grafana.marchi.app`.

### Prometheus High Memory

```bash
# Check current usage
kubectl top pod -n monitoring

# If over limits, reduce retention in monitoring.yaml
```

### Missing Metrics

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check ServiceMonitors
kubectl get servicemonitor -n monitoring
```

### HelmRelease Failed

```bash
# Check Flux logs
flux logs --kind=HelmRelease --name=kube-prometheus-stack -n monitoring

# Describe HelmRelease
kubectl describe helmrelease kube-prometheus-stack -n monitoring
```

---

## Upgrade Chart Version

1. Edit `clusters/homelab/apps/monitoring.yaml`
2. Change `version: "72.9.1"` to desired version
3. Commit and push
4. Sync: `flux reconcile kustomization apps --with-source`

---

## Add Custom Dashboard

Create a ConfigMap with the dashboard JSON:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  my-dashboard.json: |
    { "dashboard JSON here" }
```

---

## Related

- [[Homelab|Homelab Dashboard]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel]]
- [[Runbooks/Flux-Commands|Flux Commands]]

## External Links

- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)

## Tags

#homelab #monitoring #prometheus #grafana #helm #flux
