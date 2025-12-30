---
doc_id: ref/reference/configuration-custom-ca
chunk_id: ref/reference/configuration-custom-ca#chunk-2
heading_path: ["configuration-custom-ca", "Configuration"]
chunk_type: mixed
tokens: 84
summary: "Write certificates to:
- `~/."
---
### Method 1: Automatic provisioned engine

Write certificates to:
- `~/.config/dagger/ca-certificates` on Linux
- `~/Library/Application Support/dagger/ca-certificates` on macOS
- `$XDG_CONFIG_HOME/dagger/ca-certificates` if set

### Method 2: Custom runner

Place custom CAs in the `/usr/local/share/ca-certificates/` directory of the Dagger container:

```bash
docker run --rm \
    -v /var/lib/dagger \
    -v $PWD/ca-certificates:/usr/local/share/ca-certificates/ \
    --name dagger-engine-custom \
    --privileged \
    registry.dagger.io/engine:v0.19.7
```

The CAs will be automatically installed on Dagger startup.
