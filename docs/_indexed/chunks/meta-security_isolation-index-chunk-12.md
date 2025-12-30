---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-12
heading_path: ["Security and process isolation", "Recommended configurations"]
chunk_type: code
tokens: 76
summary: "Recommended configurations"
---

## Recommended configurations

### PID namespace isolation (recommended for production)

To enable PID namespace isolation, add to your docker-compose.yml:

```yaml
windmill_worker:
  privileged: true
  environment:
    - ENABLE_UNSHARE_PID=true
```

**Why enable this**: Protects worker credentials from being accessed by jobs through process memory and environment variables. This is a critical security feature for production deployments.

### NSJAIL sandboxing (maximum security)

```yaml
