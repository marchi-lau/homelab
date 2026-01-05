# Stirling PDF (s-pdf)

All-in-one PDF toolkit for merging, splitting, converting, and manipulating PDF files.

## Quick Links

- **URL**: https://s-pdf.marchi.app
- **GitHub**: https://github.com/Stirling-Tools/Stirling-PDF
- **Docker Hub**: https://hub.docker.com/r/frooodle/s-pdf
- **Docs**: https://docs.stirlingpdf.com

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `s-pdf` |
| Image | `frooodle/s-pdf:latest` |
| Port | 8080 |
| Ingress | Cloudflare Tunnel |
| Storage | None (stateless) |

---

## Features

### Page Operations
- Merge, Split, Rotate, Remove pages
- Rearrange, Extract pages
- Multi-page layout, Scale pages

### Conversion
- PDF to Image (PNG, JPEG, WebP)
- Image to PDF
- PDF to Word/PowerPoint/HTML/XML
- HTML to PDF, Markdown to PDF

### Security
- Add/Remove password protection
- Change permissions
- Add watermark
- Sanitize PDF, Redact text

### Other Tools
- Compress PDF
- OCR (text recognition)
- Add page numbers
- Repair PDF
- Detect blank pages
- Compare PDFs
- Sign PDF

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `DOCKER_ENABLE_SECURITY` | `false` | Disable login (no auth) |
| `INSTALL_BOOK_AND_ADVANCED_HTML_OPS` | `false` | Skip Calibre install |
| `SYSTEM_DEFAULTLOCALE` | `en_US` | UI language |

---

## Commands

```bash
# Check pod status
kubectl get pods -n s-pdf

# View logs
kubectl logs -n s-pdf -l app=s-pdf

# Restart deployment
kubectl rollout restart deployment/s-pdf -n s-pdf

# Check ingress
kubectl get ingress -n s-pdf
```

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[it-tools|IT-Tools]] - Developer toolkit
- [[string-is|string-is]] - String toolkit

## Tags

#app #tools #pdf #s-pdf #cloudflare
