---
doc_id: ops/3_cli/branch-specific-items
chunk_id: ops/3_cli/branch-specific-items#chunk-7
heading_path: ["Branch-specific items", "Create wmill.yaml with branch configuration"]
chunk_type: code
tokens: 78
summary: "Create wmill.yaml with branch configuration"
---

## Create wmill.yaml with branch configuration
wmill init
```

2. **Configure patterns** in `wmill.yaml`:

```yaml
gitBranches:
  main:
    specificItems:
      resources:
        - "u/alex/config/**"
      variables:
        - "u/alex/env_*"
      triggers:
        - "u/alex/kafka_*"
    overrides:
      skipSecrets: false

  dev:
    specificItems:
      resources:
        - "u/alex/config/**"
      variables:
        - "u/alex/env_*"
      triggers:
        - "u/alex/kafka_*"
    overrides:
      skipSecrets: true
```

### Working with different environments

**On main branch**:
```bash
git checkout main
wmill sync pull
