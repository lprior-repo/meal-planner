---
doc_id: ops/reference/container-runtimes-docker
chunk_id: ops/reference/container-runtimes-docker#chunk-3
heading_path: ["container-runtimes-docker", "Example"]
chunk_type: code
tokens: 51
summary: "```bash
$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger c..."
---
```bash
$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger core version
v0.18.19

$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```
