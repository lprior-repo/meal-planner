import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/portion.{
  calculate_daily_portions, calculate_portion_for_target,
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

// Test calculate_daily_portions
pub fn calculate_daily_portions_test() {
  let recipes = [
    Recipe(
      id: id.recipe_id("recipe-1"),
      name: "Recipe 1",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
      servings: 1,
      category: "Main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: id.recipe_id("recipe-2"),
      name: "Recipe 2",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 15.0, carbs: 30.0),
      servings: 1,
      category: "Side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  let daily_macros = Macros(protein: 140.0, fat: 50.0, carbs: 100.0)
  let results = calculate_daily_portions(daily_macros, 2, recipes)

  // Should return 2 portions for 2 recipes
  should.equal(list.length(results), 2)

  // Each portion gets half of daily macros
  let _per_meal = Macros(protein: 70.0, fat: 25.0, carbs: 50.0)

  // First recipe: 70/30 = 2.33x scale
  let first = list.first(results)
  case first {
    Ok(portion) -> {
      should.equal(portion.scale_factor, 2.0)
      should.be_true(portion.meets_target)
    }
    Error(_) -> should.fail()
  }
}
