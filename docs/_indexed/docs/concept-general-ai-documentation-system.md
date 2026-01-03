---
id: concept/general/ai-documentation-system
title: "Documentation System (AI + Human)"
category: concept
tags: ["documentation", "concept"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>core</category>
  <title>Documentation System (AI + Human)</title>
  <description>How we design documentation for both AI agents and humans to consume efficiently.</description>
  <created_at>2026-01-02T19:55:26.815511</created_at>
  <updated_at>2026-01-02T19:55:26.815511</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="The Problem" level="2"/>
    <section name="The Solution" level="2"/>
    <section name="Current System" level="2"/>
    <section name="Research: Best Practices" level="2"/>
    <section name="How We Use It" level="2"/>
    <section name="Building Documentation" level="2"/>
    <section name="Indexing" level="2"/>
    <section name="Examples of AI+Human Optimized Docs" level="2"/>
  </sections>
  <features>
    <feature>building_documentation</feature>
    <feature>current_system</feature>
    <feature>examples_of_aihuman_optimized_docs</feature>
    <feature>how_we_use_it</feature>
    <feature>indexing</feature>
    <feature>research_best_practices</feature>
    <feature>the_problem</feature>
    <feature>the_solution</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/general/architecture</dependency>
    <dependency type="feature">ops/general/moon-ci-pipeline</dependency>
    <dependency type="feature">tutorial/general/fatsecret-oauth-setup</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">ARCHITECTURE.md</entity>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
    <entity relationship="uses">FATSECRET_OAUTH_SETUP.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>documentation,concept</tags>
</doc_metadata>
-->

# Documentation System (AI + Human)

> **Context**: How we design documentation for both AI agents and humans to consume efficiently.

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
- [ARCHITECTURE.md](./ops-general-architecture.md) - Architecture for humans, links for AI
- [MOON_CI_PIPELINE.md](./ops-general-moon-ci-pipeline.md) - Commands for humans, structure for AI
- [FATSECRET_OAUTH_SETUP.md](./tutorial-general-fatsecret-oauth-setup.md) - Steps for humans, context links for AI


## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md)
- [FATSECRET_OAUTH_SETUP.md](FATSECRET_OAUTH_SETUP.md)
