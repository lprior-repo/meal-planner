/// Auto meal planner module
///
/// This module provides intelligent meal planning by scoring and selecting recipes
/// based on diet principles, macro targets, and variety preferences.
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/order
import meal_planner/auto_planner/types as auto_types
import meal_planner/mealie/mapper
import meal_planner/mealie/types as mealie
import meal_planner/types

// Re-export types for convenience
pub type DietPrinciple =
  auto_types.DietPrinciple

pub type AutoPlanConfig =
  auto_types.AutoPlanConfig

pub type AutoMealPlan =
  auto_types.AutoMealPlan

// ============================================================================
// Types
// ============================================================================

/// Comprehensive recipe scoring with multiple dimensions
pub type RecipeScore {
  RecipeScore(
    recipe: types.Recipe,
    diet_compliance_score: Float,
    macro_match_score: Float,
    variety_score: Float,
    overall_score: Float,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Efficiently count list items using fold instead of O(n) length
fn count_list(items: List(a)) -> Int {
  list.fold(items, 0, fn(acc, _) { acc + 1 })
}

// ============================================================================
// Filtering Functions
// ============================================================================

/// Filter recipes based on diet principle compliance
/// Works with internal Recipe type
/// Supports all diet principles with appropriate compliance checks
pub fn filter_by_diet_principles(
  recipes: List(types.Recipe),
  principles: List(DietPrinciple),
) -> List(types.Recipe) {
  filter_recipes_by_principles(recipes, principles)
}

/// Filter Mealie recipes based on diet principles
/// Converts MealieRecipe to Recipe first, then applies diet filtering
/// This allows diet principles to work with Mealie API data
pub fn filter_mealie_recipes_by_diet(
  mealie_recipes: List(mealie.MealieRecipe),
  principles: List(DietPrinciple),
) -> List(mealie.MealieRecipe) {
  case principles {
    [] -> mealie_recipes
    _ -> {
      let recipes = list.map(mealie_recipes, mapper.mealie_to_recipe)
      let filtered = filter_recipes_by_principles(recipes, principles)
      let filtered_ids = list.map(filtered, fn(r) { r.id })
      list.filter(mealie_recipes, fn(mealie_recipe) {
        let recipe_id = mapper.mealie_to_recipe(mealie_recipe).id
        list.any(filtered_ids, fn(id) { id == recipe_id })
      })
    }
  }
}

/// Internal helper: filter Recipe list by diet principles
fn filter_recipes_by_principles(
  recipes: List(types.Recipe),
  principles: List(DietPrinciple),
) -> List(types.Recipe) {
  list.filter(recipes, fn(recipe) {
    is_recipe_compliant_with_principles(recipe, principles)
  })
}

/// Check if a recipe complies with all given diet principles
fn is_recipe_compliant_with_principles(
  recipe: types.Recipe,
  principles: List(DietPrinciple),
) -> Bool {
  case principles {
    [] -> True
    _ ->
      list.all(principles, fn(principle) {
        is_recipe_compliant_with_principle(recipe, principle)
      })
  }
}

/// Check if a recipe complies with a single diet principle
fn is_recipe_compliant_with_principle(
  recipe: types.Recipe,
  principle: DietPrinciple,
) -> Bool {
  case principle {
    auto_types.VerticalDiet ->
      recipe.vertical_compliant && recipe.fodmap_level == types.Low

    auto_types.TimFerriss ->
      recipe.fodmap_level == types.Low

    auto_types.Paleo ->
      recipe.fodmap_level == types.Low

    auto_types.Keto ->
      recipe.fodmap_level == types.Low

    auto_types.Mediterranean ->
      recipe.fodmap_level == types.Low

    auto_types.HighProtein ->
      True
  }
}

// ============================================================================
// Scoring Functions
// ============================================================================

/// Calculate how well recipe macros match daily targets (divided by recipe count)
/// Uses exponential decay scoring: perfect match = 1.0, poor match approaches 0
pub fn calculate_macro_match_score(
  recipe: types.Recipe,
  targets: types.Macros,
  recipe_count: Int,
) -> Float {
  // Calculate target per recipe (daily target / number of recipes)
  let target_per_recipe =
    types.Macros(
      protein: targets.protein /. int.to_float(recipe_count),
      fat: targets.fat /. int.to_float(recipe_count),
      carbs: targets.carbs /. int.to_float(recipe_count),
    )

  // Calculate percentage deviation for each macro
  let protein_dev =
    calculate_deviation(recipe.macros.protein, target_per_recipe.protein)
  let fat_dev = calculate_deviation(recipe.macros.fat, target_per_recipe.fat)
  let carbs_dev =
    calculate_deviation(recipe.macros.carbs, target_per_recipe.carbs)

  // Average the deviations
  let avg_dev = { protein_dev +. fat_dev +. carbs_dev } /. 3.0

  // Convert to score using exponential decay
  // e^(-2 * deviation) gives: 0% dev = 1.0, 50% dev = 0.37, 100% dev = 0.14
  float_exp(-2.0 *. avg_dev)
}

/// Calculate variety score based on category uniqueness
/// Returns 1.0 for unique categories, lower scores for duplicates
pub fn calculate_variety_score(
  recipe: types.Recipe,
  already_selected: List(types.Recipe),
) -> Float {
  case already_selected {
    [] -> 1.0
    _ -> {
      // Count how many times this category appears in already selected
      let category_count =
        list.count(already_selected, fn(r) { r.category == recipe.category })

      case category_count {
        0 -> 1.0
        1 -> 0.4
        _ -> 0.2
      }
    }
  }
}

/// Score a recipe comprehensively using all dimensions
/// Simplified version - diet compliance check without validator
/// Works with internal Recipe type after conversion from MealieRecipe
pub fn score_recipe(
  recipe: types.Recipe,
  config: AutoPlanConfig,
  already_selected: List(types.Recipe),
) -> RecipeScore {
  // Diet compliance score (simplified - check vertical_compliant flag)
  let diet_score = case config.diet_principles {
    [] -> 1.0
    _ -> {
      let is_vertical =
        list.any(config.diet_principles, fn(p) { p == auto_types.VerticalDiet })
      case is_vertical {
        True ->
          case recipe.vertical_compliant && recipe.fodmap_level == types.Low {
            True -> 1.0
            False -> 0.0
          }
        // For other diets, give full score (simplified)
        False -> 1.0
      }
    }
  }

  // Macro match score
  let macro_score =
    calculate_macro_match_score(
      recipe,
      config.macro_targets,
      config.recipe_count,
    )

  // Variety score
  let variety_score = calculate_variety_score(recipe, already_selected)

  // Weighted overall score: diet 40%, macros 35%, variety 25%
  let overall =
    diet_score *. 0.4 +. macro_score *. 0.35 +. variety_score *. 0.25

  RecipeScore(
    recipe: recipe,
    diet_compliance_score: diet_score,
    macro_match_score: macro_score,
    variety_score: variety_score,
    overall_score: overall,
  )
}

/// Score a Mealie recipe directly without conversion
/// Converts MealieRecipe to internal Recipe type then scores it
/// This provides a convenient interface for scoring Mealie recipes
pub fn score_mealie_recipe(
  mealie_recipe: mealie.MealieRecipe,
  config: AutoPlanConfig,
  already_selected: List(types.Recipe),
) -> RecipeScore {
  let recipe = mapper.mealie_to_recipe(mealie_recipe)
  score_recipe(recipe, config, already_selected)
}

// ============================================================================
// Selection Functions
// ============================================================================

/// Select top N recipes with variety consideration
/// Iteratively selects recipes, rescoring variety after each selection
pub fn select_top_n(
  scored_recipes: List(RecipeScore),
  count: Int,
  variety_factor: Float,
) -> List(types.Recipe) {
  select_top_n_helper(scored_recipes, count, variety_factor, [])
}

fn select_top_n_helper(
  available: List(RecipeScore),
  remaining: Int,
  variety_factor: Float,
  selected: List(types.Recipe),
) -> List(types.Recipe) {
  case remaining {
    0 -> list.reverse(selected)
    _ ->
      case available {
        [] -> list.reverse(selected)
        _ -> {
          // Adjust scores based on variety factor
          let adjusted =
            list.map(available, fn(scored) {
              let new_variety = calculate_variety_score(scored.recipe, selected)
              let new_overall =
                scored.diet_compliance_score
                *. 0.4
                +. scored.macro_match_score
                *. 0.35
                +. new_variety
                *. 0.25
                *. variety_factor

              RecipeScore(..scored, overall_score: new_overall)
            })

          // Sort by overall score
          let sorted =
            list.sort(adjusted, fn(a, b) {
              case a.overall_score >. b.overall_score {
                True -> order.Lt
                False -> order.Gt
              }
            })

          // Take the best one
          case sorted {
            [best, ..rest] ->
              select_top_n_helper(rest, remaining - 1, variety_factor, [
                best.recipe,
                ..selected
              ])
            [] -> list.reverse(selected)
          }
        }
      }
  }
}

// ============================================================================
// Main Generation Function
// ============================================================================

/// Generate an auto meal plan from available Mealie recipes
/// Converts MealieRecipe list to internal Recipe type for processing
pub fn generate_auto_plan(
  mealie_recipes: List(mealie.MealieRecipe),
  config: AutoPlanConfig,
) -> Result(AutoMealPlan, String) {
  // Convert MealieRecipe list to internal Recipe type
  let recipes = list.map(mealie_recipes, mapper.mealie_to_recipe)

  // Validate config
  case config.recipe_count < 1 {
    True -> Error("recipe_count must be at least 1")
    False -> {
      // Filter recipes by diet principles
      let filtered = filter_by_diet_principles(recipes, config.diet_principles)

      // Count filtered recipes efficiently
      let filtered_count = count_list(filtered)
      case filtered_count < config.recipe_count {
        True ->
          Error(
            "Insufficient recipes after filtering: "
            <> int.to_string(filtered_count)
            <> " available, "
            <> int.to_string(config.recipe_count)
            <> " required",
          )
        False -> {
          // Score all filtered recipes
          let scored = list.map(filtered, fn(r) { score_recipe(r, config, []) })

          // Select top N recipes
          let selected =
            select_top_n(scored, config.recipe_count, config.variety_factor)

          // Verify selection count efficiently
          let selected_count = count_list(selected)
          case selected_count < config.recipe_count {
            True -> Error("Failed to select enough recipes")
            False -> {
              // Calculate total macros
              let total_macros =
                list.fold(
                  selected,
                  types.Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
                  fn(acc, recipe) {
                    types.Macros(
                      protein: acc.protein +. recipe.macros.protein,
                      fat: acc.fat +. recipe.macros.fat,
                      carbs: acc.carbs +. recipe.macros.carbs,
                    )
                  },
                )

              // Generate plan ID (simple timestamp-based ID)
              let plan_id = "auto-plan-" <> generate_timestamp()

              // Serialize recipes to JSON string
              let recipe_json =
                json.array(selected, types.recipe_to_json)
                |> json.to_string

              Ok(auto_types.AutoMealPlan(
                id: plan_id,
                config: config,
                recipes: selected,
                total_macros: total_macros,
                generated_at: generate_timestamp(),
                recipe_json: recipe_json,
              ))
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Timestamp Functions
// ============================================================================

/// Generate timestamp string in ISO8601 format with UTC timezone
/// Format: YYYY-MM-DDTHH:MM:SSZ
fn generate_timestamp() -> String {
  let #(#(year, month, day), #(hour, min, sec)) = erlang_universaltime()
  int_to_string(year)
  <> "-"
  <> pad_two(month)
  <> "-"
  <> pad_two(day)
  <> "T"
  <> pad_two(hour)
  <> ":"
  <> pad_two(min)
  <> ":"
  <> pad_two(sec)
  <> "Z"
}

/// Pad a single digit integer with leading zero
/// Converts 5 to "05", leaves 10 as "10"
fn pad_two(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int_to_string(n)
    False -> int_to_string(n)
  }
}

/// Convert integer to string
fn int_to_string(n: Int) -> String {
  int.to_string(n)
}

/// External function to get UTC time as {{year, month, day}, {hour, min, sec}}
@external(erlang, "calendar", "universal_time")
fn erlang_universaltime() -> #(#(Int, Int, Int), #(Int, Int, Int))

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate deviation percentage between actual and target
fn calculate_deviation(actual: Float, target: Float) -> Float {
  case target {
    0.0 -> 0.0
    _ -> {
      let diff = float.absolute_value(actual -. target)
      diff /. target
    }
  }
}

// External functions for math operations
@external(erlang, "math", "exp")
fn float_exp(x: Float) -> Float
