---
id: tutorial/reference/container-runtimes-index
title: "Container Runtimes"
category: tutorial
tags: ["tutorial", "container", "ai"]
---

# Container Runtimes

> **Context**: When the Dagger CLI is run on the host, it needs to connect to an engine. The most common way is to rely on a container runtime available on the host.


When the Dagger CLI is run on the host, it needs to connect to an engine. The most common way is to rely on a container runtime available on the host.

Dagger can be used with most OCI-compatible container runtimes, including:

- [Docker](./ops-reference-container-runtimes-docker.md)
- [Podman](./ops-reference-container-runtimes-podman.md)
- [Nerdctl / Finch](./ops-reference-container-runtimes-nerdctl.md)
- [Apple's Container](./ops-reference-container-runtimes-apple-container.md)

## How it Works

By default, Dagger will attempt to detect an available container runtime on the host - no need for additional configuration.

If you need to override the default, set `_EXPERIMENTAL_DAGGER_RUNNER_HOST` using the [connection interface](/reference/configuration/custom-runner#connection-interface).

When connecting to the engine via the selected container runtime, the CLI will:
1. Attempt to download the engine image that matches its own version
2. Start it in a container
3. Connect to it for the request

The selected container runtime also provides the backend for APIs that rely on a host container runtime, such as:
- `Host.containerImage(name: String!): Container!`
- `Container.exportImage(name: String!): Void!`

## See Also

- [Documentation Overview](./COMPASS.md)
