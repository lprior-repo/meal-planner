---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-11
heading_path: ["Recipe Import Pipeline", "Open Questions"]
chunk_type: prose
tokens: 247
summary: "Open Questions"
---

## Open Questions

### 1. Windmill Script vs Binary

**Option A: Windmill Scripts (current pattern)**
- Self-contained Rust with inline `cargo` deps
- Compiled by Windmill on first run
- Example: `windmill/f/tandoor/test_connection.rs`

**Option B: Compiled Binaries**
- Built via Dagger, deployed to worker container
- Called from Windmill bash scripts
- More control, faster execution

**Recommendation:** Start with Windmill scripts (simpler), migrate to binaries if performance matters.

### 2. Keyword Handling

Tandoor keywords must exist before assigning to recipes. Options:

**Option A: Create-if-missing (simpler)**
- Binary checks if keyword exists, creates if not
- Single API call pattern

**Option B: Separate step (more CUPID)**
- `tandoor_ensure_keywords` binary creates missing keywords
- `tandoor_create_recipe` assumes keywords exist

**Recommendation:** Option A for simplicity.

### 3. Auto-Tagging Rules

Source-based tagging from URL domain:
```text
meatchurch.com → meat-church
seriouseats.com → serious-eats
bonappetit.com → bon-appetit
```

Content-based tagging (future):
- Parse instructions for keywords: "smoker", "grill", "slow cooker"
- Tag accordingly: `#smoking`, `#grilling`, `#slow-cooker`

### 4. Error Handling

If scraping succeeds but creation fails:
- **Fail fast:** Return error, require re-scrape
- **Partial success:** Return scraped data for manual retry

**Recommendation:** Fail fast. Scraping is idempotent.
