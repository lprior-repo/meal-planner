# Recipe Migration Progress Reporting

## Overview

This feature adds progress tracking for recipe migrations, showing real-time updates like "X of Y recipes migrated". It includes:

- A PostgreSQL table to store migration progress state
- A Gleam module for progress tracking operations
- A migration script that demonstrates progress reporting
- A web API endpoint for retrieving current progress
- Comprehensive tests

## Architecture

### Components

1. **Database Layer** (`migration_progress.gleam`)
   - Functions for creating, updating, and querying migration progress
   - Automatic timestamp management with database triggers
   - Status tracking (in_progress, completed, failed)

2. **Storage Table** (`026_add_migration_progress_tracking.sql`)
   - `migration_progress` table stores the state of each migration
   - Indexed for fast lookups by migration_id and status
   - Includes progress percentage calculation
   - Timestamp tracking for audit purposes

3. **Migration Script** (`scripts/migrate_recipes.gleam`)
   - Demonstrates recipe migration with real-time progress reporting
   - Shows "X of Y recipes migrated" format
   - Can be extended for actual Mealie→Tandoor or other migrations

4. **Web API Endpoint** (`web.gleam`)
   - `GET /api/migrations/progress/:migration_id`
   - Returns JSON with current progress state
   - Can be used by UIs for real-time progress updates

## Usage

### Running the Migration Script

```bash
cd /home/lewis/src/meal-planner/gleam

# First ensure the database migration is applied
psql -d meal_planner -f migrations_pg/026_add_migration_progress_tracking.sql

# Then run the migration script
gleam run -m scripts/migrate_recipes
```

Example output:
```
=== Recipe Migration Script with Progress Reporting ===

Starting recipe migration...
Total recipes to migrate: 10

Migration tracker initialized

0 of 10 recipes migrated (0%)
1 of 10 recipes migrated (10%)
2 of 10 recipes migrated (20%)
...
10 of 10 recipes migrated (100%)

Migration completed successfully!
Final status: 10 of 10 recipes migrated
All recipes migrated with no errors
```

### Using the Web API

```bash
# Start the API server
./run.sh start

# Query migration progress
curl http://localhost:8080/api/migrations/progress/migration-20251212-1234567890

# Response:
{
  "migration_id": "migration-20251212-1234567890",
  "total_recipes": 100,
  "migrated_count": 45,
  "failed_count": 2,
  "status": "in_progress",
  "progress_message": "45 of 100 recipes migrated",
  "progress_percentage": 45.0
}
```

### Using the Gleam Module

```gleam
import meal_planner/storage/migration_progress
import pog

// Create a new migration
case migration_progress.create_migration(db, "my-migration", 100) {
  Ok(Nil) -> io.println("Migration started")
  Error(msg) -> io.println("Error: " <> msg)
}

// Update progress
case migration_progress.increment_migrated(db, "my-migration") {
  Ok(Nil) -> io.println("Progress updated")
  Error(msg) -> io.println("Error: " <> msg)
}

// Get current progress
case migration_progress.get_progress(db, "my-migration") {
  Ok(progress) -> {
    let message = migration_progress.format_progress_message(progress)
    io.println(message)  // Prints: "45 of 100 recipes migrated"
  }
  Error(msg) -> io.println("Error: " <> msg)
}

// Get progress percentage
let percentage = migration_progress.get_progress_percentage(progress)
io.println(int.to_string(int.floor_divide(percentage, 1)) <> "%")

// Complete the migration
case migration_progress.complete_migration(db, "my-migration") {
  Ok(Nil) -> io.println("Migration completed")
  Error(msg) -> io.println("Error: " <> msg)
}
```

## Database Schema

```sql
CREATE TABLE migration_progress (
  id SERIAL PRIMARY KEY,
  migration_id VARCHAR(255) NOT NULL UNIQUE,
  total_recipes INTEGER NOT NULL DEFAULT 0,
  migrated_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,

  CONSTRAINT valid_status CHECK (status IN ('in_progress', 'completed', 'failed'))
);

CREATE INDEX idx_migration_progress_id ON migration_progress(migration_id);
CREATE INDEX idx_migration_progress_status ON migration_progress(status);
```

## API Reference

### Migration Progress Type

```gleam
pub type MigrationProgress {
  MigrationProgress(
    migration_id: String,
    total_recipes: Int,
    migrated_count: Int,
    failed_count: Int,
    status: String,
  )
}
```

### Module Functions

- `create_migration(db, migration_id, total_recipes)` → `Result(Nil, String)`
  - Initialize a new migration tracker

- `increment_migrated(db, migration_id)` → `Result(Nil, String)`
  - Increment successful migration count

- `increment_failed(db, migration_id)` → `Result(Nil, String)`
  - Increment failed count

- `get_progress(db, migration_id)` → `Result(MigrationProgress, String)`
  - Fetch current migration state

- `format_progress_message(progress)` → `String`
  - Format as "X of Y recipes migrated"

- `get_progress_percentage(progress)` → `Float`
  - Calculate percentage (0-100)

- `complete_migration(db, migration_id)` → `Result(Nil, String)`
  - Mark migration as completed

- `fail_migration(db, migration_id)` → `Result(Nil, String)`
  - Mark migration as failed

## Testing

Run the migration progress tests:

```bash
cd /home/lewis/src/meal-planner/gleam
gleam test migration_progress_test
```

Tests cover:
- Progress state creation and validation
- Message formatting
- Percentage calculations (including edge cases)
- Status transitions
- Complete migration scenarios

## Integration with Actual Migrations

To use this for a real recipe migration (e.g., Mealie→Tandoor):

1. Update the migration script (`scripts/migrate_recipes.gleam`) to fetch actual recipes from source
2. Transform and upload recipes to destination
3. Call `increment_migrated()` or `increment_failed()` for each recipe
4. The progress will be tracked automatically and queryable via the API

Example for Mealie→Tandoor:

```gleam
// Fetch recipes from Mealie
case mealie.get_all_recipes(mealie_config) {
  Ok(recipes) -> {
    migration_progress.create_migration(db, migration_id, list.length(recipes)) |> ignore

    // Migrate each recipe
    list.each(recipes, fn(recipe) {
      case tandoor.create_recipe(tandoor_config, transform_recipe(recipe)) {
        Ok(_) -> {
          migration_progress.increment_migrated(db, migration_id) |> ignore
        }
        Error(_) -> {
          migration_progress.increment_failed(db, migration_id) |> ignore
        }
      }
    })

    migration_progress.complete_migration(db, migration_id) |> ignore
  }
  Error(_) -> panic
}
```

## Future Enhancements

- Real-time progress WebSocket streaming
- Migration history and comparison
- Batched progress updates for performance
- Progress prediction (ETA calculations)
- Automatic retry logic for failed recipes
- Detailed error logging per failed recipe
