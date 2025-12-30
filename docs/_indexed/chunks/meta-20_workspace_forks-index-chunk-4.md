---
doc_id: meta/20_workspace_forks/index
chunk_id: meta/20_workspace_forks/index#chunk-4
heading_path: ["Workspace forks", "Managing workspace forks"]
chunk_type: prose
tokens: 395
summary: "Managing workspace forks"
---

## Managing workspace forks

### Prerequisites

- Being on a self-hosted EE instance
- [Git sync](./meta-11_git_sync-index.md) configured (recommended for full functionality)
- [CI/CD actions ](./meta-9_deploy_gh_gl-index.md#github-actions-setup) to merge back from the git remote to Windmill

### Fork creation

#### From the UI

1. Navigate to the workspace you want to fork.
2. Click on the Workspace menu on the sidebar.
3. Click on `Fork current workspace`.
4. Configure the name and id and then press on the `Fork workspace` button.

#### From the CLI

1. Enter the local repo being synced with the workspace you want to fork.
2. Run `wmill workspace fork` and follow the prompts to name your workspace. This will use your `gitBranches` settings on your `wmill.yaml` to determine which workspace to fork from based on the branch you are on.
3. The fork will be created on your instance and is ready to be worked on.
4. Run the command shown on your terminal to create the corresponding branch and start adding edits to your newly created fork!

<!-- TODO: Add step-by-step screenshots of the fork creation process -->

### Deleting a fork

Workspace forks can be deleted by their creator, or by any workspace admin.

#### From the UI

Just press the cogwheel on the sidebar and select the option to delete the workspace fork.

#### From the CLI

1. Find the workspace profile corresponding to the workspace fork using the `wmill workspace` command.
2. If missing, add it using `wmill workspace add`
3. Now run `wmill workspace delete-fork <profile_name>`

### Permissions and access

Forks can be created by any user of the workspace. Roles and access will be the same as in the original workspace. All users of the original workspace can join the fork at any time, which will make it appear as another workspace on their menu.
