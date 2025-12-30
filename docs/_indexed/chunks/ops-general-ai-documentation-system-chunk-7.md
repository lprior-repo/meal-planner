---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-7
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "AI Coordination Workflows"]
chunk_type: code
tokens: 358
summary: "AI Coordination Workflows"
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
