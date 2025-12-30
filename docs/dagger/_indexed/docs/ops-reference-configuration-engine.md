---
id: ops/reference/configuration-engine
title: "Engine Configuration"
category: ops
tags: ["debug", "config", "ops", "docker"]
---

# Engine Configuration

> **Context**: Dagger is designed to run out-of-the-box with sensible defaults, but configuration can be modified using `engine.json` or `engine.toml` files.


Dagger is designed to run out-of-the-box with sensible defaults, but configuration can be modified using `engine.json` or `engine.toml` files.

## Configuration

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

## Logging

Supported levels (quietest to noisiest): `error`, `warn`, `info`, `debug`, `debugextra`, `trace`

```json
{
  "logLevel": "debug"
}
```

## Security

Disable `insecureRootCapabilities`:

```json
{
  "security": {
    "insecureRootCapabilities": false
  }
}
```

## Garbage Collection

Disable the garbage collector:

```json
{
  "gc": {
    "enabled": false
  }
}
```

Adjust parameters:

```json
{
  "gc": {
    "maxUsedSpace": "200GB",
    "reservedSpace": "10GB",
    "minFreeSpace": "20%",
    "sweepSize": "50%"
  }
}
```

## Custom Registries

Mirror Docker Hub to `mirror.gcr.io`:

```json
{
  "registries": {
    "docker.io": {
      "mirrors": ["mirror.gcr.io"]
    }
  }
}
```

## See Also

- [Documentation Overview](./COMPASS.md)
