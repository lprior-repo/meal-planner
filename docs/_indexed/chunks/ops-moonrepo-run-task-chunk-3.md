---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-3
heading_path: ["Run a task", "Running dependents"]
chunk_type: prose
tokens: 109
summary: "Running dependents"
---

## Running dependents

moon will *always* run upstream dependencies (`deps`) before running the primary target, as their outputs may be required for the primary target to function correctly.

However, if you're working on a project that is shared and consumed by other projects, you may want to verify that downstream dependents have not been indirectly broken by any changes. This can be achieved by passing the `--dependents` option, which will run dependent targets *after* the primary target.

```
$ moon run app:build --dependents
```
