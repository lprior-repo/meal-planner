---
doc_id: ops/getting-started/installation
chunk_id: ops/getting-started/installation#chunk-5
heading_path: ["installation", "Expected output: dagger is $HOME/.local/bin/dagger"]
chunk_type: code
tokens: 100
summary: "```

You may need to add it to your `$PATH` environment variable."
---
```

You may need to add it to your `$PATH` environment variable.

If you want to install globally, and `sudo` is available, you can specify an alternative install location by setting `BIN_DIR` and using `sudo -E`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sudo -E sh
```

If you want to set a specific version, you can set `DAGGER_VERSION`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.19.7 BIN_DIR=$HOME/.local/bin sh
```

To see the installed version of dagger:

```bash
./bin/dagger version
