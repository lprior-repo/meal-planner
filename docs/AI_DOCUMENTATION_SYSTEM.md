# Documentation for AI

How we optimize documentation for AI agents.

## The Problem

When AI reads a doc chunk, it faces:
- No context about which doc this is
- No links to next/previous chunks
- No indication of related topics
- Expensive discovery (load 110K token INDEX file)

## The Solution

**Self-contained navigation**: Each chunk knows:
- What document it belongs to
- Previous/next chunks in sequence
- Related chunks by topic
- How to find them efficiently

## Current System

- **Directory**: `docs/_indexed/`
- **Chunks**: `docs/_indexed/chunks/` (170 tokens each)
- **Navigation**: Links embedded in each chunk
- **Index**: `docs/_indexed/INDEX.json` (only load when needed)
- **Discovery**: Use CodeAnna semantic search first

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

## How We Use It

1. **Search by topic** → Use CodeAnna semantic search
2. **Read a chunk** → Follow embedded links to related chunks
3. **Go deeper** → Links tell you which chunks are next
4. **Find fast** → Metadata filters narrow search space

## Building Documentation

When adding docs:

1. Write naturally (Stripe-style: short, clear, linked)
2. Use consistent heading levels
3. Link to related docs with Markdown links
4. Categorize with tags: `tutorial-*`, `concept-*`, `ref-*`, `ops-*`, `meta-*`
5. Keep chunks ~200 tokens (prevents bloat, aids navigation)

## Indexing

Automatic via:
- `docs/_indexed/chunks/` - Chunked content
- `docs/_indexed/docs/` - Full documents
- `docs/_indexed/INDEX.json` - Searchable index (load only when needed)

Run indexing: (commands in AGENTS.md)

## Stripe-Quality Checklist

- [ ] **Short**: Under 1500 words
- [ ] **Focused**: One topic, clear purpose
- [ ] **Linked**: Cross-references to related docs
- [ ] **Scannable**: Headings, tables, code blocks
- [ ] **Complete**: Answer the question fully in one place
- [ ] **Actionable**: Clear next steps or "see also"

See: [ARCHITECTURE.md](ARCHITECTURE.md), [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md), [FATSECRET_OAUTH_SETUP.md](FATSECRET_OAUTH_SETUP.md) for examples
