---
doc_id: ops/general/setup-workspace
chunk_id: ops/general/setup-workspace#chunk-4
heading_path: ["Setup workspace", "Configuring a version control system"]
chunk_type: prose
tokens: 79
summary: "Configuring a version control system"
---

## Configuring a version control system

moon requires a version control system (VCS) to be present for functionality like file diffing, hashing, and revision comparison. The VCS and its default branch can be configured through the `vcs` setting.

.moon/workspace.yml

```yaml
vcs:
  manager: 'git'
  defaultBranch: 'master'
```

> moon defaults to `git` and the settings above, so feel free to skip this.
