---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-4
heading_path: ["Windmill Documentation Indexing System", "Index Structure"]
chunk_type: prose
tokens: 145
summary: "Index Structure"
---

## Index Structure

### Files Created

1. **`docs/windmill/DOCUMENTATION_INDEX.xml`**
   - XML-based master index
   - Entity definitions with relationships
   - DAG structure (nodes and edges)
   - Search index for fast lookup
   - RAG chunks with DAG context

2. **`docs/windmill/INDEXED_KNOWLEDGE.json`**
   - JSON format for programmatic access
   - DAG nodes and edges
   - Document metadata
   - Entity index with related entities
   - RAG chunks with enhanced context

3. **Document-level XML metadata**
   - Each markdown file now includes XML header with:
     - Document type (reference, guide, tutorial)
     - Category (flows, core_concepts, cli, sdk, deployment)
     - Difficulty level (beginner, intermediate, advanced)
     - Estimated reading time
     - Sections and features
     - Dependencies and related entities
     - Tags for search
