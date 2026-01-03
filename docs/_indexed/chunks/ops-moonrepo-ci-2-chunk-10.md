---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-10
heading_path: ["Continuous integration (CI)", "Parallelizing tasks"]
chunk_type: prose
tokens: 113
summary: "Parallelizing tasks"
---

## Parallelizing tasks

If your CI environment supports sharding across multiple jobs, then you can utilize moon's built in parallelism by passing `--jobTotal` and `--job` options. The `--jobTotal` option is an integer of the total number of jobs available, and `--job` is the current index (0 based) amongst the total.

When these options are passed, moon will only run affected [targets](/docs/concepts/target) based on the current job slice.

### GitHub Actions

GitHub Actions do not support native parallelism, but it can be emulated using its matrix.

.github/workflows/ci.yml

```yaml
