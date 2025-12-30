---
doc_id: tutorial/reference/configuration-custom-runner
chunk_id: tutorial/reference/configuration-custom-runner#chunk-4
heading_path: ["configuration-custom-runner", "Connection Interface"]
chunk_type: prose
tokens: 73
summary: "Set `_EXPERIMENTAL_DAGGER_RUNNER_HOST` to connect to a custom runner:

1."
---
Set `_EXPERIMENTAL_DAGGER_RUNNER_HOST` to connect to a custom runner:

1. `container://<container name>` - Connect to runner in a host container
2. `image://<container image reference>` - Start runner in Docker using provided image
3. `kube-pod://<podname>?context=<context>&namespace=<namespace>&container=<container>` - Connect to runner in Kubernetes pod
4. `unix://<path to unix socket>` - Connect over UNIX socket
5. `tcp://<address:port>` - Connect over TCP
