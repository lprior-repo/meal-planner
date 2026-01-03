---
doc_id: ops/moonrepo/ci
chunk_id: ops/moonrepo/ci#chunk-12
heading_path: ["ci", "..."]
chunk_type: prose
tokens: 32
summary: "..."
---

## ...
steps:
  - label: 'CI'
    parallelism: 10
    commands:
      # ...
      - 'moon ci --job $$BUILDKITE_PARALLEL_JOB --jobTotal $$BUILDKITE_PARALLEL_JOB_COUNT'
```

- [Documentation](https://buildkite.com/docs/tutorials/parallel-builds#parallel-jobs)

### CircleCI

.circleci/config.yml

```yaml
