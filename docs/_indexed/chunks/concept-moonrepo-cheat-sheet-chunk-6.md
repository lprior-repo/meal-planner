---
doc_id: concept/moonrepo/cheat-sheet
chunk_id: concept/moonrepo/cheat-sheet#chunk-6
heading_path: ["Cheat sheet", "Also inferred from the language"]
chunk_type: code
tokens: 118
summary: "Also inferred from the language"
---

## Also inferred from the language
dependsOn:
  - 'project-a'
  - 'project-b'

tasks:
  example:
    # ...
    deps:
      - '^:build'
```

### Depend on tasks from arbitrary projects

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'other-project:task'
```

### Run dependencies serially

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'first'
      - 'second'
      - 'third'
    options:
      runDepsInParallel: false
```

### Run multiple watchers/servers in parallel

moon.yml

```yaml
tasks:
  example:
    command: 'noop'
    deps:
      - 'app:watch'
      - 'backend:start'
      - 'tailwind:watch'
    local: true
```

> The `local` or `persistent` settings are required for this to work.
