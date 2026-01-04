# RustFS S3-Compatible Storage

High-performance S3-compatible object storage built in Rust.

## Overview

| Property | Value |
|----------|-------|
| **S3 API URL** | https://s3.marchi.app |
| **Console URL** | https://s3-console.marchi.app |
| **Namespace** | rustfs |
| **Image** | rustfs/rustfs:latest |
| **Storage** | 10Gi PVC (local-path) |
| **Default Credentials** | rustfsadmin / rustfsadmin |

---

## Architecture

```
                     Cloudflare Tunnel
                           |
        +------------------+------------------+
        |                                     |
   s3.marchi.app                    s3-console.marchi.app
   (S3 API :9000)                   (Web Console :9001)
        |                                     |
        +------------------+------------------+
                           |
                    +--------------+
                    |   Service    |
                    |   ClusterIP  |
                    +--------------+
                           |
                    +--------------+
                    |  Deployment  |
                    |   rustfs     |
                    +--------------+
                           |
                    +--------------+
                    |     PVC      |
                    |    10Gi      |
                    +--------------+
```

---

## First-Time Setup

1. **Access Console**: https://s3-console.marchi.app
2. **Login** with default credentials:
   - Username: `rustfsadmin`
   - Password: `rustfsadmin`
3. **Change password immediately** after first login
4. **Create access keys** for S3 API access
5. **Create buckets** as needed

---

## S3 Client Configuration

### AWS CLI

```bash
# Configure credentials
aws configure set aws_access_key_id <YOUR_ACCESS_KEY>
aws configure set aws_secret_access_key <YOUR_SECRET_KEY>

# List buckets
aws --endpoint-url https://s3.marchi.app s3 ls

# Create bucket
aws --endpoint-url https://s3.marchi.app s3 mb s3://my-bucket

# Upload file
aws --endpoint-url https://s3.marchi.app s3 cp file.txt s3://my-bucket/

# List objects
aws --endpoint-url https://s3.marchi.app s3 ls s3://my-bucket/
```

### Environment Variables

```bash
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<YOUR_SECRET_KEY>
export AWS_ENDPOINT_URL=https://s3.marchi.app
```

### Python (boto3)

```python
import boto3

s3 = boto3.client(
    's3',
    endpoint_url='https://s3.marchi.app',
    aws_access_key_id='<YOUR_ACCESS_KEY>',
    aws_secret_access_key='<YOUR_SECRET_KEY>'
)

# List buckets
response = s3.list_buckets()
for bucket in response['Buckets']:
    print(bucket['Name'])
```

---

## Manifest

Location: `clusters/homelab/apps/rustfs.yaml`

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: rustfs
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rustfs-data
  namespace: rustfs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rustfs
  namespace: rustfs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rustfs
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: rustfs
    spec:
      securityContext:
        fsGroup: 10001
      containers:
        - name: rustfs
          image: rustfs/rustfs:latest
          ports:
            - name: api
              containerPort: 9000
            - name: console
              containerPort: 9001
          volumeMounts:
            - name: rustfs-data
              mountPath: /data
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "1Gi"
              cpu: "500m"
      volumes:
        - name: rustfs-data
          persistentVolumeClaim:
            claimName: rustfs-data
---
apiVersion: v1
kind: Service
metadata:
  name: rustfs
  namespace: rustfs
spec:
  type: ClusterIP
  ports:
    - name: api
      port: 9000
      targetPort: 9000
    - name: console
      port: 9001
      targetPort: 9001
  selector:
    app: rustfs
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rustfs-api
  namespace: rustfs
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: s3.marchi.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rustfs
                port:
                  number: 9000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rustfs-console
  namespace: rustfs
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: s3-console.marchi.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rustfs
                port:
                  number: 9001
```

---

## Operations

### Check Status

```bash
# Pod status
kubectl get pods -n rustfs

# Logs
kubectl logs -n rustfs -l app=rustfs -f

# Describe
kubectl describe pod -n rustfs -l app=rustfs
```

### Restart

```bash
kubectl rollout restart deployment/rustfs -n rustfs
```

### Backup Data

```bash
# Get PVC info
kubectl get pvc -n rustfs

# Backup via SSH (data stored on node)
ssh ubuntu@10.10.10.10 "sudo tar -czf /tmp/rustfs-backup.tar.gz /var/lib/rancher/k3s/storage/pvc-*-rustfs-data"
scp ubuntu@10.10.10.10:/tmp/rustfs-backup.tar.gz ./
```

---

## Troubleshooting

### 403 Forbidden

If Cloudflare blocks access, create WAF bypass rules for:
- `s3.marchi.app`
- `s3-console.marchi.app`

See [[Network/Cloudflare-Tunnel#Troubleshooting|Cloudflare Tunnel Troubleshooting]]

### Permission Denied on Volume

The deployment uses `fsGroup: 10001` to match RustFS's internal user. If you see permission errors:

```bash
# Check pod security context
kubectl get pod -n rustfs -o yaml | grep -A5 securityContext
```

### S3 API Connection Issues

```bash
# Test endpoint
curl -I https://s3.marchi.app/minio/health/ready

# Check logs for errors
kubectl logs -n rustfs -l app=rustfs --tail=50
```

---

## Security Notes

1. **Change default credentials** immediately after deployment
2. **Create separate access keys** for different applications
3. Consider adding **Cloudflare Access** to protect the console
4. Bucket policies can restrict access per-bucket

---

## Related

- [[Homelab|Homelab Dashboard]]
- [[Network/Cloudflare-Tunnel|Cloudflare Tunnel]]
- [[Apps/n8n|n8n App]]

## External Links

- [RustFS GitHub](https://github.com/rustfs/rustfs)
- [S3 API Reference](https://docs.aws.amazon.com/s3/index.html)

## Tags

#homelab #rustfs #s3 #storage #app
