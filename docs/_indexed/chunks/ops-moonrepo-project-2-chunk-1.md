---
doc_id: ops/moonrepo/project-2
chunk_id: ops/moonrepo/project-2#chunk-1
heading_path: ["moon.{pkl,yml}"]
chunk_type: prose
tokens: 110
summary: "moon.{pkl,yml}"
---

# moon.{pkl,yml}

> **Context**: The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at

The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at the project-level. When used, this file must exist in a project's root, as configured in [`projects`](/docs/config/workspace#projects).

moon.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/project.json'
```

> Project configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
