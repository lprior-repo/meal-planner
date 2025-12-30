---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-3
heading_path: ["Security and process isolation", "Why isolation matters"]
chunk_type: prose
tokens: 153
summary: "Why isolation matters"
---

## Why isolation matters

Without proper isolation, user scripts could:

- Access parent worker process memory to extract credentials and secrets
- Read environment variables from parent processes
- Interfere with other jobs running on the same worker
- Access files outside their job directory
- Make unrestricted network connections
- Consume unlimited system resources

:::warning Important Security Notice

**Job isolation is disabled by default** in Windmill. Both NSJAIL and PID namespace isolation must be manually configured. Without isolation, scripts can access sensitive data from the worker process memory and environment variables.

**For production deployments, you should enable at least one isolation method** (PID namespace or NSJAIL) to protect your infrastructure. See the [Recommended Configurations](#recommended-configurations) section below.

:::
