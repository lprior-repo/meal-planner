---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-10
heading_path: ["Security and process isolation", "NSJAIL sandboxing (ee only)"]
chunk_type: prose
tokens: 375
summary: "NSJAIL sandboxing (ee only)"
---

## NSJAIL sandboxing (ee only)

### What is NSJAIL?

[NSJAIL](https://github.com/google/nsjail) is a process isolation tool from Google that provides:

- **Filesystem isolation** - Jobs can only access their job directory and explicitly mounted paths
- **Network restrictions** - Optional network isolation
- **Resource limits** - CPU, memory, and process limits
- **User namespace** - Jobs run as unprivileged users even when worker runs as root

### When is NSJAIL used?

NSJAIL is **disabled by default** because:

- The default Windmill images do not include the nsjail binary
- It requires using a special `-nsjail` tagged image

### Enabling NSJAIL

NSJAIL sandboxing is an EE only feature. If you are on CE, use PID namespace isolation.

To use NSJAIL sandboxing, you need both:

1. **Use the nsjail image** - Switch to an image with nsjail pre-installed:

   ```yaml
   # In docker-compose.yml or your deployment config
   image: ghcr.io/windmill-labs/windmill-ee-nsjail
   ```

2. **Enable NSJAIL** - Set the environment variable:
   ```bash
   DISABLE_NSJAIL=false
   ```

**When to enable NSJAIL:**

- You need filesystem isolation beyond PID namespaces
- You want to restrict network access from jobs
- You need resource limits per job (CPU, memory)
- You're running untrusted code and need defense-in-depth

### NSJAIL configuration

NSJAIL behavior is controlled by configuration files for each language. You can view the default configurations:

- [Python configuration](https://github.com/windmill-labs/windmill/blob/main/backend/windmill-worker/nsjail/run.python3.config.proto)
- [Deno configuration](https://github.com/windmill-labs/windmill/blob/main/backend/windmill-worker/nsjail/run.deno.config.proto)
- [Bash configuration](https://github.com/windmill-labs/windmill/blob/main/backend/windmill-worker/nsjail/run.bash.config.proto)
- [All language configs](https://github.com/windmill-labs/windmill/tree/main/backend/windmill-worker/nsjail)

These configurations control resource limits, mount points, network isolation, and other security settings. The configs are embedded into the Windmill binary at compile time.

**Without NSJAIL (default):**

- Jobs have full filesystem access under the worker's user permissions
- Jobs can read any files the worker can read
- You can still enable PID namespace isolation separately for process/memory protection (see below)
