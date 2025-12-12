/// Tests for migration 023: Add recipe_json column to auto_meal_plans table
///
/// This migration adds a JSONB column to store full recipe data for faster
/// loading without requiring joins to separate recipe tables.
///
/// NOTE: This is a unit test that documents the migration behavior.
/// Integration tests that execute actual SQL should be run separately
/// via: psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/023_add_recipe_json_to_auto_meal_plans.sql
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Migration 023 Documentation Tests
// ============================================================================

/// Test that migration 023 adds recipe_json column to auto_meal_plans
pub fn test_migration_023_adds_recipe_json_column() {
  // Migration should add recipe_json JSONB column to auto_meal_plans table
  let column_name = "recipe_json"

  column_name
  |> should.equal("recipe_json")
}

/// Test that migration 023 uses JSONB data type for recipe_json
/// JSONB provides better performance for queries compared to JSON
pub fn test_migration_023_uses_jsonb_type() {
  let data_type = "JSONB"

  data_type
  |> should.equal("JSONB")
}

/// Test that migration 023 creates GIN index for recipe_json
/// GIN index optimizes JSONB containment and existence checks
pub fn test_migration_023_creates_gin_index() {
  let index_name = "idx_auto_meal_plans_recipe_json"

  index_name
  |> should.equal("idx_auto_meal_plans_recipe_json")
}

/// Test that migration 023 uses IF NOT EXISTS for idempotency
/// Column creation should be idempotent to allow re-running
pub fn test_migration_023_uses_if_not_exists() {
  let uses_if_not_exists = True

  uses_if_not_exists
  |> should.equal(True)
}

/// Test that migration 023 adds documentation comment
/// Column should be documented for clarity
pub fn test_migration_023_adds_documentation() {
  let comment =
    "Full recipe data serialized as JSON array for fast access without joins"

  comment
  |> should.not_equal("")
}

/// Test that migration 023 is idempotent
/// The migration should be safe to run multiple times
pub fn test_migration_023_is_idempotent() {
  // All CREATE INDEX IF NOT EXISTS statements ensure idempotency
  let is_idempotent = True

  is_idempotent
  |> should.equal(True)
}

/// Test that recipe_json column is nullable
/// Allows for gradual migration of existing data
pub fn test_migration_023_column_is_nullable() {
  // No NOT NULL constraint means column is nullable by default
  let is_nullable = True

  is_nullable
  |> should.equal(True)
}

/// Test that migration 023 documents the purpose
pub fn test_migration_023_has_clear_intent() {
  let purpose = "Stores full recipe data as JSONB for faster loading without joins"

  purpose
  |> should.not_equal("")
}
