---
doc_id: ops/3_cli/workspace-management
chunk_id: ops/3_cli/workspace-management#chunk-6
heading_path: ["Workspace management", "Removing a workspace"]
chunk_type: code
tokens: 126
summary: "Removing a workspace"
---

## Removing a workspace

The `wmill workspace remove` command allows you to remove a workspace from the CLI.

```bash
wmill workspace remove <workspace_name>
```text

### Arguments

| Argument         | Description                          |
| ---------------- | ------------------------------------ |
| `workspace_name` | The name of the workspace to remove. |

### Examples

1. Remove the workspace named "MyWorkspace".

```bash
wmill workspace remove MyWorkspace
```text

:::tip Get help

At any point you can ask help with the command `-h` after a given instruction to see the list of options & commands.

Example here just using `windmill -h`:

<br/>

![CLI help](./cli_help.png.webp)

:::
