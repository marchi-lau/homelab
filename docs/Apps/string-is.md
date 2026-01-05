# string-is

Open-source, privacy-friendly online string toolkit for developers.

## Quick Links

- **URL**: https://string-is.marchi.app
- **GitHub**: https://github.com/recurser/string-is
- **Docker Hub**: https://hub.docker.com/r/daveperrett/string-is

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `string-is` |
| Image | `daveperrett/string-is:latest` |
| Port | 3000 |
| Ingress | Cloudflare Tunnel |
| Storage | None (stateless) |

---

## Features

- Base64 encode/decode
- URL encode/decode
- Hash generation (MD5, SHA1, SHA256, etc.)
- JSON formatting/validation
- JWT decode
- UUID generation
- Regex testing
- And many more string utilities

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n string-is

# View logs
kubectl logs -n string-is -l app=string-is

# Restart deployment
kubectl rollout restart deployment/string-is -n string-is

# Check ingress
kubectl get ingress -n string-is
```

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]

## Tags

#app #tools #string-is #cloudflare
