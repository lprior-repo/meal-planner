---
doc_id: ops/general/ai-documentation-system
chunk_id: ops/general/ai-documentation-system#chunk-8
heading_path: ["AI-Optimized Documentation System: Complete Design Document", "Integration Options"]
chunk_type: prose
tokens: 166
summary: "Integration Options"
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
