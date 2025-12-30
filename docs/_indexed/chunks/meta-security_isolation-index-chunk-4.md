---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-4
heading_path: ["Security and process isolation", "PID namespace isolation"]
chunk_type: code
tokens: 486
summary: "PID namespace isolation"
---

## PID namespace isolation

### What is PID namespace isolation?

PID (Process ID) namespace isolation creates a separate process namespace for each job using Linux's `unshare` command. This prevents jobs from:

- Seeing parent worker processes in `ps` output
- Reading parent process memory via `/proc/$pid/mem`
- Accessing parent environment variables via `/proc/$pid/environ`
- Accessing parent file descriptors via `/proc/$pid/fd`

### Why PID isolation matters

With PID isolation, the job runs in its own namespace and cannot see the parent worker process, preventing access to the worker's memory and environment variables.

### Enabling PID namespace isolation

To enable PID namespace isolation, you need to:

1. **Set the environment variable** on your worker:

   ```bash
   ENABLE_UNSHARE_PID=true
   ```

2. **Enable privileged mode** in docker-compose.yml (required for the default `--mount-proc` flag):
   ```yaml
   windmill_worker:
     privileged: true
   ```

**Important**: PID isolation is **disabled by default** in the main docker-compose.yml (both settings are commented out). You must manually uncomment these settings to enable it.

#### Step-by-step enablement

In your `docker-compose.yml`, find the worker service and uncomment these lines:

```yaml
windmill_worker:
  image: ${WM_IMAGE}
  # ... other settings ...

  # Uncomment these two lines:
  # privileged: true              # <- Uncomment this
  environment:
    - DATABASE_URL=${DATABASE_URL}
    - MODE=worker
    - WORKER_GROUP=default
    # - ENABLE_UNSHARE_PID=true    # <- Uncomment this
```

After uncommenting:

```yaml
windmill_worker:
  image: ${WM_IMAGE}
  privileged: true # Now enabled
  environment:
    - DATABASE_URL=${DATABASE_URL}
    - MODE=worker
    - WORKER_GROUP=default
    - ENABLE_UNSHARE_PID=true # Now enabled
```

### Requirements

- **Linux only** - Not supported on Windows or macOS
- **util-linux package** - Provides the `unshare` command (usually pre-installed)
- **Privileged mode** - Required in Docker for the default `--mount-proc` flag
- **User namespaces** - Must be enabled in kernel (check with `sysctl kernel.unprivileged_userns_clone` on Debian/Ubuntu)

### Configuration

#### Default isolation flags

By default, PID isolation uses these flags:

```bash
UNSHARE_ISOLATION_FLAGS="--user --map-root-user --pid --fork --mount-proc"
```

**Important**: While `--user --map-root-user` enables unprivileged user namespaces, the `--mount-proc` flag **requires `privileged: true` in Docker**. This is necessary to provide an isolated /proc filesystem.

What each flag does:

- `--user --map-root-user` - Creates user namespace and maps current user to root inside it
- `--pid --fork` - Creates isolated PID namespace
- `--mount-proc` - Mounts isolated /proc filesystem (requires privileged mode in Docker)

#### Custom flags

You can customize the isolation flags:

```bash
