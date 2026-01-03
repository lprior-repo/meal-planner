---
id: ops/docker/setup
title: "docker setup"
category: ops
tags: ["docker", "operations"]
---

# docker setup

> **Context**: The `moon docker setup` command will efficiently install dependencies for focused projects. This is an all-in-one command for tool and dependency inst

The `moon docker setup` command will efficiently install dependencies for focused projects. This is an all-in-one command for tool and dependency installations, and should replace `npm install` and other commands.

```
$ moon docker setup
```

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

**Caution:** This command *must be* ran after [`moon docker scaffold`](/docs/commands/docker/scaffold) and is typically ran within a `Dockerfile`! The [`moon docker file`](/docs/commands/docker/file) command can be used to generate a `Dockerfile`.

## Configuration

-   [`*`](/docs/config/toolchain) in `.moon/toolchain.yml`


## See Also

- [Docker usage guide](/docs/guides/docker)
- [`moon docker scaffold`](/docs/commands/docker/scaffold)
- [`moon docker file`](/docs/commands/docker/file)
- [`*`](/docs/config/toolchain)
