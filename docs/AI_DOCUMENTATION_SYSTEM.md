# Documentation System (AI + Human)

How we design documentation for both AI agents and humans to consume efficiently.

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

When adding docs, optimize for **both humans and AI agents**:

1. **Write clearly**: Short, concrete, linked
2. **Structure for scanning**: Headings, tables, code blocks
3. **Cross-reference**: Link to 2-3 related docs
4. **Stay focused**: One topic per doc, under 1500 words
5. **Be complete**: Full answer in one place

This helps:
- **Humans**: Quickly find what they need, follow links to related topics
- **AI agents**: Navigate by following doc links, understand context through links

## Indexing

Automatic via:
- `docs/_indexed/chunks/` - Chunked content for AI search
- `docs/_indexed/docs/` - Full documents for context
- `docs/_indexed/INDEX.json` - Searchable index (load only when needed)

Run indexing: (commands in AGENTS.md)

## Examples of AI+Human Optimized Docs

See: 
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture for humans, links for AI
- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md) - Commands for humans, structure for AI
- [FATSECRET_OAUTH_SETUP.md](FATSECRET_OAUTH_SETUP.md) - Steps for humans, context links for AI
