---
doc_id: ops/reference/container-runtimes-nerdctl
chunk_id: ops/reference/container-runtimes-nerdctl#chunk-2
heading_path: ["container-runtimes-nerdctl", "Prerequisites"]
chunk_type: mixed
tokens: 73
summary: "Ensure that `nerdctl` (or `finch`) is installed and running on your system:

```bash
nerdctl info..."
---
Ensure that `nerdctl` (or `finch`) is installed and running on your system:

```bash
nerdctl info
```

> **Warning**: To use the `nerdctl` backend as unprivileged user, `nerdctl` must be installed in [rootless mode](https://github.com/containerd/nerdctl/blob/main/docs/rootless.md).

### Using `lima`

To use `nerdctl` with Dagger via `lima`, create the following shell script at `/usr/local/bin/nerdctl`:

```bash
#!/bin/sh
lima nerdctl "$@"
```
