---
doc_id: meta/25_dedicated_workers/index
chunk_id: meta/25_dedicated_workers/index#chunk-3
heading_path: ["Dedicated workers / High throughput", "Dedicated workers for flows"]
chunk_type: prose
tokens: 104
summary: "Dedicated workers for flows"
---

## Dedicated workers for flows

Dedicated workers can also be assigned to a flow. In that case, the dedicated worker will start one runner for each flow step that supports it ([TypeScript](./meta-1_typescript_quickstart-index.md) and [Python](./meta-2_python_quickstart-index.md)), eliminating cold start between each execution.
Other steps will be run on the same worker but without any optimization.

To enable it, the process is the same as for scripts, but the "Dedicated Workers" option for that flow has to be enabled in the [flow Settings](./tutorial-flows-3-editor-components.md#settings).
