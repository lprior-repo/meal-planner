---
doc_id: ops/getting-started/installation
chunk_id: ops/getting-started/installation#chunk-4
heading_path: ["installation", "Expected output: dagger v0.19.7 (registry.dagger.io/engine:v0.19.7) darwin/amd64"]
chunk_type: code
tokens: 47
summary: "```



The quickest way of installing the latest stable release of `dagger` on Linux is to use [i..."
---
```

### Linux

The quickest way of installing the latest stable release of `dagger` on Linux is to use [install.sh](https://github.com/dagger/dagger/blob/main/install.sh):

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
```

This installs `dagger` in `$HOME/.local/bin`:

```bash
type dagger
