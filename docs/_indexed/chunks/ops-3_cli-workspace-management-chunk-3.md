---
doc_id: ops/3_cli/workspace-management
chunk_id: ops/3_cli/workspace-management#chunk-3
heading_path: ["Workspace management", "Adding a workspace"]
chunk_type: code
tokens: 397
summary: "Adding a workspace"
---

## Adding a workspace

<video
    className="border-2 rounded-xl object-cover w-full h-full"
    autoPlay
    muted
    src="/videos/cli_add_workspace.mp4"
    controls
/>
<br/>

The wmill CLI is capable of handling working with many remotes & workspaces.
Each combination of remote & workspace is registered with together with a name
locally using:

```bash
wmill workspace add [workspace_name] [workspace_id] [remote]
```

You can login to the workspace with a token or directly from browser.

The new workspace will automatically be [switched](#switch-workspaces) to.

### Arguments

| Argument         | Description                                                                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `workspace_name` | The name of the workspace. Note: This is a name used to refer this workspace locally on your machine. It can be same or different from your remote instance |
| `workspace_id`   | The ID of the workspace.remote. The workspace ID is displayed in the switch workspace menu.                                                                 |
| `remote`         | The base URL of the Windmill installation (e.g., https://app.windmill.dev or https://your-windmill-instance.com).                                          |

### Options

| Option                    | parameter          | Description                                                                                                                                            |
| ------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-c`, `--create`          | None               | Create the workspace if it does not exist.                                                                                                             |
| `--create-workspace-name` | `<workspace_name>` | Specify the workspace name. Ignored if `--create` is not specified or the workspace already exists. Defaults to the workspace ID.                      |
| `--create-username`       | `<username>`       | Specify your own username in the newly created workspace. Ignored if `--create` is not specified or the workspace already exists. Defaults to "admin". |

### Examples

1. Prompts for the workspace name, ID, and remote URL.

```bash
wmill workspace add
```

2. Adds a workspace with the name "MyWorkspace", ID "workspace123", and base URL of the Windmill installation "https://example.com".

```bash
wmill workspace add MyWorkspace workspace123 https://example.com
```

1. This command creates a workspace with the name "MyWorkspace2," using the provided username "john.doe."

```bash
wmill workspace add --create --create-workspace-name MyWorkspace2 --create-username john.doe
```
