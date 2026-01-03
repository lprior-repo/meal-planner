---
doc_id: ops/windmill/gitsync-settings
chunk_id: ops/windmill/gitsync-settings#chunk-18
heading_path: ["Git sync settings", "Differences from sync command"]
chunk_type: prose
tokens: 132
summary: "Differences from sync command"
---

## Differences from sync command

The `gitsync-settings` command is specifically for managing configuration, not workspace content:

| Feature | `gitsync-settings` | `sync` |
|---------|-------------------|---------|
| **Purpose** | Manages git-sync configuration settings | Synchronizes actual workspace content (scripts, flows, etc.) |
| **Scope** | Configuration metadata only | Workspace resources and files |
| **Target** | `wmill.yaml` git-sync settings | Workspace scripts, flows, apps, resources |
| **File Operations** | Modifies `wmill.yaml` structure | Creates/updates resource files in sync directory |
| **Safety** | Configuration changes only | Can create/delete workspace resources |

For more details on the `wmill.yaml` configuration structure, see [wmill.yaml](./ops-windmill-sync.md#wmillyaml).
