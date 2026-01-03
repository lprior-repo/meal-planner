---
doc_id: ref/moonrepo/file-group
chunk_id: ref/moonrepo/file-group#chunk-2
heading_path: ["File groups", "Configuration"]
chunk_type: prose
tokens: 74
summary: "Configuration"
---

## Configuration

File groups can be configured per project through [`moon.yml`](/docs/config/project), or for many projects through [`.moon/tasks.yml`](/docs/config/tasks).

### Token functions

File groups can be referenced in [tasks](/docs/concepts/task) using [token functions](/docs/concepts/token). For example, the `@group(name)` token will expand to all paths configured in the `sources` file group.

moon.yml

```yaml
tasks:
  build:
    command: 'vite build'
    inputs:
      - '@group(sources)'
```
