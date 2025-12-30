---
doc_id: ops/guides/ci
chunk_id: ops/guides/ci#chunk-12
heading_path: ["Continuous integration (CI)", "..."]
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
