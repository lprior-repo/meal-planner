/// Birdie Snapshot Tests for Encoders
///
/// Uses Birdie to capture and verify JSON encoder output against saved snapshots.
/// This prevents unintended changes to JSON structure and validates encoder correctness.
///
/// Run tests with: gleam test
/// Update snapshots with: gleam run -m birdie
import birdie
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder.{
  CreateRecipeRequest, encode_create_recipe,
}

pub fn main() {
  gleeunit.main()
}

/// Test: Recipe create encoder with minimal fields
pub fn recipe_encoder_minimal_test() {
  let request =
    CreateRecipeRequest(
      name: "Simple Recipe",
      description: None,
      servings: 1,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  encode_create_recipe(request)
  |> json.to_string
  |> birdie.snap("recipe_encoder_minimal")
}

/// Test: Recipe create encoder with all fields
pub fn recipe_encoder_complete_test() {
  let request =
    CreateRecipeRequest(
      name: "Complex Recipe",
      description: Some("A delicious recipe"),
      servings: 4,
      servings_text: Some("4 servings"),
      working_time: Some(30),
      waiting_time: Some(60),
    )

  encode_create_recipe(request)
  |> json.to_string
  |> birdie.snap("recipe_encoder_complete")
}

/// Test: Recipe encoder with special characters
pub fn recipe_encoder_special_chars_test() {
  let request =
    CreateRecipeRequest(
      name: "Crème Brûlée",
      description: Some("Recipe with \"quotes\""),
      servings: 2,
      servings_text: None,
      working_time: Some(15),
      waiting_time: None,
    )

  encode_create_recipe(request)
  |> json.to_string
  |> birdie.snap("recipe_encoder_special_chars")
}

/// Test: Recipe encoder validates structure consistency
pub fn recipe_encoder_consistency_test() {
  let request =
    CreateRecipeRequest(
      name: "Test Recipe",
      description: None,
      servings: 3,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  let encoded = encode_create_recipe(request) |> json.to_string

  // Verify structure contains all expected fields
  string.contains(encoded, "\"name\"") |> should.be_true
  string.contains(encoded, "\"description\"") |> should.be_true
  string.contains(encoded, "\"servings\"") |> should.be_true
  string.contains(encoded, "\"working_time\"") |> should.be_true
  string.contains(encoded, "\"waiting_time\"") |> should.be_true
  string.contains(encoded, "\"steps\"") |> should.be_true

  // Snapshot to catch unintended changes
  birdie.snap(encoded, "recipe_encoder_consistency")
}
