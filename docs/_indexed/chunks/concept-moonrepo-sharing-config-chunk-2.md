---
doc_id: concept/moonrepo/sharing-config
chunk_id: concept/moonrepo/sharing-config#chunk-2
heading_path: ["Sharing workspace configuration", "Versioning"]
chunk_type: code
tokens: 183
summary: "Versioning"
---

## Versioning

Inheriting an upstream configuration can be dangerous, as the settings may change at any point, resulting in broken builds. To mitigate this, you can used a "versioned" upstream configuration, which is ideally a fixed point in time. How this is implemented is up to you or your company, but we suggest the following patterns:

### Using versioned filenames

A rudimentary solution is to append a version to the upstream filename. When the file is modified, a new version should be created, while the previous version remains untouched.

```diff
-extends: '../shared/project.yml'
+extends: '../shared/project-v1.yml'
```

### Using branches, tags, or commits

When using a version control platform, like GitHub above, you can reference the upstream configuration through a branch, tag, commit, or sha. Since these are a reference point in time, they are relatively safe.

```diff
-extends: 'https://raw.githubusercontent.com/moonrepo/examples/master/.moon/tasks.yml'
+extends: 'https://raw.githubusercontent.com/moonrepo/examples/c3f10160bcd16b48b8d4d21b208bb50f6b09bd96/.moon/tasks.yml'
```
