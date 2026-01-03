---
doc_id: ops/windmill/sync
chunk_id: ops/windmill/sync#chunk-12
heading_path: ["Sync", "Cloning an instance"]
chunk_type: prose
tokens: 261
summary: "Cloning an instance"
---

## Cloning an instance

Instances can be cloned with Windmill CLI. This is useful for instance migration or for setting up a new (prod) instance with the same configuration as an existing one.

### Pulling an instance

To pull instance users, groups, settings and configs (=worker groups+SMTP) from the instance use `wmill instance pull`.

You can skip any of those using `--skip-XXX`.

You can also pull all workspaces at the same time by adding the `--include-workspaces` option. It will setup for each a local workspace (including a folder in the current directory) with a prefix specific to the instance (based on the name you've given to the instance).

### Pushing an instance

To push to an instance use `wmill instance push`. It takes the same options as pulling an instance.

When using `--include-workspaces`, you will also have to select the instance prefix of the local workspaces you want to push (make sure you're in its parent folder).

During the push process, you will be prompted to decide whether to [re-encrypt](./ops-windmill-workspace-management.md#managing-encryption-keys) the secrets of the workspace on the remote instance. In the case of instance migration, it is recommended to select "no" as the secrets are already encrypted with the correct key.
