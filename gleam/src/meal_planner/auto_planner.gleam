/// Auto Meal Planner Algorithm
/// Generates optimal meal plans based on diet principles, macro targets, and variety
///
/// Scoring Algorithm:
/// - Diet compliance: 40% weight (vertical diet compliance)
/// - Macro match: 35% weight (how close to target macros per meal)
/// - Variety: 25% weight (diverse protein sources, avoid duplicates)

import gleam/float
import gleam/int
import gleam/list
import gleam/string
import shared/types.{type Macros, type Recipe, Low, Macros}

// =============================================================================
// Types
// =============================================================================

/// Diet principle for meal planning
pub type DietPrinciple {
  VerticalDiet
}

/// Auto meal plan configuration
pub type AutoPlanConfig {
  AutoPlanConfig(
    diet_principles: List(DietPrinciple),
    macro_targets: Macros,
    recipe_count: Int,
    variety_factor: Float,
    user_id: String,
  )
}

/// Recipe score with component breakdowns
pub type RecipeScore {
  RecipeScore(
    recipe: Recipe,
    diet_compliance_score: Float,
    macro_match_score: Float,
    variety_score: Float,
    overall_score: Float,
  )
}

/// Auto-generated meal plan
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    recipes: List(Recipe),
    config: AutoPlanConfig,
    generated_at: String,
    total_macros: Macros,
  )
}

// =============================================================================
// Main Algorithm
// =============================================================================

/// Generate an auto meal plan from available recipes
/// Returns an optimized selection of recipes that meet diet principles,
/// match macro targets, and provide variety
pub fn generate_auto_plan(
  available_recipes: List(Recipe),
  config: AutoPlanConfig,
) -> Result(AutoMealPlan, String) {
  // Step 1: Filter by diet principles
  let filtered = filter_by_diet_principles(available_recipes, config.diet_principles)

  // Check if we have enough recipes
  case list.length(filtered) < config.recipe_count {
    True ->
      Error(
        "Insufficient recipes after diet filtering. Found "
        <> int.to_string(list.length(filtered))
        <> ", need "
        <> int.to_string(config.recipe_count),
      )
    False -> {
      // Step 2: Score all recipes
      let scored = score_all_recipes(config, [], filtered)

      // Step 3: Select top N with variety
      let selected = select_top_n(scored, config.recipe_count, config.variety_factor)

      // Step 4: Build meal plan
      build_meal_plan(selected, config)
    }
  }
}

// =============================================================================
// Diet Principle Filtering
// =============================================================================

/// Filter recipes by diet principles
/// Returns only recipes that meet all specified diet requirements
pub fn filter_by_diet_principles(
  recipes: List(Recipe),
  principles: List(DietPrinciple),
) -> List(Recipe) {
  case principles {
    [] -> recipes
    _ -> {
      list.filter(recipes, fn(recipe) {
        list.all(principles, fn(principle) {
          check_diet_compliance(recipe, principle)
        })
      })
    }
  }
}

/// Check if a recipe complies with a specific diet principle
fn check_diet_compliance(recipe: Recipe, principle: DietPrinciple) -> Bool {
  case principle {
    VerticalDiet -> recipe.vertical_compliant && recipe.fodmap_level == Low
  }
}

// =============================================================================
// Recipe Scoring
// =============================================================================

/// Score all recipes against config and already selected recipes
fn score_all_recipes(
  config: AutoPlanConfig,
  already_selected: List(Recipe),
  recipes: List(Recipe),
) -> List(RecipeScore) {
  list.map(recipes, fn(recipe) {
    score_recipe(recipe, config, already_selected)
  })
}

/// Score a single recipe
/// Returns a RecipeScore with component scores and weighted overall score
pub fn score_recipe(
  recipe: Recipe,
  config: AutoPlanConfig,
  already_selected: List(Recipe),
) -> RecipeScore {
  // Calculate component scores
  let diet_score = calculate_diet_compliance_score(recipe, config.diet_principles)
  let macro_score = calculate_macro_match_score(recipe, config.macro_targets, config.recipe_count)
  let variety_score = calculate_variety_score(recipe, already_selected)

  // Calculate weighted overall score
  // Diet compliance: 40%, Macro match: 35%, Variety: 25%
  let overall =
    diet_score *. 0.4
    +. macro_score *. 0.35
    +. variety_score *. 0.25

  RecipeScore(
    recipe: recipe,
    diet_compliance_score: diet_score,
    macro_match_score: macro_score,
    variety_score: variety_score,
    overall_score: overall,
  )
}

/// Calculate diet compliance score (0.0-1.0)
fn calculate_diet_compliance_score(
  recipe: Recipe,
  principles: List(DietPrinciple),
) -> Float {
  case principles {
    [] -> 1.0
    _ -> {
      let compliant =
        list.all(principles, fn(principle) {
          check_diet_compliance(recipe, principle)
        })
      case compliant {
        True -> 1.0
        False -> 0.0
      }
    }
  }
}

/// Calculate macro match score (0.0-1.0)
/// Compares recipe macros to ideal per-meal targets (total targets / recipe_count)
pub fn calculate_macro_match_score(
  recipe: Recipe,
  targets: Macros,
  recipe_count: Int,
) -> Float {
  // Calculate per-meal targets
  let per_meal_protein = targets.protein /. int_to_float(recipe_count)
  let per_meal_fat = targets.fat /. int_to_float(recipe_count)
  let per_meal_carbs = targets.carbs /. int_to_float(recipe_count)

  // Calculate percentage deviations
  let protein_dev = calculate_deviation_pct(recipe.macros.protein, per_meal_protein)
  let fat_dev = calculate_deviation_pct(recipe.macros.fat, per_meal_fat)
  let carbs_dev = calculate_deviation_pct(recipe.macros.carbs, per_meal_carbs)

  // Average the scores (inverted deviation = better match)
  let protein_score = 1.0 -. float.min(protein_dev, 1.0)
  let fat_score = 1.0 -. float.min(fat_dev, 1.0)
  let carbs_score = 1.0 -. float.min(carbs_dev, 1.0)

  // Weighted average (protein most important)
  protein_score *. 0.4 +. fat_score *. 0.3 +. carbs_score *. 0.3
}

/// Calculate percentage deviation (0.0 = perfect match, 1.0+ = large deviation)
fn calculate_deviation_pct(actual: Float, target: Float) -> Float {
  case target {
    0.0 -> 0.0
    _ -> float.absolute_value(actual -. target) /. target
  }
}

/// Calculate variety score (0.0-1.0)
/// Penalizes duplicate categories and similar recipes
pub fn calculate_variety_score(
  recipe: Recipe,
  already_selected: List(Recipe),
) -> Float {
  case already_selected {
    [] -> 1.0
    _ -> {
      // Check category uniqueness
      let category_penalty = calculate_category_penalty(recipe, already_selected)

      // Check protein source diversity (based on category prefix)
      let protein_penalty = calculate_protein_diversity_penalty(recipe, already_selected)

      // Combine penalties (lower penalty = higher score)
      1.0 -. { category_penalty *. 0.6 +. protein_penalty *. 0.4 }
    }
  }
}

/// Calculate penalty for duplicate categories
fn calculate_category_penalty(
  recipe: Recipe,
  already_selected: List(Recipe),
) -> Float {
  let same_category_count =
    list.filter(already_selected, fn(r) { r.category == recipe.category })
    |> list.length

  // Penalty increases with duplicates
  case same_category_count {
    0 -> 0.0
    1 -> 0.5
    _ -> 1.0
  }
}

/// Calculate penalty for similar protein sources
fn calculate_protein_diversity_penalty(
  recipe: Recipe,
  already_selected: List(Recipe),
) -> Float {
  let recipe_protein_type = extract_protein_type(recipe.category)

  let same_protein_count =
    list.filter(already_selected, fn(r) {
      extract_protein_type(r.category) == recipe_protein_type
    })
    |> list.length

  // Penalty for same protein type
  case same_protein_count {
    0 -> 0.0
    1 -> 0.3
    _ -> 0.7
  }
}

/// Extract protein type from category (beef, lamb, bison, etc.)
fn extract_protein_type(category: String) -> String {
  case string.split(category, "-") {
    [protein_type, ..] -> protein_type
    [] -> category
  }
}

// =============================================================================
// Selection Algorithm
// =============================================================================

/// Select top N recipes with variety factor
/// Uses a greedy algorithm that balances score and variety
pub fn select_top_n(
  scored_recipes: List(RecipeScore),
  count: Int,
  variety_factor: Float,
) -> List(Recipe) {
  select_recipes_greedy(scored_recipes, [], count, variety_factor)
}

/// Greedy selection with variety consideration
fn select_recipes_greedy(
  remaining: List(RecipeScore),
  selected: List(Recipe),
  count: Int,
  variety_factor: Float,
) -> List(Recipe) {
  case list.length(selected) >= count {
    True -> list.reverse(selected)
    False -> {
      case remaining {
        [] -> list.reverse(selected)
        _ -> {
          // Re-score remaining recipes considering already selected
          let rescored =
            list.map(remaining, fn(score) {
              let variety_score = calculate_variety_score(score.recipe, selected)

              // Combine original score with variety
              let adjusted_score =
                score.overall_score *. { 1.0 -. variety_factor }
                +. variety_score *. variety_factor

              #(score.recipe, adjusted_score)
            })

          // Sort by adjusted score
          let sorted =
            list.sort(rescored, fn(a, b) {
              let #(_, score_a) = a
              let #(_, score_b) = b
              float.compare(score_b, score_a)
            })

          // Select top recipe
          case sorted {
            [#(best_recipe, _), ..rest_sorted] -> {
              // Remove selected recipe from remaining
              let new_remaining =
                list.filter(remaining, fn(s) { s.recipe.id != best_recipe.id })

              // Add to selected
              let new_selected = [best_recipe, ..selected]

              // Continue selection
              select_recipes_greedy(new_remaining, new_selected, count, variety_factor)
            }
            [] -> list.reverse(selected)
          }
        }
      }
    }
  }
}

// =============================================================================
// Plan Building
// =============================================================================

/// Build final meal plan from selected recipes
fn build_meal_plan(
  recipes: List(Recipe),
  config: AutoPlanConfig,
) -> Result(AutoMealPlan, String) {
  // Calculate total macros
  let total_macros =
    list.fold(recipes, types.macros_zero(), fn(acc, recipe) {
      types.macros_add(acc, recipe.macros)
    })

  // Generate plan ID
  let plan_id = generate_plan_id(config.user_id)

  // Generate timestamp
  let timestamp = generate_timestamp()

  Ok(AutoMealPlan(
    id: plan_id,
    recipes: recipes,
    config: config,
    generated_at: timestamp,
    total_macros: total_macros,
  ))
}

/// Generate unique plan ID
fn generate_plan_id(user_id: String) -> String {
  "auto-plan-" <> user_id <> "-" <> generate_timestamp()
}

/// Generate ISO 8601 timestamp (placeholder - would use proper time library)
fn generate_timestamp() -> String {
  "2025-12-03T00:00:00Z"
}

/// Convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
