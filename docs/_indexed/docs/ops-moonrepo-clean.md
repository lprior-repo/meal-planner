---
id: ops/moonrepo/clean
title: "clean"
category: ops
tags: ["moonrepo", "operations", "clean"]
---

# clean

> **Context**: The `moon clean` command will clean the current workspace by deleting stale cache. For the most part, the action pipeline will clean automatically, bu

The `moon clean` command will clean the current workspace by deleting stale cache. For the most part, the action pipeline will clean automatically, but this command can be used to reset the workspace entirely.

```
$ moon clean

## Delete cache with a custom lifetime
$ moon clean --lifetime '24 hours'
```

### Options

-   `--lifetime` - The maximum lifetime of cached artifacts before being marked as stale. Defaults to "7 days".


## See Also

- [Documentation Index](./COMPASS.md)
