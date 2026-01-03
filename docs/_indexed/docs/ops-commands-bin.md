---
id: ops/commands/bin
title: "bin"
category: ops
tags: ["operations", "bin", "commands"]
---

# bin

> **Context**: The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, th

The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, this will return a 1 or 2 exit code with no value respectively.

```
$ moon bin node
/Users/example/.proto/tools/node/x.x.x/bin/node
```

> A tool is considered "not configured" when not in use, for example, querying yarn/pnpm when the package manager is configured for "npm". A tool is considered "not installed", when it has not been downloaded and installed into the tools directory.

## Arguments

-   `<tool>` - Name of the tool to query.


## See Also

- [Documentation Index](./COMPASS.md)
