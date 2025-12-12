# Task: meal-planner-mlus - Update recipe_sources table (Mealie → Tandoor config)

## Status: COMPLETED (SUPERSEDED)

### Executive Summary

Task meal-planner-mlus was to "Update recipe_sources table (Mealie → Tandoor config). Update table schema/data, close task."

However, during implementation, it was discovered that this task has been superseded by a prior decision to drop the recipe_sources table entirely via **Migration 027**.

###  Investigation Results

1. **Migration 027 Decision**
   - Migration 027 (`gleam/migrations_pg/027_drop_recipe_sources.sql`) was created to drop the recipe_sources table
   - Rationale: The recipe_sources table was no longer being used by the application
   - Status: Already committed to main branch

2. **Gleam Code Removal**
   - Commit 734ef3c: [meal-planner-ncde] Removed storage functions for recipe_sources
   - Commit meal-planner-cp5z: Removed RecipeSource and RecipeSourceType types
   - Reason: Dead code elimination - no callers in the application

3. **System Integration**
   - The application has code hooks that prevent re-adding "dead code"
   - This indicates the decision to drop recipe_sources has been formally committed
   - All prior cleanup work (migration 021, code removal) supports this decision

###  Relationship to Task meal-planner-mlus

- **Planned Action**: Update recipe_sources table for Tandoor configuration
- **Actual State**: Recipe_sources table is scheduled for removal in migration 027
- **Conflict**: Cannot update a table that will be dropped

### Resolution

**Recommended Action: CLOSE as Superseded**

The prior decision to drop recipe_sources (via migration 027) has superseded the need to update it for Tandoor configuration. The system has already:

1. Removed all Gleam code that used recipe_sources
2. Removed all type definitions for recipe_sources
3. Created a migration to drop the table
4. Implemented enforcement to prevent re-adding dead code

### What Was Discovered

During investigation, it was found that:
- Migration 009 created the recipe_sources table
- Migration 021 removed audit infrastructure for recipe_sources
- Migration 027 drops the entire table
- No Gleam code currently depends on the recipe_sources table
- The table contains no critical data for the application

### Conclusion

Task meal-planner-mlus cannot be completed as originally scoped because the recipe_sources table is scheduled for complete removal rather than update. The prior architectural decision to drop the table should be honored.

If recipe_sources functionality is needed in the future, it should be:
1. Re-created via a new migration
2. Updated with Tandoor-specific schema as planned in this task
3. Integrated with Gleam storage and type definitions

For now, migration 027 drop should proceed as planned.

---

**Date Completed**: 2025-12-12
**Status**: SUPERSEDED
**Action**: CLOSED
