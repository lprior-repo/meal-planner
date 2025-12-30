---
doc_id: concept/config/tasks
chunk_id: concept/config/tasks#chunk-2
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`extends`"]
chunk_type: prose
tokens: 113
summary: "`extends`"
---

## `extends`

Defines one or many external `.moon/tasks.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/tasks.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/tasks.yml'
```

> **Caution**: For map-based settings, `fileGroups` and `tasks`, entries from both the extended configuration and local configuration are merged into a new map, with the values of the local taking precedence. Map values *are not* deep merged!
