---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-3
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Problem Statement"]
chunk_type: prose
tokens: 154
summary: "Problem Statement"
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
