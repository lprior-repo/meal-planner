---
doc_id: ops/editors/vscode
chunk_id: ops/editors/vscode#chunk-2
heading_path: ["VS Code extension", "Views"]
chunk_type: prose
tokens: 197
summary: "Views"
---

## Views

All views are available within the moon sidebar. Simply click the moon icon in the left activity bar!

### Projects

The backbone of moon is the projects view. In this view, all moon configured projects will be listed, categorized by their [`layer`](/docs/config/project#layer), [`stack`](/docs/config/project#stack), and designated with their [`language`](/docs/config/project#language).

Each project can then be expanded to view all available tasks. Tasks can be ran by clicking the `▶` icon, or using the command palette.

> This view is available in both the "Explorer" and "moon" sidebars.

### Tags

Similar to the projects view, the tags view displays projects grouped by their [`tags`](/docs/config/project#tags).

> This view is only available in the "moon" sidebar.

### Last run

Information about the last ran task will be displayed in a beautiful table with detailed stats.

This table displays all actions that were ran alongside the primary target(s). They are ordered topologically via the action graph.
