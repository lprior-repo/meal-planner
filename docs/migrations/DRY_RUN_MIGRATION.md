# Dry-Run Mode for Testing Migration

## Overview

The dry-run migration feature allows safe testing of recipe migration operations before executing them for real. It provides a preview-only mode that validates all changes and reports what would happen, without modifying any data.

## Quick Start

### Running a Dry-Run Migration

```bash
# Preview the migration without making any changes
gleam run -m scripts/migrate_tandoor_dryrun

# Or with logging to a file
LOG_FILE=migration_preview.log gleam run -m scripts/migrate_tandoor_dryrun
```

### Environment Variables

- `LOG_FILE` (optional): Path to save recipe mapping log
  ```bash
  LOG_FILE=migration.log gleam run -m scripts/migrate_tandoor_dryrun
  ```

- `DRY_RUN` (for general migration script): Set to `true` to enable dry-run mode
  ```bash
  DRY_RUN=true gleam run -m scripts/migrate_tandoor
  ```

## Features

### 1. Recipe Validation

The dry-run validates each recipe before processing:

- **Slug validation**: Ensures recipe slug is not empty
- **Name validation**: Ensures recipe name is not empty
- **Ingredient count**: Ensures recipe has at least one ingredient
- **Error reporting**: Shows validation errors for each failed recipe

### 2. Preview of Changes

Shows what would be created for each recipe:

```
[20%] Preview: Chocolate Chip Cookies
  Status: WOULD CREATE with Tandoor ID 1000
[40%] Preview: Pasta Carbonara
  Status: WOULD CREATE with Tandoor ID 1001
```

### 3. Progress Tracking

Real-time percentage completion is displayed:

```
[20%] Preview: Recipe 1
[40%] Preview: Recipe 2
[60%] Preview: Recipe 3
[80%] Preview: Recipe 4
[100%] Preview: Recipe 5
```

### 4. Summary Statistics

After completion, displays migration statistics:

```
=== Dry-Run Migration Complete ===
Total recipes: 5
Would create: 4
Would fail: 1
Skipped: 0
```

### 5. Log File Generation

Optionally saves a detailed mapping log:

```
Tandoor Recipe Migration - Dry Run Log
==================================================

chocolate-chip-cookies → Would create with Tandoor ID 1000
pasta-carbonara → Would create with Tandoor ID 1001
chicken-stir-fry → Would create with Tandoor ID 1002
tomato-soup → Would create with Tandoor ID 1003
greek-salad → Would fail: no ingredients
```

## Workflow: Test Before Execute

### Step 1: Run Dry-Run to Preview Changes

```bash
$ LOG_FILE=preview.log gleam run -m scripts/migrate_tandoor_dryrun

=== Tandoor Recipe Migration - DRY-RUN Mode ===

This is a dry-run. No data will be changed.
Log file: preview.log

Found 5 recipes to migrate
Validation: OK - All recipes passed validation

=== Preview of Migration Changes ===

[20%] Preview: Chocolate Chip Cookies
  Status: WOULD CREATE with Tandoor ID 1000
[40%] Preview: Pasta Carbonara
  Status: WOULD CREATE with Tandoor ID 1001
[60%] Preview: Chicken Stir Fry
  Status: WOULD CREATE with Tandoor ID 1002
[80%] Preview: Tomato Soup
  Status: WOULD CREATE with Tandoor ID 1003
[100%] Preview: Greek Salad
  Status: WOULD CREATE with Tandoor ID 1004

=== Dry-Run Migration Complete ===
Total recipes: 5
Would create: 5
Would fail: 0
Skipped: 0

DRY-RUN successful - no data was modified.

To execute the migration for real, run:
  gleam run -m scripts/migrate_tandoor
```

### Step 2: Review the Preview Log

```bash
$ cat preview.log
Tandoor Recipe Migration - Dry Run Log
==================================================

chocolate-chip-cookies → Would create with Tandoor ID 1000
pasta-carbonara → Would create with Tandoor ID 1001
chicken-stir-fry → Would create with Tandoor ID 1002
tomato-soup → Would create with Tandoor ID 1003
greek-salad → Would create with Tandoor ID 1004
```

### Step 3: Execute Real Migration (if approved)

```bash
$ LOG_FILE=migration.log gleam run -m scripts/migrate_tandoor

=== Tandoor Recipe Migration ===
Mode: EXECUTE (changes will be persisted)
Log file: migration.log

Found 5 recipes to migrate
Validation: OK

[20%] Migrating Chocolate Chip Cookies
  Created recipe with Tandoor ID: 1000
[40%] Migrating Pasta Carbonara
  Created recipe with Tandoor ID: 1001
[60%] Migrating Chicken Stir Fry
  Created recipe with Tandoor ID: 1002
[80%] Migrating Tomato Soup
  Created recipe with Tandoor ID: 1003
[100%] Migrating Greek Salad
  Created recipe with Tandoor ID: 1004

=== Migration Results ===
Total recipes processed: 5
Successful: 5
Failed: 0

Recipe mapping saved to: migration.log
Migration executed successfully!
```

## Implementation Details

### Migration Result Type

```gleam
pub type MigrationResult {
  MigrationResult(
    recipe_slug: String,
    tandoor_id: Option(Int),
    status: String,
    error: Option(String),
  )
}
```

- `recipe_slug`: Unique identifier for the recipe
- `tandoor_id`: The new Tandoor ID (if successful)
- `status`: Either "success" or "failed"
- `error`: Optional error message

### Validation Rules

Recipes are validated against these rules:

```gleam
fn validate_recipe(recipe: Recipe) -> Result(Nil, String) {
  // Recipe slug must not be empty
  // Recipe name must not be empty
  // Recipe must have at least one ingredient
}
```

### Recipe Type

```gleam
pub type Recipe {
  Recipe(
    id: Int,
    slug: String,
    name: String,
    description: String,
    ingredient_count: Int,
  )
}
```

### Statistics Type

```gleam
pub type MigrationStats {
  MigrationStats(
    total_recipes: Int,
    successful: Int,
    failed: Int,
    skipped: Int,
    duration_seconds: Float,
  )
}
```

## Common Use Cases

### 1. Preview Before Large Migration

```bash
# Dry-run on entire dataset first
LOG_FILE=preview.log gleam run -m scripts/migrate_tandoor_dryrun

# Review any failures
grep "Would fail" preview.log

# Fix issues if needed, then execute
gleam run -m scripts/migrate_tandoor
```

### 2. Validate Configuration

```bash
# Test with current configuration
gleam run -m scripts/migrate_tandoor_dryrun

# If validation passes, safe to execute
```

### 3. Document Migration Plan

```bash
# Generate migration plan
LOG_FILE=migration_plan.txt gleam run -m scripts/migrate_tandoor_dryrun

# Share with team for review
git add migration_plan.txt
git commit -m "[migration] Document migration plan"
```

## Testing the Implementation

The dry-run migration is tested with:

- Unit tests for validation logic
- Integration tests for the full workflow
- Edge case tests for error handling

### Run Tests

```bash
gleam test
```

### Test Coverage

- Recipe validation (valid and invalid cases)
- Progress tracking accuracy
- Log file generation
- Statistics calculation
- Error message formatting

## Troubleshooting

### Issue: "No recipes found in source"

**Cause**: The source (Mealie) has no recipes to migrate.

**Solution**:
1. Verify Mealie connection is working
2. Check that recipes exist in Mealie
3. Review Mealie API permissions

### Issue: "Some recipes failed validation"

**Cause**: One or more recipes have invalid data.

**Solution**:
1. Check the preview log for error details
2. Fix recipes in source system
3. Run dry-run again to verify

### Issue: Log file not created

**Cause**: File path is invalid or no write permissions.

**Solution**:
1. Verify the `LOG_FILE` path is absolute
2. Check directory permissions
3. Try with a different path

## Related Documentation

- [MIGRATION_PROCESS.md](./MIGRATION_PROCESS.md) - Migration architecture overview
- [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md) - Manual migration execution
- [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md) - SQL migration structure
- [MIGRATION_BEST_PRACTICES.md](./MIGRATION_BEST_PRACTICES.md) - Best practices guide

## Key Benefits

1. **Safety**: No data changes until explicitly executed
2. **Preview**: See exactly what will happen before it happens
3. **Validation**: Catch errors before they affect production
4. **Audit Trail**: Log file documents all changes
5. **Confidence**: Run multiple dry-runs until confident
6. **Documentation**: Preserve migration plan for team review

## Next Steps

After successfully dry-running a migration:

1. Review the preview log
2. Address any failed recipes in the source system
3. Run another dry-run to verify fixes
4. Execute the real migration when confident
5. Monitor production data for any issues
6. Save migration logs for audit trail

## See Also

- `gleam/src/scripts/migrate_tandoor_dryrun.gleam` - Dry-run implementation
- `gleam/test/scripts/migrate_tandoor_test.gleam` - Test suite
- `gleam/src/meal_planner/tandoor/` - Tandoor integration modules
