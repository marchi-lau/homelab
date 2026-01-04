# Troubleshooting

Common issues and solutions for homelab K3s cluster.

## Quick Diagnostics

```bash
export KUBECONFIG=~/.kube/config-s740

# Cluster health
kubectl get nodes
kubectl get pods -A | grep -v Running

# Recent problems
kubectl get events -A --field-selector type=Warning
```

---

## Connection Issues

### Can't ping 10.10.10.10

| Check | Solution |
|-------|----------|
| Mac on Homelab WiFi? | Connect to "Homelab" WiFi |
| S740 powered? | PoE - check switch port LED |
| Switch port on VLAN 10? | UniFi → Devices → Switch → Port → Homelab |

### Can't SSH to node

```bash
# Test connectivity
ping 10.10.10.10

# Verbose SSH
ssh -v ubuntu@10.10.10.10
```

| Error | Solution |
|-------|----------|
| Connection timeout | Network/VLAN issue |
| Connection refused | SSH not running on S740 |
| Permission denied | Wrong password or key |

### Kubectl connection refused

```bash
# Check KUBECONFIG is set
echo $KUBECONFIG
# Should show: /Users/<you>/.kube/config-s740

# If empty
export KUBECONFIG=~/.kube/config-s740
kubectl get nodes
```

### Kubectl unauthorized (401)

Kubeconfig has wrong credentials. Regenerate:

```bash
rm ~/.kube/config-s740
ssh -A ubuntu@10.10.10.10 "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config-s740
sed -i '' 's/127.0.0.1/10.10.10.10/g' ~/.kube/config-s740
chmod 600 ~/.kube/config-s740
```

---

## Node Issues

### Node NotReady

```bash
# Check on node
ssh ubuntu@10.10.10.10
sudo systemctl status k3s
sudo journalctl -u k3s -n 50
```

| Cause | Solution |
|-------|----------|
| K3s stopped | `sudo systemctl start k3s` |
| Node rebooted | Wait 2-3 min for K3s to start |
| Disk full | `df -h` then cleanup |
| Network issue | Check gateway `ping 10.10.10.1` |

### High memory usage

```bash
ssh ubuntu@10.10.10.10
free -h
ps aux --sort=-%mem | head -10
```

---

## Pod Issues

### Pod Pending

```bash
kubectl describe pod <pod> -n <namespace>
```

| Reason | Solution |
|--------|----------|
| Insufficient CPU/memory | Check node resources |
| No matching node | Check taints/tolerations |
| PVC pending | Check storage |

### Pod CrashLoopBackOff

```bash
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
```

### Pod ImagePullBackOff

```bash
kubectl describe pod <pod> -n <namespace>
```

- Check image name spelling
- Check internet connectivity from node
- Check private registry credentials

---

## K3s Issues

### K3s won't start

```bash
ssh ubuntu@10.10.10.10
sudo journalctl -u k3s -n 100

# Check port conflicts
sudo netstat -tlnp | grep 6443
```

### Reset K3s completely

⚠️ **Destructive - loses all cluster data!**

```bash
ssh ubuntu@10.10.10.10

# Uninstall
sudo /usr/local/bin/k3s-uninstall.sh

# Reinstall
curl -sfL https://get.k3s.io | sudo sh -s - server --disable=traefik --write-kubeconfig-mode=644
```

Then regenerate kubeconfig on Mac.

---

## SSH Sudo Issues

### "sudo: a terminal is required"

SSH agent forwarding not working:

```bash
# Check agent has key
ssh-add -l

# If empty, add key
ssh-add ~/.ssh/id_rsa

# Use -A flag
ssh -A ubuntu@10.10.10.10 "sudo ..."
```

If PAM not configured, see [[Nodes/S740-Master#Phase 5 SSH Agent Sudo (Secure)|SSH Agent Sudo setup]].

---

## Related

- [[Nodes/S740-Master|S740 Master]]
- [[Runbooks/Quick-Commands|Quick Commands]]

## Tags

#homelab #troubleshooting #runbook
