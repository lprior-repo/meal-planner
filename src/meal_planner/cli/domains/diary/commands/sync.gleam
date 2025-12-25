/// Sync commands for diary domain
///
/// Handles synchronization between Tandoor and FatSecret:
/// - sync_to_tandoor: Export FatSecret diary to Tandoor meal plan
/// - sync_from_fatsecret: Import Tandoor meal plan to FatSecret diary
import gleam/io
import gleam/option.{Some}
import meal_planner/config.{type Config}
import meal_planner/postgres
import pog

// ============================================================================
// Helper Functions
// ============================================================================

/// Create database connection
fn create_db_connection(config: Config) -> Result(pog.Connection, String) {
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: Some(config.database.password),
      pool_size: config.database.pool_size,
    )
  case postgres.connect(db_config) {
    Ok(conn) -> Ok(conn)
    Error(_) -> Error("Failed to connect to database")
  }
}

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle sync_to_tandoor command - export FatSecret entries to Tandoor
///
/// Takes a date range and exports FatSecret diary entries to Tandoor
/// as a meal plan. This allows meal tracking from FatSecret to inform
/// Tandoor meal planning.
pub fn sync_to_tandoor_handler(
  config: Config,
  start_date: String,
  end_date: String,
) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(_conn) -> {
      // TODO: Implement sync logic
      // 1. Fetch FatSecret entries for date range
      // 2. Aggregate nutrition by meal
      // 3. Create or update Tandoor meal plan entries
      // 4. Report results
      io.println(
        "Syncing FatSecret diary to Tandoor: "
        <> start_date
        <> " to "
        <> end_date,
      )
      io.println("(Sync to Tandoor not yet implemented)")
      Ok(Nil)
    }
  }
}

/// Handle sync_from_fatsecret command - import Tandoor meal plan to FatSecret
///
/// Takes a date range and syncs Tandoor meal plan to FatSecret diary.
/// This creates FatSecret diary entries from planned Tandoor meals.
pub fn sync_from_fatsecret_handler(
  config: Config,
  start_date: String,
  end_date: String,
) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(_conn) -> {
      // TODO: Implement sync logic using meal_sync.gleam
      // 1. Fetch Tandoor meal plan for date range
      // 2. Get recipe nutrition for each meal
      // 3. Create FatSecret diary entries
      // 4. Report sync results using meal_sync.format_sync_report
      io.println(
        "Syncing Tandoor meal plan to FatSecret: "
        <> start_date
        <> " to "
        <> end_date,
      )
      io.println("(Sync from FatSecret not yet implemented)")
      Ok(Nil)
    }
  }
}
