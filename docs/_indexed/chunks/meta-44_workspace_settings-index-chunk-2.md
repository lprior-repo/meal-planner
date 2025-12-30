---
doc_id: meta/44_workspace_settings/index
chunk_id: meta/44_workspace_settings/index#chunk-2
heading_path: ["Workspace settings", "General"]
chunk_type: prose
tokens: 308
summary: "General"
---

## General

The General settings section provides basic workspace configuration options.

![Workspace settings](./workspace_settings.png "Workspace settings")

### Workspace name
The display name of your workspace. This can be changed at any time and will be reflected throughout the interface.

### Workspace ID
A unique identifier for your workspace. This is set during workspace creation and cannot be modified.

### Workspace color
Choose a custom color for your workspace. This helps visually distinguish between different workspaces in the interface. It is not a styling option.

![Select workspace color](./select_workspace_colors.png "Select workspace color")

![Workspace color](./workspace_color.png "Workspace color")

### Export workspace
Download a ZIP file containing all workspace resources, including:
- Scripts
- Flows
- Apps
- Resources
- Variables (secrets are exported as encrypted values)

This is useful for backup purposes. For migrating workspace content, see [CLI](./meta-3_cli-index.md).

### Delete workspace
There are two options for removing a workspace:

#### Archive workspace

Only workspace admins and instance superadmins can archive a workspace. Temporarily disable a workspace while preserving all its content. Archived workspaces:
- Cannot be accessed by regular users
- Maintain all data and configurations
- Can be unarchived by workspace admins or instance superadmins
- Do not count towards workspace limits

#### Delete workspace
Only instance superadmins can delete a workspace. Permanently remove the workspace and all associated content. This action:
- Cannot be undone
- Requires instance superadmin permissions
- Deletes all scripts, flows, apps, and other workspace resources
