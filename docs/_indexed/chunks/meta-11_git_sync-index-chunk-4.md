---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-4
heading_path: ["Git sync", "Repositories to sync"]
chunk_type: prose
tokens: 241
summary: "Repositories to sync"
---

## Repositories to sync

The changes will be deployed to all the repositories set in the Git sync settings.

### Sync modes

You can choose between two sync modes for each repository:

#### Sync mode (default)

Changes are committed directly to the branch specified in the [git_repository](../../integrations/git_repository.mdx) resource. This is the standard mode for simple workspace synchronization.

When combined with [branch-specific items](./ops-3_cli-branch-specific-items.md), different workspaces can sync to different branches while maintaining environment-specific configurations (e.g., production workspace syncs to `prod` branch, development workspace syncs to `dev` branch).

#### Promotion mode

Windmill will create branches per deployed object based on its path, prefixed with 'wm_deploy/'. This enables advanced deployment workflows with pull requests and code review processes.

When promotion mode is enabled, you can choose to:

- **Create one branch per deployed object** (default)
- **Group deployed objects by folder**: Create a branch per folder containing objects being deployed instead

You can configure promotion-specific sync behavior using `promotionOverrides` in your [`wmill.yaml`](./ops-3_cli-sync.md#wmillyaml) file. This allows different filter settings when promoting changes to specific branches.

This promotion mode is used to [deploy to a prod workspace using a git workflow](#git-sync---promotion-mode-deploy-to-prod-using-a-git-workflow).
