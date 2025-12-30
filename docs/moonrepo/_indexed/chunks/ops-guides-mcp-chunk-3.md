---
doc_id: ops/guides/mcp
chunk_id: ops/guides/mcp#chunk-3
heading_path: ["MCP integration", "Available tools"]
chunk_type: prose
tokens: 139
summary: "Available tools"
---

## Available tools

The following tools are available in the moon MCP server and can be executed by LLMs using agent mode.

- `get_project` - Get a project and its tasks by `id`.
- `get_projects` - Get all projects.
- `get_task` - Get a task by `target`.
- `get_tasks` - Get all tasks.
- `get_touched_files` - Gets touched files between base and head revisions. (v1.38.0)
- `sync_projects` - Runs the `SyncProject` action for one or many projects by `id`. (v1.38.0)
- `sync_workspace` - Runs the `SyncWorkspace` action. (v1.38.0)

> **Info:** The [request and response shapes](https://github.com/moonrepo/moon/blob/master/packages/types/src/mcp.ts) for these tools are defined as TypeScript types in the [`@moonrepo/types`](https://www.npmjs.com/package/@moonrepo/types) package.
