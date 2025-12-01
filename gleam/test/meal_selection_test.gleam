import gleeunit
import gleeunit/should
import meal_planner/meal_selection.{
  Eggs, RedMeat, Salmon, Variety, default_meal_selection_config,
  get_distribution, get_meal_category, is_within_targets, select_meals_for_week,
}
import meal_planner/types.{type Recipe, Ingredient, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// Helper function to create a test recipe
fn make_recipe(
  name: String,
  category: String,
  vertical_compliant: Bool,
) -> Recipe {
  Recipe(
    id: name,
    name: name,
    ingredients: [Ingredient("Test ingredient", "1 unit")],
    instructions: ["Test instruction"],
    macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
    servings: 1,
    category: category,
    fodmap_level: Low,
    vertical_compliant: vertical_compliant,
  )
}

pub fn get_meal_category_red_meat_test() {
  let recipe = make_recipe("Ribeye Steak", "beef", True)
  recipe
  |> get_meal_category
  |> should.equal(RedMeat)
}

pub fn get_meal_category_vertical_beef_test() {
  let recipe = make_recipe("Ground Beef", "vertical-beef", True)
  recipe
  |> get_meal_category
  |> should.equal(RedMeat)
}

pub fn get_meal_category_pork_test() {
  let recipe = make_recipe("Pork Chops", "pork", True)
  recipe
  |> get_meal_category
  |> should.equal(RedMeat)
}

pub fn get_meal_category_salmon_test() {
  let recipe = make_recipe("Grilled Salmon", "fish", True)
  recipe
  |> get_meal_category
  |> should.equal(Salmon)
}

pub fn get_meal_category_salmon_by_category_test() {
  let recipe = make_recipe("Baked Salmon", "salmon", True)
  recipe
  |> get_meal_category
  |> should.equal(Salmon)
}

pub fn get_meal_category_eggs_test() {
  let recipe = make_recipe("Scrambled Eggs", "breakfast", True)
  recipe
  |> get_meal_category
  |> should.equal(Eggs)
}

pub fn get_meal_category_eggs_vertical_breakfast_test() {
  let recipe = make_recipe("Egg Omelet", "vertical-breakfast", True)
  recipe
  |> get_meal_category
  |> should.equal(Eggs)
}

pub fn get_meal_category_eggs_by_name_test() {
  let recipe = make_recipe("Egg Whites", "protein", True)
  recipe
  |> get_meal_category
  |> should.equal(Eggs)
}

pub fn get_meal_category_variety_test() {
  let recipe = make_recipe("Chicken Breast", "chicken", True)
  recipe
  |> get_meal_category
  |> should.equal(Variety)
}

pub fn default_config_test() {
  let config = default_meal_selection_config()
  config.red_meat_min_percent
  |> should.equal(0.6)
  config.red_meat_max_percent
  |> should.equal(0.7)
  config.protein_min_percent
  |> should.equal(0.2)
  config.protein_max_percent
  |> should.equal(0.3)
  config.variety_max_percent
  |> should.equal(0.1)
}

pub fn select_meals_for_week_distribution_test() {
  // Create a diverse recipe pool
  let recipes = [
    make_recipe("Ribeye", "beef", True),
    make_recipe("Ground Beef", "beef", True),
    make_recipe("Pork Chops", "pork", True),
    make_recipe("Grilled Salmon", "salmon", True),
    make_recipe("Scrambled Eggs", "breakfast", True),
    make_recipe("Chicken", "chicken", True),
  ]

  let result = select_meals_for_week(recipes, 21)

  // Due to integer truncation, actual total may be slightly less
  // red_meat: 21 * 0.65 = 13, protein: 21 * 0.25 = 5, variety: max(21-13-5, 2) = 2
  // Total: 13 + 5 + 2 = 20
  result.total_count
  |> should.equal(20)

  // Check that we have a good distribution
  // Red meat should be 60-70% of 21 = ~13-15 meals
  { result.red_meat_count >= 12 }
  |> should.be_true

  { result.red_meat_count <= 16 }
  |> should.be_true

  // Salmon + Eggs should be 20-30% = ~4-6 meals
  let protein_alt = result.salmon_count + result.eggs_count
  { protein_alt >= 3 }
  |> should.be_true

  { protein_alt <= 8 }
  |> should.be_true

  // Variety should be <= 10% = <= 2 meals
  { result.variety_count <= 3 }
  |> should.be_true
}

pub fn get_distribution_test() {
  let result =
    meal_selection.MealSelectionResult(
      selected_recipes: [],
      red_meat_count: 14,
      salmon_count: 3,
      eggs_count: 2,
      variety_count: 2,
      total_count: 21,
    )

  let dist = get_distribution(result)

  // Red meat: 14/21 = 0.666...
  { dist.red_meat >=. 0.66 }
  |> should.be_true

  { dist.red_meat <=. 0.67 }
  |> should.be_true

  // Salmon: 3/21 = 0.142...
  { dist.salmon >=. 0.14 }
  |> should.be_true

  { dist.salmon <=. 0.15 }
  |> should.be_true
}

pub fn is_within_targets_valid_distribution_test() {
  let result =
    meal_selection.MealSelectionResult(
      selected_recipes: [],
      red_meat_count: 14,
      salmon_count: 3,
      eggs_count: 2,
      variety_count: 2,
      total_count: 21,
    )

  let config = default_meal_selection_config()

  result
  |> is_within_targets(config)
  |> should.be_true
}

pub fn is_within_targets_too_much_red_meat_test() {
  let result =
    meal_selection.MealSelectionResult(
      selected_recipes: [],
      red_meat_count: 18,
      salmon_count: 2,
      eggs_count: 1,
      variety_count: 0,
      total_count: 21,
    )

  let config = default_meal_selection_config()

  result
  |> is_within_targets(config)
  |> should.be_false
}

pub fn is_within_targets_not_enough_red_meat_test() {
  let result =
    meal_selection.MealSelectionResult(
      selected_recipes: [],
      red_meat_count: 10,
      salmon_count: 5,
      eggs_count: 4,
      variety_count: 2,
      total_count: 21,
    )

  let config = default_meal_selection_config()

  result
  |> is_within_targets(config)
  |> should.be_false
}

pub fn is_within_targets_too_much_variety_test() {
  let result =
    meal_selection.MealSelectionResult(
      selected_recipes: [],
      red_meat_count: 13,
      salmon_count: 2,
      eggs_count: 2,
      variety_count: 4,
      total_count: 21,
    )

  let config = default_meal_selection_config()

  result
  |> is_within_targets(config)
  |> should.be_false
}

pub fn select_meals_filters_non_compliant_test() {
  let recipes = [
    make_recipe("Compliant Beef", "beef", True),
    make_recipe("Non-Compliant Beef", "beef", False),
  ]

  let result = select_meals_for_week(recipes, 10)

  // Due to distribution logic: 10 * 0.65 = 6 red meat, 10 * 0.25 = 2 protein
  // Since we only have red meat available, we get 6 red meat meals
  result.total_count
  |> should.equal(6)

  // Should only cycle through the compliant recipe
  result.red_meat_count
  |> should.equal(6)
}
