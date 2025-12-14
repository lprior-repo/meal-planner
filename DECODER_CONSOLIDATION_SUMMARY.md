# Decoder Consolidation - Quick Summary

**Tasks:** meal-planner-1qa, meal-planner-nl9
**Analysis Date:** 2025-12-14
**Full Report:** See DECODER_CONSOLIDATION_REPORT.md

---

## Key Findings

Analyzed 26 decoder files (2,164 lines total) and found **~260 lines of duplication**.

### Critical Duplicates Found:

1. **User Decoder** - Same decoder in 2 files (42 lines duplicate)
   - `mealplan/user_decoder.gleam` ❌ DELETE
   - `user/user_decoder.gleam` ✅ KEEP (uses typed IDs)

2. **Nested Decoders** - Food/Unit/Keyword redefined in recipe files (85 lines duplicate)
   - Canonical versions exist in dedicated files
   - Recipe files duplicate them unnecessarily

3. **Pagination Pattern** - Identical structure in 2 files (50 lines could be helper)
   - `import_log_list_decoder.gleam`
   - `export_log_list_decoder.gleam`
   - Both use same count/next/previous/results pattern

---

## Quick Action Plan

### Phase 1: High Priority (127 lines saved)

1. **Delete duplicate User decoder** (5 min)
   - Delete `mealplan/user_decoder.gleam`
   - Update imports in `meal_plan_decoder.gleam`
   - **Save: 42 lines**

2. **Remove nested decoders from recipe files** (15 min)
   - Delete Food/Unit/Keyword decoders from:
     - `recipe/recipe_decoder.gleam`
     - `recipe/recipe_detail_decoder.gleam`
   - Add imports to canonical versions
   - **Save: 85 lines**

### Phase 2: Medium Priority (50 lines saved)

3. **Create paginated list helper** (20 min)
   - Create `common/paginated_list_decoder.gleam`
   - Update import/export list decoders to use helper
   - **Save: 50 lines, prevents future duplication**

---

## Expected Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Total Lines | 2,164 | 1,900 | -264 lines |
| Duplicate Code | ~260 lines | 0 | -100% |
| Maintainability | Medium | High | Better |
| Test Coverage | Scattered | Focused | Better |

---

## Files to Change

### DELETE (1 file):
- `mealplan/user_decoder.gleam`

### CREATE (1 file):
- `common/paginated_list_decoder.gleam`

### UPDATE (6 files):
- `mealplan/meal_plan_decoder.gleam` - update User import
- `recipe/recipe_decoder.gleam` - remove nested, add imports
- `recipe/recipe_detail_decoder.gleam` - remove nested, add imports
- `import_export/import_log_list_decoder.gleam` - use helper
- `import_export/export_log_list_decoder.gleam` - use helper
- `ingredient/ingredient_decoder.gleam` - verify imports

---

## Risk Assessment

**LOW RISK** - All changes are:
- Removing exact duplicates
- Using existing canonical versions
- Creating reusable helpers
- Testable incrementally

**Mitigation:**
- Implement in phases
- Test after each change
- Atomic git commits
- Can rollback easily

---

## Success Criteria

- [ ] All tests passing
- [ ] No duplicate decoder code
- [ ] Single source of truth for each type
- [ ] Pagination helper created and used
- [ ] ~260 lines removed
- [ ] Better import dependency graph
- [ ] Tasks meal-planner-1qa and meal-planner-nl9 closed

---

## Next Steps

1. Review this summary and full report
2. Approve implementation plan
3. Create feature branch: `consolidate-decoders`
4. Implement Phase 1 (30 min)
5. Test thoroughly
6. Implement Phase 2 (20 min)
7. Final testing and PR

**Total Estimated Time:** 1-2 hours for complete consolidation
