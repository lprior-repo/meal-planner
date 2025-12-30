---
doc_id: meta/9_deploy_gh_gl/index
chunk_id: meta/9_deploy_gh_gl/index#chunk-3
heading_path: ["Deploy to prod using a git workflow", "Managing multiple teams and folders"]
chunk_type: prose
tokens: 361
summary: "Managing multiple teams and folders"
---

## Managing multiple teams and folders

When working with multiple teams in Windmill, there are several approaches to organize your workflows and prevent overlapping changes. Here are the recommended practices:

### Option 1: Same workspace, different folders, different repositories

This is the recommended approach for most cases:

1. Keep all teams in the same [workspace](./meta-44_workspace_settings-index.md) but assign each team to different [folders](./meta-8_groups_and_folders-index.md)
2. Create separate repositories for each team
3. In each repository's [`wmill.yaml`](./meta-11_git_sync-index.md#wmill-yaml), specify the folders that team has ownership of using the `includes` field:

```yaml
includes:
  - "f/team1_folder/**"  # Team 1's folder
  - "f/team2_folder/**"  # Team 2's folder
````

This setup ensures that:

- Each team works in their own isolated space.
- Changes from different teams won't overlap.
- Teams can have the same initial code in their respective folders.
- Each team's changes will be tracked in their own repository.

### Option 2: Separate workspaces

Alternatively, you can create separate workspaces for each team. This approach:

- Provides complete isolation between teams.
- Allows teams to have their own deployment workflows.
- May require more maintenance overhead.
- Is useful when teams need completely different configurations or environments.

### Managing changes and pull requests

When using the [promotion mode](./meta-11_git_sync-index.md#git-sync---promotion-mode-deploy-to-prod-using-a-git-workflow) in Git sync:

- Changes to the same item will be grouped into a single PR.
- Different items will create separate PRs.
- You can use the [group per folder](./meta-11_git_sync-index.md#group-deployed-objects-by-folder) option to group changes by folder instead of by item.

:::tip
When setting up multiple repositories for different teams, ensure that each repository's `wmill.yaml` file correctly specifies the folders the team should have access to. This prevents accidental modifications to another team's code.
:::
