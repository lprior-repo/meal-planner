# Recipe Mappings Log

## Overview

The recipe mappings module provides an audit log for tracking the migration of recipes from Mealie to Tandoor. Each mapping record contains:

- **Mealie slug**: The original recipe identifier from Mealie (unique)
- **Tandoor ID**: The numeric ID assigned by Tandoor after import
- **Recipe names**: Both Mealie and Tandoor names for reference
- **Timestamp**: When the mapping was created
- **Status**: Current state (active, deprecated, or error)
- **Notes**: Optional field for additional context

## Database Schema

### Table: `recipe_mappings`

```sql
CREATE TABLE recipe_mappings (
    mapping_id SERIAL PRIMARY KEY,
    mealie_slug TEXT NOT NULL UNIQUE,
    tandoor_id INTEGER NOT NULL,
    mealie_name TEXT NOT NULL,
    tandoor_name TEXT NOT NULL,
    mapped_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'deprecated', 'error'))
);
```

### Indexes

- **idx_recipe_mappings_mealie_slug**: Unique index on `mealie_slug` for fast lookups
- **idx_recipe_mappings_tandoor_id**: Index on `tandoor_id` for reverse lookups
- **idx_recipe_mappings_mapped_at**: Index on `mapped_at` for time-based queries
- **idx_recipe_mappings_status**: Index on `status` for filtering operations
- **idx_recipe_mappings_status_date**: Composite index for common queries

## API Reference

### Type Definitions

#### MappingStatus

```gleam
pub type MappingStatus {
  Active      // Mapping is currently in use
  Deprecated  // Mapping has been superseded or removed
  Error       // Import failed or mapping has issues
}
```

#### RecipeMapping

```gleam
pub type RecipeMapping {
  RecipeMapping(
    mapping_id: Int,
    mealie_slug: String,
    tandoor_id: Int,
    mealie_name: String,
    tandoor_name: String,
    mapped_at: String,
    notes: Option(String),
    status: MappingStatus,
  )
}
```

#### RecipeMappingError

```gleam
pub type RecipeMappingError {
  DatabaseError(String)      // Generic database error
  NotFound                    // Mapping not found
  SlugAlreadyExists(String)   // Duplicate slug
}
```

### Core Functions

#### insert_mapping

Insert a new recipe mapping into the log.

```gleam
pub fn insert_mapping(
  conn: pog.Connection,
  mealie_slug: String,
  tandoor_id: Int,
  mealie_name: String,
  tandoor_name: String,
  notes: Option(String),
) -> Result(Int, RecipeMappingError)
```

**Example:**

```gleam
let result = storage.insert_recipe_mapping(
  conn,
  "tiramisu-classic",
  42,
  "Tiramisu Classic",
  "Tiramisu",
  Some("Imported from Mealie v1.2.0")
)

case result {
  Ok(mapping_id) -> io.println("Created mapping " <> int.to_string(mapping_id))
  Error(RecipeMappingError.SlugAlreadyExists(slug)) ->
    io.println("Recipe " <> slug <> " already mapped")
  Error(_) -> io.println("Database error")
}
```

**Error Cases:**
- `SlugAlreadyExists(slug)`: The Mealie slug is already in the database
- `DatabaseError(msg)`: Database connection or query error

#### get_by_mealie_slug

Look up a mapping by Mealie recipe slug.

```gleam
pub fn get_by_mealie_slug(
  conn: pog.Connection,
  slug: String,
) -> Result(Option(RecipeMapping), RecipeMappingError)
```

**Example:**

```gleam
case storage.get_recipe_mapping_by_mealie_slug(conn, "tiramisu-classic") {
  Ok(Some(mapping)) -> io.println("Found Tandoor ID: " <> int.to_string(mapping.tandoor_id))
  Ok(None) -> io.println("Recipe not yet imported")
  Error(_) -> io.println("Database error")
}
```

#### get_by_tandoor_id

Find all mappings for a given Tandoor recipe ID (may have duplicates if same recipe created from different sources).

```gleam
pub fn get_by_tandoor_id(
  conn: pog.Connection,
  tandoor_id: Int,
) -> Result(List(RecipeMapping), RecipeMappingError)
```

#### get_all_active

Get all active mappings in reverse chronological order.

```gleam
pub fn get_all_active(
  conn: pog.Connection,
) -> Result(List(RecipeMapping), RecipeMappingError)
```

**Use Case:** Audit recent imports, verification of migration success.

#### get_by_status

Get all mappings with a specific status.

```gleam
pub fn get_by_status(
  conn: pog.Connection,
  status: MappingStatus,
) -> Result(List(RecipeMapping), RecipeMappingError)
```

**Example:**

```gleam
// Find all failed imports
case storage.get_recipe_mappings_by_status(conn, storage.Error) {
  Ok(mappings) -> {
    list.each(mappings, fn(m) {
      io.println("Failed: " <> m.mealie_name <> " - " <> option.unwrap(m.notes, "No notes"))
    })
  }
  Error(_) -> io.println("Database error")
}
```

#### update_status

Change the status of a mapping.

```gleam
pub fn update_status(
  conn: pog.Connection,
  mapping_id: Int,
  new_status: MappingStatus,
) -> Result(Nil, RecipeMappingError)
```

**Use Cases:**
- Mark a recipe as deprecated when removed from Tandoor
- Mark as error when import validation fails
- Reactivate a corrected import

#### update_notes

Add or update notes on a mapping.

```gleam
pub fn update_notes(
  conn: pog.Connection,
  mapping_id: Int,
  notes: String,
) -> Result(Nil, RecipeMappingError)
```

**Example:**

```gleam
storage.update_recipe_mapping_notes(
  conn,
  42,
  "Manually adjusted nutritional values after verification"
)
```

#### count_all

Get total count of all mappings.

```gleam
pub fn count_all(conn: pog.Connection) -> Result(Int, RecipeMappingError)
```

#### count_by_status

Get count of mappings by status.

```gleam
pub fn count_by_status(
  conn: pog.Connection,
  status: MappingStatus,
) -> Result(Int, RecipeMappingError)
```

**Example:**

```gleam
case storage.count_recipe_mappings_by_status(conn, storage.Active) {
  Ok(count) -> io.println("Active mappings: " <> int.to_string(count))
  Error(_) -> io.println("Error counting mappings")
}
```

#### delete_mapping

Remove a mapping from the log (hard delete - use with care).

```gleam
pub fn delete_mapping(
  conn: pog.Connection,
  mapping_id: Int,
) -> Result(Nil, RecipeMappingError)
```

**Note:** Prefer marking as deprecated instead of hard deletion for audit trail preservation.

### Helper Functions

#### status_to_string

Convert status to database representation.

```gleam
pub fn status_to_string(status: MappingStatus) -> String
```

#### status_from_string

Parse status from database string (case-insensitive, defaults to Active).

```gleam
pub fn status_from_string(s: String) -> MappingStatus
```

## Typical Workflows

### 1. Recording a Successful Import

```gleam
case storage.insert_recipe_mapping(
  conn,
  "carbonara-pasta",
  156,
  "Carbonara Pasta",
  "Carbonara",
  Some("Imported from Mealie 1.2.0, no modifications")
) {
  Ok(id) -> io.println("Recorded mapping " <> int.to_string(id))
  Error(storage.SlugAlreadyExists(_)) -> io.println("Already imported")
  Error(storage.DatabaseError(msg)) -> io.println("Error: " <> msg)
}
```

### 2. Checking if a Recipe Has Been Migrated

```gleam
case storage.get_recipe_mapping_by_mealie_slug(conn, "original-slug") {
  Ok(Some(mapping)) -> {
    io.println("Found at Tandoor ID: " <> int.to_string(mapping.tandoor_id))
  }
  Ok(None) -> io.println("Not yet migrated - ready to import")
  Error(_) -> io.println("Database error during lookup")
}
```

### 3. Handling Import Errors

```gleam
// Store failed import with error status
case storage.insert_recipe_mapping(
  conn,
  "problematic-recipe",
  0,
  "Problematic Recipe",
  "N/A",
  Some("Nutritional values exceed safe limits - requires manual review")
) {
  Ok(mapping_id) -> {
    let _ = storage.update_recipe_mapping_status(
      conn,
      mapping_id,
      storage.Error
    )
    io.println("Recorded failed import for manual review")
  }
  Error(_) -> io.println("Failed to record error")
}
```

### 4. Auditing Recent Imports

```gleam
case storage.get_all_active_recipe_mappings(conn) {
  Ok(mappings) -> {
    mappings
    |> list.take(10)
    |> list.each(fn(m) {
      io.println(
        m.mealie_name <> " → " <> int.to_string(m.tandoor_id)
        <> " (" <> m.mapped_at <> ")"
      )
    })
  }
  Error(_) -> io.println("Failed to retrieve mappings")
}
```

### 5. Deduplication Before Import

```gleam
fn should_import_recipe(conn: pog.Connection, mealie_slug: String) -> Bool {
  case storage.get_recipe_mapping_by_mealie_slug(conn, mealie_slug) {
    Ok(Some(_)) -> False  // Already imported
    Ok(None) -> True      // Ready to import
    Error(_) -> True      // On error, attempt import (might fail again)
  }
}
```

## Integration with Other Modules

### food_logs

The recipe mappings table is complementary to food_logs:
- `recipe_mappings`: Historical audit log of imports (write-once)
- `food_logs`: Food consumption logs that reference recipes (updated frequently)

### storage (main module)

All recipe mapping functions are re-exported through the main storage module:

```gleam
import meal_planner/storage

// Direct access to recipe mapping functions
storage.insert_recipe_mapping(conn, ...)
storage.get_recipe_mapping_by_mealie_slug(conn, ...)
storage.get_all_active_recipe_mappings(conn)
```

## Performance Characteristics

### Lookup Performance

| Operation | Index | Time Complexity |
|-----------|-------|-----------------|
| Get by Mealie slug | UNIQUE | O(log N) |
| Get by Tandoor ID | Regular | O(log N) |
| Get all active | Compound (status + date) | O(log N + K) |
| Count by status | Regular | O(log N + K) |

Where N = total mappings, K = result set size

### Storage Overhead

- Minimal: ~200-300 bytes per mapping
- 10,000 recipes = ~3MB

## Error Handling Strategy

### Database Errors

All database operations return `Result(_, RecipeMappingError)`. Handle appropriately:

```gleam
import meal_planner/storage

case storage.get_recipe_mapping_by_mealie_slug(conn, slug) {
  Ok(Some(mapping)) -> { /* success */ }
  Ok(None) -> { /* not found */ }
  Error(storage.DatabaseError(msg)) -> {
    // Log error, possibly retry or fallback
    logger.error("Database error: " <> msg)
  }
  Error(storage.SlugAlreadyExists(slug)) -> {
    // Deduplication - skip this recipe
  }
  Error(storage.NotFound) -> {
    // Handle missing mapping
  }
}
```

### Constraint Violations

The `mealie_slug` column is UNIQUE - attempting to insert a duplicate will return `SlugAlreadyExists`. Use this for deduplication:

```gleam
case storage.insert_recipe_mapping(conn, slug, id, name1, name2, notes) {
  Ok(mapping_id) -> io.println("New import recorded")
  Error(RecipeMappingError.SlugAlreadyExists(_)) -> {
    io.println("Recipe already imported - skipping")
  }
  Error(e) -> io.println("Unexpected error: " <> error_to_string(e))
}
```

## Migration Notes

### Rollback

If needed, remove the table with:

```sql
DROP TABLE IF EXISTS recipe_mappings CASCADE;
```

This will not affect other tables as it's a standalone audit log.

### Future Extensions

Potential enhancements:
- Batch import tracking (which import batch a recipe came from)
- Nutritional value diffs (Mealie vs Tandoor)
- Ingredient mapping log
- User who performed the import
- Validation status and timestamps

## Testing

The module includes comprehensive type documentation and error handling. Full integration tests require a PostgreSQL database connection. Unit tests for status conversion functions are included in:

- `gleam/test/meal_planner/storage/recipe_mappings_test.gleam`

## Summary

The recipe mappings module provides:

1. **Audit Trail**: Complete record of recipe migrations
2. **Deduplication**: Check before importing to avoid duplicates
3. **Error Tracking**: Mark failed imports for manual review
4. **Status Management**: Track active, deprecated, and error mappings
5. **Flexible Lookup**: Query by slug, Tandoor ID, status, or date range
6. **Minimal Overhead**: Lean data structure with efficient indexing
