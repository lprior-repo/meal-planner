# Custom Runner Configuration

A runner is the "backend" of Dagger where containers are actually executed.

Runners are responsible for:
- Executing containers specified by functions
- Pulling container images, Git repos and other sources
- Pushing container images to registries
- Managing the cache backing function execution

## Distribution and Versioning

The runner is distributed as a container image at `registry.dagger.io/engine`.

Tags are made for each release version (e.g., `registry.dagger.io/engine:v0.12.3`).

## Execution Requirements

1. The runner container needs root capabilities, including `CAP_SYS_ADMIN` (use `--privileged` flag)
2. The runner container should be given a volume at `/var/lib/dagger`
3. Use the default entrypoint to start the runner

## Connection Interface

Set `_EXPERIMENTAL_DAGGER_RUNNER_HOST` to connect to a custom runner:

1. `container://<container name>` - Connect to runner in a host container
2. `image://<container image reference>` - Start runner in Docker using provided image
3. `kube-pod://<podname>?context=<context>&namespace=<namespace>&container=<container>` - Connect to runner in Kubernetes pod
4. `unix://<path to unix socket>` - Connect over UNIX socket
5. `tcp://<address:port>` - Connect over TCP

## GPU Support (Experimental)

GPU support works with NVIDIA GPUs and requires a custom GPU-enabled runner.

### Local host

```bash
VERSION=$(dagger version | cut -d' ' -f2)
docker rm -f dagger-engine-${VERSION} 2>/dev/null && docker run --gpus all -d --privileged -e _EXPERIMENTAL_DAGGER_GPU_SUPPORT=true --name dagger-engine-${VERSION} registry.dagger.io/engine:${VERSION}-gpu -- --debug
```

### Test GPU access

```bash
dagger -m github.com/samalba/dagger-modules/nvidia-gpu call has-gpu
```
