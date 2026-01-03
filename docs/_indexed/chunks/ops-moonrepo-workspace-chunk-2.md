---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-2
heading_path: [".moon/workspace.{pkl,yml}", "`extends`"]
chunk_type: prose
tokens: 105
summary: "`extends`"
---

## `extends`

Defines one or many external `.moon/workspace.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/workspace.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/workspace.yml'
```

> Settings will be merged recursively for blocks, with values defined in the local configuration taking precedence over those defined in the extended configuration. However, the `projects` setting *does not merge*!
