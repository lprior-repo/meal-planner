---
doc_id: ops/getting-started/installation
chunk_id: ops/getting-started/installation#chunk-7
heading_path: ["installation", "Development release"]
chunk_type: mixed
tokens: 162
summary: "> **Warning:** Development releases should be considered unfinished."
---
> **Warning:** Development releases should be considered unfinished.

### macOS/Linux

To install the latest development release, use the following command:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_COMMIT=head sh
```

This will install the development release of the Dagger CLI in `./bin/dagger`.

### Windows

To install the latest development release, use the following command in PowerShell 7.0:

```powershell
iwr -useb https://dl.dagger.io/dagger/install.ps1 | iex; Install-Dagger -DaggerCommit head
```

This will install the development release of the Dagger CLI in the `<your home folder>\dagger` directory.

> **Warning:** Running this CLI against the stable Dagger Engine will, by default, stop and remove the stable version and install a development version of the Dagger Engine instead. You may prefer to install it in an isolated environment so as to avoid conflicts.
