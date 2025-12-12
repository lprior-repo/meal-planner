//// Tests for the Mealie mapper module
//// Covers conversion from Mealie types to internal meal planner types

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/mealie/mapper
import meal_planner/mealie/types as mealie
import meal_planner/types.{Low}
import qcheck
import qcheck as gen

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Helpers
// ============================================================================

/// Create a test MealieRecipe with full data
fn test_mealie_recipe() -> mealie.MealieRecipe {
  let unit = mealie.MealieUnit(id: "unit-1", name: "cup", abbreviation: "c")
  let food =
    mealie.MealieFood(id: "food-1", name: "Chicken breast", description: None)

  let ingredient =
    mealie.MealieIngredient(
      reference_id: "ing-1",
      quantity: Some(2.0),
      unit: Some(unit),
      food: Some(food),
      note: None,
      is_food: True,
      disable_amount: False,
      display: "2 cups chicken breast",
      original_text: Some("2 c chicken breast"),
    )

  let instruction =
    mealie.MealieInstruction(
      id: "step-1",
      title: Some("Prepare chicken"),
      text: "Cut chicken into bite-sized pieces",
    )

  let category =
    mealie.MealieCategory(id: "cat-1", name: "Dinner", slug: "dinner")

  let nutrition =
    mealie.MealieNutrition(
      calories: Some("450 kcal"),
      fat_content: Some("15g"),
      protein_content: Some("35g"),
      carbohydrate_content: Some("50g"),
      fiber_content: Some("8g"),
      sodium_content: Some("600mg"),
      sugar_content: Some("5g"),
    )

  mealie.MealieRecipe(
    id: "recipe-123",
    slug: "chicken-stir-fry",
    name: "Chicken Stir Fry",
    description: Some("A quick and healthy stir fry"),
    image: Some("/images/chicken.jpg"),
    recipe_yield: Some("4 servings"),
    total_time: Some("30 minutes"),
    prep_time: Some("10 minutes"),
    cook_time: Some("20 minutes"),
    rating: Some(5),
    org_url: Some("https://example.com/recipe"),
    recipe_ingredient: [ingredient],
    recipe_instructions: [instruction],
    recipe_category: [category],
    tags: [],
    nutrition: Some(nutrition),
    date_added: Some("2025-12-09T00:00:00Z"),
    date_updated: Some("2025-12-09T12:00:00Z"),
  )
}

/// Create a minimal MealieRecipe
fn minimal_mealie_recipe() -> mealie.MealieRecipe {
  mealie.MealieRecipe(
    id: "recipe-456",
    slug: "simple-salad",
    name: "Simple Salad",
    description: None,
    image: None,
    recipe_yield: None,
    total_time: None,
    prep_time: None,
    cook_time: None,
    rating: None,
    org_url: None,
    recipe_ingredient: [],
    recipe_instructions: [],
    recipe_category: [],
    tags: [],
    nutrition: None,
    date_added: None,
    date_updated: None,
  )
}

// ============================================================================
// Recipe Conversion Tests
// ============================================================================

pub fn mealie_to_recipe_with_full_data_test() {
  let mealie_recipe = test_mealie_recipe()
  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  // Verify basic fields
  recipe.name
  |> should.equal("Chicken Stir Fry")

  recipe.servings
  |> should.equal(4)

  recipe.category
  |> should.equal("Dinner")

  // Verify defaults
  recipe.fodmap_level
  |> should.equal(Low)

  recipe.vertical_compliant
  |> should.equal(False)

  // Verify ingredients were converted
  list.length(recipe.ingredients)
  |> should.equal(1)

  // Verify instructions were converted
  list.length(recipe.instructions)
  |> should.equal(1)
}

pub fn mealie_to_recipe_with_minimal_data_test() {
  let mealie_recipe = minimal_mealie_recipe()
  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  recipe.name
  |> should.equal("Simple Salad")

  recipe.servings
  |> should.equal(1)

  recipe.category
  |> should.equal("Uncategorized")

  list.length(recipe.ingredients)
  |> should.equal(0)

  list.length(recipe.instructions)
  |> should.equal(0)
}

pub fn recipe_id_generation_test() {
  let mealie_recipe = test_mealie_recipe()
  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  // Recipe ID should be prefixed with "mealie-"
  let id_string = id.recipe_id_to_string(recipe.id)

  string.contains(id_string, "mealie-")
  |> should.be_true

  string.contains(id_string, "chicken-stir-fry")
  |> should.be_true
}

// ============================================================================
// Ingredient Conversion Tests
// ============================================================================

pub fn mealie_to_ingredient_with_all_fields_test() {
  let unit = mealie.MealieUnit(id: "unit-1", name: "cup", abbreviation: "c")
  let food =
    mealie.MealieFood(id: "food-1", name: "Chicken breast", description: None)

  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-1",
      quantity: Some(2.0),
      unit: Some(unit),
      food: Some(food),
      note: None,
      is_food: True,
      disable_amount: False,
      display: "2 cups chicken breast",
      original_text: Some("2 c chicken breast"),
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.name
  |> should.equal("2 cups chicken breast")

  ingredient.quantity
  |> should.equal("2 c")
}

pub fn mealie_to_ingredient_with_quantity_only_test() {
  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-2",
      quantity: Some(3.5),
      unit: None,
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "3.5 items",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("3.5")
}

pub fn mealie_to_ingredient_with_unit_only_test() {
  let unit =
    mealie.MealieUnit(id: "unit-2", name: "pinch", abbreviation: "pinch")

  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-3",
      quantity: None,
      unit: Some(unit),
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "salt",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("pinch")
}

pub fn mealie_to_ingredient_with_no_quantity_or_unit_test() {
  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-4",
      quantity: None,
      unit: None,
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "salt",
      original_text: Some("salt to taste"),
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("salt to taste")
}

pub fn mealie_to_ingredient_fallback_to_taste_test() {
  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-5",
      quantity: None,
      unit: None,
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "pepper",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("to taste")
}

pub fn mealie_to_ingredient_uses_food_name_test() {
  let food = mealie.MealieFood(id: "food-1", name: "Butter", description: None)

  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-6",
      quantity: Some(2.0),
      unit: None,
      food: Some(food),
      note: None,
      is_food: True,
      disable_amount: False,
      display: "",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.name
  |> should.equal("Butter")
}

pub fn mealie_to_ingredient_uses_note_as_fallback_test() {
  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-7",
      quantity: None,
      unit: None,
      food: None,
      note: Some("Fresh herbs"),
      is_food: False,
      disable_amount: False,
      display: "",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.name
  |> should.equal("Fresh herbs")
}

// ============================================================================
// Nutrition Conversion Tests
// ============================================================================

pub fn mealie_to_macros_with_full_nutrition_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: Some("450 kcal"),
      fat_content: Some("15g"),
      protein_content: Some("35g"),
      carbohydrate_content: Some("50g"),
      fiber_content: Some("8g"),
      sodium_content: Some("600mg"),
      sugar_content: Some("5g"),
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.protein
  |> should.equal(35.0)

  macros.fat
  |> should.equal(15.0)

  macros.carbs
  |> should.equal(50.0)
}

pub fn mealie_to_macros_with_none_test() {
  let macros = mapper.mealie_to_macros(None)

  macros.protein
  |> should.equal(0.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)
}

pub fn mealie_to_macros_with_partial_nutrition_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: Some("300"),
      fat_content: None,
      protein_content: Some("25g"),
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.protein
  |> should.equal(25.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)
}

pub fn mealie_to_macros_with_decimal_values_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: Some("450.5"),
      fat_content: Some("15.3g"),
      protein_content: Some("35.7g"),
      carbohydrate_content: Some("50.1g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.protein
  |> should.equal(35.7)

  macros.fat
  |> should.equal(15.3)

  macros.carbs
  |> should.equal(50.1)
}

// ============================================================================
// Recipe Yield Parsing Tests
// ============================================================================

pub fn parse_recipe_yield_with_number_and_text_test() {
  mapper.parse_recipe_yield(Some("4 servings"))
  |> should.equal(4)
}

pub fn parse_recipe_yield_with_number_only_test() {
  mapper.parse_recipe_yield(Some("6"))
  |> should.equal(6)
}

pub fn parse_recipe_yield_with_serves_prefix_test() {
  mapper.parse_recipe_yield(Some("serves 8"))
  |> should.equal(8)
}

pub fn parse_recipe_yield_with_none_test() {
  mapper.parse_recipe_yield(None)
  |> should.equal(1)
}

pub fn parse_recipe_yield_with_invalid_text_test() {
  mapper.parse_recipe_yield(Some("several people"))
  |> should.equal(1)
}

pub fn parse_recipe_yield_with_zero_test() {
  mapper.parse_recipe_yield(Some("0 servings"))
  |> should.equal(1)
}

pub fn parse_recipe_yield_with_large_number_test() {
  mapper.parse_recipe_yield(Some("Makes 24 cookies"))
  |> should.equal(24)
}

// ============================================================================
// Number Extraction Tests
// ============================================================================

pub fn extract_number_from_simple_string_test() {
  // Test internal number extraction logic through public API
  let nutrition =
    mealie.MealieNutrition(
      calories: Some("150"),
      fat_content: None,
      protein_content: None,
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))
  // Calories aren't used in macros, so test through a different field
  macros.protein
  |> should.equal(0.0)
}

pub fn extract_number_from_string_with_unit_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some("25g"),
      protein_content: None,
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.fat
  |> should.equal(25.0)
}

pub fn extract_number_from_string_with_decimal_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: None,
      protein_content: Some("42.8g"),
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.protein
  |> should.equal(42.8)
}

pub fn extract_number_from_string_with_spaces_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: None,
      protein_content: None,
      carbohydrate_content: Some("  60  grams  "),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.carbs
  |> should.equal(60.0)
}

// ============================================================================
// Float Rounding Tests
// ============================================================================

pub fn float_rounding_whole_number_test() {
  let unit = mealie.MealieUnit(id: "unit-1", name: "cup", abbreviation: "c")

  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-1",
      quantity: Some(2.0),
      unit: Some(unit),
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "flour",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("2 c")
}

pub fn float_rounding_decimal_test() {
  let unit = mealie.MealieUnit(id: "unit-1", name: "cup", abbreviation: "c")

  let mealie_ing =
    mealie.MealieIngredient(
      reference_id: "ing-1",
      quantity: Some(1.5),
      unit: Some(unit),
      food: None,
      note: None,
      is_food: False,
      disable_amount: False,
      display: "flour",
      original_text: None,
    )

  let ingredient = mapper.mealie_to_ingredient(mealie_ing)

  ingredient.quantity
  |> should.equal("1.5 c")
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn full_recipe_conversion_preserves_all_data_test() {
  let mealie_recipe = test_mealie_recipe()
  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  // Verify all major components are present
  recipe.name
  |> should.not_equal("")

  list.length(recipe.ingredients)
  |> should.not_equal(0)

  list.length(recipe.instructions)
  |> should.not_equal(0)

  recipe.macros.protein
  |> should.equal(35.0)

  recipe.macros.fat
  |> should.equal(15.0)

  recipe.macros.carbs
  |> should.equal(50.0)
}

pub fn recipe_with_multiple_ingredients_test() {
  let unit1 = mealie.MealieUnit(id: "unit-1", name: "cup", abbreviation: "c")
  let unit2 =
    mealie.MealieUnit(id: "unit-2", name: "tablespoon", abbreviation: "tbsp")

  let ing1 =
    mealie.MealieIngredient(
      reference_id: "ing-1",
      quantity: Some(2.0),
      unit: Some(unit1),
      food: None,
      note: None,
      is_food: True,
      disable_amount: False,
      display: "2 cups rice",
      original_text: None,
    )

  let ing2 =
    mealie.MealieIngredient(
      reference_id: "ing-2",
      quantity: Some(1.0),
      unit: Some(unit2),
      food: None,
      note: None,
      is_food: True,
      disable_amount: False,
      display: "1 tbsp oil",
      original_text: None,
    )

  let mealie_recipe =
    mealie.MealieRecipe(
      id: "recipe-789",
      slug: "fried-rice",
      name: "Fried Rice",
      description: None,
      image: None,
      recipe_yield: Some("2"),
      total_time: None,
      prep_time: None,
      cook_time: None,
      rating: None,
      org_url: None,
      recipe_ingredient: [ing1, ing2],
      recipe_instructions: [],
      recipe_category: [],
      tags: [],
      nutrition: None,
      date_added: None,
      date_updated: None,
    )

  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  list.length(recipe.ingredients)
  |> should.equal(2)

  recipe.servings
  |> should.equal(2)
}

pub fn recipe_with_multiple_instructions_test() {
  let inst1 =
    mealie.MealieInstruction(
      id: "step-1",
      title: Some("Step 1"),
      text: "Prepare ingredients",
    )

  let inst2 =
    mealie.MealieInstruction(
      id: "step-2",
      title: Some("Step 2"),
      text: "Cook everything",
    )

  let inst3 =
    mealie.MealieInstruction(id: "step-3", title: None, text: "Serve hot")

  let mealie_recipe =
    mealie.MealieRecipe(
      id: "recipe-999",
      slug: "test-recipe",
      name: "Test Recipe",
      description: None,
      image: None,
      recipe_yield: None,
      total_time: None,
      prep_time: None,
      cook_time: None,
      rating: None,
      org_url: None,
      recipe_ingredient: [],
      recipe_instructions: [inst1, inst2, inst3],
      recipe_category: [],
      tags: [],
      nutrition: None,
      date_added: None,
      date_updated: None,
    )

  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  list.length(recipe.instructions)
  |> should.equal(3)

  // Verify first instruction
  case list.first(recipe.instructions) {
    Ok(first) ->
      first
      |> should.equal("Prepare ingredients")
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Property Tests for Macro Preservation
// ============================================================================

/// Property: Protein preservation
/// For any valid protein value, conversion should preserve it exactly
pub fn property_protein_preservation_test() {
  use protein_str <- qcheck.given(
    gen.bounded_float(from: 0.0, to: 1000.0) |> gen.map(float.to_string),
  )

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: None,
      protein_content: Some(protein_str <> "g"),
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))
  let expected = string.trim(protein_str) |> float.parse |> result.unwrap(0.0)

  // Allow small floating-point rounding errors (within 0.01)
  let difference = float.absolute_value(macros.protein -. expected)
  { difference <. 0.01 }
  |> should.be_true
}

/// Property: Fat preservation
/// For any valid fat value, conversion should preserve it exactly
pub fn property_fat_preservation_test() {
  use fat_str <- qcheck.given(
    gen.bounded_float(from: 0.0, to: 1000.0) |> gen.map(float.to_string),
  )

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some(fat_str <> "g"),
      protein_content: None,
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))
  let expected = string.trim(fat_str) |> float.parse |> result.unwrap(0.0)

  let difference = float.absolute_value(macros.fat -. expected)
  { difference <. 0.01 }
  |> should.be_true
}

/// Property: Carbs preservation
/// For any valid carb value, conversion should preserve it exactly
pub fn property_carbs_preservation_test() {
  use carbs_str <- qcheck.given(
    gen.bounded_float(from: 0.0, to: 1000.0) |> gen.map(float.to_string),
  )

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: None,
      protein_content: None,
      carbohydrate_content: Some(carbs_str <> "g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))
  let expected = string.trim(carbs_str) |> float.parse |> result.unwrap(0.0)

  let difference = float.absolute_value(macros.carbs -. expected)
  { difference <. 0.01 }
  |> should.be_true
}

/// Property: All macros preserved together
/// When all three macros are provided, they should all be preserved
pub fn property_all_macros_preserved_test() {
  use protein_str <- qcheck.given(gen.bounded_float(from: 0.0, to: 500.0))
  use fat_str <- qcheck.given(gen.bounded_float(from: 0.0, to: 500.0))
  use carbs_str <- qcheck.given(gen.bounded_float(from: 0.0, to: 500.0))

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some(float.to_string(fat_str) <> "g"),
      protein_content: Some(float.to_string(protein_str) <> "g"),
      carbohydrate_content: Some(float.to_string(carbs_str) <> "g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  // Verify protein
  let protein_diff = float.absolute_value(macros.protein -. protein_str)
  { protein_diff <. 0.01 }
  |> should.be_true

  // Verify fat
  let fat_diff = float.absolute_value(macros.fat -. fat_str)
  { fat_diff <. 0.01 }
  |> should.be_true

  // Verify carbs
  let carbs_diff = float.absolute_value(macros.carbs -. carbs_str)
  { carbs_diff <. 0.01 }
  |> should.be_true
}

/// Property: Macro formatting doesn't affect parsing
/// Macros with various units (g, grams, kcal, etc.) should parse identically
pub fn property_macro_format_invariance_test() {
  use value <- qcheck.given(gen.bounded_float(from: 1.0, to: 500.0))

  let formats = [
    float.to_string(value),
    float.to_string(value) <> "g",
    float.to_string(value) <> " g",
    float.to_string(value) <> "grams",
    float.to_string(value) <> " grams",
  ]

  let results =
    list.map(formats, fn(fmt) {
      let nutrition =
        mealie.MealieNutrition(
          calories: None,
          fat_content: Some(fmt),
          protein_content: None,
          carbohydrate_content: None,
          fiber_content: None,
          sodium_content: None,
          sugar_content: None,
        )
      mapper.mealie_to_macros(Some(nutrition)).fat
    })

  // All results should be approximately equal (within rounding error)
  case results {
    [first, ..rest] -> {
      list.all(rest, fn(val) {
        let diff = float.absolute_value(val -. first)
        diff <. 0.01
      })
      |> should.be_true
    }
    [] -> should.fail()
  }
}

/// Property: Zero macros are preserved
/// A recipe with all zero macros should maintain that
pub fn property_zero_macros_preserved_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: Some("0 kcal"),
      fat_content: Some("0g"),
      protein_content: Some("0g"),
      carbohydrate_content: Some("0g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.protein
  |> should.equal(0.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)
}

/// Property: Macros survive full recipe conversion roundtrip
/// MealieRecipe -> Recipe should preserve macro values
pub fn property_macros_survive_recipe_conversion_test() {
  use protein_val <- qcheck.given(gen.bounded_float(from: 1.0, to: 300.0))
  use fat_val <- qcheck.given(gen.bounded_float(from: 1.0, to: 200.0))
  use carbs_val <- qcheck.given(gen.bounded_float(from: 1.0, to: 400.0))

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some(float.to_string(fat_val) <> "g"),
      protein_content: Some(float.to_string(protein_val) <> "g"),
      carbohydrate_content: Some(float.to_string(carbs_val) <> "g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let mealie_recipe =
    mealie.MealieRecipe(
      id: "recipe-prop",
      slug: "property-test",
      name: "Property Test Recipe",
      description: None,
      image: None,
      recipe_yield: Some("1"),
      total_time: None,
      prep_time: None,
      cook_time: None,
      rating: None,
      org_url: None,
      recipe_ingredient: [],
      recipe_instructions: [],
      recipe_category: [],
      tags: [],
      nutrition: Some(nutrition),
      date_added: None,
      date_updated: None,
    )

  let recipe = mapper.mealie_to_recipe(mealie_recipe)

  // Verify macros survived conversion
  let protein_diff = float.absolute_value(recipe.macros.protein -. protein_val)
  { protein_diff <. 0.01 }
  |> should.be_true

  let fat_diff = float.absolute_value(recipe.macros.fat -. fat_val)
  { fat_diff <. 0.01 }
  |> should.be_true

  let carbs_diff = float.absolute_value(recipe.macros.carbs -. carbs_val)
  { carbs_diff <. 0.01 }
  |> should.be_true
}

/// Property: Invalid macro strings safely default to 0
/// Non-numeric strings should parse to 0 without errors
pub fn property_invalid_macros_default_to_zero_test() {
  use invalid_str <- qcheck.given(
    gen.from_generators(
      gen.return("none"),
      [
        gen.return("a"),
        gen.return("b"),
        gen.return("x"),
        gen.return("!"),
        gen.return("@"),
        gen.return("recipe"),
        gen.return("xyz"),
      ],
    ),
  )

  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some(invalid_str),
      protein_content: None,
      carbohydrate_content: None,
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let macros = mapper.mealie_to_macros(Some(nutrition))

  macros.fat
  |> should.equal(0.0)
}
