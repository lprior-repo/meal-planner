---
doc_id: ops/reference/container-runtimes-nerdctl
chunk_id: ops/reference/container-runtimes-nerdctl#chunk-3
heading_path: ["container-runtimes-nerdctl", "Example"]
chunk_type: code
tokens: 51
summary: "```bash
$ nerdctl ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ nerdctl..."
---
```bash
$ nerdctl ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ nerdctl core version
v0.18.19

$ nerdctl ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```
