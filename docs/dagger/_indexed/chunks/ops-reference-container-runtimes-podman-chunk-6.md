---
doc_id: ops/reference/container-runtimes-podman
chunk_id: ops/reference/container-runtimes-podman#chunk-6
heading_path: ["container-runtimes-podman", "Example"]
chunk_type: code
tokens: 51
summary: "```bash
$ podman ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger c..."
---
```bash
$ podman ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger core version
v0.18.19

$ podman ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```
