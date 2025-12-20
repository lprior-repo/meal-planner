import gleam/list
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/automation/preferences
import meal_planner/id
import meal_planner/types.{High, Low, Macros, Medium, Recipe}

pub fn main() {
  gleeunit.main()
}

pub fn default_filters_test() {
  let filters = preferences.default_filters()

  filters.max_fodmap_level
  |> should.equal(option.None)

  filters.require_vertical_diet
  |> should.equal(False)

  filters.allowed_cuisines
  |> should.equal(option.None)

  filters.max_difficulty
  |> should.equal(option.None)
}

pub fn filter_by_fodmap_test() {
  let recipe_low =
    Recipe(
      id: id.recipe_id("1"),
      name: "Low FODMAP Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let recipe_high =
    Recipe(
      id: id.recipe_id("2"),
      name: "High FODMAP Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 25.0, fat: 15.0, carbs: 45.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: High,
      vertical_compliant: False,
    )

  let recipes = [recipe_low, recipe_high]

  // Filter to only allow Low FODMAP
  let filters =
    preferences.PreferenceFilters(
      max_fodmap_level: option.Some(Low),
      require_vertical_diet: False,
      allowed_cuisines: option.None,
      max_difficulty: option.None,
      min_protein_per_serving: option.None,
      max_calories_per_serving: option.None,
    )

  let filtered = preferences.filter_recipes(recipes, filters)

  filtered
  |> list.length
  |> should.equal(1)

  filtered
  |> list.first
  |> should.be_ok
  |> fn(r) { r.name }
  |> should.equal("Low FODMAP Recipe")
}

pub fn filter_by_protein_test() {
  let recipe_high_protein =
    Recipe(
      id: id.recipe_id("1"),
      name: "High Protein Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 30.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let recipe_low_protein =
    Recipe(
      id: id.recipe_id("2"),
      name: "Low Protein Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 15.0, fat: 10.0, carbs: 45.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let recipes = [recipe_high_protein, recipe_low_protein]

  // Filter to only allow recipes with at least 30g protein
  let filters =
    preferences.PreferenceFilters(
      max_fodmap_level: option.None,
      require_vertical_diet: False,
      allowed_cuisines: option.None,
      max_difficulty: option.None,
      min_protein_per_serving: option.Some(30.0),
      max_calories_per_serving: option.None,
    )

  let filtered = preferences.filter_recipes(recipes, filters)

  filtered
  |> list.length
  |> should.equal(1)

  filtered
  |> list.first
  |> should.be_ok
  |> fn(r) { r.name }
  |> should.equal("High Protein Recipe")
}

pub fn calculate_difficulty_test() {
  let breakfast_recipe =
    Recipe(
      id: id.recipe_id("1"),
      name: "Breakfast Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      servings: 1,
      category: "Breakfast",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let dinner_recipe =
    Recipe(
      id: id.recipe_id("2"),
      name: "Dinner Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  preferences.calculate_difficulty(breakfast_recipe)
  |> should.equal(preferences.Easy)

  preferences.calculate_difficulty(dinner_recipe)
  |> should.equal(preferences.Medium)
}

pub fn count_matching_test() {
  let recipes = [
    Recipe(
      id: id.recipe_id("1"),
      name: "Recipe 1",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: id.recipe_id("2"),
      name: "Recipe 2",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 25.0, fat: 15.0, carbs: 45.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: High,
      vertical_compliant: False,
    ),
    Recipe(
      id: id.recipe_id("3"),
      name: "Recipe 3",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 35.0, fat: 12.0, carbs: 38.0),
      servings: 2,
      category: "Dinner",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  let filters =
    preferences.PreferenceFilters(
      max_fodmap_level: option.Some(Low),
      require_vertical_diet: True,
      allowed_cuisines: option.None,
      max_difficulty: option.None,
      min_protein_per_serving: option.None,
      max_calories_per_serving: option.None,
    )

  preferences.count_matching(recipes, filters)
  |> should.equal(2)
}
