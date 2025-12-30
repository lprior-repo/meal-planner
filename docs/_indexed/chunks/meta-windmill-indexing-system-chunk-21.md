---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-21
heading_path: ["Windmill Documentation Indexing System", "Index Maintenance"]
chunk_type: prose
tokens: 85
summary: "Index Maintenance"
---

## Index Maintenance

### Adding New Documents

1. Create document with XML metadata header
2. Add entity to `DOCUMENTATION_INDEX.xml`
3. Update DAG nodes and edges
4. Add to `INDEXED_KNOWLEDGE.json`
5. Create RAG chunks with DAG context

### Updating Relationships

1. Modify edges in DAG section
2. Update `<related_entities>` in document metadata
3. Ensure no cycles are introduced
4. Validate DAG integrity

### Regenerating Search Index

```bash
