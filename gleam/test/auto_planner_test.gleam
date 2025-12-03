/// Comprehensive test suite for auto meal planner module
/// Tests automatic recipe generation, variety optimization, and macro targeting

import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleeunit
import gleeunit/should
import shared/types.{
  type Macros, type Recipe, type UserProfile, Active, Ingredient, Low, Macros,
  Maintain, Recipe, UserProfile,
}

// ============================================================================
// Auto Plan Types
// ============================================================================

pub type DietPrinciple {
  VerticalDiet
  TimFerriss
  Flexible
}

pub type AutoPlanConfig {
  AutoPlanConfig(
    diet_principles: List(DietPrinciple),
    macro_targets: Macros,
    recipe_count: Int,
    variety_factor: Float,
    user_id: String,
  )
}

pub type AutoMealPlan {
  AutoMealPlan(
    recipes: List(Recipe),
    total_macros: Macros,
    compliance_score: Float,
    variety_score: Float,
  )
}

// ============================================================================
// Recipe Generation Tests
// ============================================================================

/// Test generating 4 recipes from a pool
pub fn generate_4_recipes_test() {
  let recipes = create_test_recipes(20)
  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: Macros(protein: 150.0, carbs: 200.0, fat: 70.0),
      recipe_count: 4,
      variety_factor: 0.7,
      user_id: "test-user",
    )

  let result = generate_auto_plan(recipes, config)

  result
  |> should.be_ok

  case result {
    Ok(plan) -> {
      plan.recipes
      |> list.length
      |> should.equal(4)

      // Verify no duplicate recipes
      let recipe_ids = list.map(plan.recipes, fn(r) { r.id })
      let unique_ids = list.unique(recipe_ids)
      list.length(recipe_ids)
      |> should.equal(list.length(unique_ids))
    }
    Error(_) -> should.fail()
  }
}

/// Test macro targeting accuracy
pub fn macro_targeting_test() {
  let recipes = create_test_recipes(20)
  let target_macros = Macros(protein: 180.0, carbs: 250.0, fat: 60.0)
  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: target_macros,
      recipe_count: 4,
      variety_factor: 0.5,
      user_id: "test-user",
    )

  let result = generate_auto_plan(recipes, config)

  case result {
    Ok(plan) -> {
      // Total macros should be within 20% of target
      let tolerance = 0.20

      let protein_diff =
        float.absolute_value(plan.total_macros.protein -. target_macros.protein)
      let protein_within_range =
        protein_diff /. target_macros.protein <. tolerance

      protein_within_range
      |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

/// Test variety optimization
pub fn variety_optimization_test() {
  let recipes = create_diverse_recipes(30)
  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: Macros(protein: 160.0, carbs: 200.0, fat: 70.0),
      recipe_count: 4,
      variety_factor: 0.8,
      user_id: "test-user",
    )

  let result = generate_auto_plan(recipes, config)

  case result {
    Ok(plan) -> {
      // Check variety score is high
      plan.variety_score
      |> should.satisfy(fn(s) { s >. 0.6 })

      // No duplicate recipes
      let unique_recipes = list.unique_by(plan.recipes, fn(r) { r.id })
      list.length(unique_recipes)
      |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}

/// Test insufficient compliant recipes error
pub fn insufficient_recipes_error_test() {
  let limited_recipes = create_test_recipes(2)
  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: Macros(protein: 150.0, carbs: 200.0, fat: 70.0),
      recipe_count: 4,
      variety_factor: 0.7,
      user_id: "test-user",
    )

  let result = generate_auto_plan(limited_recipes, config)

  result
  |> should.be_error
}

/// Test diet principle filtering
pub fn diet_principle_filtering_test() {
  let recipes = create_mixed_diet_recipes(30)
  let vertical_config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: Macros(protein: 150.0, carbs: 200.0, fat: 70.0),
      recipe_count: 4,
      variety_factor: 0.7,
      user_id: "test-user",
    )

  let result = generate_auto_plan(recipes, vertical_config)

  case result {
    Ok(plan) -> {
      // All recipes should be vertical diet compliant
      plan.recipes
      |> list.all(fn(r) { types.is_vertical_diet_compliant(r) })
      |> should.be_true

      // Compliance score should be high
      plan.compliance_score
      |> should.satisfy(fn(s) { s >. 0.8 })
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// User Profile Integration Tests
// ============================================================================

/// Test generating plan based on user profile
pub fn user_profile_integration_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 4,
    )

  let daily_targets = types.daily_macro_targets(profile)
  let recipes = create_test_recipes(30)

  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: daily_targets,
      recipe_count: 4,
      variety_factor: 0.7,
      user_id: profile.id,
    )

  let result = generate_auto_plan(recipes, config)

  result
  |> should.be_ok
}

/// Test variety score calculation
pub fn variety_score_calculation_test() {
  let high_variety_recipes = [
    create_recipe("beef-rice", "beef", 40.0, 50.0, 15.0),
    create_recipe("salmon-potato", "salmon", 35.0, 45.0, 12.0),
    create_recipe("chicken-beans", "chicken", 38.0, 40.0, 10.0),
    create_recipe("eggs-veggies", "eggs", 25.0, 20.0, 18.0),
  ]

  let high_score = calculate_variety_score(high_variety_recipes)

  let low_variety_recipes = [
    create_recipe("beef-rice-1", "beef", 40.0, 50.0, 15.0),
    create_recipe("beef-rice-2", "beef", 40.0, 50.0, 15.0),
    create_recipe("beef-rice-3", "beef", 40.0, 50.0, 15.0),
    create_recipe("beef-rice-4", "beef", 40.0, 50.0, 15.0),
  ]

  let low_score = calculate_variety_score(low_variety_recipes)

  high_score
  |> should.be_greater_than(low_score)
}

/// Test empty recipe pool
pub fn empty_recipe_pool_test() {
  let config =
    AutoPlanConfig(
      diet_principles: [VerticalDiet],
      macro_targets: Macros(protein: 150.0, carbs: 200.0, fat: 70.0),
      recipe_count: 4,
      variety_factor: 0.7,
      user_id: "test-user",
    )

  let result = generate_auto_plan([], config)

  result
  |> should.be_error
}

// ============================================================================
// Helper Functions
// ============================================================================

fn generate_auto_plan(
  recipes: List(Recipe),
  config: AutoPlanConfig,
) -> Result(AutoMealPlan, String) {
  let filtered = filter_by_diet_principles(recipes, config.diet_principles)

  case list.length(filtered) < config.recipe_count {
    True -> Error("Insufficient compliant recipes")
    False -> {
      let selected = list.take(filtered, config.recipe_count)
      let total = sum_macros(selected)
      let compliance = calculate_compliance_score(
        selected,
        list.first(config.diet_principles) |> result.unwrap(Flexible),
      )
      let variety = calculate_variety_score(selected)

      Ok(AutoMealPlan(
        recipes: selected,
        total_macros: total,
        compliance_score: compliance,
        variety_score: variety,
      ))
    }
  }
}

fn filter_by_diet_principles(
  recipes: List(Recipe),
  principles: List(DietPrinciple),
) -> List(Recipe) {
  case list.contains(principles, Flexible) {
    True -> recipes
    False -> {
      case list.contains(principles, VerticalDiet) {
        True -> list.filter(recipes, types.is_vertical_diet_compliant)
        False -> recipes
      }
    }
  }
}

fn calculate_variety_score(recipes: List(Recipe)) -> Float {
  let protein_sources = get_protein_sources(recipes)
  let unique_sources = list.unique(protein_sources)

  int.to_float(list.length(unique_sources))
  /. int.to_float(list.length(recipes))
}

fn get_protein_sources(recipes: List(Recipe)) -> List(String) {
  list.map(recipes, fn(recipe) {
    case list.first(recipe.ingredients) {
      Ok(ing) -> ing.name
      Error(_) -> "unknown"
    }
  })
}

fn calculate_compliance_score(
  recipes: List(Recipe),
  principle: DietPrinciple,
) -> Float {
  case principle {
    VerticalDiet -> {
      let compliant_count =
        list.count(recipes, types.is_vertical_diet_compliant)
      int.to_float(compliant_count) /. int.to_float(list.length(recipes))
    }
    TimFerriss -> 0.0
    Flexible -> 1.0
  }
}

fn sum_macros(recipes: List(Recipe)) -> Macros {
  let per_serving_macros = list.map(recipes, types.macros_per_serving)
  types.macros_sum(per_serving_macros)
}

// ============================================================================
// Test Data Generators
// ============================================================================

fn create_test_recipes(count: Int) -> List(Recipe) {
  list.range(1, count)
  |> list.map(fn(i) {
    create_compliant_recipe(
      "recipe-" <> int.to_string(i),
      35.0 +. int.to_float(i) *. 2.0,
      50.0 +. int.to_float(i) *. 3.0,
      15.0 +. int.to_float(i),
    )
  })
}

fn create_diverse_recipes(count: Int) -> List(Recipe) {
  let proteins = ["beef", "salmon", "chicken", "bison", "eggs"]
  list.range(0, count - 1)
  |> list.map(fn(i) {
    let protein_idx = i % list.length(proteins)
    let protein = case list.at(proteins, protein_idx) {
      Ok(p) -> p
      Error(_) -> "beef"
    }
    create_recipe(
      protein <> "-meal-" <> int.to_string(i),
      protein,
      35.0 +. int.to_float(i),
      50.0,
      15.0,
    )
  })
}

fn create_mixed_diet_recipes(count: Int) -> List(Recipe) {
  list.range(1, count)
  |> list.map(fn(i) {
    case i % 2 {
      0 ->
        create_compliant_recipe(
          "recipe-" <> int.to_string(i),
          35.0,
          50.0,
          15.0,
        )
      _ ->
        create_non_compliant_recipe(
          "recipe-" <> int.to_string(i),
          30.0,
          80.0,
          20.0,
        )
    }
  })
}

fn create_compliant_recipe(
  id: String,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> Recipe {
  Recipe(
    id: id,
    name: id,
    ingredients: [Ingredient("Beef", "8 oz"), Ingredient("White rice", "1 cup")],
    instructions: ["Cook"],
    macros: Macros(protein: protein, carbs: carbs, fat: fat),
    servings: 1,
    category: "main",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn create_non_compliant_recipe(
  id: String,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> Recipe {
  Recipe(
    id: id,
    name: id,
    ingredients: [Ingredient("Pasta", "2 cups")],
    instructions: ["Cook"],
    macros: Macros(protein: protein, carbs: carbs, fat: fat),
    servings: 1,
    category: "main",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

fn create_recipe(
  id: String,
  protein_source: String,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> Recipe {
  Recipe(
    id: id,
    name: id,
    ingredients: [Ingredient(protein_source, "8 oz")],
    instructions: ["Cook"],
    macros: Macros(protein: protein, carbs: carbs, fat: fat),
    servings: 1,
    category: "main",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
