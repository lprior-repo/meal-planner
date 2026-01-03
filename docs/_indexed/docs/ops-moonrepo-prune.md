---
id: ops/moonrepo/prune
title: "docker prune"
category: ops
tags: ["docker", "moonrepo", "operations"]
---

# docker prune

> **Context**: The `moon docker prune` command will reduce the overall filesize of the Docker environment by installing production only dependencies for projects tha

The `moon docker prune` command will reduce the overall filesize of the Docker environment by installing production only dependencies for projects that were scaffolded, and removing any applicable extraneous files.

```
$ moon docker prune
```

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

**Caution:** This command *must be* ran after [`moon docker scaffold`](/docs/commands/docker/scaffold) and is typically ran within a `Dockerfile`! The [`moon docker file`](/docs/commands/docker/file) command can be used to generate a `Dockerfile`.

## Configuration

-   [`docker.prune`](/docs/config/workspace#prune) in `.moon/workspace.yml`


## See Also

- [Docker usage guide](/docs/guides/docker)
- [`moon docker scaffold`](/docs/commands/docker/scaffold)
- [`moon docker file`](/docs/commands/docker/file)
- [`docker.prune`](/docs/config/workspace#prune)
