---
id: tutorial/reference/troubleshooting
title: "Troubleshooting"
category: tutorial
tags: ["tutorial", "docker", "module", "ai", "container"]
---

# Troubleshooting

> **Context**: Common problems and their solutions when using Dagger.


Common problems and their solutions when using Dagger.

## Dagger is unresponsive with a BuildKit error

A Dagger Function may hang or become unresponsive, eventually generating a BuildKit error such as `buildkit failed to respond` or `container state improper`.

**Solution:**

1. Stop and remove the Dagger Engine container:

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker container stop "$DAGGER_ENGINE_DOCKER_CONTAINER"
docker container rm "$DAGGER_ENGINE_DOCKER_CONTAINER"
```

2. Clear unused volumes and data (optional):

```bash
docker volume prune
docker system prune
```

## Dagger is unable to resolve host names after network configuration changes

If the network configuration of the host changes after the Dagger Engine container starts, Docker does not notify the Dagger Engine of the change.

**Solution:** Restart the Dagger Engine container:

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker restart "$DAGGER_ENGINE_DOCKER_CONTAINER"
```

## Dagger restarts with a "CNI setup error"

The Dagger Engine requires the `iptable_nat` Linux kernel module.

**Solution:** Load this module:

```bash
sudo modprobe iptable_nat
```

To have this module loaded automatically on startup:

```bash
echo iptable_nat | sudo tee -a /etc/modules-load.d/iptables_nat.conf
```

## Errors related to code generation

A Dagger Function may fail with errors like:
- `unable to start container process`
- `failed to update codegen and runtime`
- `failed to generate code`

**Solution:**

1. Remove the `DOCKER_DEFAULT_PLATFORM` variable
2. Ensure Rosetta is disabled in Docker Desktop on Mac
3. Remove any running Dagger Engine containers:

```bash
docker rm -fv $(docker ps --filter name="dagger-engine-*" -q) && docker rmi $(docker images -q --filter reference=registry.dagger.io/engine)
```

## Debugging Tips

### Rerun commands with `--interactive`

Run `dagger call` with the `--interactive` (`-i` for short) flag to open a terminal in the context of a workflow failure.

### Rerun commands with `--debug`

Run any `dagger` subcommand with the `--debug` flag for more detailed output.

### Access the Dagger Engine logs

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker logs $DAGGER_ENGINE_DOCKER_CONTAINER
```

### Enable SDK debug logs (Python)

```python
import logging
from dagger.log import configure_logging

configure_logging(logging.DEBUG)
```

## See Also

- [Documentation Overview](./COMPASS.md)
