---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-3
heading_path: ["Windmill Documentation Indexing System", "Key Principles"]
chunk_type: prose
tokens: 144
summary: "Key Principles"
---

## Key Principles

### 1. XML-Based Metadata (Anthropic Best Practices)

Following Anthropic's documentation guidelines, each document includes structured XML metadata that:

- **Separates concerns**: Clearly distinguishes between content, metadata, and structure
- **Uses consistent tagging**: Standard XML tags for document attributes
- **Enables parsing**: Machine-readable metadata for automated processing
- **Provides context**: Rich metadata about dependencies, difficulty, examples, and more

### 2. DAG-Based Referencing

Documents are organized in a Directed Acyclic Graph structure showing:

- **Nodes**: Individual documents, features, tools, and concepts
- **Edges**: Relationships between documents (dependencies, prerequisites, usage patterns)
- **Layers**: Hierarchical organization from basic concepts to advanced deployment
- **Cycles prevented**: No circular dependencies ensure clear navigation paths
