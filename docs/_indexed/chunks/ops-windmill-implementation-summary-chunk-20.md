---
doc_id: ops/windmill/implementation-summary
chunk_id: ops/windmill/implementation-summary#chunk-20
heading_path: ["Documentation Indexing Implementation Summary", "Get all entities in category \"flows\""]
chunk_type: prose
tokens: 31
summary: "Get all entities in category \"flows\""
---

## Get all entities in category "flows"
flow_entities = [
    k for k, v in index['entity_index'].items()
    if 'flows' in v['tags']
]

print(f"Flow features: {flow_entities}")
