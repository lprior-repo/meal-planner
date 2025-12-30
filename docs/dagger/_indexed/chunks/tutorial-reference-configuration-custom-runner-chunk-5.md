---
doc_id: tutorial/reference/configuration-custom-runner
chunk_id: tutorial/reference/configuration-custom-runner#chunk-5
heading_path: ["configuration-custom-runner", "GPU Support (Experimental)"]
chunk_type: mixed
tokens: 70
summary: "GPU support works with NVIDIA GPUs and requires a custom GPU-enabled runner."
---
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
