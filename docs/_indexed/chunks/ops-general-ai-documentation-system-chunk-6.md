---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-6
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "CLI Tool Specification: `docnav`"]
chunk_type: code
tokens: 874
summary: "CLI Tool Specification: `docnav`"
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
```text
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
```text
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
