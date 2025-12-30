---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-4
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Research: What the Best Do"]
chunk_type: code
tokens: 374
summary: "Research: What the Best Do"
---

## Research: What the Best Do

### 1. Anthropic's Contextual Retrieval (Sep 2024)

**The breakthrough**: Prepend 50-100 tokens of context to each chunk before embedding.

```yaml
Original: "The company's revenue grew by 3% over the previous quarter."

Contextualized: "This chunk is from an SEC filing on ACME corp's performance 
in Q2 2023; the previous quarter's revenue was $314 million. The company's 
revenue grew by 3% over the previous quarter."
```text

**Results**:
- Contextual Embeddings alone: 35% reduction in retrieval failures
- Contextual Embeddings + BM25: 49% reduction
- With reranking: 67% reduction

**Key technique**: Use Claude to generate context per chunk:
```html
<document>{{WHOLE_DOCUMENT}}</document>
<chunk>{{CHUNK_CONTENT}}</chunk>
Please give a short succinct context to situate this chunk within the 
overall document for the purposes of improving search retrieval.
```

**Cost**: ~$1.02 per million document tokens (with prompt caching)

**Source**: https://www.anthropic.com/news/contextual-retrieval

### 2. LlamaIndex Production RAG Best Practices

**Decouple retrieval from synthesis**:
- Embed document summaries → link to chunks
- Embed sentences → link to surrounding window
- Hierarchical retrieval: document-level first, then chunk-level

**Structured retrieval for scale**:
- Metadata filters + auto-retrieval
- Document hierarchies with recursive retrieval
- Combine semantic search with keyword (BM25) search

**Dynamic retrieval by task**:
- QA needs different chunks than summarization
- Router modules to select retrieval strategy

**Source**: https://docs.llamaindex.ai/en/stable/optimizing/production_rag/

### 3. Common Patterns Across Industry

| Technique | Used By | Benefit |
|-----------|---------|---------|
| Contextual prefixes | Anthropic, Google | Better retrieval accuracy |
| Hierarchical chunking | LlamaIndex, LangChain | Multi-level navigation |
| Hybrid search (semantic + keyword) | Everyone | Catches both exact matches and concepts |
| Metadata tagging | Pinecone, Weaviate, Chroma | Structured filtering |
| Reranking | Cohere, Anthropic | Better top-K selection |

---
