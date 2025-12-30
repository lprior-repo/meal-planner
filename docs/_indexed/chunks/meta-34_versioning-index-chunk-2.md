---
doc_id: meta/34_versioning/index
chunk_id: meta/34_versioning/index#chunk-2
heading_path: ["Versioning", "Script versioning"]
chunk_type: prose
tokens: 280
summary: "Script versioning"
---

## Script versioning

Scripts, when deployed, can have a parent script identified by its hash. Indeed, scripts are never overwritten, they are instead subsumed by a child script which corresponds to the new version of the parent script. This guarantees traceability of every action done on the platform, including editing scripts. It also enables versioning.

Versioning is a good practice from software engineering which everyone familiar with git already knows. Windmill versioning is a simplified git with two simplifying assumptions:

- **Linearity**: the lineage or the chain of Scripts from the one with no ancestor/parent to the one with no child is linear - there is no branching and there is no merging.
- **Not diff-based**: every version of a Script contains its entire content and not just the diff between it and its direct parent. This is for simplicity and read-performance sake.

### Script hashes

Versions of Scripts are uniquely defined by their hashes. They are an immutable reference similar to a git commit SHA. Scripts also have a path, and many versions share the same path. When a script is [deployed at a path](./meta-0_draft_and_deploy-index.md), it creates a new hash that becomes the "HEAD" of the path. The previous "HEAD" is archived but still deployed forever.

When a script is saved, it is immediately deployed.
