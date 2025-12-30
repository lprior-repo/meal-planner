---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-5
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Proposed Architecture"]
chunk_type: prose
tokens: 260
summary: "Proposed Architecture"
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
```yaml

---
