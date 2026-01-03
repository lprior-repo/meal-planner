---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-15
heading_path: ["Continuous integration (CI)", "Caching artifacts"]
chunk_type: prose
tokens: 188
summary: "Caching artifacts"
---

## Caching artifacts

When a CI pipeline reaches a certain scale, its run times increase, tasks are unnecessarily ran, and build artifacts are not shared. To combat this, we support [remote caching](/docs/guides/remote-cache), a mechanism where we store build artifacts in the cloud, and sync these artifacts to machines on demand.

### Manual persistence

If you'd prefer to *not use* remote caching at this time, you can cache artifacts yourself, by persisting the `.moon/cache/{hashes,outputs}` directories. All other files and folders in `.moon/cache` *should not* be persisted, as they are not safe/portable across machines.

However, because tasks can generate a different hash each run, you'll need to manually invalidate your cache. Blindly storing the `hashes` and `outputs` directories without a mechanism to invalidate will simply not work, as the contents will drastically change between CI runs. This is the primary reason why the remote caching service exists.
