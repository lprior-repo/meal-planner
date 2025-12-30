---
doc_id: concept/general/cheat-sheet
chunk_id: concept/general/cheat-sheet#chunk-5
heading_path: ["Cheat sheet", "Task configuration"]
chunk_type: code
tokens: 58
summary: "Task configuration"
---

## Task configuration

Learn more about available options.

### Disable caching

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      cache: false
```

### Re-run flaky tasks

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      retryCount: 3
```

### Depend on tasks from parent project's dependencies

moon.yml

```yaml
