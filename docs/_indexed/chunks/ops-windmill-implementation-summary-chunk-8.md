---
doc_id: ops/windmill/implementation-summary
chunk_id: ops/windmill/implementation-summary#chunk-8
heading_path: ["Documentation Indexing Implementation Summary", "When retrieving chunks, include DAG context"]
chunk_type: prose
tokens: 23
summary: "When retrieving chunks, include DAG context"
---

## When retrieving chunks, include DAG context
chunk = retrieve_chunk("windmill_retries_constant")
context = chunk.dag_context  # {prerequisites: [], dependents: [...]}
