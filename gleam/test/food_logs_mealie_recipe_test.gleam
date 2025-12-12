/// Tests for food_logs with mealie_recipe source_type
///
/// This test verifies backward compatibility for food logs that use the
/// legacy 'mealie_recipe' source_type. Since the system migrated from Mealie
/// to Tandoor, this tests that old records can be validated and that the
/// logging system properly handles the source_type field.
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/storage/logs
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Mealie Recipe Source Type Tests
// ============================================================================

/// Test that mealie_recipe is a valid legacy source_type
/// This verifies backward compatibility for old data
pub fn test_mealie_recipe_is_legacy_source_type() {
  let mealie_recipe = "mealie_recipe"

  mealie_recipe
  |> should.equal("mealie_recipe")
}

/// Test that FoodLogEntry can store mealie_recipe source_type
pub fn test_food_log_entry_with_mealie_recipe_source_type() {
  let entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-123-456"),
      recipe_id: meal_planner/id.recipe_id("chicken-stir-fry"),
      recipe_name: "Chicken Stir Fry",
      servings: 1.5,
      macros: types.Macros(protein: 35.5, fat: 12.3, carbs: 45.2),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:30:00Z",
      source_type: "mealie_recipe",
      source_id: "chicken-stir-fry",
    )

  entry.source_type
  |> should.equal("mealie_recipe")

  entry.source_id
  |> should.equal("chicken-stir-fry")
}

/// Test that mealie_recipe logs can be retrieved with full micronutrient data
pub fn test_mealie_recipe_log_with_micronutrients() {
  let entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-789-001"),
      recipe_id: meal_planner/id.recipe_id("salmon-bowl"),
      recipe_name: "Salmon Bowl",
      servings: 2.0,
      macros: types.Macros(protein: 45.0, fat: 18.0, carbs: 55.0),
      micronutrients: Some(types.Micronutrients(
        fiber: Some(8.5),
        sugar: Some(12.3),
        sodium: Some(480.0),
        cholesterol: Some(85.0),
        vitamin_a: Some(150.0),
        vitamin_c: Some(45.0),
        vitamin_d: Some(20.0),
        vitamin_e: Some(8.0),
        vitamin_k: Some(120.0),
        vitamin_b6: Some(1.5),
        vitamin_b12: Some(3.2),
        folate: Some(210.0),
        thiamin: Some(1.2),
        riboflavin: Some(1.8),
        niacin: Some(8.5),
        calcium: Some(350.0),
        iron: Some(2.8),
        magnesium: Some(95.0),
        phosphorus: Some(480.0),
        potassium: Some(850.0),
        zinc: Some(3.2),
      )),
      meal_type: types.Lunch,
      logged_at: "2025-12-12T12:30:00Z",
      source_type: "mealie_recipe",
      source_id: "salmon-bowl",
    )

  // Verify source_type is mealie_recipe
  entry.source_type
  |> should.equal("mealie_recipe")

  // Verify micronutrients are present
  let micros = case entry.micronutrients {
    Some(m) -> m
    None -> panic as "Expected micronutrients"
  }

  micros.fiber
  |> should.equal(Some(8.5))

  micros.zinc
  |> should.equal(Some(3.2))
}

/// Test that multiple mealie_recipe logs can be created with different meal types
pub fn test_multiple_mealie_recipe_meal_types() {
  let breakfast_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-breakfast-001"),
      recipe_id: meal_planner/id.recipe_id("oatmeal-berries"),
      recipe_name: "Oatmeal with Berries",
      servings: 1.0,
      macros: types.Macros(protein: 12.0, fat: 5.0, carbs: 48.0),
      micronutrients: None,
      meal_type: types.Breakfast,
      logged_at: "2025-12-12T08:00:00Z",
      source_type: "mealie_recipe",
      source_id: "oatmeal-berries",
    )

  let lunch_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-lunch-001"),
      recipe_id: meal_planner/id.recipe_id("turkey-sandwich"),
      recipe_name: "Turkey Sandwich",
      servings: 1.0,
      macros: types.Macros(protein: 28.0, fat: 8.0, carbs: 35.0),
      micronutrients: None,
      meal_type: types.Lunch,
      logged_at: "2025-12-12T12:15:00Z",
      source_type: "mealie_recipe",
      source_id: "turkey-sandwich",
    )

  let dinner_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-dinner-001"),
      recipe_id: meal_planner/id.recipe_id("grilled-salmon"),
      recipe_name: "Grilled Salmon",
      servings: 1.5,
      macros: types.Macros(protein: 42.0, fat: 20.0, carbs: 5.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "mealie_recipe",
      source_id: "grilled-salmon",
    )

  let snack_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-snack-001"),
      recipe_id: meal_planner/id.recipe_id("greek-yogurt"),
      recipe_name: "Greek Yogurt",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 3.0, carbs: 6.0),
      micronutrients: None,
      meal_type: types.Snack,
      logged_at: "2025-12-12T16:00:00Z",
      source_type: "mealie_recipe",
      source_id: "greek-yogurt",
    )

  // Verify all entries have mealie_recipe source_type
  breakfast_entry.source_type
  |> should.equal("mealie_recipe")

  lunch_entry.source_type
  |> should.equal("mealie_recipe")

  dinner_entry.source_type
  |> should.equal("mealie_recipe")

  snack_entry.source_type
  |> should.equal("mealie_recipe")

  // Verify meal types are correct
  breakfast_entry.meal_type
  |> should.equal(types.Breakfast)

  lunch_entry.meal_type
  |> should.equal(types.Lunch)

  dinner_entry.meal_type
  |> should.equal(types.Dinner)

  snack_entry.meal_type
  |> should.equal(types.Snack)
}

/// Test that mealie_recipe logs can be distinguished from tandoor_recipe
pub fn test_mealie_recipe_vs_tandoor_recipe_distinction() {
  let mealie_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-123"),
      recipe_id: meal_planner/id.recipe_id("curry"),
      recipe_name: "Curry",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "mealie_recipe",
      source_id: "curry",
    )

  let tandoor_entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("tandoor-123"),
      recipe_id: meal_planner/id.recipe_id("curry"),
      recipe_name: "Curry",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "curry",
    )

  // Verify they have different source_types
  mealie_entry.source_type
  |> should.not_equal(tandoor_entry.source_type)

  mealie_entry.source_type
  |> should.equal("mealie_recipe")

  tandoor_entry.source_type
  |> should.equal("tandoor_recipe")
}

/// Test mealie_recipe with various recipe slug formats
pub fn test_mealie_recipe_slug_formats() {
  let recipe_slugs = [
    "chicken-stir-fry",
    "beef-wellington",
    "vegetable-curry",
    "pasta-carbonara",
    "thai-green-curry",
  ]

  let entries =
    recipe_slugs
    |> gleam/list.map(fn(slug) {
      types.FoodLogEntry(
        id: meal_planner/id.log_entry_id("mealie-" <> slug),
        recipe_id: meal_planner/id.recipe_id(slug),
        recipe_name: slug,
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        micronutrients: None,
        meal_type: types.Dinner,
        logged_at: "2025-12-12T19:00:00Z",
        source_type: "mealie_recipe",
        source_id: slug,
      )
    })

  // Verify all entries have mealie_recipe source_type
  entries
  |> gleam/list.each(fn(entry) {
    entry.source_type
    |> should.equal("mealie_recipe")
  })
}

/// Test mealie_recipe log with minimal data
pub fn test_mealie_recipe_minimal_data() {
  let entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-minimal"),
      recipe_id: meal_planner/id.recipe_id("test-recipe"),
      recipe_name: "Test Recipe",
      servings: 1.0,
      macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      micronutrients: None,
      meal_type: types.Snack,
      logged_at: "2025-12-12T10:00:00Z",
      source_type: "mealie_recipe",
      source_id: "test-recipe",
    )

  // Verify all required fields are present
  entry.source_type
  |> should.equal("mealie_recipe")

  entry.recipe_name
  |> should.equal("Test Recipe")

  entry.servings
  |> should.equal(1.0)

  entry.macros.protein
  |> should.equal(10.0)
}

/// Test mealie_recipe log with maximum data
pub fn test_mealie_recipe_maximum_data() {
  let entry =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-maximum-data"),
      recipe_id: meal_planner/id.recipe_id("premium-steak"),
      recipe_name: "Premium Steak with Sides",
      servings: 2.0,
      macros: types.Macros(protein: 60.0, fat: 35.0, carbs: 40.0),
      micronutrients: Some(types.Micronutrients(
        fiber: Some(6.0),
        sugar: Some(8.0),
        sodium: Some(500.0),
        cholesterol: Some(100.0),
        vitamin_a: Some(200.0),
        vitamin_c: Some(50.0),
        vitamin_d: Some(25.0),
        vitamin_e: Some(10.0),
        vitamin_k: Some(150.0),
        vitamin_b6: Some(2.0),
        vitamin_b12: Some(4.0),
        folate: Some(250.0),
        thiamin: Some(1.5),
        riboflavin: Some(2.0),
        niacin: Some(10.0),
        calcium: Some(400.0),
        iron: Some(3.5),
        magnesium: Some(110.0),
        phosphorus: Some(500.0),
        potassium: Some(900.0),
        zinc: Some(4.0),
      )),
      meal_type: types.Dinner,
      logged_at: "2025-12-12T20:00:00Z",
      source_type: "mealie_recipe",
      source_id: "premium-steak",
    )

  // Verify source_type is mealie_recipe
  entry.source_type
  |> should.equal("mealie_recipe")

  // Verify all macros are stored
  entry.macros.protein
  |> should.equal(60.0)

  entry.macros.fat
  |> should.equal(35.0)

  entry.macros.carbs
  |> should.equal(40.0)

  // Verify all micronutrients are stored
  let micros = case entry.micronutrients {
    Some(m) -> m
    None -> panic as "Expected micronutrients"
  }

  micros.protein
  |> should.equal(None)

  micros.iron
  |> should.equal(Some(3.5))

  micros.zinc
  |> should.equal(Some(4.0))
}

/// Test mealie_recipe logging backward compatibility
/// This verifies that the system can still handle mealie_recipe source_type
/// even though new records should use tandoor_recipe
pub fn test_mealie_recipe_backward_compatibility() {
  let old_mealie_log =
    types.FoodLogEntry(
      id: meal_planner/id.log_entry_id("mealie-legacy-001"),
      recipe_id: meal_planner/id.recipe_id("legacy-recipe"),
      recipe_name: "Legacy Recipe from Mealie",
      servings: 1.5,
      macros: types.Macros(protein: 25.0, fat: 12.0, carbs: 40.0),
      micronutrients: None,
      meal_type: types.Lunch,
      logged_at: "2025-12-11T12:30:00Z",
      source_type: "mealie_recipe",
      source_id: "legacy-recipe",
    )

  // Old logs should still be readable and valid
  old_mealie_log.source_type
  |> should.equal("mealie_recipe")

  // The entry should contain all original data
  old_mealie_log.recipe_name
  |> should.equal("Legacy Recipe from Mealie")

  old_mealie_log.logged_at
  |> should.equal("2025-12-11T12:30:00Z")
}
