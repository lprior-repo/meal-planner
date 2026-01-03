---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-3
heading_path: ["Continuous integration (CI)", "Configuring tasks"]
chunk_type: prose
tokens: 135
summary: "Configuring tasks"
---

## Configuring tasks

By default, *all tasks* run in CI, as you should always be building, linting, typechecking, testing, so on and so forth. However, this isn't always true, so this can be disabled on a per-task basis through the [`runInCI`](/docs/config/project#runinci) or [`local`](/docs/config/project#local) options.

```yaml
tasks:
  dev:
    command: 'webpack server'
    options:
      runInCI: false
    # Or
    local: true
```

> **Caution**: This option *must* be set to false for tasks that spawn a long-running or never-ending process, like HTTP or development servers. To help mitigate this, tasks named `dev`, `start`, or `serve` are false by default. This can be easily controlled with the [`local`](/docs/config/project#local) setting.
