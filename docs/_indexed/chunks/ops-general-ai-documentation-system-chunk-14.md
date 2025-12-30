---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-14
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Builds local embedding index, compares vectors"]
chunk_type: prose
tokens: 109
summary: "Builds local embedding index, compares vectors"
---

## Builds local embedding index, compares vectors
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
