---
id: ops/commands/setup
title: "setup"
category: ops
tags: ["commands", "setup", "operations"]
---

# setup

> **Context**: The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured t

The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured tools into the toolchain.

```
$ moon setup
```

> **info**
> This command should rarely be used, as the environment is automatically setup when running other commands, like detecting affected projects, running a task, or generating a build artifact.

## Configuration

- [`*`](/docs/config/toolchain) in `.moon/toolchain.yml`


## See Also

- [`*`](/docs/config/toolchain)
