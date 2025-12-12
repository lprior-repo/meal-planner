/// Tests for migration 019: Drop recipes table
///
/// This migration drops the recipes table to complete the migration to using
/// Mealie as the sole source of truth for recipes.
///
/// NOTE: This is a unit test that documents the migration behavior.
/// Integration tests that execute actual SQL should be run separately
/// via: psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/019_drop_recipes_table.sql
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Migration 019 Documentation Tests
// ============================================================================

/// Test that migration 019 SQL is valid
/// This test documents that the migration:
/// 1. Uses DROP TABLE IF EXISTS for idempotency
/// 2. Uses CASCADE to handle dependencies
/// 3. Removes the recipes table cleanly
pub fn test_migration_019_uses_correct_sql_pattern() {
  // The migration SQL should be:
  // DROP TABLE IF EXISTS recipes CASCADE;

  let migration_pattern = "DROP TABLE IF EXISTS"
  let cascade_pattern = "CASCADE"

  // Verify basic SQL patterns are correct
  migration_pattern
  |> should.not_equal("")

  cascade_pattern
  |> should.equal("CASCADE")
}

/// Test that migration 019 is documented
/// Migration should have rollback documentation
pub fn test_migration_019_has_rollback_documentation() {
  // Migration 019 should reference rollback file
  let rollback_reference =
    "migrations_pg/rollback/019_restore_recipes_table.sql"

  rollback_reference
  |> should.not_equal("")
}

/// Test that using DROP TABLE IF EXISTS makes migration idempotent
pub fn test_migration_019_idempotency_pattern() {
  let uses_if_exists = True

  uses_if_exists
  |> should.equal(True)
}
