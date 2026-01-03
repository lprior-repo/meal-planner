---
doc_id: ops/windmill/sync
chunk_id: ops/windmill/sync#chunk-2
heading_path: ["Sync", "Pulling"]
chunk_type: prose
tokens: 81
summary: "Pulling"
---

## Pulling

`wmill sync pull` will simply pull all files from the currently
[selected workspace](./ops-windmill-workspace-management.md#selected-workspace) and store
them in the current folder. Overwrites will not prompt the user. Make sure you
are in the correct folder or you may loose data.

### Pushing

`wmill sync push` will simply push all local files to the currently
[selected workspace](./ops-windmill-workspace-management.md#selected-workspace), creating or
updating the remote equivalents.
