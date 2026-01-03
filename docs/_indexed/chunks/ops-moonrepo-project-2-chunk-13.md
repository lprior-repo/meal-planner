---
doc_id: ops/moonrepo/project-2
chunk_id: ops/moonrepo/project-2#chunk-13
heading_path: ["moon.{pkl,yml}", "`fileGroups`"]
chunk_type: prose
tokens: 118
summary: "`fileGroups`"
---

## `fileGroups`

Defines [file groups](/docs/concepts/file-group) to be used by local tasks. By default, this setting *is not required* for the following reasons:

-   File groups are an optional feature, and are designed for advanced use cases.
-   File groups defined in [`.moon/tasks.yml`](/docs/config/tasks) will be inherited by all projects.

When defined this setting requires a map, where the key is the file group name, and the value is a list of [globs or file paths](/docs/concepts/file-pattern), or environment variables. Globs and paths are [relative to a project](/docs/concepts/file-pattern#project-relative) (even when defined [globally](/docs/config/tasks)).

moon.yml

```yaml
