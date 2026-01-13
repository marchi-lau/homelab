# Service Specification: Monitoring Stack (kube-prometheus-stack)

> Spec Number: 003
> Created: 2026-01-14
> Status: Deployed
> Manifest: clusters/homelab/apps/monitoring.yaml

## Overview

The monitoring stack provides comprehensive observability for the K3s cluster using kube-prometheus-stack Helm chart. It includes Prometheus for metrics collection, Grafana for visualization, node-exporter for host metrics, and kube-state-metrics for Kubernetes resource metrics. Optimized for K3s with disabled etcd/scheduler/controller-manager monitoring.

## Service Requirements

### SR-1: Metrics Collection
- **Need:** Collect metrics from cluster and applications
- **Solution:** Prometheus with 60s scrape interval, 7-day retention
- **Verification:** `kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus`

### SR-2: Visualization Dashboard
- **Need:** Visual dashboards for metrics analysis
- **Solution:** Grafana with pre-configured Kubernetes dashboards
- **Verification:** `curl -s https://grafana.marchi.app`

### SR-3: Node Metrics
- **Need:** Host-level metrics (CPU, memory, disk, network)
- **Solution:** node-exporter DaemonSet on all nodes
- **Verification:** `kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter`

## Deployment Configuration

| Property | Value |
|----------|-------|
| Namespace | `monitoring` |
| Type | HelmRelease |
| Chart | kube-prometheus-stack v72.9.1 |
| Replicas | 1 (per component) |

### Resources (Prometheus)

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 256Mi | 512Mi |
| CPU | 100m | 500m |

### Resources (Grafana)

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 128Mi | 256Mi |
| CPU | 50m | 200m |

### Resources (Operator)

| Resource | Request | Limit |
|----------|---------|-------|
| Memory | 64Mi | 128Mi |
| CPU | 50m | 200m |

### Health Probes

| Probe | Type | Port | Path | Initial Delay |
|-------|------|------|------|---------------|
| Built-in | HTTP | Various | Various | Chart defaults |

## Networking

| Property | Value |
|----------|-------|
| Service Type | ClusterIP |
| Grafana Port | 80 |
| Prometheus Port | 9090 |
| Ingress Class | cloudflare-tunnel |
| Public URL | https://grafana.marchi.app |

## Storage

| Component | Storage Class | Size |
|-----------|---------------|------|
| Prometheus | local-path | 5Gi |
| Grafana | local-path | 1Gi |

## Configuration

### Helm Values Summary

| Setting | Value | Purpose |
|---------|-------|---------|
| fullnameOverride | prometheus | Simplify resource names |
| retention | 7d | Metrics retention period |
| retentionSize | 2GB | Max storage size |
| scrapeInterval | 60s | Metrics collection frequency |
| alertmanager.enabled | false | Save resources |
| kubeEtcd.enabled | false | K3s uses SQLite |
| kubeScheduler.enabled | false | K3s bundles control plane |
| kubeControllerManager.enabled | false | K3s bundles control plane |
| kubeProxy.enabled | false | K3s uses different proxy |

### Grafana Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| adminUser | admin | Default username |
| adminPassword | admin | Default password (change!) |
| timezone | Asia/Hong_Kong | Dashboard timezone |

### Secrets

| Secret | Keys | Purpose |
|--------|------|---------|
| N/A | N/A | Credentials in Helm values |

## Dependencies

### Requires
- Flux HelmRepository (prometheus-community)
- local-path storage class
- Cloudflare Tunnel operator

### Required By
- Homepage dashboard (displays monitoring links)

## Operations

### Status Check
```bash
kubectl get pods -n monitoring
kubectl get helmrelease -n monitoring
flux get helmrelease -n monitoring kube-prometheus-stack
```

### Restart
```bash
kubectl rollout restart deployment -n monitoring -l app.kubernetes.io/name=grafana
```

### Update Chart Version
1. Edit `clusters/homelab/apps/monitoring.yaml`
2. Change `spec.chart.spec.version`
3. Commit and push
4. Flux auto-syncs: `flux reconcile helmrelease kube-prometheus-stack -n monitoring`

## Troubleshooting

### Grafana shows no data
- **Symptom:** Dashboards display "No data"
- **Cause:** Prometheus not scraping targets
- **Fix:** Check Prometheus targets at /targets endpoint

### High memory usage
- **Symptom:** Prometheus OOM killed
- **Cause:** Too many metrics or too long retention
- **Fix:** Reduce retentionSize or add resource limits

## Related

- Docs: [[docs/Apps/Monitoring.md]]
- External: https://prometheus.io/docs/

## Tags

#homelab #k8s #monitoring #prometheus #grafana #helm
