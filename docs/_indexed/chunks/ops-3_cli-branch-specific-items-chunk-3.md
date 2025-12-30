---
doc_id: ops/3_cli/branch-specific-items
chunk_id: ops/3_cli/branch-specific-items#chunk-3
heading_path: ["Branch-specific items", "Configuration"]
chunk_type: code
tokens: 156
summary: "Configuration"
---

## Configuration

Branch-specific items are configured using two complementary patterns in your `wmill.yaml`:

### Branch-specific items

Items that should only be branch-specific for certain branches:

```yaml
gitBranches:
  main:
    specificItems:
      variables:
        - "u/alex/prod_*"
      resources:
        - "u/alex/production/**"
      triggers:
        - "u/alex/prod_kafka_*"

  dev:
    specificItems:
      variables:
        - "u/alex/dev_*"
      resources:
        - "u/alex/development/**"
      triggers:
        - "u/alex/dev_kafka_*"
```

### Common specific items

Items that should be branch-specific across all branches:

```yaml
gitBranches:
  commonSpecificItems:
    variables:
      - "u/alex/database_*"
      - "f/config/**"
    resources:
      - "u/alex/api_keys/**"
      - "f/environments/**"
    triggers:
      - "u/alex/kafka_*"
      - "f/streaming/**"
```

### Pattern matching

Patterns support standard glob syntax:

- `*` matches any characters within a path segment
- `**` matches any characters across path segments
- `u/alex/database_*` matches `u/alex/database_config`, `u/alex/database_url`, etc.
- `f/environments/**` matches all files under `f/environments/` recursively
