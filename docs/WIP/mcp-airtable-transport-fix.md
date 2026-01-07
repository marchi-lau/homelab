# MCP-Airtable Transport Fix - Work in Progress

**Date**: 2026-01-06
**Status**: Blocked - Claude Desktop bridge issues
**Last Updated**: 2026-01-06 17:17 PST

## Problem Summary

The mcp-airtable MCP server shows "Server disconnected" in Claude Desktop. The server is working correctly on K8s, but the bridge (supergateway/mcp-remote) fails to connect.

## Current Status

### Infrastructure ✅
- Synology worker node (k3s-node-01) added to cluster
- mcp-airtable deployed on worker node with 2Gi memory
- Server responds correctly to direct HTTP requests
- Tailscale ingress working

### Server Verification ✅
```bash
# MCP endpoint test - WORKS
curl -sk "https://mcp-airtable.tailb1bee0.ts.net/mcp" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}'

# Response:
event: message
data: {"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{},"resources":{},"prompts":{}},"serverInfo":{"name":"mcp-airtable","version":"1.0.0"}},"jsonrpc":"2.0","id":1}
```

### Claude Desktop Connection ❌
Both bridges fail with "Server disconnected":

1. **supergateway** - Original approach
```json
"mcp-airtable": {
  "command": "npx",
  "args": ["-y", "supergateway", "--streamableHttp", "https://mcp-airtable.tailb1bee0.ts.net/mcp", ...]
}
```

2. **mcp-remote** - Recommended approach
```json
"mcp-airtable": {
  "command": "npx",
  "args": ["-y", "mcp-remote", "https://mcp-airtable.tailb1bee0.ts.net/mcp", "--header", "x-airtable-api-key:${AIRTABLE_API_KEY}", ...],
  "env": { "AIRTABLE_API_KEY": "pat..." }
}
```

## Research Findings

### MCP Transport Evolution
- **SSE deprecated**: March 2025 (spec 2025-03-26)
- **Streamable HTTP**: New standard transport
- Sources:
  - https://blog.fka.dev/blog/2025-06-06-why-mcp-deprecated-sse-and-go-with-streamable-http/
  - https://modelcontextprotocol.io/specification/2025-06-18/basic/transports

### Claude Desktop Limitations
- Only supports **stdio** transport natively
- Cannot connect to HTTP servers directly via JSON config
- Requires a bridge (mcp-remote or supergateway) to convert stdio ↔ HTTP
- UI-based remote server config available for Pro/Team/Enterprise (Settings > Connectors)

### Working Examples for Comparison
- **Zeabur MCP**: Works because `zeabur-mcp` is a LOCAL npm package (stdio) that makes HTTP calls internally
- **mcp-cloudflare/mcp-weather**: Use SSE transport with `mcp-remote` - still working (backwards compatible)

## K8s Deployment Status

```yaml
# Pod: mcp-airtable-5dcfb99648-cxz9d
Node: k3s-node-01 (Synology worker)
Status: Running (1/1)
Memory: 2Gi limit, 512Mi request
CPU: 1000m limit, 100m request
Transport: streamable-http
```

### Memory Fix Applied
TypeScript build was running OOM with 1Gi. Fixed by:
- Increased memory limit to 2Gi
- Added NODE_OPTIONS="--max-old-space-size=1536"

## Files Modified

| File | Repository | Status |
|------|------------|--------|
| `src/server.ts` | delta-and-beta/mcp-airtable | Merged (PR #2) |
| `clusters/homelab/apps/mcp-airtable.yaml` | marchi-lau/homelab | Merged to main |
| `claude_desktop_config.json` | Local | Updated to use mcp-remote |
| `.mcp.json` | marchi-lau/homelab | Updated to use mcp-remote |

## Possible Solutions to Investigate

### 1. Use Local Airtable MCP Package
Instead of remote K8s server, use a local npm package:
```json
"mcp-airtable": {
  "command": "npx",
  "args": ["-y", "airtable-mcp-server"],
  "env": { "AIRTABLE_API_KEY": "pat..." }
}
```
Package: https://www.npmjs.com/package/airtable-mcp-server

### 2. Debug mcp-remote Connection
Check mcp-remote logs to see why it disconnects:
```bash
# Run mcp-remote manually to see errors
npx mcp-remote https://mcp-airtable.tailb1bee0.ts.net/mcp --header "x-airtable-api-key:pat..."
```

### 3. Check Transport Compatibility
mcp-remote may expect SSE, not Streamable HTTP. Try:
```bash
npx mcp-remote https://mcp-airtable.tailb1bee0.ts.net/mcp --transport http-only
```

### 4. Use Claude Desktop Connectors UI
For Pro/Team/Enterprise plans, add via Settings > Connectors instead of JSON config.

## Debugging Commands

```bash
# Check pod status
KUBECONFIG=~/.kube/config-s740 kubectl get pods -n mcp-airtable -o wide

# Check pod logs
KUBECONFIG=~/.kube/config-s740 kubectl logs -n mcp-airtable -l app=mcp-airtable --tail=50

# Test MCP endpoint directly
curl -sk "https://mcp-airtable.tailb1bee0.ts.net/mcp" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}'

# Test mcp-remote manually
npx -y mcp-remote https://mcp-airtable.tailb1bee0.ts.net/mcp

# Check Claude Desktop logs (macOS)
tail -f ~/Library/Logs/Claude/mcp*.log
```

## Next Steps

1. [ ] Debug why mcp-remote disconnects (check logs)
2. [ ] Try `--transport` flag with mcp-remote
3. [ ] Consider using local `airtable-mcp-server` package instead
4. [ ] Check Claude Desktop MCP logs for detailed error
5. [ ] Test with Claude Code CLI which supports HTTP directly

## Related Documents

- [[Nodes/Synology-Worker|Synology Worker Node]]
- [[Runbooks/Add-Synology-Worker|Add Worker Runbook]]
- [[Apps/mcp-cloudflare|MCP Cloudflare (working example)]]
