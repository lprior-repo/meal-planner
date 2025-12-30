# AI-Optimized Documentation System: Complete Design Document

## Executive Summary

This document outlines a comprehensive system for transforming documentation into an AI-agent-optimized format. The system combines deterministic CLI tooling with AI coordination to create self-navigating documentation where each chunk contains enough context and links for an AI agent to "follow the thread" without loading expensive index files.

**Key Insight**: The best AI documentation systems (Anthropic, LlamaIndex, OpenAI) all solve the same problem: **chunks lose context when split**. Our solution embeds navigation and context directly into each chunk.

---

## Problem Statement

### Current Pain Points

When an AI agent reads a documentation chunk, it faces these issues:

1. **Dead Ends**: Chunk ends, no indication of where to go next
2. **Lost Context**: "The company's revenue grew 3%" - which company? when?
3. **Expensive Discovery**: To find related content, must load INDEX.json (110K tokens) or COMPASS.md (8K tokens)
4. **Guessing Game**: `ls docs/_indexed/chunks/*oauth*` returns 9 files - which one has what's needed?

### The Goal

Each chunk should be **self-contained for navigation**:
- Know what document it belongs to and where it sits
- Link to prev/next chunks in sequence
- Link to related chunks by topic
- Cost ~200 tokens total (170 content + 30 navigation)

---

## Research: What the Best Do

### 1. Anthropic's Contextual Retrieval (Sep 2024)

**The breakthrough**: Prepend 50-100 tokens of context to each chunk before embedding.

```yaml
Original: "The company's revenue grew by 3% over the previous quarter."

Contextualized: "This chunk is from an SEC filing on ACME corp's performance 
in Q2 2023; the previous quarter's revenue was $314 million. The company's 
revenue grew by 3% over the previous quarter."
```

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

## Proposed Architecture

### Design Philosophy

**AI + Deterministic CLI** is the optimal architecture:

| Component | Handles | Why |
|-----------|---------|-----|
| **CLI Tool** | Fast, repeatable operations | Debuggable, composable, scriptable |
| **AI Coordination** | Quality decisions, relationship evaluation | Judgment calls, context understanding |

This is better than:
- Pure Python script (can't iterate/inspect intermediate results)
- Pure AI generation (slow, expensive, non-deterministic)
- Manual curation (doesn't scale)

### System Components

```text
┌─────────────────────────────────────────────────────────────────┐
│                        AI COORDINATOR                           │
│  (Claude/GPT analyzing outputs, making decisions, orchestrating)│
└─────────────────────┬───────────────────────────────────────────┘
                      │ Calls CLI, reviews output, adjusts params
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      docnav CLI TOOL                            │
├─────────────────────────────────────────────────────────────────┤
│  docnav analyze    → Extract relationships, build graph         │
│  docnav context    → Add contextual prefixes to chunks          │
│  docnav link       → Add navigation footers to chunks           │
│  docnav validate   → Check link integrity, find orphans         │
│  docnav stats      → Coverage metrics, quality scores           │
│  docnav repair     → Fix broken links, update stale refs        │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    docs/_indexed/chunks/                        │
│  Each chunk now has:                                            │
│  - Contextual prefix (50-80 tokens)                             │
│  - Navigation footer (20-40 tokens)                             │
│  - Self-contained for AI consumption                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## CLI Tool Specification: `docnav`

### Subcommands Overview

```bash
docnav analyze [OPTIONS]     # Build relationship graph
docnav context [OPTIONS]     # Add contextual prefixes
docnav link [OPTIONS]        # Add navigation footers
docnav validate [OPTIONS]    # Check integrity
docnav stats [OPTIONS]       # Coverage metrics
docnav repair [OPTIONS]      # Fix issues
```text

### Detailed Subcommand Specifications

#### `docnav analyze`

**Purpose**: Analyze all chunks, extract relationships, build a graph.

```bash
docnav analyze \
  --chunks-dir docs/_indexed/chunks \
  --manifest docs/_indexed/chunks_manifest.json \
  --output relations.json \
  [--use-semantic]           # Also use codanna for semantic similarity
  [--semantic-top-k 5]       # Top K semantic matches per chunk
```text

**Output** (`relations.json`):
```json
{
  "generated_at": "2025-12-30T10:00:00Z",
  "chunks": [
    {
      "id": "tutorial-flows-11-flow-approval-chunk-3",
      "doc_id": "tutorial/flows/11-flow-approval",
      "heading_path": ["Suspend & Approval", "Resume Form"],
      "tags": ["tutorial", "flows", "approval", "suspend", "resume"],
      "keywords": ["resume_form", "schema", "verifier"],
      "sequence": {
        "prev": "tutorial-flows-11-flow-approval-chunk-2",
        "next": "tutorial-flows-11-flow-approval-chunk-4"
      },
      "related": {
        "by_tag": [
          {"id": "tutorial-windmill-flows-guide-chunk-12", "shared_tags": 3, "tags": ["flows", "approval", "tutorial"]},
          {"id": "concept-flows-10-flow-trigger-chunk-1", "shared_tags": 2, "tags": ["flows", "tutorial"]}
        ],
        "by_keyword": [
          {"id": "ref-flows-input-transforms-chunk-2", "shared_keywords": ["schema"], "score": 0.8}
        ],
        "by_semantic": [
          {"id": "tutorial-windmill-flows-guide-chunk-5", "score": 0.89, "reason": "OAuth approval pattern"}
        ]
      }
    }
  ],
  "stats": {
    "total_chunks": 1532,
    "avg_related_by_tag": 3.2,
    "orphan_chunks": 12,
    "hub_chunks": ["meta-core_concepts-index-chunk-1", "tutorial-windmill-intro-chunk-1"]
  }
}
```text

#### `docnav context`

**Purpose**: Add contextual prefix to each chunk.

```bash
docnav context \
  --chunks-dir docs/_indexed/chunks \
  --manifest docs/_indexed/chunks_manifest.json \
  --relations relations.json \
  [--template default|minimal|detailed] \
  [--use-llm]                # Use Claude for better context (costs $)
  [--dry-run]                # Show what would change
```text

**Template options**:

**Minimal** (~30 tokens):
```markdown
> **Context**: {doc_title} > {heading_path}. Tags: {tags}.
```text

**Default** (~50 tokens):
```markdown
> **Context**: This chunk covers "{current_heading}" in {doc_title}. 
> {prev_context}Part of: {category}. Tags: {tags}.
```text

**Detailed** (~80 tokens):
```markdown
> **Context**: This chunk explains {current_heading} in the {doc_title} documentation.
> {It follows {prev_heading} which covered {prev_topic}. | This is the first section.}
> Key concepts: {keywords}. Category: {category}. Difficulty: {difficulty}.
```bash

**LLM-generated** (best quality, ~$0.001 per chunk):
```markdown
> **Context**: This chunk describes how to configure resume forms in Windmill 
> approval flows. Resume forms let suspended flows collect user input (like OAuth 
> verifier codes) before continuing. This builds on the basic suspend mechanism 
> from the previous section.
```text

#### `docnav link`

**Purpose**: Add navigation footer to each chunk.

```bash
docnav link \
  --chunks-dir docs/_indexed/chunks \
  --relations relations.json \
  [--min-shared-tags 2]      # Minimum tags to consider "related"
  [--max-related 4]          # Maximum related links per chunk
  [--include-semantic]       # Include semantic matches
  [--dry-run]
```text

**Output format** (appended to each chunk):
```markdown
---
<!-- docnav:v1 generated:2025-12-30 -->
**Sequence**: [← Suspend Mechanism](./tutorial-flows-11-flow-approval-chunk-2.md) | [Resume Payload →](./tutorial-flows-11-flow-approval-chunk-4.md)
**Related**: [OAuth Flow Pattern](./tutorial-windmill-flows-guide-chunk-12.md) | [Input Transforms](./ref-flows-input-transforms-chunk-2.md) | [Flow Triggers](./concept-flows-10-flow-trigger-chunk-1.md)
**Parent**: [Suspend & Approval / Prompts](./tutorial-flows-11-flow-approval.md)
```text

#### `docnav validate`

**Purpose**: Check link integrity, find issues.

```bash
docnav validate \
  --chunks-dir docs/_indexed/chunks \
  [--fix]                    # Auto-fix simple issues
  [--output validation.json]
```text

**Checks**:
- All links resolve to existing files
- No circular references in sequence links
- All chunks have at least prev OR next (except first/last)
- No orphan chunks (0 incoming links)
- Context prefix exists and is well-formed

**Output**:
```
Validation Report
=================
✓ 1520/1532 chunks valid
✗ 12 issues found:

BROKEN_LINK (3):
  - tutorial-flows-11-flow-approval-chunk-3.md:45 → concept-flows-xyz.md (not found)
  
ORPHAN (5):
  - meta-changelog-chunk-12.md (0 incoming links)
  
MISSING_CONTEXT (4):
  - concept-3_cli-app-chunk-1.md (no context prefix)
```text

#### `docnav stats`

**Purpose**: Show coverage and quality metrics.

```bash
docnav stats \
  --chunks-dir docs/_indexed/chunks \
  --relations relations.json
```text

**Output**:
```
Documentation Navigation Stats
==============================
Total chunks:           1,532
With context prefix:    1,528 (99.7%)
With sequence links:    1,520 (99.2%)
With related links:     1,489 (97.2%)
Avg related per chunk:  3.2

Quality Scores:
  Fully linked (A):     1,450 (94.6%)
  Partial (B):          70 (4.6%)
  Orphans (F):          12 (0.8%)

Hub Documents (most referenced):
  1. meta-core_concepts-index-chunk-1 (234 incoming)
  2. tutorial-windmill-intro-chunk-1 (189 incoming)
  3. concept-flows-11-flow-approval-chunk-1 (156 incoming)

Clusters Detected:
  - "flows" cluster: 245 chunks
  - "cli" cluster: 89 chunks
  - "tandoor" cluster: 67 chunks
```text

#### `docnav repair`

**Purpose**: Fix common issues automatically.

```bash
docnav repair \
  --chunks-dir docs/_indexed/chunks \
  --relations relations.json \
  [--broken-links]           # Remove or update broken links
  [--orphans]                # Add links TO orphan chunks from related
  [--stale-context]          # Regenerate context for chunks with stale info
  [--dry-run]
```yaml

---

## AI Coordination Workflows

### Workflow 1: Initial Setup (One-time)

```
AI: "Let me set up documentation navigation for this repo."

1. Run: docnav analyze --output relations.json
2. Review: Check relations.json for quality
   - Are tag matches sensible?
   - Any obvious misses?
3. Run: docnav stats
   - Check orphan count
   - Identify hub documents
4. Decide: Template vs LLM for context
   - Small corpus (<500 chunks): LLM is fine
   - Large corpus: Use template
5. Run: docnav context --template default
6. Run: docnav link --min-shared-tags 2 --max-related 4
7. Run: docnav validate
8. Fix: Any issues found
9. Run: docnav stats (verify improvement)
```text

### Workflow 2: After New Docs Added (Incremental)

```
AI: "New docs were added, let me update navigation."

1. Run: docnav analyze --incremental --output relations.json
2. Run: docnav context --incremental
3. Run: docnav link --incremental
4. Run: docnav validate
5. Fix: Any new issues
```text

### Workflow 3: Quality Review (Periodic)

```
AI: "Let me check documentation navigation quality."

1. Run: docnav stats
2. Review: 
   - Orphan count trending up?
   - Any clusters under-linked?
3. Run: docnav validate
4. If issues:
   - docnav repair --broken-links --dry-run
   - Review proposed fixes
   - docnav repair --broken-links (apply)
```text

### Workflow 4: Interactive Linking (AI Judgment)

For ambiguous cases where the CLI can't decide:

```
AI runs: docnav link --interactive --output decisions_needed.json

decisions_needed.json:
{
  "ambiguous": [
    {
      "chunk": "concept-flows-13-flow-branches-chunk-2",
      "candidates": [
        {"id": "concept-flows-12-flow-loops-chunk-1", "score": 0.45, "reason": "1 shared tag, keyword 'iteration'"},
        {"id": "tutorial-flows-11-flow-approval-chunk-3", "score": 0.42, "reason": "2 shared tags but different topic"}
      ],
      "question": "Include loop-related link for branches chunk?"
    }
  ]
}

AI reviews, makes decision, updates config:
docnav link --decisions decisions_resolved.json
```yaml

---

## Integration Options

### Option A: Standalone Tool (`docnav`)

**Pros**:
- Clean separation of concerns
- Can be used on any doc corpus
- Easy to test independently

**Cons**:
- Another tool to maintain
- Must run after `doc_transformer.py`

**Location**: `scripts/docnav.py` or `scripts/docnav/` (multi-file)

### Option B: Extend `doc_transformer.py`

**Pros**:
- Single tool for all doc processing
- Runs as part of existing pipeline

**Cons**:
- Makes transformer more complex
- Harder to run navigation independently

**Implementation**: Add Step 5.5 (Analyze), Step 5.6 (Context), Step 5.7 (Link)

### Option C: Hybrid (Recommended)

**doc_transformer.py** handles: Discovery → Analyze → Transform → Chunk → Index
**docnav** handles: Context → Link → Validate → Repair

Run sequence:
```bash
python doc_transformer.py
python docnav.py context
python docnav.py link
python docnav.py validate
```yaml

---

## Implementation Considerations

### Language Choice

| Language | Pros | Cons |
|----------|------|------|
| **Python** | Matches transformer, easy JSON, rich ecosystem | Slower for large corpora |
| **Rust** | Fast, matches codebase style, great CLI libs | More code for same functionality |

**Recommendation**: Python for v1 (faster to iterate), Rust for v2 if performance matters.

### Semantic Search Integration

```bash
# Option 1: Shell out to codanna
docnav analyze --use-semantic
# Internally calls: codanna documents search "chunk content" --top-k 5

# Option 2: Direct embedding comparison
# Requires: fastembed or sentence-transformers
# Builds local embedding index, compares vectors
```text

**Recommendation**: Start with tag-based only, add semantic as optional enhancement.

### Cost Estimates (for LLM context generation)

| Corpus Size | Chunks (est.) | Claude Haiku Cost | Time |
|-------------|---------------|-------------------|------|
| 200 docs | ~1,500 chunks | ~$1.50 | ~10 min |
| 1,000 docs | ~7,500 chunks | ~$7.50 | ~50 min |
| 10,000 docs | ~75,000 chunks | ~$75 | ~8 hours |

Template-based context: $0, ~30 seconds for any size.

---

## Chunk Output Format (Final)

### Before (Current)
```markdown
---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-3
heading_path: ["Suspend & Approval", "Resume Form"]
chunk_type: prose
tokens: 156
summary: "Resume Form configuration..."
---

## Resume Form

The `resume_form` schema defines...
```text

### After (With Navigation)
```markdown
---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-3
heading_path: ["Suspend & Approval", "Resume Form"]
chunk_type: prose
tokens: 203
summary: "Resume Form configuration..."
---

> **Context**: This chunk explains resume form configuration in Windmill approval flows. 
> Resume forms collect user input (like OAuth verifiers) when flows are suspended. 
> Continues from "Suspend Mechanism". Part of: tutorial/flows.

## Resume Form

The `resume_form` schema defines...

---
<!-- docnav:v1 -->
**Sequence**: [← Suspend Mechanism](./tutorial-flows-11-flow-approval-chunk-2.md) | [Resume Payload →](./tutorial-flows-11-flow-approval-chunk-4.md)
**Related**: [OAuth Flow Pattern](./tutorial-windmill-flows-guide-chunk-12.md) | [Input Transforms](./ref-flows-input-transforms-chunk-2.md)
**Parent**: [Full Document](../docs/tutorial-flows-11-flow-approval.md)
```

**Token overhead**: ~50 tokens (context: ~35, navigation: ~15)
**Total per chunk**: ~200-220 tokens average

---

## Success Metrics

### Quantitative
- **Coverage**: >95% chunks have context + navigation
- **Link validity**: 100% links resolve
- **Orphan rate**: <2% chunks with no incoming links
- **Token efficiency**: <250 tokens per chunk average

### Qualitative (AI Agent Experience)
- Can follow any topic thread without loading index files
- Related links are actually relevant (spot check)
- Context prefix answers "what is this about?" instantly
- Navigation is predictable (always same format, same location)

---

## Open Questions for Future Discussion

1. **Template vs LLM for context?**
   - Template: Free, fast, consistent, but generic
   - LLM: Costs ~$1.50 for your corpus, but much better context
   - Hybrid: Template for most, LLM for "hub" documents?

2. **How many related links per chunk?**
   - 2-3: Cleaner, more focused
   - 4-5: More options, but potentially noisy
   - Dynamic: Based on confidence scores?

3. **Semantic search integration priority?**
   - V1: Tag-based only (simpler, faster)
   - V1.5: Add semantic as optional flag
   - V2: Semantic by default with tag fallback

4. **Interactive mode scope?**
   - Minimal: AI just runs commands
   - Medium: AI reviews stats, adjusts params
   - Full: AI makes per-chunk decisions for ambiguous cases

5. **Integration with codanna indexing?**
   - Run docnav before or after `codanna documents index`?
   - Should navigation links be visible to semantic search?

6. **Update strategy for existing corpus?**
   - Full regeneration (clean but slow)
   - Incremental (fast but may miss cross-chunk updates)
   - Hybrid (incremental + periodic full refresh)

---

## Next Steps (When Ready to Implement)

1. **Decide** on open questions above
2. **Create** `scripts/docnav.py` with basic structure
3. **Implement** `analyze` subcommand first (foundational)
4. **Test** on current corpus, review relations.json
5. **Implement** `context` with template approach
6. **Implement** `link` subcommand
7. **Implement** `validate` and `stats`
8. **Run** full workflow on docs/_indexed/chunks
9. **Verify** AI agent experience improved
10. **Document** in AGENTS.md how to use

---

## Summary

This system transforms documentation from "chunks with dead ends" to "self-navigating knowledge graph". Each chunk becomes a node that knows:
- Where it came from (context)
- Where to go next (sequence)
- What's related (links)

The AI+CLI architecture means:
- Deterministic, fast operations handled by CLI
- Quality judgments and orchestration handled by AI
- Iterative refinement through multiple passes
- Full auditability of what changed and why

**Estimated effort**: 
- V1 (tag-based, template context): 2-4 hours
- V1.5 (add semantic, LLM context option): +2-3 hours
- V2 (interactive mode, repair, full validation): +4-6 hours
