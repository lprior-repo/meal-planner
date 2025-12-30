---
doc_id: ops/windmill/implementation-summary
chunk_id: ops/windmill/implementation-summary#chunk-19
heading_path: ["Documentation Indexing Implementation Summary", "Load index"]
chunk_type: prose
tokens: 13
summary: "Load index"
---

## Load index
with open('docs/windmill/INDEXED_KNOWLEDGE.json') as f:
    index = json.load(f)
