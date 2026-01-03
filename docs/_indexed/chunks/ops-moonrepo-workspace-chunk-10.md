---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-10
heading_path: [".moon/workspace.{pkl,yml}", "`pipeline`"]
chunk_type: code
tokens: 126
summary: "`pipeline`"
---

## `pipeline`

Configures aspects of task running and the action pipeline.

### `cacheLifetime`

The maximum lifetime of cached artifacts before they're marked as stale and automatically removed by the action pipeline. Defaults to "7 days". This field requires an integer and a timeframe unit that can be [parsed as a duration](https://docs.rs/humantime/2.1.0/humantime/fn.parse_duration.html).

.moon/workspace.yml

```yaml
pipeline:
  cacheLifetime: '24 hours'
```

### `inheritColorsForPipedTasks`

Force colors to be inherited from the current terminal for all tasks that are ran as a child process and their output is piped to the action pipeline. Defaults to `true`.

.moon/workspace.yml

```yaml
pipeline:
  inheritColorsForPipedTasks: true
```
