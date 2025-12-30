---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-19
heading_path: ["Windmill Documentation Indexing System", "When retrieving chunks, include DAG context:"]
chunk_type: prose
tokens: 23
summary: "When retrieving chunks, include DAG context:"
---

## When retrieving chunks, include DAG context:

chunk = retrieve_chunk("windmill_retries_constant")
context = chunk.dag_context  # {prerequisites: [], dependents: [...]}
