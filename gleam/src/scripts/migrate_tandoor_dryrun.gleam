/// Dry-run migration mode for testing Tandoor recipe migration
///
/// This module provides dry-run mode functionality that allows safe testing
/// of migration operations before executing them for real. It supports:
/// - Recipe validation
/// - Preview of changes
/// - Progress tracking
/// - No actual data persistence
///
/// Usage:
///   gleam run -m scripts/migrate_tandoor_dryrun   # Preview migration

import envoy
import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

/// Recipe for migration
pub type Recipe {
  Recipe(
    id: Int,
    slug: String,
    name: String,
    description: String,
    ingredient_count: Int,
  )
}

/// Result of a migration attempt
pub type MigrationResult {
  MigrationResult(
    recipe_slug: String,
    tandoor_id: Option(Int),
    status: String,
    error: Option(String),
  )
}

/// Statistics about the migration
pub type MigrationStats {
  MigrationStats(
    total_recipes: Int,
    successful: Int,
    failed: Int,
    skipped: Int,
    duration_seconds: Float,
  )
}

/// Main entry point for dry-run migration
pub fn main() {
  io.println("")
  io.println("=== Tandoor Recipe Migration - DRY-RUN Mode ===")
  io.println("")
  io.println("This is a dry-run. No data will be changed.")
  io.println("")

  // Get log file path if specified
  let log_file = case envoy.get("LOG_FILE") {
    Ok(path) -> Some(path)
    Error(_) -> None
  }

  case log_file {
    Some(path) -> io.println("Log file: " <> path)
    None -> io.println("No log file specified (LOG_FILE env var)")
  }
  io.println("")

  // Run dry-run migration
  case run_dry_run_migration(log_file) {
    Ok(stats) -> {
      io.println("=== Dry-Run Migration Complete ===")
      print_stats(stats)
      io.println("")
      io.println("DRY-RUN successful - no data was modified.")
      io.println("")
      io.println("To execute the migration for real, run:")
      io.println("  gleam run -m scripts/migrate_tandoor")
    }
    Error(err) -> {
      io.println("=== Dry-Run Migration Failed ===")
      io.println("Error: " <> err)
      io.println("")
    }
  }
}

/// Execute dry-run migration
fn run_dry_run_migration(
  log_file: Option(String),
) -> Result(MigrationStats, String) {
  let recipes = get_test_recipes()

  case list.is_empty(recipes) {
    True -> Error("No recipes to migrate")
    False -> {
      io.println("Found " <> int.to_string(list.length(recipes)) <> " recipes to migrate")
      io.println("")

      // Validate all recipes first
      case validate_recipes(recipes) {
        Error(e) -> Error("Validation failed: " <> e)
        Ok(_) -> {
          io.println("Validation: OK - All recipes passed validation")
          io.println("")
          io.println("=== Preview of Migration Changes ===")
          io.println("")

          // Process recipes
          let results = process_recipes_dry_run(recipes)

          // Count results
          let successful =
            list.count(results, fn(r) { r.status == "success" })
          let failed =
            list.count(results, fn(r) { r.status == "failed" })

          // Save log if requested
          case log_file {
            Some(path) -> {
              let log_content = format_log(results)
              case simplifile.write(path, log_content) {
                Ok(_) -> {
                  io.println("")
                  io.println("Log saved to: " <> path)
                }
                Error(_) ->
                  io.println("Warning: Could not save log file")
              }
            }
            None -> Nil
          }

          io.println("")

          Ok(MigrationStats(
            total_recipes: list.length(recipes),
            successful: successful,
            failed: failed,
            skipped: 0,
            duration_seconds: 0.0,
          ))
        }
      }
    }
  }
}

/// Process recipes in dry-run mode
fn process_recipes_dry_run(
  recipes: List(Recipe),
) -> List(MigrationResult) {
  list.index_map(recipes, fn(recipe, idx) {
    let total = list.length(recipes)
    let percent = { idx + 1 } * 100 / total
    io.println(
      "[" <> int.to_string(percent) <> "%] Preview: " <> recipe.name,
    )

    // Validate recipe
    case validate_recipe(recipe) {
      Error(e) -> {
        io.println("  Status: WOULD FAIL - " <> e)
        MigrationResult(
          recipe_slug: recipe.slug,
          tandoor_id: None,
          status: "failed",
          error: Some(e),
        )
      }
      Ok(_) -> {
        // Simulate Tandoor ID that would be generated
        let simulated_id = 1000 + idx
        io.println(
          "  Status: WOULD CREATE with Tandoor ID " <> int.to_string(simulated_id),
        )
        MigrationResult(
          recipe_slug: recipe.slug,
          tandoor_id: Some(simulated_id),
          status: "success",
          error: None,
        )
      }
    }
  })
}

/// Get test recipes for dry-run
fn get_test_recipes() -> List(Recipe) {
  [
    Recipe(
      id: 1,
      slug: "chocolate-chip-cookies",
      name: "Chocolate Chip Cookies",
      description: "Classic homemade chocolate chip cookies",
      ingredient_count: 8,
    ),
    Recipe(
      id: 2,
      slug: "pasta-carbonara",
      name: "Pasta Carbonara",
      description: "Traditional Italian carbonara",
      ingredient_count: 5,
    ),
    Recipe(
      id: 3,
      slug: "chicken-stir-fry",
      name: "Chicken Stir Fry",
      description: "Quick and delicious stir fry",
      ingredient_count: 12,
    ),
    Recipe(
      id: 4,
      slug: "tomato-soup",
      name: "Tomato Soup",
      description: "Creamy homemade tomato soup",
      ingredient_count: 6,
    ),
    Recipe(
      id: 5,
      slug: "greek-salad",
      name: "Greek Salad",
      description: "Fresh Mediterranean salad",
      ingredient_count: 7,
    ),
  ]
}

/// Validate all recipes
fn validate_recipes(recipes: List(Recipe)) -> Result(Nil, String) {
  case list.all(recipes, fn(r) { validate_recipe(r) |> result.is_ok }) {
    True -> Ok(Nil)
    False -> Error("Some recipes failed validation")
  }
}

/// Validate single recipe
fn validate_recipe(recipe: Recipe) -> Result(Nil, String) {
  let errors = []

  let errors = case string.is_empty(recipe.slug) {
    True -> ["empty slug", ..errors]
    False -> errors
  }

  let errors = case string.is_empty(recipe.name) {
    True -> ["empty name", ..errors]
    False -> errors
  }

  let errors = case recipe.ingredient_count <= 0 {
    True -> ["no ingredients", ..errors]
    False -> errors
  }

  case list.is_empty(errors) {
    True -> Ok(Nil)
    False ->
      Error(
        recipe.slug
        <> ": "
        <> string.join(errors, ", "),
      )
  }
}

/// Format results as log
fn format_log(results: List(MigrationResult)) -> String {
  let header = "Tandoor Recipe Migration - Dry Run Log\n" <> "=" |> string.repeat(50) <> "\n\n"

  let body =
    results
    |> list.map(fn(result) {
      case result.tandoor_id {
        Some(id) ->
          result.recipe_slug
          <> " → Would create with Tandoor ID "
          <> int.to_string(id)
        None ->
          result.recipe_slug
          <> " → Would fail: "
          <> case result.error {
            Some(err) -> err
            None -> "unknown error"
          }
      }
    })
    |> string.join("\n")

  header <> body <> "\n"
}

/// Print statistics
fn print_stats(stats: MigrationStats) -> Nil {
  io.println("Total recipes: " <> int.to_string(stats.total_recipes))
  io.println("Would create: " <> int.to_string(stats.successful))
  io.println("Would fail: " <> int.to_string(stats.failed))
  io.println("Skipped: " <> int.to_string(stats.skipped))
  io.println("")
}
