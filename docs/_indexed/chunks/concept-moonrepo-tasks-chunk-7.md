---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-7
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`taskOptions` (v1.20.0)"]
chunk_type: prose
tokens: 120
summary: "`taskOptions` (v1.20.0)"
---

## `taskOptions` (v1.20.0)

> For more information on task options, refer to the [`options`](/docs/config/project#options) section in the [`moon.yml`](/docs/config/project) doc.

Like [tasks](#tasks), this setting allows you to define task options that will be inherited by *all tasks* within the configured file, and by all project-level inherited tasks. This setting is the 1st link in the inheritance chain, and can be overridden within each task.

.moon/tasks.yml

```yaml
taskOptions:
  # Never cache builds
  cache: false
  # Always re-run flaky tests
  retryCount: 2

tasks:
  build:
    # ...
    options:
      # Override the default cache setting
      cache: true
```
