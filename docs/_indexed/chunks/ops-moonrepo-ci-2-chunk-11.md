---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-11
heading_path: ["Continuous integration (CI)", "..."]
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
