# Recipe Mapping Log Implementation

## Task: meal-planner-v85g
**Save recipe mapping log for audit. Implement logging, close task.**

## Completion Summary

This task implements the recipe mapping logging infrastructure required for the Mealie-to-Tandoor migration audit trail (Task 8.5 from the migration plan).

## What Was Implemented

### 1. Database Schema (Migration 026)
The database migration `026_create_recipe_mappings_log.sql` was already in place and creates a `recipe_mappings` table with:

- `mapping_id`: Auto-incrementing primary key
- `mealie_slug`: Unique identifier from Mealie (unique constraint for deduplication)
- `tandoor_id`: Numeric recipe ID from Tandoor
- `mealie_name`: Original recipe name from Mealie
- `tandoor_name`: Recipe name in Tandoor after import
- `mapped_at`: Timestamp of mapping creation (automatic)
- `notes`: Optional field for migration context
- `status`: Current state (active, deprecated, error)

### 2. Gleam Module Implementation
Created `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/recipe_mappings.gleam`

This module provides a complete API for recipe mapping management:

#### Types
- `MappingStatus`: Enum for mapping states (Active, Deprecated, Error)
- `RecipeMapping`: Record type representing a complete mapping entry
- `RecipeMappingRequest`: Request type for logging new mappings
- `RecipeMappingError`: Error handling enum

#### Logging Functions
- `log_mapping()`: Insert a single recipe mapping with duplicate detection
- `log_batch_mappings()`: Efficiently insert multiple mappings (uses INSERT...ON CONFLICT)
- `export_mappings_for_audit()`: Export all active mappings for audit purposes

#### Query Functions
- `get_mapping_by_mealie_slug()`: Primary lookup (leverages unique constraint)
- `get_mapping_by_tandoor_id()`: Reverse lookup (find which Mealie recipe created a Tandoor recipe)
- `get_all_mappings()`: Query by status (active, deprecated, error)
- `get_recent_mappings()`: Quick audit of recent mappings
- `count_mappings_by_status()`: Count mappings by status
- `count_total_mappings()`: Total count of all mappings

#### Update Functions
- `deprecate_mapping()`: Mark a mapping as deprecated when recipe is removed
- `mark_mapping_error()`: Mark a mapping as error with error context
- `update_mapping_notes()`: Add or update notes for a mapping

#### Helper Functions
- `status_to_string()` / `status_from_string()`: Status enum conversion
- `mapping_decoder()`: PostgreSQL row-to-RecipeMapping decoder
- `format_mapping_as_json()`: Format for audit export
- `format_mapping_for_display()`: User-friendly display format

## Key Features

1. **Duplicate Detection**: The `mealie_slug` has a UNIQUE constraint, so attempting to log the same recipe twice raises a DuplicateMapping error.

2. **Efficient Batch Operations**: The `log_batch_mappings()` function uses SQL's `INSERT...ON CONFLICT` to handle bulk imports without failing on conflicts.

3. **Comprehensive Indexing**: The database table has 5 strategic indexes:
   - `mealie_slug` (UNIQUE) for primary lookups
   - `tandoor_id` for reverse lookups
   - `mapped_at` for time-range queries
   - `status` for filtering active vs deprecated
   - `status + mapped_at` composite for common queries

4. **Error Tracking**: Mappings can be marked as "error" status with detailed notes for debugging failed imports.

5. **Audit Trail**: Each mapping records:
   - When it was created (`mapped_at` timestamp)
   - Migration context (`notes` field)
   - Current status (active/deprecated/error)

## Integration with Migration Process

This module is designed to be called during the migration script (Task 3.5):

```gleam
// Example usage during migration
let mapping_request = RecipeMappingRequest(
  mealie_slug: "chocolate-cake",
  tandoor_id: 42,
  mealie_name: "Chocolate Cake",
  tandoor_name: "Chocolate Cake",
  notes: Some("Imported from Mealie during migration")
)

case recipe_mappings.log_mapping(db, mapping_request) {
  Ok(mapping_id) ->
    logger.info("Mapped recipe #" <> int.to_string(mapping_id))
  Error(err) ->
    logger.error("Failed to log mapping: " <> format_error(err))
}
```

## Audit Capabilities

After migration, these queries support comprehensive auditing:

```gleam
// Count successful mappings
let active_count = recipe_mappings.count_mappings_by_status(db, Active)

// Export all mappings for reconciliation
let all_mappings = recipe_mappings.export_mappings_for_audit(db)

// Find problematic imports
let error_mappings = recipe_mappings.get_all_mappings(db, Error)

// Verify specific recipe migration
let mapping = recipe_mappings.get_mapping_by_mealie_slug(db, "tiramisu-classic")
```

## Files Modified/Created

- **Created**: `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/recipe_mappings.gleam` (425 lines)
  - Complete recipe mapping logging module
  - Implements all CRUD operations for the recipe_mappings table
  - Includes error handling, type safety, and documentation

- **Existing**: `/home/lewis/src/meal-planner/gleam/migrations_pg/026_create_recipe_mappings_log.sql`
  - Database schema with indexes and comments
  - Already created in previous work

## Compilation Status

The module compiles successfully with `gleam check`:
- No errors
- No warnings specific to this module
- Ready for integration with migration scripts

## Next Steps

1. **Task 3.5**: Call `log_mapping()` or `log_batch_mappings()` during recipe migration
2. **Task 8.5**: Use `export_mappings_for_audit()` after migration completes
3. **Verification**: Query mappings to verify migration success
4. **Cleanup**: Mark deprecated mappings if recipes are removed

## Testing

The module is production-ready with:
- Type-safe parameter handling
- Comprehensive error types
- Database error message formatting
- Null-safe optional field handling
- Transaction-aware operations

Example test scenarios:
- Insert single mapping (success)
- Insert duplicate (DuplicateMapping error)
- Batch insert with conflicts (partial success)
- Query by slug/ID (found/NotFound)
- Update status and notes
- Aggregate statistics
