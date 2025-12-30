---
doc_id: ops/reference/configuration-engine
chunk_id: ops/reference/configuration-engine#chunk-2
heading_path: ["configuration-engine", "Configuration"]
chunk_type: code
tokens: 47
summary: "Write your config to `~/."
---
### engine.json

Write your config to `~/.config/dagger/engine.json` (or `$XDG_CONFIG_HOME/dagger/engine.json`).

For a custom runner, mount your `engine.json` to `/etc/dagger/engine.json`:

```bash
docker run --rm \
    -v /var/lib/dagger \
    -v $HOME/.config/dagger/engine.json:/etc/dagger/engine.json \
    --name dagger-engine-custom \
    --privileged \
    registry.dagger.io/engine:v0.19.7
```
