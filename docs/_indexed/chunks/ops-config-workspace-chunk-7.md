---
doc_id: ops/config/workspace
chunk_id: ops/config/workspace#chunk-7
heading_path: [".moon/workspace.{pkl,yml}", "`generator`"]
chunk_type: prose
tokens: 93
summary: "`generator`"
---

## `generator`

Configures aspects of the template generator.

### `templates`

A list of paths in which templates can be located. Supports the following types of paths, and defaults to `./templates`.

-   File system paths, relative from the workspace root.
-   Git repositories and a revision, prefixed with `git://`. (v1.23.0)
-   npm packages and a version, prefixed with `npm://`. (v1.23.0)

.moon/workspace.yml

```yaml
generator:
  templates:
    - './templates'
    - 'file://./other/templates'
    - 'git://github.com/moonrepo/templates#master'
    - 'npm://@moonrepo/templates#1.2.3'
```
