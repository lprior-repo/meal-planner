/// Recipe migration script with progress reporting
///
/// This script demonstrates recipe migration from one source to another with
/// progress tracking that shows "X of Y recipes migrated".
///
/// Run with: gleam run -m scripts/migrate_recipes
import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import meal_planner/storage/migration_progress
import pog

/// Main entry point for the migration script
pub fn main() {
  io.println("=== Recipe Migration Script with Progress Reporting ===")
  io.println("")

  // Configuration
  let migration_id = "migration-" <> generate_timestamp()
  let pool_name = process.new_name(prefix: "recipe_migrate_pool")

  // Initialize database connection pool
  let config =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("meal_planner")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(10)

  case pog.start(config) {
    Error(e) -> {
      io.println("Failed to start database connection pool")
      io.println(format_start_error(e))
      Nil
    }
    Ok(started) -> {
      let db = started.data

      // Verify the migration_progress table exists
      case verify_table_exists(db) {
        False -> {
          io.println("ERROR: migration_progress table not found")
          io.println("Please run migration 026 first:")
          io.println(
            "  psql -d meal_planner -f migrations_pg/026_add_migration_progress_tracking.sql",
          )
          Nil
        }
        True -> {
          // Simulate recipe migration
          run_migration(db, migration_id)
        }
      }
    }
  }
}

/// Run the recipe migration with progress tracking
fn run_migration(db: pog.Connection, migration_id: String) -> Nil {
  // Sample recipe data (simulating recipes to migrate)
  let sample_recipes = [
    "Grilled Chicken Breast",
    "Salmon with Lemon",
    "Turkey Meatballs",
    "Beef Stew",
    "Chicken Stir Fry",
    "Grilled Fish Tacos",
    "Pasta Primavera",
    "Vegetable Soup",
    "Roasted Root Vegetables",
    "Herb Roasted Chicken",
  ]

  let total_recipes = list.length(sample_recipes)

  io.println("Starting recipe migration...")
  io.println("Total recipes to migrate: " <> int.to_string(total_recipes))
  io.println("")

  // Create migration progress tracker
  case migration_progress.create_migration(db, migration_id, total_recipes) {
    Error(msg) -> {
      io.println("ERROR: Failed to create migration tracker")
      io.println(msg)
      Nil
    }
    Ok(Nil) -> {
      io.println("Migration tracker initialized")
      io.println("")

      // Simulate recipe migration with progress reporting
      let _ =
        sample_recipes
        |> list.fold(0, fn(index, _recipe_name) {
          // Simulate processing time
          process.sleep(500)

          // Update progress
          case migration_progress.increment_migrated(db, migration_id) {
            Error(msg) -> {
              io.println("Error updating progress: " <> msg)
            }
            Ok(Nil) -> {
              // Get current progress
              case migration_progress.get_progress(db, migration_id) {
                Error(msg) -> {
                  io.println("Error fetching progress: " <> msg)
                }
                Ok(progress) -> {
                  let percentage =
                    migration_progress.get_progress_percentage(progress)
                  let message =
                    migration_progress.format_progress_message(progress)
                  io.println(
                    message <> " (" <> format_percentage(percentage) <> "%)",
                  )
                }
              }
            }
          }

          index + 1
        })

      io.println("")

      // Final status
      case migration_progress.get_progress(db, migration_id) {
        Error(msg) -> {
          io.println("Error fetching final progress: " <> msg)
        }
        Ok(final_progress) -> {
          case migration_progress.complete_migration(db, migration_id) {
            Error(msg) -> {
              io.println("Error completing migration: " <> msg)
            }
            Ok(Nil) -> {
              io.println("Migration completed successfully!")
              io.println(
                "Final status: "
                <> migration_progress.format_progress_message(final_progress),
              )
              case final_progress.failed_count {
                0 -> {
                  io.println("All recipes migrated with no errors")
                }
                n -> {
                  io.println(int.to_string(n) <> " recipes failed to migrate")
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Verify the migration_progress table exists
fn verify_table_exists(db: pog.Connection) -> Bool {
  let sql =
    "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_progress')"

  case
    pog.query(sql)
    |> pog.execute(db)
  {
    Error(_) -> False
    Ok(rows) -> {
      case rows {
        [] -> False
        [row, ..] -> {
          case pog.col_bool(row, 0) {
            Error(_) -> False
            Ok(exists) -> exists
          }
        }
      }
    }
  }
}

/// Generate a timestamp string for the migration ID
fn generate_timestamp() -> String {
  "20251212-" <> int.to_string(erlang_time())
}

/// Get current Erlang timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn erlang_time() -> Int

/// Format percentage with one decimal place
fn format_percentage(percentage: Float) -> String {
  let rounded = percentage |> int.floor_divide(1) |> result.unwrap(0)
  int.to_string(rounded)
}

/// Format database start error for display
fn format_start_error(_error: pog.QueryError) -> String {
  "Make sure PostgreSQL is running and accessible at localhost:5432"
}
