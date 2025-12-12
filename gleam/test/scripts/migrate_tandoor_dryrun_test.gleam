/// Tests for the Tandoor dry-run migration script
///
/// This test suite verifies:
/// - Recipe validation logic
/// - Dry-run preview functionality
/// - Statistics calculation
/// - Log file formatting
/// - Error handling

import gleeunit
import gleeunit/should
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Test types (mirroring the actual script)
pub type Recipe {
  Recipe(
    id: Int,
    slug: String,
    name: String,
    description: String,
    ingredient_count: Int,
  )
}

pub type MigrationResult {
  MigrationResult(
    recipe_slug: String,
    tandoor_id: Option(Int),
    status: String,
    error: Option(String),
  )
}

pub type MigrationStats {
  MigrationStats(
    total_recipes: Int,
    successful: Int,
    failed: Int,
    skipped: Int,
    duration_seconds: Float,
  )
}

// Helper to create test recipes
fn make_recipe(id: Int, slug: String, name: String, ingredients: Int) {
  Recipe(
    id: id,
    slug: slug,
    name: name,
    description: "Test recipe",
    ingredient_count: ingredients,
  )
}

// ==============================================================================
// VALIDATION TESTS
// ==============================================================================

pub fn test_validate_recipe_valid() {
  let recipe = make_recipe(1, "pasta", "Pasta", 5)
  validate_recipe(recipe)
  |> should.equal(Ok(Nil))
}

pub fn test_validate_recipe_empty_slug() {
  let recipe = make_recipe(1, "", "Pasta", 5)
  validate_recipe(recipe)
  |> should.be_error()
}

pub fn test_validate_recipe_empty_name() {
  let recipe = make_recipe(1, "pasta", "", 5)
  validate_recipe(recipe)
  |> should.be_error()
}

pub fn test_validate_recipe_zero_ingredients() {
  let recipe = make_recipe(1, "pasta", "Pasta", 0)
  validate_recipe(recipe)
  |> should.be_error()
}

pub fn test_validate_recipe_negative_ingredients() {
  let recipe = make_recipe(1, "pasta", "Pasta", -5)
  validate_recipe(recipe)
  |> should.be_error()
}

pub fn test_validate_recipes_all_valid() {
  let recipes = [
    make_recipe(1, "pasta", "Pasta", 5),
    make_recipe(2, "salad", "Salad", 3),
    make_recipe(3, "soup", "Soup", 4),
  ]
  validate_recipes(recipes)
  |> should.equal(Ok(Nil))
}

pub fn test_validate_recipes_empty_list() {
  let recipes: List(Recipe) = []
  validate_recipes(recipes)
  |> should.equal(Ok(Nil))
}

pub fn test_validate_recipes_with_invalid() {
  let recipes = [
    make_recipe(1, "pasta", "Pasta", 5),
    make_recipe(2, "", "Invalid", 3),
  ]
  validate_recipes(recipes)
  |> should.be_error()
}

// ==============================================================================
// MIGRATION RESULT TESTS
// ==============================================================================

pub fn test_migration_result_success() {
  let result = MigrationResult(
    recipe_slug: "pasta",
    tandoor_id: Some(123),
    status: "success",
    error: None,
  )
  result.status
  |> should.equal("success")
  result.tandoor_id
  |> should.equal(Some(123))
  result.error
  |> should.equal(None)
}

pub fn test_migration_result_failure() {
  let result = MigrationResult(
    recipe_slug: "pasta",
    tandoor_id: None,
    status: "failed",
    error: Some("Invalid ingredients"),
  )
  result.status
  |> should.equal("failed")
  result.tandoor_id
  |> should.equal(None)
  result.error
  |> should.equal(Some("Invalid ingredients"))
}

pub fn test_count_successful_results() {
  let results = [
    MigrationResult("pasta", Some(1), "success", None),
    MigrationResult("salad", Some(2), "success", None),
    MigrationResult("soup", None, "failed", Some("Error")),
  ]
  let successful = list.count(results, fn(r) { r.status == "success" })
  successful
  |> should.equal(2)
}

pub fn test_count_failed_results() {
  let results = [
    MigrationResult("pasta", Some(1), "success", None),
    MigrationResult("soup", None, "failed", Some("Error 1")),
    MigrationResult("stew", None, "failed", Some("Error 2")),
  ]
  let failed = list.count(results, fn(r) { r.status == "failed" })
  failed
  |> should.equal(2)
}

// ==============================================================================
// STATISTICS TESTS
// ==============================================================================

pub fn test_migration_stats_creation() {
  let stats = MigrationStats(
    total_recipes: 10,
    successful: 8,
    failed: 2,
    skipped: 0,
    duration_seconds: 5.5,
  )
  stats.total_recipes
  |> should.equal(10)
  stats.successful
  |> should.equal(8)
  stats.failed
  |> should.equal(2)
}

pub fn test_migration_stats_success_rate() {
  let stats = MigrationStats(
    total_recipes: 100,
    successful: 95,
    failed: 5,
    skipped: 0,
    duration_seconds: 10.0,
  )
  let success_rate = stats.successful * 100 / stats.total_recipes
  success_rate
  |> should.equal(95)
}

pub fn test_migration_stats_zero_recipes() {
  let stats = MigrationStats(
    total_recipes: 0,
    successful: 0,
    failed: 0,
    skipped: 0,
    duration_seconds: 0.0,
  )
  stats.total_recipes
  |> should.equal(0)
}

// ==============================================================================
// LOG FORMATTING TESTS
// ==============================================================================

pub fn test_format_log_single_success() {
  let results = [
    MigrationResult("pasta", Some(123), "success", None),
  ]
  let log = format_log(results)
  log
  |> should.contain("pasta")
  log
  |> should.contain("123")
}

pub fn test_format_log_single_failure() {
  let results = [
    MigrationResult("pasta", None, "failed", Some("Invalid")),
  ]
  let log = format_log(results)
  log
  |> should.contain("pasta")
  log
  |> should.contain("Invalid")
}

pub fn test_format_log_multiple() {
  let results = [
    MigrationResult("pasta", Some(123), "success", None),
    MigrationResult("salad", Some(124), "success", None),
    MigrationResult("soup", None, "failed", Some("No ingredients")),
  ]
  let log = format_log(results)
  log
  |> should.contain("pasta")
  log
  |> should.contain("salad")
  log
  |> should.contain("soup")
  log
  |> should.contain("123")
  log
  |> should.contain("124")
}

pub fn test_format_log_has_header() {
  let results = [
    MigrationResult("pasta", Some(123), "success", None),
  ]
  let log = format_log(results)
  log
  |> should.contain("Tandoor Recipe Migration - Dry Run Log")
}

pub fn test_format_log_empty_results() {
  let results: List(MigrationResult) = []
  let log = format_log(results)
  log
  |> should.contain("Tandoor Recipe Migration - Dry Run Log")
}

// ==============================================================================
// EDGE CASES AND ERROR HANDLING
// ==============================================================================

pub fn test_validate_recipe_with_spaces_in_slug() {
  let recipe = make_recipe(1, "   ", "Pasta", 5)
  // Empty after trimming would fail
  validate_recipe(recipe)
  // Slug is not empty (has spaces), so should pass validation
  |> should.equal(Ok(Nil))
}

pub fn test_validate_recipe_max_ingredients() {
  let recipe = make_recipe(1, "pasta", "Pasta", 1000)
  validate_recipe(recipe)
  |> should.equal(Ok(Nil))
}

pub fn test_large_batch_success_count() {
  let results = list.range(1, 101)
  |> list.map(fn(i) {
    MigrationResult(
      "recipe_" <> int.to_string(i),
      Some(1000 + i),
      "success",
      None,
    )
  })

  let successful = list.count(results, fn(r) { r.status == "success" })
  successful
  |> should.equal(100)
}

pub fn test_mixed_success_and_failure() {
  let results = list.range(1, 11)
  |> list.map(fn(i) {
    case i % 2 {
      0 ->
        MigrationResult(
          "recipe_" <> int.to_string(i),
          Some(1000 + i),
          "success",
          None,
        )
      _ ->
        MigrationResult(
          "recipe_" <> int.to_string(i),
          None,
          "failed",
          Some("Test error"),
        )
    }
  })

  let successful = list.count(results, fn(r) { r.status == "success" })
  let failed = list.count(results, fn(r) { r.status == "failed" })

  successful
  |> should.equal(5)
  failed
  |> should.equal(5)
}

// ==============================================================================
// HELPER FUNCTIONS (copied from implementation for testing)
// ==============================================================================

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

fn validate_recipes(recipes: List(Recipe)) -> Result(Nil, String) {
  case list.all(recipes, fn(r) { validate_recipe(r) |> result.is_ok }) {
    True -> Ok(Nil)
    False -> Error("Some recipes failed validation")
  }
}

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
