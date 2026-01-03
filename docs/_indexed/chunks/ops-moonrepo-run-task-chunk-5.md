---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-5
heading_path: ["Run a task", "Passing arguments to the underlying command"]
chunk_type: prose
tokens: 78
summary: "Passing arguments to the underlying command"
---

## Passing arguments to the underlying command

If you'd like to pass arbitrary arguments to the underlying task command, in addition to the already defined `args`, you can pass them after `--`. These arguments are *appended as-is*.

```
$ moon run app:build -- --force
```

> The `--` delimiter and any arguments *must* be defined last on the command line.
