---
doc_id: ops/moonrepo/overview
chunk_id: ops/moonrepo/overview#chunk-13
heading_path: ["Overview", "Profiling (v1.26.0)"]
chunk_type: prose
tokens: 78
summary: "Profiling (v1.26.0)"
---

## Profiling (v1.26.0)

When the `--dump` option or `MOON_DUMP` environment variable is set, moon will generate a trace profile and dump it to the current working directory. This profile can be opened with Chrome (via `chrome://tracing`) or [Perfetto](https://ui.perfetto.dev/).

This profile will display many of the operations within moon as a flame chart, allowing you to inspect and debug slow operations.
