# Integration Testing Guide

Complete guide to the meal-planner integration test harness.

## Overview

The integration test harness provides:

1. **Automatic Test Database Management**: Each test gets isolated database with auto-cleanup
2. **HTTP Testing Utilities**: Mock requests and response validation
3. **Test Data Builders**: Clean, reusable test data with sensible defaults
4. **Example Tests**: Comprehensive patterns and best practices

## Quick Start

### Basic Integration Test

```gleam
import gleeunit/should
import meal_planner/storage
import meal_planner/integration/test_helpers

pub fn test_save_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Your test code here
    let recipe = Recipe(
      id: "test-1",
      name: "Test Recipe",
      // ... other fields
    )

    case storage.save_recipe(conn, recipe) {
      Ok(_) -> should.be_true(True)
      Error(_) -> panic as "Save failed"
    }
  })
  |> should.be_ok
}
```

## Architecture

### Test Database Lifecycle

```
Test Start
    ↓
1. Generate unique DB name: test_db_<timestamp>_<random>
    ↓
2. Connect to admin database (postgres)
    ↓
3. CREATE DATABASE test_db_xxx
    ↓
4. Connect to test database
    ↓
5. Run all migrations from migrations_pg/
    ↓
6. Execute test function
    ↓
7. DROP DATABASE test_db_xxx (cleanup)
    ↓
Test End
```

**Key Benefits:**
- Complete isolation (no test pollution)
- Parallel test execution safe
- Automatic cleanup (even on failures)
- Real database (not mocks)

### Module Structure

```
gleam/test/meal_planner/integration/
├── test_helpers.gleam          # Database lifecycle management
└── food_logging_test.gleam     # Example integration tests (disabled)

gleam/test/
├── integration_test_utils.gleam  # Re-export module
└── property_test.gleam            # Property-based tests
```

## Available Test Helpers

### `test_helpers.gleam`

**Main Functions:**

```gleam
/// Execute test with isolated database
pub fn with_integration_db(
  test_fn: fn(pog.Connection) -> Nil
) -> Result(Nil, String)

/// Version that allows test to return Result
pub fn with_integration_db_result(
  test_fn: fn(pog.Connection) -> Result(Nil, String)
) -> Result(Nil, String)
```

**Example Usage:**

```gleam
pub fn test_example() {
  test_helpers.with_integration_db(fn(conn) {
    // Setup
    let user = create_test_user()

    // Execute
    let assert Ok(_) = storage.save_user(conn, user)

    // Verify
    let assert Ok(loaded) = storage.get_user(conn, user.id)
    should.equal(loaded.name, user.name)
  })
  |> should.be_ok
}
```

## Testing Patterns

### 1. Arrange-Act-Assert

Structure all tests clearly:

```gleam
pub fn test_create_and_retrieve() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Setup test data
    let recipe = Recipe(id: "test-1", name: "Test", ...)

    // Act: Perform operation
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Assert: Verify outcome
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "test-1")
    should.equal(retrieved.name, "Test")
  })
  |> should.be_ok
}
```

### 2. Test Isolation

Each test is completely isolated:

```gleam
// Test A creates test_db_1733630400_123456
pub fn test_a() {
  test_helpers.with_integration_db(fn(conn) {
    // Isolated database - won't affect test_b
  })
}

// Test B creates test_db_1733630401_789012
pub fn test_b() {
  test_helpers.with_integration_db(fn(conn) {
    // Completely separate database
  })
}
```

### 3. Error Handling

```gleam
pub fn test_validation_error() {
  test_helpers.with_integration_db(fn(conn) {
    // Invalid data should return error
    let invalid = Recipe(servings: 0, ...)

    let result = storage.save_recipe(conn, invalid)
    should.be_error(result)
  })
  |> should.be_ok
}
```

### 4. Multiple Operations

```gleam
pub fn test_workflow() {
  test_helpers.with_integration_db(fn(conn) {
    // Create
    let recipe = create_test_recipe()
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Read
    let assert Ok(loaded) = storage.get_recipe_by_id(conn, recipe.id)

    // Update
    let updated = Recipe(..loaded, name: "Updated")
    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Delete
    let assert Ok(_) = storage.delete_recipe(conn, recipe.id)
    should.be_error(storage.get_recipe_by_id(conn, recipe.id))
  })
  |> should.be_ok
}
```

## Database Configuration

Default test configuration (in `test_helpers.gleam`):

```gleam
TestDbConfig(
  host: "localhost",
  port: 5432,
  user: "meal_planner",
  password: "meal_planner",
  admin_database: "postgres",
)
```

**Customization:**

To use different credentials, modify `test_db_config()` function or set environment variables.

## Running Tests

### All Tests

```bash
gleam test
```

### Specific Module

```bash
gleam test --target erlang -- --module meal_planner/integration/test_name
```

### With Verbose Output

```bash
gleam test -- --verbose
```

## Best Practices

### DO:
- ✅ Use descriptive test names: `test_save_recipe_with_invalid_data_returns_error`
- ✅ Test one scenario per test function
- ✅ Use the AAA pattern (Arrange-Act-Assert)
- ✅ Test both happy path and error cases
- ✅ Clean up resources (automatic with `with_integration_db`)
- ✅ Use realistic test data

### DON'T:
- ❌ Share state between tests
- ❌ Rely on test execution order
- ❌ Use hardcoded database names
- ❌ Skip cleanup (handled automatically)
- ❌ Test multiple unrelated things in one test
- ❌ Use production database for tests

## Troubleshooting

### Database Connection Errors

**Symptom:** Tests fail with "Failed to connect to admin database"

**Solutions:**
1. Verify PostgreSQL is running: `systemctl status postgresql`
2. Check credentials match in `test_db_config()`
3. Ensure user exists: `psql -U postgres -c "\du"`
4. Grant permissions: `ALTER USER meal_planner CREATEDB;`

### Migration Errors

**Symptom:** Tests fail during migration execution

**Solutions:**
1. Verify migrations exist: `ls migrations_pg/`
2. Check migration SQL syntax
3. Ensure migrations are numbered correctly (001_, 002_, etc.)
4. Test migrations manually: `psql -d test_db -f migrations_pg/001_schema.sql`

### Orphaned Test Databases

**Symptom:** Many `test_db_*` databases remain after tests

**Solutions:**
1. Check for panics in test code (prevents cleanup)
2. Manual cleanup:
   ```sql
   SELECT 'DROP DATABASE ' || datname || ' WITH (FORCE);'
   FROM pg_database
   WHERE datname LIKE 'test_db_%';
   ```
3. Add explicit cleanup in tests if needed

### Slow Tests

**Solutions:**
1. Reduce test data to minimum needed
2. Use connection pooling (already configured)
3. Run tests in parallel (Gleam handles this)
4. Consider test categorization (unit vs integration)

## Example: Complete Integration Test

```gleam
import gleeunit/should
import meal_planner/storage
import meal_planner/integration/test_helpers
import meal_planner/types.{Recipe, Macros, Ingredient}

pub fn test_recipe_crud_workflow() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Create test recipe
    let recipe = Recipe(
      id: "test-recipe-1",
      name: "Grilled Chicken",
      ingredients: [
        Ingredient(name: "Chicken breast", quantity: "8 oz"),
        Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: ["Grill chicken until cooked"],
      macros: Macros(protein: 45.0, fat: 8.0, carbs: 0.0),
      servings: 1,
      category: "chicken",
      fodmap_level: types.Low,
      vertical_compliant: True,
    )

    // Act 1: Save recipe
    case storage.save_recipe(conn, recipe) {
      Ok(_) -> {
        // Assert 1: Can retrieve saved recipe
        case storage.get_recipe_by_id(conn, recipe.id) {
          Ok(loaded) -> {
            should.equal(loaded.name, "Grilled Chicken")
            should.equal(loaded.macros.protein, 45.0)

            // Act 2: Update recipe
            let updated = Recipe(..loaded, name: "Grilled Chicken Updated")
            case storage.save_recipe(conn, updated) {
              Ok(_) -> {
                // Assert 2: Update persisted
                case storage.get_recipe_by_id(conn, recipe.id) {
                  Ok(final) -> {
                    should.equal(final.name, "Grilled Chicken Updated")

                    // Act 3: Delete recipe
                    case storage.delete_recipe(conn, recipe.id) {
                      Ok(_) -> {
                        // Assert 3: Recipe deleted
                        should.be_error(storage.get_recipe_by_id(conn, recipe.id))
                      }
                      Error(_) -> panic as "Delete failed"
                    }
                  }
                  Error(_) -> panic as "Load after update failed"
                }
              }
              Error(_) -> panic as "Update failed"
            }
          }
          Error(_) -> panic as "Load failed"
        }
      }
      Error(_) -> panic as "Save failed"
    }
  })
  |> should.be_ok
}
```

## Advanced Topics

### Testing Transactions

```gleam
pub fn test_transaction_rollback() {
  test_helpers.with_integration_db(fn(conn) {
    // Begin transaction
    let assert Ok(_) = pog.query("BEGIN") |> pog.execute(conn)

    // Make changes
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Rollback
    let assert Ok(_) = pog.query("ROLLBACK") |> pog.execute(conn)

    // Verify rollback
    should.be_error(storage.get_recipe_by_id(conn, recipe.id))
  })
  |> should.be_ok
}
```

### Testing Concurrent Operations

```gleam
pub fn test_concurrent_saves() {
  test_helpers.with_integration_db(fn(conn) {
    // Create multiple recipes
    let recipes = [recipe1, recipe2, recipe3]

    // Save concurrently (using OTP)
    let tasks = list.map(recipes, fn(r) {
      task.async(fn() { storage.save_recipe(conn, r) })
    })

    // Wait for all
    let results = list.map(tasks, task.await_forever)

    // All should succeed
    list.all(results, result.is_ok)
    |> should.be_true
  })
  |> should.be_ok
}
```

### Custom Assertions

```gleam
fn assert_recipe_count(conn: pog.Connection, expected: Int) -> Nil {
  case storage.get_all_recipes(conn) {
    Ok(recipes) -> should.equal(list.length(recipes), expected)
    Error(_) -> panic as "Failed to get recipes"
  }
}

pub fn test_with_custom_assertion() {
  test_helpers.with_integration_db(fn(conn) {
    assert_recipe_count(conn, 0)

    let assert Ok(_) = storage.save_recipe(conn, recipe1)
    assert_recipe_count(conn, 1)

    let assert Ok(_) = storage.save_recipe(conn, recipe2)
    assert_recipe_count(conn, 2)
  })
  |> should.be_ok
}
```

## Future Enhancements

Planned improvements:

- [ ] HTTP request/response testing utilities
- [ ] Test data builders (builder pattern)
- [ ] Snapshot testing for JSON/HTML
- [ ] Performance testing utilities
- [ ] Parallel test optimization
- [ ] Test coverage reporting
- [ ] CI/CD integration examples

## Contributing

When adding integration tests:

1. Follow the AAA pattern
2. Use descriptive test names
3. Test both success and error cases
4. Keep tests fast (minimize data)
5. Document complex scenarios
6. Ensure cleanup (use `with_integration_db`)

## References

- [Gleam Testing Documentation](https://gleam.run/writing-gleam/testing/)
- [Gleeunit Framework](https://hexdocs.pm/gleeunit/)
- [PostgreSQL Testing Best Practices](https://www.postgresql.org/docs/current/regress.html)
- [Test Data Builders Pattern](https://martinfowler.com/bliki/ObjectMother.html)
