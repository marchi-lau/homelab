# Homepage

A highly customizable homepage/dashboard with service integrations.

## Quick Links

- **URL**: https://homepage.marchi.app
- **GitHub**: https://github.com/gethomepage/homepage
- **Docs**: https://gethomepage.dev

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `homepage` |
| Image | `ghcr.io/gethomepage/homepage:latest` |
| Port | 3000 |
| Ingress | Cloudflare Tunnel |
| Storage | ConfigMap + emptyDir |

---

## Pre-configured Services

### Automation
- **n8n** - Workflow Automation
- **Uptime Kuma** - Status Monitoring

### Monitoring
- **Grafana** - Metrics Dashboard
- **Prometheus** - Metrics Collection

### Tools
- **IT-Tools** - Developer Utilities
- **Stirling PDF** - PDF Toolkit
- **string-is** - String Toolkit
- **AI Draw.io** - AI Diagram Editor

### Storage
- **RustFS Console** - S3 Storage Console
- **RustFS API** - S3 API Endpoint

---

## Configuration

Configuration is managed via ConfigMap. To update:

1. Edit `clusters/homelab/apps/homepage.yaml`
2. Modify the ConfigMap data sections:
   - `settings.yaml` - Theme, layout
   - `services.yaml` - Service links
   - `bookmarks.yaml` - Quick bookmarks
   - `widgets.yaml` - Dashboard widgets

3. Commit and push
4. Flux will sync automatically

---

## Architecture Notes

Homepage requires a writable `/app/config/logs` directory. Since ConfigMaps are read-only, the deployment uses:

1. **initContainer** - Copies ConfigMap files to an emptyDir and creates the logs directory
2. **emptyDir volume** - Provides writable storage for the main container

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "25m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n homepage

# View logs
kubectl logs -n homepage -l app=homepage

# Restart (to reload config)
kubectl rollout restart deployment/homepage -n homepage

# View current config
kubectl get configmap homepage-config -n homepage -o yaml
```

---

## Adding New Services

Edit the `services.yaml` section in the ConfigMap:

```yaml
- GroupName:
    - ServiceName:
        icon: icon-name.png
        href: https://service.marchi.app
        description: Service description
```

Icons available at: https://github.com/walkxcode/dashboard-icons

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[uptime-kuma|Uptime Kuma]] - Status monitoring

## Tags

#app #dashboard #homepage #cloudflare
