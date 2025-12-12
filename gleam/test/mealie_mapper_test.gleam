//// Tests for the Mealie mapper module
//// Covers conversion from Mealie types to internal meal planner types

import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/mealie/mapper
import meal_planner/mealie/types as mealie
import meal_planner/types.{Low}

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
// Additional Macro Preservation Tests
// ============================================================================

/// Test that all macros are preserved together with various values
pub fn all_macros_preserved_test() {
  // Test with various typical nutrition values
  let test_cases = [
    #(25.0, "25", 10.0, "10", 30.0, "30"),
    #(35.5, "35.5", 15.2, "15.2", 45.8, "45.8"),
    #(0.0, "0", 0.0, "0", 0.0, "0"),
    #(100.0, "100", 50.0, "50", 200.0, "200"),
    #(12.3, "12.3", 8.7, "8.7", 15.1, "15.1"),
  ]

  list.each(test_cases, fn(test_case) {
    let #(protein_val, protein_str, fat_val, fat_str, carbs_val, carbs_str) =
      test_case

    let nutrition =
      mealie.MealieNutrition(
        calories: None,
        fat_content: Some(fat_str <> "g"),
        protein_content: Some(protein_str <> "g"),
        carbohydrate_content: Some(carbs_str <> "g"),
        fiber_content: None,
        sodium_content: None,
        sugar_content: None,
      )

    let macros = mapper.mealie_to_macros(Some(nutrition))

    // Verify protein
    let protein_diff = float.absolute_value(macros.protein -. protein_val)
    { protein_diff <. 0.01 }
    |> should.be_true

    // Verify fat
    let fat_diff = float.absolute_value(macros.fat -. fat_val)
    { fat_diff <. 0.01 }
    |> should.be_true

    // Verify carbs
    let carbs_diff = float.absolute_value(macros.carbs -. carbs_val)
    { carbs_diff <. 0.01 }
    |> should.be_true
  })
}

/// Test macro formatting doesn't affect parsing
pub fn macro_format_invariance_test() {
  let value = 42.5

  let formats = ["42.5", "42.5g", "42.5 g", "42.5grams", "42.5 grams"]

  list.each(formats, fn(fmt) {
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
    let result = mapper.mealie_to_macros(Some(nutrition)).fat
    let diff = float.absolute_value(result -. value)
    { diff <. 0.01 }
    |> should.be_true
  })
}

/// Test zero macros are preserved
pub fn zero_macros_preserved_test() {
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

/// Test macros survive full recipe conversion roundtrip
pub fn macros_survive_recipe_conversion_test() {
  let nutrition =
    mealie.MealieNutrition(
      calories: None,
      fat_content: Some("15.5g"),
      protein_content: Some("30.2g"),
      carbohydrate_content: Some("45.8g"),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )

  let mealie_recipe =
    mealie.MealieRecipe(
      id: "recipe-test",
      slug: "test-recipe",
      name: "Test Recipe",
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
  let protein_diff = float.absolute_value(recipe.macros.protein -. 30.2)
  { protein_diff <. 0.01 }
  |> should.be_true

  let fat_diff = float.absolute_value(recipe.macros.fat -. 15.5)
  { fat_diff <. 0.01 }
  |> should.be_true

  let carbs_diff = float.absolute_value(recipe.macros.carbs -. 45.8)
  { carbs_diff <. 0.01 }
  |> should.be_true
}

/// Test invalid macro strings safely default to 0
pub fn invalid_macros_default_to_zero_test() {
  let invalid_strings = ["none", "a", "x", "!", "@", "recipe", "xyz", ""]

  list.each(invalid_strings, fn(invalid_str) {
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
  })
}
