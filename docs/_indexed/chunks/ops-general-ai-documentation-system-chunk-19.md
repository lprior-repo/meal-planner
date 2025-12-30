---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-19
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Open Questions for Future Discussion"]
chunk_type: prose
tokens: 217
summary: "Open Questions for Future Discussion"
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
