---
doc_id: tutorial/flows/22-while-loops
chunk_id: tutorial/flows/22-while-loops#chunk-4
heading_path: ["While loops", "Squash"]
chunk_type: prose
tokens: 94
summary: "Squash"
---

## Squash

If set to `true`, all iterations will be run on the same worker.
In addition, for supported languages ([TypeScript](./meta-1_typescript_quickstart-index.md) and [Python](./meta-2_python_quickstart-index.md)), a single runner per step will be used for the entire loop, eliminating cold starts between iterations.
We use the same logic as for [Dedicated workers](./meta-25_dedicated_workers-index.md), but the worker is only "dedicated" to the flow steps for the duration of the loop.

Squashing cannot be used in combination with parallelization.
