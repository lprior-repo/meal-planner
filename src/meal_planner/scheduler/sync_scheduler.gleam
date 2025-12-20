//// FatSecret Auto-Sync Scheduler
////
//// Automatically syncs today's meal plan to FatSecret diary every 2-4 hours.
//// Part of NORTH STAR epic (meal-planner-gsa).

import birl
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import meal_planner/config.{type Config}
import meal_planner/id.{type UserId}
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types.{type SchedulerError}

// ============================================================================
// Core Types
// ============================================================================

/// Result of auto-sync execution
pub type SyncResult {
  SyncResult(synced: Int, skipped: Int, failed: Int, errors: List(String))
}

// ============================================================================
// Main Entry Point
// ============================================================================

/// Trigger automatic sync of today's meal plan to FatSecret diary
pub fn trigger_auto_sync(user_id: UserId) -> Result(SyncResult, SchedulerError) {
  // Step 1: Create job execution record
  let job_id =
    id.job_id(
      "auto_sync_" <> { birl.now() |> birl.to_unix_milli |> int.to_string },
    )
  let execution = job_manager.mark_job_running(job_id)

  case execution {
    Ok(_exec) -> {
      // Step 2: Perform the sync operation
      let sync_result = perform_fatsecret_sync(user_id)

      // Step 3: Update execution record with results
      case sync_result {
        Ok(result) -> {
          // Mark job as completed with output
          let output = sync_result_to_json(result) |> option.Some
          let _ = job_manager.mark_job_completed(job_id, output)
          Ok(result)
        }
        Error(err) -> {
          // Mark job as failed
          let _ = job_manager.mark_job_failed(job_id, "Sync failed")
          Error(err)
        }
      }
    }
    Error(err) -> Error(err)
  }
}

/// Perform the actual FatSecret diary sync
/// TODO: Implement when FatSecret sync module is ready
fn perform_fatsecret_sync(
  _user_id: UserId,
) -> Result(SyncResult, SchedulerError) {
  // Get today's date in YYYY-MM-DD format
  let _today = get_today_date()

  // TODO: Implement full sync logic when database queries are ready
  // This would:
  // 1. Fetch today's meal plan from local database
  // 2. For each meal entry, create/update FatSecret diary entry
  // 3. Track synced/skipped/failed counts
  // 4. Return comprehensive result

  // For now, return empty result
  Ok(SyncResult(synced: 0, skipped: 0, failed: 0, errors: []))
}

/// Trigger full synchronization of all Tandoor data to local storage
///
/// Synchronizes:
/// - Recipes
/// - Ingredients
/// - Meal plans
/// - Shopping lists
///
/// This is the foundation for offline access and caching.
///
/// Returns:
/// - Ok(SyncResult) with counts of synced/skipped/failed items
/// - Error(SchedulerError) on failure
pub fn trigger_full_sync(_config: Config) -> Result(SyncResult, SchedulerError) {
  // TODO: Implement full sync logic
  // 1. Fetch all recipes from Tandoor API
  // 2. Fetch all ingredients
  // 3. Fetch all meal plans
  // 4. Fetch all shopping lists
  // 5. Store locally in database
  // 6. Return summary statistics

  // For now, return empty result indicating no items synced yet
  Ok(SyncResult(synced: 0, skipped: 0, failed: 0, errors: []))
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get today's date in YYYY-MM-DD format
fn get_today_date() -> String {
  birl.now()
  |> birl.to_iso8601
  |> string.split("-")
  |> list.take(3)
  |> string.join("-")
}

// ============================================================================
// JSON Encoders
// ============================================================================

/// Encode SyncResult to JSON for job output
pub fn sync_result_to_json(result: SyncResult) -> json.Json {
  json.object([
    #("synced", json.int(result.synced)),
    #("skipped", json.int(result.skipped)),
    #("failed", json.int(result.failed)),
    #("errors", json.array(result.errors, json.string)),
  ])
}
