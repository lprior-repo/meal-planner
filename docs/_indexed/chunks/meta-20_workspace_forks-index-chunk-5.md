---
doc_id: meta/20_workspace_forks/index
chunk_id: meta/20_workspace_forks/index#chunk-5
heading_path: ["Workspace forks", "Git sync integration"]
chunk_type: prose
tokens: 276
summary: "Git sync integration"
---

## Git sync integration

When workspace forks are used with [git sync](./meta-11_git_sync-index.md), Windmill will automatically create a git branch on the same repository as
the parent workspace, and keep track of changes there. External changes to the branch are then synced back to the forked workspace if the appropriate
CI/CD actions are setup. Once the changes are ready, a PR can be opened to sync back changes to the original workspace.

Workspace forks are designed to be used with git sync, so make sure to have it properly setup and in particular the [CI/CD actions](./meta-9_deploy_gh_gl-index.md#github-actions-setup) specific to forks should be set. Make sure to not forget the `push-on-merge-to-forks.yaml` action.

### Fork and branch naming

Forks workspace IDs are always prefixed by `wm-fork-`. The associated branch name is always prefixed by `wm-fork/<originalBranch>/` where `<originalBranch>` is the branch that is associated with the original branch was worked from.

For example:

| Workspace ID | Default or selected branch of repo associated with workspace | Fork Workspace ID | Branch associated to fork |
|--------------|--------------------------------------------------------------|-------------------|---------------------------|
| windmill     | main                                                         | wm-fork-feature1  | wm-fork/main/feature1     |

This naming convention is what enables Windmill to match branches to workspaces without having to reconfigure it for each branch. This is why fork workspace ids and branch names cannot be changed.
