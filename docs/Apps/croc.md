# croc (private file-transfer relay)

Self-hosted [croc](https://github.com/schollz/croc) relay, reachable **only** over the tailnet.

Used to send files peer-to-peer between **two different Tailscale users** — something Taildrop
cannot do, since Taildrop only works within a single user's own devices.

croc contents are already end-to-end encrypted via PAKE; the relay only "staples" the two
connections together. Self-hosting means nothing touches the public croc relay and all bytes
stay inside the WireGuard tunnel.

| Item | Value |
|------|-------|
| Namespace | `croc` |
| Image | `docker.io/schollz/croc` (default entrypoint = `croc relay`) |
| Relay address | `croc.tailb1bee0.ts.net:9009` |
| Ports | `9009` comms, `9010-9013` multiplexed data |
| Exposure | Tailscale operator (own tailnet device) — **not** public, **not** on the LAN |
| Manifest | `clusters/homelab/apps/croc.yaml` |

---

## Why the tailscale operator, not hostNetwork / NodePort

croc needs **fixed, real ports** (9009-9013). Clients connect to `:9009`, and the relay hands
back one of `9010-9013` for the actual data stream — so those exact port numbers must be
reachable on the same host the client dialed.

- **NodePort won't work**: it only allocates from `30000-32767`, not `9009-9013`.
- **`hostNetwork` / `hostPort` would work but leaks**: they bind `0.0.0.0` — *every* node
  interface — so the relay would also listen on the node's LAN address (`10.10.10.x`).
  A Tailscale ACL only governs traffic arriving over the tailnet; it **cannot** stop a LAN
  peer from hitting `10.10.10.10:9009`. Closing that would need a host firewall rule pinning
  the ports to `tailscale0`, and croc has no bind-address flag to help.
- **The operator gives the Service its own tailnet device** with the real ports and **no LAN
  exposure at all**. Same pattern already used by `ai-workstation` (which exposes raw TCP/22).

> This also means **no k3s node needs to join the tailnet** — none currently do.

---

## Setup

### 1. Create the relay password Secret

The Secret is intentionally **not** in git (Flux would clobber it, and the password would be
committed). Create it once, out-of-band:

```bash
export KUBECONFIG=~/.kube/config-s740

kubectl create namespace croc --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic croc-secret \
  --namespace=croc \
  --from-literal=CROC_PASS="$(openssl rand -base64 24)"
```

Read it back (you need this exact value on both clients):

```bash
kubectl get secret croc-secret -n croc -o jsonpath='{.data.CROC_PASS}' | base64 -d; echo
```

### 2. Deploy

```bash
git add clusters/homelab/apps/croc.yaml clusters/homelab/apps/kustomization.yaml
git commit -m "deploy: croc relay"
git push
flux reconcile kustomization apps --with-source
```

### 3. Verify

```bash
kubectl get pods -n croc
kubectl get svc  -n croc
tailscale status | grep croc          # the relay should appear as a tailnet device
```

---

## Tailscale ACL

Add to your policy file. This permits **only** the two named users to reach the relay on
`9009-9013/tcp`, and nothing else.

Any human member of the tailnet may use the relay. Since the tailnet is tied to the
`delta-and-beta.com` domain, every member **is** an `@delta-and-beta.com` account — so
`autogroup:member` is exactly "anyone with a @delta-and-beta.com email", with no user list
to maintain as people join or leave.

**No `tagOwners` change is needed.** The croc proxy carries `tag:kubernetes` — the tag the
operator already assigns to all 13 of its proxies (and carries itself). Do **not** invent a new
tag such as `tag:croc-relay`: the operator's OAuth client is scoped to `tag:kubernetes`, so a
new tag fails with `tagOwners[...]: does not exist` and the proxy never registers.

Add only this rule:

```jsonc
{
  "acls": [
    {
      "action": "accept",
      "src":    ["autogroup:member"],          // all @delta-and-beta.com users
      "dst":    ["tag:kubernetes:9009-9013"],  // croc relay ports
      "proto":  "tcp",
    },
  ],
}
```

The rule is scoped by **port**, not by device: `9009-9013` is croc's range, and no other
`tag:kubernetes` device listens on it — so in practice this grants the croc relay and nothing
else.

> If you later want device-level precision, add a host alias once the relay is up:
> `"hosts": {"croc": "<croc 100.x IP>"}` and target `"dst": ["croc:9009-9013"]`.

Why `autogroup:member` and not `*`:

| Identity | `autogroup:member` | `*` |
|----------|--------------------|-----|
| `@delta-and-beta.com` users (incl. future ones) | ✅ allowed | ✅ allowed |
| Tagged devices (the 18 k8s proxy pods, `ai-connector`, …) | ❌ denied | ⚠️ allowed |
| Users **shared into** the tailnet from another tailnet | ❌ denied | ⚠️ allowed |

So `autogroup:member` grants the whole domain while still keeping the relay off-limits to
service/tagged devices and any externally-shared accounts.

> ⚠️ **This only *denies everyone else* if you remove the default catch-all.** The starter
> Tailscale policy ships with `{"action":"accept","src":["*"],"dst":["*:*"]}`, which would
> let anything on the tailnet reach the relay regardless of the rule above. Tailscale ACLs
> are default-deny, so once the catch-all is gone, only the rule above grants access.

---

## Client usage

Both ends must use the **same `--pass`**, or the relay rejects them. The **code phrase is
separate** — it's what pairs the sender with the receiver (croc prints it on send; use it,
or set your own with `--code`).

Set the relay password once per shell:

```bash
export CROC_PASS='<the value from the Secret>'
```

**Send:**

```bash
croc --relay "croc.tailb1bee0.ts.net:9009" --pass "$CROC_PASS" send FILE
```

croc prints a code phrase, e.g. `croc 1234-mango-tulip-radio`. Give that to the receiver.

**Receive:**

```bash
croc --relay "croc.tailb1bee0.ts.net:9009" --pass "$CROC_PASS" 1234-mango-tulip-radio
```

Notes:

- `--relay` and `--pass` are **global flags** — they go *before* the `send` subcommand.
- Both users must be on the tailnet and permitted by the ACL above.
- Since `CROC_PASS` is an env var croc reads natively, you can omit `--pass` if it's exported.
- To pick your own code phrase instead of a random one: `croc ... send --code my-secret-code FILE`.

---

## Troubleshooting

| Symptom | Cause |
|---------|-------|
| `could not connect to relay` | Not on the tailnet, or ACL denies you. Check `tailscale status`. |
| Relay accepts then drops | `--pass` mismatch between the two ends, or against the relay's `CROC_PASS`. |
| Transfer stalls after pairing | Only `9009` is reachable; `9010-9013` are blocked. Confirm the ACL covers the **full range**. |
| Pod `CreateContainerConfigError` | The `croc-secret` Secret doesn't exist yet — see Setup step 1. |

```bash
kubectl logs -n croc -l app=croc
kubectl describe pod -n croc -l app=croc
```

---

## Fallback: hostNetwork variant

Only if you'd rather bind the relay to a node's own tailnet address. Requires joining a node
to the tailnet first (**none are today**):

```bash
# on the chosen k3s node
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=croc-relay
kubectl label node k3s-node-01 role=croc-relay
```

Then in the Deployment's pod spec, drop the Service exposure and use:

```yaml
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  nodeSelector:
    role: croc-relay
```

⚠️ Remember this **also opens 9009-9013 on the node's LAN IP**. Restrict them to the tailnet:

```bash
sudo iptables -A INPUT -i tailscale0 -p tcp --dport 9009:9013 -j ACCEPT
sudo iptables -A INPUT            -p tcp --dport 9009:9013 -j DROP
```

---

## Related

- [[Network/Tailscale-Operator|Tailscale Operator (Private Ingress)]]
- [[Homelab]]

## Tags

#homelab #croc #tailscale #filetransfer
