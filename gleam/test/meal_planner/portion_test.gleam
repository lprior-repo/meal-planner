import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/mealie/types.{
  MealieCategory, MealieIngredient, MealieInstruction, MealieNutrition,
  MealieRecipe,
} as mealie_types
import meal_planner/portion.{
  calculate_portion_for_mealie_recipe, calculate_portion_for_target,
}
import meal_planner/types.{Ingredient, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// Test calculate_portion_for_target with Recipe type
pub fn calculate_portion_basic_recipe_test() {
  let recipe =
    Recipe(
      id: id.recipe_id("test-recipe"),
      name: "Test Recipe",
      ingredients: [Ingredient(name: "Chicken", quantity: "100g")],
      instructions: ["Cook it"],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
      servings: 1,
      category: "Main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let target = Macros(protein: 60.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_target(recipe, target)

  // Should scale by protein: 60/30 = 2.0
  should.equal(result.scale_factor, 2.0)
  should.equal(result.scaled_macros.protein, 60.0)
  should.equal(result.scaled_macros.fat, 20.0)
  should.equal(result.scaled_macros.carbs, 40.0)
  should.equal(result.meets_target, True)
}

// Test calculate_portion_for_target with no macros
pub fn calculate_portion_no_macros_recipe_test() {
  let recipe =
    Recipe(
      id: id.recipe_id("empty-recipe"),
      name: "Empty Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "Main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let target = Macros(protein: 60.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_target(recipe, target)

  // Should default to 1.0 scale when no macros
  should.equal(result.scale_factor, 1.0)
  should.equal(result.meets_target, False)
}

// Test calculate_portion_for_mealie_recipe basic
pub fn calculate_portion_mealie_recipe_test() {
  let mealie_recipe =
    MealieRecipe(
      id: "mealie-123",
      slug: "test-beef-stew",
      name: "Beef Stew",
      description: Some("A hearty beef stew"),
      image: None,
      recipe_yield: Some("4"),
      total_time: Some("120"),
      prep_time: Some("30"),
      cook_time: Some("90"),
      rating: None,
      org_url: None,
      recipe_ingredient: [],
      recipe_instructions: [],
      recipe_category: [
        MealieCategory(id: "cat1", name: "Main", slug: "main"),
      ],
      tags: [],
      nutrition: Some(MealieNutrition(
        calories: Some("300"),
        fat_content: Some("10"),
        protein_content: Some("30"),
        carbohydrate_content: Some("20"),
        fiber_content: None,
        sodium_content: None,
        sugar_content: None,
      )),
      date_added: None,
      date_updated: None,
    )

  let target = Macros(protein: 60.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_mealie_recipe(mealie_recipe, target)

  // Should scale by protein: 60/30 = 2.0
  should.equal(result.scale_factor, 2.0)
  should.equal(result.scaled_macros.protein, 60.0)
  should.equal(result.scaled_macros.fat, 20.0)
  should.equal(result.scaled_macros.carbs, 40.0)
  should.equal(result.meets_target, True)
}

// Test calculate_portion_for_mealie_recipe with nutrition strings containing units
pub fn calculate_portion_mealie_recipe_with_units_test() {
  let mealie_recipe =
    MealieRecipe(
      id: "mealie-456",
      slug: "chicken-breast",
      name: "Chicken Breast",
      description: None,
      image: None,
      recipe_yield: Some("2"),
      total_time: None,
      prep_time: None,
      cook_time: None,
      rating: None,
      org_url: None,
      recipe_ingredient: [],
      recipe_instructions: [],
      recipe_category: [
        MealieCategory(id: "cat2", name: "Protein", slug: "protein"),
      ],
      tags: [],
      nutrition: Some(MealieNutrition(
        calories: Some("150"),
        fat_content: Some("5g"),
        protein_content: Some("25g"),
        carbohydrate_content: Some("2g"),
        fiber_content: None,
        sodium_content: None,
        sugar_content: None,
      )),
      date_added: None,
      date_updated: None,
    )

  let target = Macros(protein: 50.0, fat: 10.0, carbs: 4.0)
  let result = calculate_portion_for_mealie_recipe(mealie_recipe, target)

  // Should scale by protein: 50/25 = 2.0
  should.equal(result.scale_factor, 2.0)
  should.equal(result.scaled_macros.protein, 50.0)
}

// Test calculate_portion_for_mealie_recipe with no nutrition
pub fn calculate_portion_mealie_recipe_no_nutrition_test() {
  let mealie_recipe =
    MealieRecipe(
      id: "mealie-789",
      slug: "unknown-recipe",
      name: "Unknown Recipe",
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

  let target = Macros(protein: 60.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_mealie_recipe(mealie_recipe, target)

  // Should default to 1.0 scale when no nutrition
  should.equal(result.scale_factor, 1.0)
  should.equal(result.meets_target, False)
}

// Test scale factor capping
pub fn calculate_portion_scale_capping_test() {
  let recipe =
    Recipe(
      id: id.recipe_id("test-recipe"),
      name: "Test Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 100.0, fat: 10.0, carbs: 20.0),
      servings: 1,
      category: "Main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Request massive scaling (would be 10x protein)
  let target = Macros(protein: 1000.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_target(recipe, target)

  // Should be capped at 4.0x
  should.equal(result.scale_factor, 4.0)
  should.equal(result.scaled_macros.protein, 400.0)
}

// Test scale factor minimum capping
pub fn calculate_portion_scale_minimum_test() {
  let recipe =
    Recipe(
      id: id.recipe_id("test-recipe"),
      name: "Test Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 100.0, fat: 10.0, carbs: 20.0),
      servings: 1,
      category: "Main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Request tiny scaling (would be 0.05x protein)
  let target = Macros(protein: 5.0, fat: 20.0, carbs: 40.0)
  let result = calculate_portion_for_target(recipe, target)

  // Should be capped at 0.25x
  should.equal(result.scale_factor, 0.25)
  should.equal(result.scaled_macros.protein, 25.0)
}
