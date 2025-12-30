---
doc_id: ops/getting-started/installation
chunk_id: ops/getting-started/installation#chunk-3
heading_path: ["installation", "dagger is /usr/local/bin/dagger"]
chunk_type: code
tokens: 110
summary: "```

If you do not have Homebrew installed, you can use [install."
---
```

If you do not have Homebrew installed, you can use [install.sh](https://github.com/dagger/dagger/blob/main/install.sh):

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh
```

If your user account doesn't have sufficient privileges to install in `/usr/local` and `sudo` is available, you can set `BIN_DIR` and use `sudo -E`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sudo -E sh
```

If you want to set a specific version, you can set `DAGGER_VERSION`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.19.7 BIN_DIR=/usr/local/bin sh
```

To see the installed version of dagger:

```bash
./bin/dagger version
