# IT-Tools

Collection of handy online tools for developers, with great UX.

## Quick Links

- **URL**: https://it-tools.marchi.app
- **GitHub**: https://github.com/CorentinTh/it-tools
- **Docker Hub**: https://hub.docker.com/r/corentinth/it-tools

---

## Deployment Info

| Property | Value |
|----------|-------|
| Namespace | `it-tools` |
| Image | `corentinth/it-tools:latest` |
| Port | 80 |
| Ingress | Cloudflare Tunnel |
| Storage | None (stateless) |

---

## Features

### Crypto
- Token generator, Hash text, Bcrypt, UUIDs, ULID, Encrypt/Decrypt text

### Converter
- Date-time, Integer base, Color, Case, JSON ↔ YAML/TOML/CSV

### Web
- URL encode/decode, URL parser, Device info, Basic auth generator, Open Graph meta generator

### Images & Videos
- QR Code generator/reader, SVG placeholder, Camera recorder

### Development
- Git cheatsheet, Random port generator, Crontab generator, JSON prettify, SQL prettify, Docker run to compose

### Network
- IPv4/IPv6 info, MAC address lookup, IPv4 subnet calculator

### Math
- Math evaluator, ETA calculator, Percentage calculator

### Measurement
- Chronometer, Temperature converter

### Text
- Lorem ipsum generator, Text statistics, Markdown cheatsheet

### Data
- Phone parser, IBAN validator, Credit card validator

---

## Resource Limits

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

---

## Commands

```bash
# Check pod status
kubectl get pods -n it-tools

# View logs
kubectl logs -n it-tools -l app=it-tools

# Restart deployment
kubectl rollout restart deployment/it-tools -n it-tools

# Check ingress
kubectl get ingress -n it-tools
```

---

## Related

- [[../Homelab|Homelab Overview]]
- [[../Network/Cloudflare-Tunnel|Cloudflare Tunnel Setup]]
- [[string-is|string-is]] - Similar string toolkit

## Tags

#app #tools #it-tools #developer #cloudflare
