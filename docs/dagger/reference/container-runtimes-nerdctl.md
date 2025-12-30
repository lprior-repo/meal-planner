# Nerdctl Runtime

Dagger can be used with any OCI-compatible container runtime, including `nerdctl` and `finch`.

## Prerequisites

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

## Example

```bash
$ nerdctl ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ nerdctl core version
v0.18.19

$ nerdctl ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```

## About `nerdctl`

[`nerdctl`](https://github.com/containerd/nerdctl) is a Docker-compatible tool to manage and run containers.
