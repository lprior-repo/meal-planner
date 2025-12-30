---
id: ops/sync/projects
title: "sync projects"
category: ops
tags: ["operations", "sync"]
---

# sync projects

> **Context**: The `moon sync projects` command will force sync *all* projects in the workspace to help achieve a [healthy repository state](/docs/faq#what-should-be

v1.8.0

The `moon sync projects` command will force sync *all* projects in the workspace to help achieve a [healthy repository state](/docs/faq#what-should-be-considered-the-source-of-truth). This applies the following:

- Ensures cross-project dependencies are linked based on [`dependsOn`](/docs/config/project#dependson).
- Ensures language specific configuration files are present and accurate (`package.json`, `tsconfig.json`, etc).
- Ensures root configuration and project configuration are in sync.
- Any additional language specific semantics that may be required.

```
$ moon sync projects
```

> This command should rarely be ran, as [`moon run`](/docs/commands/run) will sync affected projects automatically! However, when migrating or refactoring, manual syncing may be necessary.

## Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`


## See Also

- [healthy repository state](/docs/faq#what-should-be-considered-the-source-of-truth)
- [`dependsOn`](/docs/config/project#dependson)
- [`moon run`](/docs/commands/run)
- [`projects`](/docs/config/workspace#projects)
