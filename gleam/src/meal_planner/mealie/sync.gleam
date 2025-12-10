//// Mealie Meal Plan Sync Module
////
//// Provides bidirectional synchronization between Gleam auto-planner
//// generated meal plans and Mealie's meal plan API.
////
//// Key features:
//// - Push generated plans to Mealie
//// - Pull existing plans from Mealie
//// - Diff-based sync to minimize API calls
//// - Conflict resolution strategies

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/auto_planner/types as auto_types
import meal_planner/config.{type Config}
import meal_planner/id
import meal_planner/mealie/client.{type ClientError}
import meal_planner/mealie/types.{type MealieMealPlanEntry, MealieMealPlanEntry}
import meal_planner/types as meal_types

// ============================================================================
// Types
// ============================================================================

/// Sync operation result
pub type SyncResult {
  SyncResult(
    /// Entries created in Mealie
    created: List(MealieMealPlanEntry),
    /// Entries updated in Mealie
    updated: List(MealieMealPlanEntry),
    /// Entries deleted from Mealie
    deleted: List(String),
    /// Entries that failed to sync
    errors: List(SyncError),
  )
}

/// Sync error with context
pub type SyncError {
  SyncError(entry_date: String, entry_type: String, error: ClientError)
}

/// Conflict resolution strategy
pub type ConflictStrategy {
  /// Local (Gleam) wins - overwrite Mealie entries
  LocalWins
  /// Remote (Mealie) wins - keep Mealie entries
  RemoteWins
  /// Merge - keep both, add new entries
  Merge
}

/// Sync options
pub type SyncOptions {
  SyncOptions(
    /// How to handle conflicts
    conflict_strategy: ConflictStrategy,
    /// Whether to delete remote entries not in local plan
    delete_orphans: Bool,
    /// Entry type to use (e.g., "breakfast", "lunch", "dinner")
    default_entry_type: String,
  )
}

/// A local meal plan entry for sync
pub type LocalMealPlanEntry {
  LocalMealPlanEntry(
    date: String,
    entry_type: String,
    title: String,
    recipe_id: Option(String),
    text: Option(String),
  )
}

// ============================================================================
// Default Configuration
// ============================================================================

/// Default sync options - local wins, delete orphans, dinner as default
pub fn default_sync_options() -> SyncOptions {
  SyncOptions(
    conflict_strategy: LocalWins,
    delete_orphans: True,
    default_entry_type: "dinner",
  )
}

/// Merge-based sync options - keeps both local and remote
pub fn merge_sync_options() -> SyncOptions {
  SyncOptions(
    conflict_strategy: Merge,
    delete_orphans: False,
    default_entry_type: "dinner",
  )
}

// ============================================================================
// Main Sync Functions
// ============================================================================

/// Sync local meal plan entries to Mealie for a date range
///
/// This is the main entry point for pushing generated meal plans to Mealie.
///
/// ## Flow:
/// 1. Fetch existing entries from Mealie for the date range
/// 2. Compare with local entries
/// 3. Apply conflict resolution strategy
/// 4. Create/update/delete entries as needed
///
/// ## Example:
/// ```gleam
/// let entries = [
///   LocalMealPlanEntry(
///     date: "2025-12-10",
///     entry_type: "dinner",
///     title: "Chicken Stir Fry",
///     recipe_id: Some("chicken-stir-fry"),
///     text: None,
///   ),
/// ]
/// case sync_to_mealie(config, entries, "2025-12-10", "2025-12-16", default_sync_options()) {
///   Ok(result) -> {
///     io.println("Created: " <> int.to_string(list.length(result.created)))
///     io.println("Updated: " <> int.to_string(list.length(result.updated)))
///   }
///   Error(err) -> io.println("Sync failed: " <> client.error_to_string(err))
/// }
/// ```
pub fn sync_to_mealie(
  config: Config,
  local_entries: List(LocalMealPlanEntry),
  start_date: String,
  end_date: String,
  options: SyncOptions,
) -> Result(SyncResult, ClientError) {
  // Fetch existing entries from Mealie
  use remote_entries <- result.try(client.get_meal_plans(
    config,
    start_date,
    end_date,
  ))

  // Perform the sync
  sync_entries(config, local_entries, remote_entries, options)
}

/// Sync local entries with remote entries according to strategy
fn sync_entries(
  config: Config,
  local_entries: List(LocalMealPlanEntry),
  remote_entries: List(MealieMealPlanEntry),
  options: SyncOptions,
) -> Result(SyncResult, ClientError) {
  case options.conflict_strategy {
    LocalWins -> sync_local_wins(config, local_entries, remote_entries, options)
    RemoteWins -> Ok(SyncResult(created: [], updated: [], deleted: [], errors: []))
    Merge -> sync_merge(config, local_entries, remote_entries, options)
  }
}

/// Local wins strategy: overwrite remote entries with local
fn sync_local_wins(
  config: Config,
  local_entries: List(LocalMealPlanEntry),
  remote_entries: List(MealieMealPlanEntry),
  options: SyncOptions,
) -> Result(SyncResult, ClientError) {
  // Find entries to create, update, or delete
  let to_create =
    list.filter(local_entries, fn(local) {
      !has_matching_remote(local, remote_entries)
    })

  let to_update =
    list.filter_map(local_entries, fn(local) {
      find_matching_remote(local, remote_entries)
    })

  let to_delete = case options.delete_orphans {
    True ->
      list.filter(remote_entries, fn(remote) {
        !has_matching_local(remote, local_entries)
      })
    False -> []
  }

  // Execute creates
  let #(created, create_errors) =
    create_entries(config, to_create, options.default_entry_type)

  // Execute updates
  let #(updated, update_errors) = update_entries(config, to_update, local_entries)

  // Execute deletes
  let #(deleted, delete_errors) = delete_entries(config, to_delete)

  Ok(SyncResult(
    created: created,
    updated: updated,
    deleted: deleted,
    errors: list.flatten([create_errors, update_errors, delete_errors]),
  ))
}

/// Merge strategy: add new entries without deleting existing
fn sync_merge(
  config: Config,
  local_entries: List(LocalMealPlanEntry),
  remote_entries: List(MealieMealPlanEntry),
  _options: SyncOptions,
) -> Result(SyncResult, ClientError) {
  // Only create entries that don't exist remotely
  let to_create =
    list.filter(local_entries, fn(local) {
      !has_matching_remote(local, remote_entries)
    })

  let #(created, errors) = create_entries(config, to_create, "dinner")

  Ok(SyncResult(created: created, updated: [], deleted: [], errors: errors))
}

// ============================================================================
// Matching Helpers
// ============================================================================

/// Check if a local entry has a matching remote entry (same date + type)
fn has_matching_remote(
  local: LocalMealPlanEntry,
  remote_entries: List(MealieMealPlanEntry),
) -> Bool {
  list.any(remote_entries, fn(remote) {
    remote.date == local.date && remote.entry_type == local.entry_type
  })
}

/// Find matching remote entry for a local entry
fn find_matching_remote(
  local: LocalMealPlanEntry,
  remote_entries: List(MealieMealPlanEntry),
) -> Result(MealieMealPlanEntry, Nil) {
  list.find(remote_entries, fn(remote) {
    remote.date == local.date && remote.entry_type == local.entry_type
  })
}

/// Check if a remote entry has a matching local entry
fn has_matching_local(
  remote: MealieMealPlanEntry,
  local_entries: List(LocalMealPlanEntry),
) -> Bool {
  list.any(local_entries, fn(local) {
    remote.date == local.date && remote.entry_type == local.entry_type
  })
}

// ============================================================================
// CRUD Operations
// ============================================================================

/// Create new entries in Mealie
fn create_entries(
  config: Config,
  entries: List(LocalMealPlanEntry),
  default_type: String,
) -> #(List(MealieMealPlanEntry), List(SyncError)) {
  let results =
    list.map(entries, fn(local) {
      let mealie_entry =
        MealieMealPlanEntry(
          id: "",
          date: local.date,
          entry_type: case local.entry_type {
            "" -> default_type
            t -> t
          },
          title: Some(local.title),
          text: local.text,
          recipe_id: local.recipe_id,
          recipe: None,
        )

      case client.create_meal_plan_entry(config, mealie_entry) {
        Ok(created) -> Ok(created)
        Error(err) ->
          Error(SyncError(
            entry_date: local.date,
            entry_type: local.entry_type,
            error: err,
          ))
      }
    })

  partition_results(results)
}

/// Update existing entries in Mealie
fn update_entries(
  config: Config,
  remote_entries: List(MealieMealPlanEntry),
  local_entries: List(LocalMealPlanEntry),
) -> #(List(MealieMealPlanEntry), List(SyncError)) {
  let results =
    list.map(remote_entries, fn(remote) {
      // Find matching local entry
      case
        list.find(local_entries, fn(local) {
          remote.date == local.date && remote.entry_type == local.entry_type
        })
      {
        Ok(local) -> {
          // Update remote with local data
          let updated_entry =
            MealieMealPlanEntry(
              ..remote,
              title: Some(local.title),
              text: local.text,
              recipe_id: local.recipe_id,
            )

          case client.update_meal_plan_entry(config, updated_entry) {
            Ok(updated) -> Ok(updated)
            Error(err) ->
              Error(SyncError(
                entry_date: remote.date,
                entry_type: remote.entry_type,
                error: err,
              ))
          }
        }
        Error(_) -> Error(SyncError(
          entry_date: remote.date,
          entry_type: remote.entry_type,
          error: client.ConfigError("No matching local entry found"),
        ))
      }
    })

  partition_results(results)
}

/// Delete entries from Mealie
fn delete_entries(
  config: Config,
  entries: List(MealieMealPlanEntry),
) -> #(List(String), List(SyncError)) {
  let results =
    list.map(entries, fn(entry) {
      case client.delete_meal_plan_entry(config, entry.id) {
        Ok(_) -> Ok(entry.id)
        Error(err) ->
          Error(SyncError(
            entry_date: entry.date,
            entry_type: entry.entry_type,
            error: err,
          ))
      }
    })

  partition_delete_results(results)
}

// ============================================================================
// Result Helpers
// ============================================================================

/// Partition results into successes and errors
fn partition_results(
  results: List(Result(MealieMealPlanEntry, SyncError)),
) -> #(List(MealieMealPlanEntry), List(SyncError)) {
  list.fold(results, #([], []), fn(acc, res) {
    case res {
      Ok(entry) -> #([entry, ..acc.0], acc.1)
      Error(err) -> #(acc.0, [err, ..acc.1])
    }
  })
}

/// Partition delete results into successes and errors
fn partition_delete_results(
  results: List(Result(String, SyncError)),
) -> #(List(String), List(SyncError)) {
  list.fold(results, #([], []), fn(acc, res) {
    case res {
      Ok(id) -> #([id, ..acc.0], acc.1)
      Error(err) -> #(acc.0, [err, ..acc.1])
    }
  })
}

// ============================================================================
// Formatting
// ============================================================================

/// Format sync result for display
pub fn format_sync_result(result: SyncResult) -> String {
  let created_count = list.length(result.created)
  let updated_count = list.length(result.updated)
  let deleted_count = list.length(result.deleted)
  let error_count = list.length(result.errors)

  "Meal Plan Sync Complete\n"
  <> "━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  <> "✓ Created: "
  <> string.inspect(created_count)
  <> "\n"
  <> "✓ Updated: "
  <> string.inspect(updated_count)
  <> "\n"
  <> "✓ Deleted: "
  <> string.inspect(deleted_count)
  <> "\n"
  <> case error_count > 0 {
    True -> "✗ Errors: " <> string.inspect(error_count) <> "\n"
    False -> ""
  }
}

/// Format sync error for display
pub fn format_sync_error(error: SyncError) -> String {
  "Failed to sync "
  <> error.entry_type
  <> " on "
  <> error.entry_date
  <> ": "
  <> client.error_to_string(error.error)
}

// ============================================================================
// Auto-Planner Integration
// ============================================================================

/// Sync an auto-generated meal plan to Mealie
///
/// Converts recipes from an AutoMealPlan to LocalMealPlanEntry and syncs them.
/// Only syncs recipes that came from Mealie (IDs starting with "mealie-").
///
/// ## Example:
/// ```gleam
/// let plan = ncp_auto_planner.generate_meal_plan_for_deficit(conn, goals, actual, config, 5)
/// case sync_auto_plan_to_mealie(app_config, plan, "2025-12-10", "dinner") {
///   Ok(result) -> {
///     io.println("Synced " <> int.to_string(list.length(result.created)) <> " recipes")
///   }
///   Error(err) -> io.println("Sync failed")
/// }
/// ```
pub fn sync_auto_plan_to_mealie(
  config: Config,
  plan: auto_types.AutoMealPlan,
  date: String,
  entry_type: String,
) -> Result(SyncResult, ClientError) {
  // Convert auto plan recipes to local entries
  let local_entries = auto_plan_to_local_entries(plan, date, entry_type)

  // Use merge strategy to avoid overwriting existing entries
  sync_to_mealie(config, local_entries, date, date, merge_sync_options())
}

/// Convert an AutoMealPlan to LocalMealPlanEntry list
///
/// Only includes recipes that came from Mealie (IDs starting with "mealie-").
/// These recipe IDs have format "mealie-<slug>" where slug is used as recipe_id.
pub fn auto_plan_to_local_entries(
  plan: auto_types.AutoMealPlan,
  date: String,
  entry_type: String,
) -> List(LocalMealPlanEntry) {
  list.filter_map(plan.recipes, fn(recipe) {
    case extract_mealie_slug(recipe) {
      Some(slug) ->
        Ok(LocalMealPlanEntry(
          date: date,
          entry_type: entry_type,
          title: recipe.name,
          recipe_id: Some(slug),
          text: None,
        ))
      None -> Error(Nil)
    }
  })
}

/// Extract Mealie recipe slug from recipe ID
///
/// Returns Some(slug) if the recipe ID starts with "mealie-", None otherwise.
fn extract_mealie_slug(recipe: meal_types.Recipe) -> Option(String) {
  let id_str = id.recipe_id_to_string(recipe.id)
  case string.starts_with(id_str, "mealie-") {
    True -> Some(string.drop_start(id_str, 7))
    False -> None
  }
}

/// Check how many recipes in a plan are from Mealie
pub fn count_mealie_recipes(plan: auto_types.AutoMealPlan) -> Int {
  list.count(plan.recipes, fn(recipe) {
    case extract_mealie_slug(recipe) {
      Some(_) -> True
      None -> False
    }
  })
}

/// Get list of non-Mealie recipes (for informational purposes)
pub fn get_non_mealie_recipes(plan: auto_types.AutoMealPlan) -> List(String) {
  list.filter_map(plan.recipes, fn(recipe) {
    case extract_mealie_slug(recipe) {
      Some(_) -> Error(Nil)
      None -> Ok(recipe.name)
    }
  })
}
