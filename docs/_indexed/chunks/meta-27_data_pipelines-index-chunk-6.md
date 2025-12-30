---
doc_id: meta/27_data_pipelines/index
chunk_id: meta/27_data_pipelines/index#chunk-6
heading_path: ["Data pipelines", "Limit of the number of executions per second"]
chunk_type: prose
tokens: 57
summary: "Limit of the number of executions per second"
---

## Limit of the number of executions per second

Windmill's core is its queue of jobs which is implemented in Postgres using the `UPDATE SKIP LOCKED` pattern. It can scale comfortably to 5k requests per second (RPS) on a normal Postgres database during benchmarks.
