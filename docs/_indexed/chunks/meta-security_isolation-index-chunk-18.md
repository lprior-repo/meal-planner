---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-18
heading_path: ["Security and process isolation", "Make permanent (add to /etc/sysctl.conf)"]
chunk_type: code
tokens: 239
summary: "Make permanent (add to /etc/sysctl.conf)"
---

## Make permanent (add to /etc/sysctl.conf)
echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.conf
```

### Docker container: "unshare: unshare failed: Operation not permitted"

**Cause**: The `--mount-proc` flag requires privileged mode in Docker.

**Solution**: Enable privileged mode in docker-compose.yml:

```yaml
windmill_worker:
  privileged: true
  environment:
    - ENABLE_UNSHARE_PID=true
```

**Alternative**: If you cannot use privileged mode, remove `--mount-proc` from the flags (less secure):

```yaml
windmill_worker:
  environment:
    - ENABLE_UNSHARE_PID=true
    - UNSHARE_ISOLATION_FLAGS=--user --map-root-user --pid --fork
```

Note: Without `--mount-proc`, jobs may still be able to see host processes in /proc.

### Kubernetes/Helm: unshare fails

**Cause**: The `--mount-proc` flag requires privileged mode.

**Solution**: Enable privileged mode in pod spec:

```yaml
securityContext:
  privileged: true
```

And set the environment variable:

```yaml
env:
  - name: ENABLE_UNSHARE_PID
    value: 'true'
```

For Helm deployments, set the appropriate values to enable privileged mode and the environment variable.

### Windows workers fail to start

**Cause**: PID isolation is Linux-only.

**Solution**: Set `ENABLE_UNSHARE_PID=false` for Windows workers.

### Jobs fail with "Cannot allocate memory"

**Cause**: Insufficient resources for isolation overhead.

**Solution**:

- Increase worker memory limits
- Reduce number of concurrent jobs
- Use `DISABLE_NSJAIL=true` and rely on PID isolation only
