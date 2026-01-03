---
doc_id: ops/moonrepo/projects-2
chunk_id: ops/moonrepo/projects-2#chunk-1
heading_path: ["sync projects"]
chunk_type: prose
tokens: 159
summary: "sync projects"
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
