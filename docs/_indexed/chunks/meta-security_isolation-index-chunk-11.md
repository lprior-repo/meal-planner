---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-11
heading_path: ["Security and process isolation", "Isolation comparison"]
chunk_type: prose
tokens: 228
summary: "Isolation comparison"
---

## Isolation comparison

| Feature                | NSJAIL      | PID Namespace | None       |
| ---------------------- | ----------- | ------------- | ---------- |
| Filesystem isolation   | ✅ Full     | ❌ No         | ❌ No      |
| Network isolation      | ⚠️ Optional | ❌ No         | ❌ No      |
| Memory protection      | ✅ Yes      | ✅ Yes        | ❌ No      |
| Process visibility     | ✅ Hidden   | ✅ Hidden     | ❌ Visible |
| Environment protection | ✅ Yes      | ✅ Yes        | ❌ No      |
| Resource limits        | ✅ Yes      | ❌ No         | ❌ No      |

### Isolation hierarchy

When multiple isolation methods are available, Windmill uses them in this priority order:

1. **NSJAIL** (if nsjail binary available and `DISABLE_NSJAIL=false`) - Provides comprehensive isolation
2. **PID Namespace** (if `ENABLE_UNSHARE_PID=true` and unshare available) - Provides process isolation
3. **None** (if neither enabled or available) - No isolation

**Important**: NSJAIL and PID namespace isolation are **not used simultaneously**. If NSJAIL is available and enabled, it takes precedence and PID namespace isolation is not used.
