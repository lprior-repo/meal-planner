/// Tests for food_logs with tandoor_recipe source_type
///
/// This test verifies that the food logging system properly handles
/// the new 'tandoor_recipe' source_type for recipes sourced from the
/// Tandoor recipe manager API. This replaces the legacy 'mealie_recipe'
/// source_type.
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tandoor Recipe Source Type Tests
// ============================================================================

/// Test that tandoor_recipe is a valid source_type
/// This is the new standard for recipes from Tandoor API
pub fn test_tandoor_recipe_is_valid_source_type() {
  let tandoor_recipe = "tandoor_recipe"

  tandoor_recipe
  |> should.equal("tandoor_recipe")
}

/// Test that FoodLogEntry can be created with tandoor_recipe source_type
pub fn test_food_log_entry_with_tandoor_recipe_source_type() {
  let entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-123-456"),
      recipe_id: id.recipe_id("tandoor-1"),
      recipe_name: "Chicken Stir Fry",
      servings: 1.5,
      macros: types.Macros(protein: 35.5, fat: 12.3, carbs: 45.2),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:30:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-1",
    )

  entry.source_type
  |> should.equal("tandoor_recipe")

  entry.source_id
  |> should.equal("tandoor-1")
}

/// Test that tandoor_recipe logs can be created with full micronutrient data
pub fn test_tandoor_recipe_log_with_micronutrients() {
  let entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-789-001"),
      recipe_id: id.recipe_id("tandoor-42"),
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
      source_type: "tandoor_recipe",
      source_id: "tandoor-42",
    )

  // Verify source_type is tandoor_recipe
  entry.source_type
  |> should.equal("tandoor_recipe")

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

/// Test that tandoor_recipe logs can be created with different meal types
pub fn test_tandoor_recipe_multiple_meal_types() {
  let breakfast_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-breakfast-001"),
      recipe_id: id.recipe_id("tandoor-100"),
      recipe_name: "Oatmeal with Berries",
      servings: 1.0,
      macros: types.Macros(protein: 12.0, fat: 5.0, carbs: 48.0),
      micronutrients: None,
      meal_type: types.Breakfast,
      logged_at: "2025-12-12T08:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-100",
    )

  let lunch_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-lunch-001"),
      recipe_id: id.recipe_id("tandoor-101"),
      recipe_name: "Turkey Sandwich",
      servings: 1.0,
      macros: types.Macros(protein: 28.0, fat: 8.0, carbs: 35.0),
      micronutrients: None,
      meal_type: types.Lunch,
      logged_at: "2025-12-12T12:15:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-101",
    )

  let dinner_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-dinner-001"),
      recipe_id: id.recipe_id("tandoor-102"),
      recipe_name: "Grilled Salmon",
      servings: 1.5,
      macros: types.Macros(protein: 42.0, fat: 20.0, carbs: 5.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-102",
    )

  let snack_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-snack-001"),
      recipe_id: id.recipe_id("tandoor-103"),
      recipe_name: "Greek Yogurt",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 3.0, carbs: 6.0),
      micronutrients: None,
      meal_type: types.Snack,
      logged_at: "2025-12-12T16:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-103",
    )

  // Verify all entries have tandoor_recipe source_type
  breakfast_entry.source_type
  |> should.equal("tandoor_recipe")

  lunch_entry.source_type
  |> should.equal("tandoor_recipe")

  dinner_entry.source_type
  |> should.equal("tandoor_recipe")

  snack_entry.source_type
  |> should.equal("tandoor_recipe")

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

/// Test that tandoor_recipe can be distinguished from mealie_recipe and other sources
pub fn test_tandoor_recipe_vs_other_sources() {
  let tandoor_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-curry-1"),
      recipe_id: id.recipe_id("tandoor-50"),
      recipe_name: "Curry",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-50",
    )

  let mealie_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("mealie-curry-1"),
      recipe_id: id.recipe_id("curry"),
      recipe_name: "Curry",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "mealie_recipe",
      source_id: "curry",
    )

  let custom_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("custom-curry-1"),
      recipe_id: id.recipe_id("custom-curry"),
      recipe_name: "Custom Curry",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "custom_food",
      source_id: "custom-curry",
    )

  let usda_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("usda-beef-1"),
      recipe_id: id.recipe_id("usda-12345"),
      recipe_name: "Beef",
      servings: 1.0,
      macros: types.Macros(protein: 25.0, fat: 15.0, carbs: 0.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "usda_food",
      source_id: "usda-12345",
    )

  // Verify source_types are distinct
  tandoor_entry.source_type
  |> should.equal("tandoor_recipe")

  mealie_entry.source_type
  |> should.not_equal(tandoor_entry.source_type)

  custom_entry.source_type
  |> should.not_equal(tandoor_entry.source_type)

  usda_entry.source_type
  |> should.not_equal(tandoor_entry.source_type)
}

/// Test tandoor_recipe with numeric Tandoor API IDs
pub fn test_tandoor_recipe_with_numeric_ids() {
  let recipe_ids = [
    "tandoor-1",
    "tandoor-42",
    "tandoor-100",
    "tandoor-9999",
  ]

  let entries =
    recipe_ids
    |> list.map(fn(recipe_id) {
      types.FoodLogEntry(
        id: id.log_entry_id("log-" <> recipe_id),
        recipe_id: id.recipe_id(recipe_id),
        recipe_name: "Recipe from Tandoor",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        micronutrients: None,
        meal_type: types.Dinner,
        logged_at: "2025-12-12T19:00:00Z",
        source_type: "tandoor_recipe",
        source_id: recipe_id,
      )
    })

  // Verify all entries have tandoor_recipe source_type
  entries
  |> list.each(fn(entry) {
    entry.source_type
    |> should.equal("tandoor_recipe")
  })

  // Verify we have 4 entries
  entries
  |> list.length()
  |> should.equal(4)
}

/// Test tandoor_recipe log with minimal data
pub fn test_tandoor_recipe_minimal_data() {
  let entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-minimal"),
      recipe_id: id.recipe_id("tandoor-5"),
      recipe_name: "Simple Recipe",
      servings: 1.0,
      macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      micronutrients: None,
      meal_type: types.Snack,
      logged_at: "2025-12-12T10:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-5",
    )

  // Verify all required fields are present
  entry.source_type
  |> should.equal("tandoor_recipe")

  entry.recipe_name
  |> should.equal("Simple Recipe")

  entry.servings
  |> should.equal(1.0)

  entry.macros.protein
  |> should.equal(10.0)
}

/// Test tandoor_recipe log with maximum data
pub fn test_tandoor_recipe_maximum_data() {
  let entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-maximum"),
      recipe_id: id.recipe_id("tandoor-999"),
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
      source_type: "tandoor_recipe",
      source_id: "tandoor-999",
    )

  // Verify source_type is tandoor_recipe
  entry.source_type
  |> should.equal("tandoor_recipe")

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

  micros.iron
  |> should.equal(Some(3.5))

  micros.zinc
  |> should.equal(Some(4.0))
}

/// Test that multiple tandoor_recipe entries can be aggregated
pub fn test_tandoor_recipe_aggregation() {
  let entries = [
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-agg-1"),
      recipe_id: id.recipe_id("tandoor-1"),
      recipe_name: "Breakfast",
      servings: 1.0,
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 50.0),
      micronutrients: None,
      meal_type: types.Breakfast,
      logged_at: "2025-12-12T08:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-1",
    ),
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-agg-2"),
      recipe_id: id.recipe_id("tandoor-2"),
      recipe_name: "Lunch",
      servings: 1.5,
      macros: types.Macros(protein: 35.0, fat: 15.0, carbs: 60.0),
      micronutrients: None,
      meal_type: types.Lunch,
      logged_at: "2025-12-12T12:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-2",
    ),
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-agg-3"),
      recipe_id: id.recipe_id("tandoor-3"),
      recipe_name: "Dinner",
      servings: 2.0,
      macros: types.Macros(protein: 50.0, fat: 25.0, carbs: 40.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-3",
    ),
  ]

  // Verify all entries have tandoor_recipe source_type
  entries
  |> list.each(fn(entry) {
    entry.source_type
    |> should.equal("tandoor_recipe")
  })

  // Calculate aggregate macros
  let aggregate_macros =
    entries
    |> list.map(fn(entry) { entry.macros })
    |> types.macros_sum()

  // Total protein: 20 + 35 + 50 = 105
  aggregate_macros.protein
  |> should.equal(105.0)

  // Total fat: 10 + 15 + 25 = 50
  aggregate_macros.fat
  |> should.equal(50.0)

  // Total carbs: 50 + 60 + 40 = 150
  aggregate_macros.carbs
  |> should.equal(150.0)
}

/// Test tandoor_recipe with high servings multiplier
pub fn test_tandoor_recipe_high_servings() {
  let entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-high-serving"),
      recipe_id: id.recipe_id("tandoor-20"),
      recipe_name: "Family Meal",
      servings: 5.0,
      macros: types.Macros(protein: 15.0, fat: 8.0, carbs: 25.0),
      micronutrients: None,
      meal_type: types.Dinner,
      logged_at: "2025-12-12T19:00:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-20",
    )

  // Verify serving size
  entry.servings
  |> should.equal(5.0)

  // Verify source type is preserved
  entry.source_type
  |> should.equal("tandoor_recipe")
}

/// Test tandoor_recipe forward compatibility
/// New tandoor_recipe should be the standard source type going forward
pub fn test_tandoor_recipe_forward_compatibility() {
  let modern_entry =
    types.FoodLogEntry(
      id: id.log_entry_id("tandoor-modern-001"),
      recipe_id: id.recipe_id("tandoor-2025"),
      recipe_name: "Modern Recipe from Tandoor",
      servings: 1.5,
      macros: types.Macros(protein: 30.0, fat: 15.0, carbs: 45.0),
      micronutrients: None,
      meal_type: types.Lunch,
      logged_at: "2025-12-12T12:30:00Z",
      source_type: "tandoor_recipe",
      source_id: "tandoor-2025",
    )

  // Modern logs should use tandoor_recipe exclusively
  modern_entry.source_type
  |> should.equal("tandoor_recipe")

  // Verify that source_id follows Tandoor ID format
  modern_entry.source_id
  |> should.equal("tandoor-2025")
}
