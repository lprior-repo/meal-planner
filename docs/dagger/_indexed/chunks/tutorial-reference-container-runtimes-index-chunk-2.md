---
doc_id: tutorial/reference/container-runtimes-index
chunk_id: tutorial/reference/container-runtimes-index#chunk-2
heading_path: ["container-runtimes-index", "How it Works"]
chunk_type: prose
tokens: 127
summary: "By default, Dagger will attempt to detect an available container runtime on the host - no need fo..."
---
By default, Dagger will attempt to detect an available container runtime on the host - no need for additional configuration.

If you need to override the default, set `_EXPERIMENTAL_DAGGER_RUNNER_HOST` using the [connection interface](/reference/configuration/custom-runner#connection-interface).

When connecting to the engine via the selected container runtime, the CLI will:
1. Attempt to download the engine image that matches its own version
2. Start it in a container
3. Connect to it for the request

The selected container runtime also provides the backend for APIs that rely on a host container runtime, such as:
- `Host.containerImage(name: String!): Container!`
- `Container.exportImage(name: String!): Void!`
