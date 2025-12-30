---
doc_id: ops/reference/container-runtimes-podman
chunk_id: ops/reference/container-runtimes-podman#chunk-2
heading_path: ["container-runtimes-podman", "Prerequisites"]
chunk_type: mixed
tokens: 77
summary: "Ensure that Podman is installed and running on your system:

```bash
podman info
```

> **Warning..."
---
Ensure that Podman is installed and running on your system:

```bash
podman info
```

> **Warning**: Podman must be configured for [rootful container execution](https://docs.podman.io/en/stable/markdown/podman-machine-set.1.html#rootful).

Install Podman using the [official instructions](https://podman.io/getting-started/installation).

> **Note**: Podman Desktop on Mac and RHEL 8.x users may need to additionally execute `modprobe iptable_nat`.

To access the virtual machine used by Podman Desktop on Mac:

```bash
