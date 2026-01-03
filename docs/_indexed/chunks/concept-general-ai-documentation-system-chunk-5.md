---
doc_id: concept/general/ai-documentation-system
chunk_id: concept/general/ai-documentation-system#chunk-5
heading_path: ["Documentation System (AI + Human)", "Research: Best Practices"]
chunk_type: prose
tokens: 119
summary: "Research: Best Practices"
---

## Research: Best Practices

| Technique | Benefit | Used By |
|-----------|---------|---------|
| Contextual prefixes | 35% better retrieval | Anthropic, Google |
| Hierarchical chunking | Multi-level navigation | LlamaIndex |
| Hybrid search (semantic + keyword) | Catches concepts AND exact matches | Everyone |
| Metadata tagging | Structured filtering | Pinecone, Weaviate |
| Reranking | Better top-K selection | Cohere, Anthropic |

**Key insight**: Prepend 50-100 tokens of context to each chunk before embedding. Results in 67% fewer retrieval failures with reranking.

Source: [Anthropic Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
