---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-15
heading_path: ["Workers and worker groups", "Process isolation and security"]
chunk_type: prose
tokens: 252
summary: "Process isolation and security"
---

## Process isolation and security

Windmill workers provide multiple layers of process isolation to protect your infrastructure from potentially malicious or buggy code execution.

### Isolation mechanisms

Windmill supports two primary isolation mechanisms that can be used independently or together:

1. **PID namespace isolation** (enabled by default in docker-compose) - Protects process memory and environment variables
2. **NSJAIL sandboxing** (optional, requires special image) - Provides filesystem, network, and resource isolation

### Environment variables

Configure worker isolation through these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_UNSHARE_PID` | `false` (true in docker-compose) | Enable PID namespace isolation using Linux unshare |
| `DISABLE_NSJAIL` | `true` | Enable NSJAIL sandboxing (requires `-nsjail` image, set to `false` to enable) |
| `UNSHARE_ISOLATION_FLAGS` | `--user --map-root-user --pid --fork --mount-proc` | Customize unshare isolation flags |

### Default configuration

The official docker-compose enables PID namespace isolation by default:

```yaml
windmill_worker:
  environment:
    - DATABASE_URL=${DATABASE_URL}
    - MODE=worker
    - WORKER_GROUP=default
    - ENABLE_UNSHARE_PID=true # Enabled by default
```

PID namespace isolation prevents jobs from accessing parent process memory and environment variables, protecting sensitive credentials like `DATABASE_URL`.

For complete documentation on security isolation, see the [Security and Process Isolation](/docs/advanced/security_isolation) guide.
