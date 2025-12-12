/// Tests for migration progress tracking
import gleeunit
import gleeunit/should
import meal_planner/storage/migration_progress

pub fn main() {
  gleeunit.main()
}

/// Test that MigrationProgress can be created with expected fields
pub fn test_migration_progress_creation() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-migration-1",
      total_recipes: 100,
      migrated_count: 50,
      failed_count: 2,
      status: "in_progress",
    )

  progress.migration_id |> should.equal("test-migration-1")
  progress.total_recipes |> should.equal(100)
  progress.migrated_count |> should.equal(50)
  progress.failed_count |> should.equal(2)
  progress.status |> should.equal("in_progress")
}

/// Test format_progress_message generates correct output
pub fn test_format_progress_message() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 45,
      failed_count: 0,
      status: "in_progress",
    )

  migration_progress.format_progress_message(progress)
  |> should.equal("45 of 100 recipes migrated")
}

/// Test format_progress_message with zero migrated
pub fn test_format_progress_message_zero() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 0,
      failed_count: 0,
      status: "in_progress",
    )

  migration_progress.format_progress_message(progress)
  |> should.equal("0 of 100 recipes migrated")
}

/// Test format_progress_message with all migrated
pub fn test_format_progress_message_complete() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 100,
      failed_count: 0,
      status: "completed",
    )

  migration_progress.format_progress_message(progress)
  |> should.equal("100 of 100 recipes migrated")
}

/// Test get_progress_percentage with 50% complete
pub fn test_get_progress_percentage_50_percent() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 50,
      failed_count: 0,
      status: "in_progress",
    )

  migration_progress.get_progress_percentage(progress)
  |> should.equal(50.0)
}

/// Test get_progress_percentage with 0% complete
pub fn test_get_progress_percentage_zero_percent() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 0,
      failed_count: 0,
      status: "in_progress",
    )

  migration_progress.get_progress_percentage(progress)
  |> should.equal(0.0)
}

/// Test get_progress_percentage with 100% complete
pub fn test_get_progress_percentage_100_percent() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 100,
      migrated_count: 100,
      failed_count: 0,
      status: "completed",
    )

  migration_progress.get_progress_percentage(progress)
  |> should.equal(100.0)
}

/// Test get_progress_percentage with zero total (edge case)
pub fn test_get_progress_percentage_zero_total() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 0,
      migrated_count: 0,
      failed_count: 0,
      status: "in_progress",
    )

  migration_progress.get_progress_percentage(progress)
  |> should.equal(0.0)
}

/// Test that completed status is correctly set
pub fn test_migration_completed_status() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 10,
      migrated_count: 10,
      failed_count: 0,
      status: "completed",
    )

  progress.status |> should.equal("completed")
}

/// Test that failed status is correctly set
pub fn test_migration_failed_status() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 10,
      migrated_count: 5,
      failed_count: 5,
      status: "failed",
    )

  progress.status |> should.equal("failed")
}

/// Test that in_progress status is correctly set
pub fn test_migration_in_progress_status() {
  let progress =
    migration_progress.MigrationProgress(
      migration_id: "test-1",
      total_recipes: 10,
      migrated_count: 3,
      failed_count: 1,
      status: "in_progress",
    )

  progress.status |> should.equal("in_progress")
}

/// Test complete progress tracking scenario
pub fn test_complete_migration_scenario() {
  // Start with 0 progress
  let initial =
    migration_progress.MigrationProgress(
      migration_id: "test-scenario-1",
      total_recipes: 5,
      migrated_count: 0,
      failed_count: 0,
      status: "in_progress",
    )

  initial |> migration_progress.format_progress_message
  |> should.equal("0 of 5 recipes migrated")

  // After first batch
  let after_first =
    migration_progress.MigrationProgress(
      migration_id: "test-scenario-1",
      total_recipes: 5,
      migrated_count: 2,
      failed_count: 0,
      status: "in_progress",
    )

  after_first |> migration_progress.format_progress_message
  |> should.equal("2 of 5 recipes migrated")
  after_first |> migration_progress.get_progress_percentage
  |> should.equal(40.0)

  // After completion
  let completed =
    migration_progress.MigrationProgress(
      migration_id: "test-scenario-1",
      total_recipes: 5,
      migrated_count: 5,
      failed_count: 0,
      status: "completed",
    )

  completed |> migration_progress.format_progress_message
  |> should.equal("5 of 5 recipes migrated")
  completed |> migration_progress.get_progress_percentage
  |> should.equal(100.0)
}
