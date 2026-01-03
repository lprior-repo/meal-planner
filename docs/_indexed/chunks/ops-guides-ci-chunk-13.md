---
doc_id: ops/guides/ci
chunk_id: ops/guides/ci#chunk-13
heading_path: ["Continuous integration (CI)", "..."]
chunk_type: prose
tokens: 52
summary: "..."
---

## ...
jobs:
  ci:
    # ...
    parallelism: 10
    steps:
      # ...
      - run: 'moon ci --job $CIRCLE_NODE_INDEX --jobTotal $CIRCLE_NODE_TOTAL'
```

- [Documentation](https://circleci.com/docs/2.0/parallelism-faster-jobs/)

### TravisCI

TravisCI does not support native parallelism, but it can be emulated using its matrix.

.travis.yml

```yaml
