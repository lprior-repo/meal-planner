---
doc_id: ops/3_cli/branch-specific-items
chunk_id: ops/3_cli/branch-specific-items#chunk-19
heading_path: ["Branch-specific items", "Git sync integration"]
chunk_type: prose
tokens: 140
summary: "Git sync integration"
---

## Git sync integration

When [Git sync](./meta-11_git_sync-index.md) is configured, branch-specific items work seamlessly with your Git repository setup. Git sync will automatically push changes to the correct branch-specific files based on the repository and branch configured in your `git_repository` resource.

**Example workflow**:
- **Production workspace**: Configured with `git_repository` pointing to `repoX` on `prod` branch
  - Changes to `database.resource.yaml` → pushes to `database.prod.resource.yaml` in repository
- **Development workspace**: Configured with `git_repository` pointing to `repoX` on `dev` branch
  - Changes to `database.resource.yaml` → pushes to `database.dev.resource.yaml` in repository

This ensures that each workspace environment maintains its own branch-specific configurations while using the same logical resource names in the Windmill workspace.
