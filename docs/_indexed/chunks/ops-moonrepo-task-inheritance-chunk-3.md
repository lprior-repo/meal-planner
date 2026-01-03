---
doc_id: ops/moonrepo/task-inheritance
chunk_id: ops/moonrepo/task-inheritance#chunk-3
heading_path: ["Task inheritance", "Merge strategies"]
chunk_type: prose
tokens: 276
summary: "Merge strategies"
---

## Merge strategies

When a [global task](/docs/config/tasks#tasks) and [local task](/docs/config/project#tasks) of the same name exist, they are merged into a single task. To accomplish this, one of many [merge strategies](/docs/config/project#options) can be used.

Merging is applied to the parameters [`args`](/docs/config/project#args), [`deps`](/docs/config/project#deps), [`env`](/docs/config/project#env-1), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), using the [`merge`](/docs/config/project#merge), [`mergeArgs`](/docs/config/project#mergeargs), [`mergeDeps`](/docs/config/project#mergedeps), [`mergeEnv`](/docs/config/project#mergeenv), [`mergeInputs`](/docs/config/project#mergeinputs) and [`mergeOutputs`](/docs/config/project#mergeoutputs) options respectively. Each of these options support one of the following strategy values.

-   `append` (default) - Values found in the local task are merged *after* the values found in the global task. For example, this strategy is useful for toggling flag arguments.
-   `prepend` - Values found in the local task are merged *before* the values found in the global task. For example, this strategy is useful for applying option arguments that must come before positional arguments.
-   `preserve` - Preserve the original global task values. This should rarely be used, but exists for situations where an inheritance chain is super long and complex, but we simply want to the base values. (v1.29.0)
-   `replace` - Values found in the local task entirely *replaces* the values in the global task. This strategy is useful when you need full control.

All 3 of these strategies are demonstrated below, with a somewhat contrived example, but you get the point.

```yaml
