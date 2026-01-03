---
doc_id: ops/moonrepo/cache
chunk_id: ops/moonrepo/cache#chunk-3
heading_path: ["Cache", "Archiving & hydration"]
chunk_type: prose
tokens: 175
summary: "Archiving & hydration"
---

## Archiving & hydration

On top of our hashing layer, we have another concept known as archiving, where in we create a tarball archive of a task's outputs and store it in `.moon/cache/outputs`. These are akin to build artifacts.

When we encounter a cache hit on a hash, we trigger a mechanism known as hydration, where we efficiently unpack an existing tarball archive into a task's outputs. This can be understood as a timeline, where every point in time will have its own hash + archive that moon can play back.

Furthermore, if we receive a cache hit on the hash, and the hash is the same as the last run, and outputs exist, we exit early without hydrating and assume the project is already hydrated. In the terminal, you'll see a message for "cached".
