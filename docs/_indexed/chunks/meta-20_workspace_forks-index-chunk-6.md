---
doc_id: meta/20_workspace_forks/index
chunk_id: meta/20_workspace_forks/index#chunk-6
heading_path: ["Workspace forks", "Synchronization and merging"]
chunk_type: prose
tokens: 187
summary: "Synchronization and merging"
---

## Synchronization and merging

### Simple edits with the deployement UI

Once a fork is created, it is automatically setup to deploy to its parent branch. You can deploy any item to the parent branch directly from the UI by clicking it and selecting `Deploy to staging/prod`. Learn more about the [Deployment UI](./meta-12_staging_prod-index.md).

There is currently no way to update the parent workspace changes back to the fork through the UI, but some features are planned to remediate to this.

### Git sync based merging

When git sync is properly setup, the workspace is synchronized with one of the branches in your repo, and the forks are also synchronized with their own branches. It is then possible your preferred git workflow to merge into or out of these branches to sync, so you can update the fork, or deploy changes into the parent workspace.
