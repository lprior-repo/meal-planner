import gleeunit
import gleeunit/should
import meal_planner/auto_planner
import meal_planner/auto_planner/types as auto_types
import meal_planner/mealie/types as mealie
import meal_planner/types
import meal_planner/id
import gleam/list
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Builders
// ============================================================================

fn create_test_recipe(
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> types.Recipe {
  types.Recipe(
    id: id.recipe_id(name),
    name: name,
    ingredients: [],
    instructions: [],
    macros: types.Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "Test",
    fodmap_level: types.Low,
    vertical_compliant: False,
  )
}

fn create_test_mealie_recipe(
  slug: String,
  name: String,
  protein: String,
  fat: String,
  carbs: String,
) -> mealie.MealieRecipe {
  mealie.MealieRecipe(
    id: slug,
    slug: slug,
    name: name,
    description: None,
    image: None,
    recipe_yield: Some("4"),
    total_time: None,
    prep_time: None,
    cook_time: None,
    rating: None,
    org_url: None,
    recipe_ingredient: [],
    recipe_instructions: [],
    recipe_category: [],
    tags: [],
    nutrition: Some(mealie.MealieNutrition(
      calories: None,
      fat_content: Some(fat),
      protein_content: Some(protein),
      carbohydrate_content: Some(carbs),
      fiber_content: None,
      sodium_content: None,
      sugar_content: None,
    )),
    date_added: None,
    date_updated: None,
  )
}

fn create_test_config(
  protein_target: Float,
  fat_target: Float,
  carbs_target: Float,
  recipe_count: Int,
) -> auto_types.AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: "test-user",
    diet_principles: [],
    macro_targets: types.Macros(
      protein: protein_target,
      fat: fat_target,
      carbs: carbs_target,
    ),
    recipe_count: recipe_count,
    variety_factor: 1.0,
  )
}

// ============================================================================
// Score Recipe Tests
// ============================================================================

pub fn test_score_recipe_perfect_macro_match() {
  let recipe = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_recipe(recipe, config, [])

  // With perfect macro match, score should be 1.0
  score.macro_match_score |> should.equal(1.0)
  score.overall_score |> should.equal(1.0)
}

pub fn test_score_recipe_poor_macro_match() {
  let recipe = create_test_recipe("Chicken", 10.0, 5.0, 10.0)
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_recipe(recipe, config, [])

  // With poor macro match, score should be significantly lower
  { score.macro_match_score <. 0.5 } |> should.be_true
  { score.overall_score <. 0.5 } |> should.be_true
}

pub fn test_score_recipe_variety_with_no_selections() {
  let recipe = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_recipe(recipe, config, [])

  // First recipe should get full variety score
  score.variety_score |> should.equal(1.0)
}

pub fn test_score_recipe_variety_with_same_category() {
  let recipe1 = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let recipe2 = types.Recipe(
    ..recipe1,
    name: "Steak",
    category: "Test",
  )
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_recipe(recipe2, config, [recipe1])

  // Same category should reduce variety score
  score.variety_score |> should.equal(0.4)
}

pub fn test_score_recipe_variety_with_different_category() {
  let recipe1 = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let recipe2 = types.Recipe(
    ..recipe1,
    name: "Salad",
    category: "Vegetables",
  )
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_recipe(recipe2, config, [recipe1])

  // Different category should maintain full variety score
  score.variety_score |> should.equal(1.0)
}

pub fn test_score_mealie_recipe_conversion() {
  let mealie_recipe = create_test_mealie_recipe(
    "chicken-stew",
    "Chicken Stew",
    "30",
    "10",
    "40",
  )
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_mealie_recipe(mealie_recipe, config, [])

  // Should successfully score the Mealie recipe
  score.recipe.name |> should.equal("Chicken Stew")
  { score.overall_score >. 0.9 } |> should.be_true
}

pub fn test_score_mealie_recipe_macro_parsing() {
  let mealie_recipe = create_test_mealie_recipe(
    "beef-burger",
    "Beef Burger",
    "25",
    "15",
    "35",
  )
  let config = create_test_config(25.0, 15.0, 35.0, 1)

  let score = auto_planner.score_mealie_recipe(mealie_recipe, config, [])

  // Macros should be parsed correctly from nutrition strings
  score.macro_match_score |> should.equal(1.0)
}

pub fn test_score_mealie_recipe_with_no_nutrition() {
  let mealie_recipe = mealie.MealieRecipe(
    id: "recipe1",
    slug: "recipe1",
    name: "Mystery Dish",
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
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score = auto_planner.score_mealie_recipe(mealie_recipe, config, [])

  // Should handle recipes with no nutrition data
  score.recipe.macros.protein |> should.equal(0.0)
  score.recipe.macros.fat |> should.equal(0.0)
  score.recipe.macros.carbs |> should.equal(0.0)
}

// ============================================================================
// Variety Score Tests
// ============================================================================

pub fn test_calculate_variety_score_empty_selection() {
  let recipe = create_test_recipe("Chicken", 30.0, 10.0, 40.0)

  let score = auto_planner.calculate_variety_score(recipe, [])

  score |> should.equal(1.0)
}

pub fn test_calculate_variety_score_same_category_first_duplicate() {
  let recipe1 = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let recipe2 = types.Recipe(..recipe1, name: "Turkey")

  let score = auto_planner.calculate_variety_score(recipe2, [recipe1])

  score |> should.equal(0.4)
}

pub fn test_calculate_variety_score_same_category_second_duplicate() {
  let recipe1 = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let recipe2 = types.Recipe(..recipe1, name: "Turkey")
  let recipe3 = types.Recipe(..recipe1, name: "Duck")

  let score = auto_planner.calculate_variety_score(recipe3, [recipe1, recipe2])

  score |> should.equal(0.2)
}

pub fn test_calculate_variety_score_different_category() {
  let recipe1 = create_test_recipe("Chicken", 30.0, 10.0, 40.0)
  let recipe2 = types.Recipe(
    ..recipe1,
    name: "Salad",
    category: "Vegetables",
  )

  let score = auto_planner.calculate_variety_score(recipe2, [recipe1])

  score |> should.equal(1.0)
}

pub fn test_score_recipe_is_deterministic() {
  let recipe = create_test_recipe("Test", 25.0, 12.0, 35.0)
  let config = create_test_config(30.0, 10.0, 40.0, 1)

  let score1 = auto_planner.score_recipe(recipe, config, [])
  let score2 = auto_planner.score_recipe(recipe, config, [])

  // Same inputs should produce identical scores
  score1.overall_score |> should.equal(score2.overall_score)
  score1.diet_compliance_score |> should.equal(score2.diet_compliance_score)
  score1.macro_match_score |> should.equal(score2.macro_match_score)
  score1.variety_score |> should.equal(score2.variety_score)
}
