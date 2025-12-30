---
doc_id: ops/general/install
chunk_id: ops/general/install#chunk-2
heading_path: ["Install moon", "Installing"]
chunk_type: code
tokens: 347
summary: "Installing"
---

## Installing

The entirety of moon is packaged and shipped as a single binary. It works on all major operating systems, and does not require any external dependencies. For convenience, we provide the following scripts to download and install moon.

### proto

moon can be installed and managed in [proto's toolchain](/proto). This will install moon to `~/.proto/tools/moon` and make the binary available at `~/.proto/bin`.

```
proto install moon
```

Furthermore, the version of moon can be pinned on a per-project basis using the `.prototools` config file.

.prototools

```
moon = "1.31.0"
```

> We suggest using proto to manage moon (and other tools), as it allows for multiple versions to be installed and used. The other installation options only allow for a single version (typically the last installed).

### Linux, macOS, WSL

In a terminal that supports Bash, run:

```
bash <(curl -fsSL https://moonrepo.dev/install/moon.sh)
```

This will install moon to `~/.moon/bin`. You'll then need to set `PATH` manually in your shell profile.

```
export PATH="$HOME/.moon/bin:$PATH"
```

### Windows

In Powershell or Windows Terminal, run:

```
irm https://moonrepo.dev/install/moon.ps1 | iex
```

This will install moon to `~\.moon\bin` and prepend to the `PATH` environment variable for the current session. To persist across sessions, update `PATH` manually in your system environment variables.

> If you are using Git Bash on Windows, you can run the Unix commands above.

### npm

moon is also packaged and shipped as a single binary through the [`@moonrepo/cli`](https://www.npmjs.com/package/@moonrepo/cli) npm package. Begin by installing this package at the root of the repository.

**Yarn:**
```
yarn add --dev @moonrepo/cli
```

**Yarn (classic):**
```
yarn add --dev @moonrepo/cli
