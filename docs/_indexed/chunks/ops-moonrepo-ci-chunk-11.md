---
doc_id: ops/moonrepo/ci
chunk_id: ops/moonrepo/ci#chunk-11
heading_path: ["ci", "..."]
chunk_type: prose
tokens: 40
summary: "..."
---

## ...
jobs:
  ci:
    # ...
    strategy:
      matrix:
        index: [0, 1]
    steps:
      # ...
      - run: 'moon ci --job ${{ matrix.index }} --jobTotal 2'
```

- [Documentation](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)

### Buildkite

.buildkite/pipeline.yml

```yaml
