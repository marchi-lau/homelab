---
id: "0003"
title: "Pin the master to 10.10.10.10 so a reboot can't flip its IP"
status: draft
created: 2026-07-16
updated: 2026-07-16
links: ["[[incidents/0001]]", "[[architectures/0002]]"]
---
## When to use
Harden against [[incidents/0001]] (master booted on a random `10.10.10.39` and broke the
cluster). **Not yet applied** — this is the durable fix that closes that outage class.

## Prerequisites
SSH to the master (`ssh ubuntu@10.10.10.10`, default user `ubuntu` per `~/.ssh/config`),
admin access to the UniFi controller, and the master's MAC `4c:52:62:1f:9e:49`.

## Steps
1. **Diagnose the multiple-IP situation first:**
   ```
   ssh ubuntu@10.10.10.10 'ip -4 addr show; sudo cat /etc/netplan/*.yaml; \
     sudo systemctl cat k3s | grep -iE "ExecStart|node-ip|tls-san"'
   ```
   This shows whether the extra IP comes from netplan (static/dup) or DHCP, and whether k3s
   pins `--node-ip`.
2. **Netplan:** set a single static `10.10.10.10/24`, gateway `10.10.10.1`; remove any
   DHCP/extra address on the interface. `sudo netplan apply` (do it via KVM console if you
   risk locking yourself out).
3. **UniFi:** confirm/repair the DHCP reservation MAC `4c:52:62:1f:9e:49 → 10.10.10.10`
   (the pool is `10.10.10.100-199`, so `.10` must be a reservation/static, not a lease).
4. **Pin k3s:** add `--node-ip 10.10.10.10` (and a `--tls-san <name>`) to the k3s server
   args so it never guesses the node-IP from a multi-IP interface. Restart k3s.
5. Reboot and confirm the address holds.

## Verification
```
kubectl get node k3s-master -o wide     # INTERNAL-IP = 10.10.10.10 after a reboot
```

## Notes / gotchas
- The whole cluster hard-codes `10.10.10.10` (kubeconfig, node-01 agent, cert SANs); a
  `--tls-san` name is what would let a future IP change *not* reject credentials.
- Editing netplan over SSH risks lockout — prefer the KVM console for step 2.
