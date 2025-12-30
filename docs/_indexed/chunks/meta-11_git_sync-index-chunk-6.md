---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-6
heading_path: ["Git sync", "wmill.yaml integration"]
chunk_type: prose
tokens: 114
summary: "wmill.yaml integration"
---

## wmill.yaml integration

Git sync settings can be controlled via the [`wmill.yaml`](./ops-3_cli-sync.md#wmillyaml) file in your repository root. This enables:

- **CLI compatibility**: Settings configured in the UI are compatible with [Windmill CLI](./meta-3_cli-index.md)
- **Version-controlled configuration**: Your sync settings are stored in git alongside your code
- **Branch-specific overrides**: Different sync behavior per git branch
- **Promotion-specific settings**: Special configuration for deployment workflows
- **[Branch-specific items](./ops-3_cli-branch-specific-items.md)**: Different versions of resources and variables per git branch for environment-specific configurations

The frontend will detect existing `wmill.yaml` files and merge settings appropriately.
