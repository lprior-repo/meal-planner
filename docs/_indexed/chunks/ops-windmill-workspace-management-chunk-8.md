---
doc_id: ops/windmill/workspace-management
chunk_id: ops/windmill/workspace-management#chunk-8
heading_path: ["Workspace management", "Managing encryption keys"]
chunk_type: prose
tokens: 230
summary: "Managing encryption keys"
---

## Managing encryption keys

All [secrets](./meta-windmill-index-46.md#secrets) of a workspace are [encrypted](./meta-windmill-index-47.md) with a symmetric key unique to that workspace. This key is generated when the workspace is created and is stored in the database in the workspace_settings.

### Encryption key during instance sync

The workspace encryption key is migrated along with the workspace. During the [push process](./ops-windmill-sync.md#pushing-an-instance), you will be prompted to decide whether to re-encrypt the secrets of the workspace on the remote instance. In the case of instance migration, it is recommended to select "no" as the secrets are already encrypted with the correct key.

### Encryption key during workspace sync

When [synchronizing workspaces](./ops-windmill-sync.md), the `--include-key` option should be used to ensure the encryption key is also included in the sync process. This is essential for maintaining the security and integrity of encrypted data as it moves between environments.

This option prompts you to confirm if the encryption key should be replaced or retained. Make an informed choice based on whether the destination environment requires a new key or should continue using the existing key.
