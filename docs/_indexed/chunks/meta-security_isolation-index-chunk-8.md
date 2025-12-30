---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-8
heading_path: ["Security and process isolation", "Alternative: Skip user namespace (requires privileged mode)"]
chunk_type: code
tokens: 334
summary: "Alternative: Skip user namespace (requires privileged mode)"
---

## Alternative: Skip user namespace (requires privileged mode)
UNSHARE_ISOLATION_FLAGS="--pid --fork --mount-proc"
```

**Recommendation**: Use the default flags with `privileged: true` for best security. Only use truly unprivileged mode if you cannot enable privileged mode and understand the security tradeoffs.

### Failure behavior

If `ENABLE_UNSHARE_PID=true` but unshare is unavailable or fails, **the worker will panic at startup** with a detailed error message:

```
ENABLE_UNSHARE_PID is set but unshare test failed.
Error: unshare: Operation not permitted
Flags: --user --map-root-user --pid --fork --mount-proc

Solutions:
• Check if user namespaces are enabled: 'sysctl kernel.unprivileged_userns_clone'
• For Docker: Requires 'privileged: true' in docker-compose for --mount-proc flag
• For Kubernetes/Helm: Requires 'privileged: true' in securityContext for --mount-proc flag
• Try different flags via UNSHARE_ISOLATION_FLAGS env var (remove --mount-proc for unprivileged)
• Alternative: Use NSJAIL instead
• Disable: Set ENABLE_UNSHARE_PID=false
```

**Note**: This fail-fast behavior only occurs when `ENABLE_UNSHARE_PID=true`. If unset or false (the default), the worker starts normally without isolation.

### Platform support

| Platform                 | Supported | Notes                                               |
| ------------------------ | --------- | --------------------------------------------------- |
| Linux (docker-compose)   | ✅ Yes    | Requires manual configuration (disabled by default) |
| Linux (bare metal)       | ✅ Yes    | Requires util-linux package                         |
| Docker Desktop (Linux)   | ✅ Yes    | Works in Linux containers with privileged mode      |
| Docker Desktop (Windows) | ⚠️ No     | Use agent workers without direct DB access          |
| Docker Desktop (macOS)   | ⚠️ No     | Set `ENABLE_UNSHARE_PID=false` for macOS workers    |
| Kubernetes / Helm        | ✅ Yes    | Requires privileged: true in securityContext        |
