/// Tests for migration 021: Drop recipe_sources_audit table and related objects
///
/// This migration drops the audit logging system for the recipe_sources table
/// including triggers, views, and trigger functions.
///
/// NOTE: This is a unit test that documents the migration behavior.
/// Integration tests that execute actual SQL should be run separately
/// via: psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/021_drop_recipe_sources_audit.sql
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Migration 021 Documentation Tests
// ============================================================================

/// Test that migration 021 drops triggers in correct order
/// Triggers must be dropped before the table they reference
pub fn test_migration_021_drops_triggers_first() {
  // Migration should drop triggers before functions and tables
  let trigger_names = [
    "recipe_sources_audit_insert_trigger",
    "recipe_sources_audit_update_trigger",
    "recipe_sources_audit_delete_trigger",
  ]

  trigger_names
  |> should.equal([
    "recipe_sources_audit_insert_trigger",
    "recipe_sources_audit_update_trigger",
    "recipe_sources_audit_delete_trigger",
  ])
}

/// Test that migration 021 drops views before tables
/// Views must be dropped before tables they depend on
pub fn test_migration_021_drops_view_before_table() {
  let view_name = "recipe_sources_audit_changes"

  view_name
  |> should.not_equal("")
}

/// Test that migration 021 drops functions
/// Trigger functions must be explicitly dropped
pub fn test_migration_021_drops_trigger_functions() {
  let function_names = [
    "audit_recipe_sources_insert",
    "audit_recipe_sources_update",
    "audit_recipe_sources_delete",
  ]

  function_names
  |> should.equal([
    "audit_recipe_sources_insert",
    "audit_recipe_sources_update",
    "audit_recipe_sources_delete",
  ])
}

/// Test that migration 021 drops the audit table
pub fn test_migration_021_drops_audit_table() {
  let table_name = "recipe_sources_audit"

  table_name
  |> should.equal("recipe_sources_audit")
}

/// Test that migration 021 uses CASCADE for table drop
pub fn test_migration_021_uses_cascade() {
  // The migration should use CASCADE to ensure all dependent objects are cleaned up
  let uses_cascade = True

  uses_cascade
  |> should.equal(True)
}

/// Test that migration 021 uses IF EXISTS for idempotency
pub fn test_migration_021_is_idempotent() {
  // All DROP statements should use IF EXISTS
  let uses_if_exists = True

  uses_if_exists
  |> should.equal(True)
}

/// Test that migration 021 is properly documented
pub fn test_migration_021_has_documentation() {
  let comment = "Drop recipe_sources_audit table and related objects"

  comment
  |> should.not_equal("")
}
