---
doc_id: ops/moonrepo/file
chunk_id: ops/moonrepo/file#chunk-1
heading_path: ["docker file"]
chunk_type: prose
tokens: 249
summary: "docker file"
---

# docker file

> **Context**: The `moon docker file <project>` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker's laye

v1.27.0

The `moon docker file <project>` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker's layer caching, and is primarily for production deploys (this should not be used for development).

```
$ moon docker file <project>
```

As mentioned above, the generated `Dockerfile` uses a multi-stage approach, where each stage is broken up into the following:

-   `base` - The base stage, which simply installs moon for a chosen Docker image. This stage requires Bash.
-   `skeleton` - Scaffolds workspace and sources repository skeletons using [`moon docker scaffold`](/docs/commands/docker/scaffold).
-   `build` - Copies required sources, installs the toolchain using [`moon docker setup`](/docs/commands/docker/setup), optionally builds the project, and optionally prunes the image using [`moon docker prune`](/docs/commands/docker/prune).
-   `start` - Runs the project after it has been built. This is typically starting an HTTP server, or executing a binary.

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.
