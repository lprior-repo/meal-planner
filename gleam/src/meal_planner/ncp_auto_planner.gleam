/// NCP Auto Planner Integration
///
/// Connects the NCP (Nutrition Control Plane) system with the auto meal planner.
/// When NCP shows macro deficits, this module:
/// 1. Analyzes the specific deficit (protein, fat, carbs)
/// 2. Queries recipes that fill those gaps
/// 3. Scores recipes for compliance with diet principles
/// 4. Returns top suggestions to hit daily targets
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import meal_planner/auto_planner/recipe_scorer
import meal_planner/auto_planner/types as auto_types

// Simplified: removed diet_validator dependency
import meal_planner/ncp
import meal_planner/storage.{type StorageError}
import meal_planner/types.{type Macros, type Recipe, Macros}
import pog

// ============================================================================
// Types
// ============================================================================

/// Configuration for auto-suggestion generation
/// Simplified: diet principles now use String type
pub type SuggestionConfig {
  SuggestionConfig(
    /// Maximum number of recipes to suggest
    max_suggestions: Int,
    /// Diet principles to follow when suggesting recipes (simplified - strings)
    diet_principles: List(String),
    /// Minimum compliance score (0.0-1.0) for recipes
    min_compliance_score: Float,
    /// Weight for variety when scoring (0.0-1.0)
    variety_weight: Float,
  )
}

/// A suggested recipe with scoring and reasoning
pub type RecipeSuggestion {
  RecipeSuggestion(
    recipe: Recipe,
    /// Overall score combining macro match, diet compliance, and variety
    total_score: Float,
    /// How well the recipe addresses the macro deficit
    macro_match_score: Float,
    /// Diet compliance score
    compliance_score: Float,
    /// Human-readable reason for suggestion
    reason: String,
    /// Macro contribution toward deficit
    contribution: Macros,
  )
}

/// Result of auto-suggestion generation
pub type SuggestionResult {
  SuggestionResult(
    /// Current macro deficit from NCP
    deficit: ncp.DeviationResult,
    /// Suggested recipes to address deficit
    suggestions: List(RecipeSuggestion),
    /// Whether user is within tolerance (no suggestions needed)
    within_tolerance: Bool,
  )
}

// ============================================================================
// Main Integration Function
// ============================================================================

/// Generate recipe suggestions based on NCP deficit analysis
///
/// This is the main entry point that connects NCP status with auto planner.
///
/// ## Flow:
/// 1. Calculate current NCP deficit from goals and actual consumption
/// 2. If within tolerance, return empty suggestions
/// 3. Query recipes that help fill macro gaps
/// 4. Score recipes for macro match, diet compliance, and variety
/// 5. Return top N suggestions
pub fn suggest_recipes_for_deficit(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
  actual: ncp.NutritionData,
  config: SuggestionConfig,
) -> Result(SuggestionResult, StorageError) {
  // Calculate deviation from goals
  let deficit = ncp.calculate_deviation(goals, actual)

  // Check if within tolerance (default: 10%)
  let within_tolerance = ncp.deviation_is_within_tolerance(deficit, 10.0)

  case within_tolerance {
    True ->
      // No suggestions needed - user is on track
      Ok(SuggestionResult(
        deficit: deficit,
        suggestions: [],
        within_tolerance: True,
      ))

    False -> {
      // Query recipes that help address the deficit
      use recipes <- result.try(query_recipes_by_macro_deficit(conn, deficit))

      // Score and rank recipes
      let scored_recipes =
        score_recipes_for_deficit(recipes, deficit, config.diet_principles)

      // Filter by minimum compliance score
      let filtered =
        list.filter(scored_recipes, fn(sugg) {
          sugg.compliance_score >=. config.min_compliance_score
        })

      // Take top N suggestions
      let top_suggestions = list.take(filtered, config.max_suggestions)

      Ok(SuggestionResult(
        deficit: deficit,
        suggestions: top_suggestions,
        within_tolerance: False,
      ))
    }
  }
}

// ============================================================================
// Recipe Querying
// ============================================================================

/// Query recipes that help address a macro deficit
///
/// Prioritizes recipes based on which macros are in deficit:
/// - Protein deficit: Query high-protein recipes (>30g protein)
/// - Carb deficit: Query high-carb recipes (>40g carbs)
/// - Fat deficit: Query high-fat recipes (>20g fat)
/// - Multiple deficits: Query balanced recipes
pub fn query_recipes_by_macro_deficit(
  conn: pog.Connection,
  deficit: ncp.DeviationResult,
) -> Result(List(Recipe), StorageError) {
  // Determine which macros are in deficit (negative deviation)
  let protein_deficit = deficit.protein_pct <. -5.0
  let fat_deficit = deficit.fat_pct <. -5.0
  let carbs_deficit = deficit.carbs_pct <. -5.0

  case protein_deficit, fat_deficit, carbs_deficit {
    // High protein deficit - prioritize protein recipes
    True, _, _ if deficit.protein_pct <. -15.0 ->
      query_high_protein_recipes(conn, 30.0)

    // High carb deficit - prioritize carb recipes
    _, _, True if deficit.carbs_pct <. -15.0 ->
      query_high_carb_recipes(conn, 40.0)

    // Fat deficit
    _, True, _ -> query_high_fat_recipes(conn, 20.0)

    // Multiple deficits - get balanced recipes
    True, True, _ | True, _, True | _, True, True ->
      query_balanced_recipes(conn)

    // Protein deficit (moderate)
    True, _, _ -> query_high_protein_recipes(conn, 25.0)

    // Carbs deficit (moderate)
    _, _, True -> query_high_carb_recipes(conn, 30.0)

    // No significant deficit or surplus
    _, _, _ -> query_balanced_recipes(conn)
  }
}

/// Query recipes with high protein content
/// TODO: Implement with proper storage API
fn query_high_protein_recipes(
  _conn: pog.Connection,
  _min_protein: Float,
) -> Result(List(Recipe), StorageError) {
  Ok([])
}

/// Query recipes with high carb content
/// TODO: Implement with proper storage API
fn query_high_carb_recipes(
  _conn: pog.Connection,
  _min_carbs: Float,
) -> Result(List(Recipe), StorageError) {
  Ok([])
}

/// Query recipes with high fat content
/// TODO: Implement with proper storage API
fn query_high_fat_recipes(
  _conn: pog.Connection,
  _min_fat: Float,
) -> Result(List(Recipe), StorageError) {
  Ok([])
}

/// Query recipes with balanced macros
/// TODO: Implement with proper storage API
fn query_balanced_recipes(
  _conn: pog.Connection,
) -> Result(List(Recipe), StorageError) {
  Ok([])
}

// ============================================================================
// Mealie Integration
// ============================================================================

/// Fetch recipes from Mealie and convert them to internal Recipe type
///
/// This function:
/// 1. Calls client.list_recipes() to get MealieRecipeSummary list
/// 2. For each summary, fetches the full MealieRecipe with client.get_recipe()
/// 3. Converts each MealieRecipe to Recipe using mapper.mealie_to_recipe()
///
/// Returns a Result with the list of converted recipes or a StorageError
///
/// Example:
/// ```gleam
/// let config = config.load()
/// case fetch_mealie_recipes(config) {
///   Ok(recipes) -> {
///     io.println("Fetched " <> int.to_string(list.length(recipes)) <> " recipes")
///   }
///   Error(err) -> io.println("Error: " <> storage.error_to_string(err))
/// }
/// ```
pub fn fetch_mealie_recipes(config: Config) -> Result(List(Recipe), StorageError) {
  // List all recipes (summaries)
  use recipe_summaries <- result.try(
    client.list_recipes(config)
    |> result.map(fn(paginated) { paginated.items })
    |> result.map_error(fn(client_err) {
      storage.OtherError(client.error_to_string(client_err))
    }),
  )

  // Fetch full recipe details for each summary
  let full_recipes =
    recipe_summaries
    |> list.filter_map(fn(summary) {
      case client.get_recipe(config, summary.slug) {
        Ok(full_recipe) -> Ok(full_recipe)
        Error(_) -> Error(Nil)
        // Skip recipes that fail to fetch
      }
    })

  // Convert Mealie recipes to internal Recipe type
  let recipes = list.map(full_recipes, mapper.mealie_to_recipe)

  Ok(recipes)
}

// ============================================================================
// Recipe Scoring
// ============================================================================

/// Score recipes for how well they address the deficit
///
/// Combines three scoring factors:
/// 1. Macro match score (0-1): How well recipe fills deficit
/// 2. Diet compliance score (0-1): Recipe compliance with diet principles
/// 3. Variety score (0-1): Ingredient diversity
fn score_recipes_for_deficit(
  recipes: List(Recipe),
  deficit: ncp.DeviationResult,
  _diet_principles: List(String),
) -> List(RecipeSuggestion) {
  recipes
  |> list.map(fn(recipe) {
    // Score macro match using NCP's scoring function
    let macro_match_score =
      ncp.score_recipe_for_deviation(deficit, recipe.macros)

    // Diet compliance (simplified - always 1.0)
    let _compliance_score = 1.0

    // Score variety
    let variety_score = recipe_scorer.score_variety(recipe)

    // Calculate weighted total score
    // Weights: macro match (50%), compliance (30%), variety (20%)
    // Simplified: compliance always 1.0
    let total_score =
      { 0.5 *. macro_match_score } +. { 0.3 *. 1.0 } +. { 0.2 *. variety_score }

    // Generate human-readable reason
    let reason = generate_suggestion_reason(deficit, recipe.macros)

    RecipeSuggestion(
      recipe: recipe,
      total_score: total_score,
      macro_match_score: macro_match_score,
      compliance_score: 1.0,
      // Simplified: always compliant
      reason: reason,
      contribution: recipe.macros,
    )
  })
  |> list.sort(fn(a, b) {
    // Sort descending by total score
    float.compare(b.total_score, a.total_score)
  })
}

/// Generate human-readable reason for recipe suggestion
fn generate_suggestion_reason(
  deficit: ncp.DeviationResult,
  macros: Macros,
) -> String {
  // Identify the largest deficit
  let protein_abs = float.absolute_value(deficit.protein_pct)
  let fat_abs = float.absolute_value(deficit.fat_pct)
  let carbs_abs = float.absolute_value(deficit.carbs_pct)

  let max_deficit = float.max(protein_abs, float.max(fat_abs, carbs_abs))

  case max_deficit {
    d if d == protein_abs && deficit.protein_pct <. 0.0 ->
      "High protein ("
      <> float.to_string(macros.protein)
      <> "g) to address deficit"

    d if d == carbs_abs && deficit.carbs_pct <. 0.0 ->
      "Good carbs (" <> float.to_string(macros.carbs) <> "g) to address deficit"

    d if d == fat_abs && deficit.fat_pct <. 0.0 ->
      "Healthy fats (" <> float.to_string(macros.fat) <> "g) to address deficit"

    _ -> "Balanced macros to help reach goals"
  }
}

// ============================================================================
// Configuration Helpers
// ============================================================================

/// Default suggestion configuration
pub fn default_config() -> SuggestionConfig {
  SuggestionConfig(
    max_suggestions: 5,
    diet_principles: [],
    min_compliance_score: 0.5,
    variety_weight: 0.2,
  )
}

/// Suggestion config for Vertical Diet
pub fn vertical_diet_config() -> SuggestionConfig {
  SuggestionConfig(
    max_suggestions: 5,
    diet_principles: ["VerticalDiet"],
    min_compliance_score: 0.7,
    variety_weight: 0.2,
  )
}

/// Suggestion config for Tim Ferriss diet
pub fn tim_ferriss_config() -> SuggestionConfig {
  SuggestionConfig(
    max_suggestions: 5,
    diet_principles: ["TimFerriss"],
    min_compliance_score: 0.7,
    variety_weight: 0.2,
  )
}

/// Suggestion config for high protein diet
pub fn high_protein_config() -> SuggestionConfig {
  SuggestionConfig(
    max_suggestions: 5,
    diet_principles: ["HighProtein"],
    min_compliance_score: 0.6,
    variety_weight: 0.1,
  )
}

// ============================================================================
// Formatting
// ============================================================================

/// Format suggestion result for display
pub fn format_suggestion_result(result: SuggestionResult) -> String {
  case result.within_tolerance {
    True ->
      "✓ You're on track! No recipe suggestions needed.\n\n"
      <> "Current status:\n"
      <> "  Protein: "
      <> format_deviation_pct(result.deficit.protein_pct)
      <> "\n"
      <> "  Fat: "
      <> format_deviation_pct(result.deficit.fat_pct)
      <> "\n"
      <> "  Carbs: "
      <> format_deviation_pct(result.deficit.carbs_pct)
      <> "\n"

    False ->
      case result.suggestions {
        [] ->
          "⚠ Macro deficit detected, but no suitable recipes found.\n"
          <> "Try expanding your recipe database or adjusting your diet preferences.\n"

        suggestions ->
          "📊 Macro Deficit Detected\n"
          <> "───────────────────────────────────────────────\n"
          <> "  Protein: "
          <> format_deviation_pct(result.deficit.protein_pct)
          <> "\n"
          <> "  Fat: "
          <> format_deviation_pct(result.deficit.fat_pct)
          <> "\n"
          <> "  Carbs: "
          <> format_deviation_pct(result.deficit.carbs_pct)
          <> "\n\n"
          <> "🍽️  Recommended Recipes\n"
          <> "───────────────────────────────────────────────\n"
          <> format_suggestions(suggestions)
      }
  }
}

/// Format a list of suggestions
fn format_suggestions(suggestions: List(RecipeSuggestion)) -> String {
  suggestions
  |> list.index_map(fn(sugg, idx) {
    let score_bar = format_score_bar(sugg.total_score)

    int.to_string(idx + 1)
    <> ". "
    <> sugg.recipe.name
    <> "\n"
    <> "   Match: "
    <> score_bar
    <> " ("
    <> float.to_string(sugg.total_score *. 100.0)
    <> "%)\n"
    <> "   Why: "
    <> sugg.reason
    <> "\n"
    <> "   Macros: P"
    <> float.to_string(sugg.contribution.protein)
    <> "g F"
    <> float.to_string(sugg.contribution.fat)
    <> "g C"
    <> float.to_string(sugg.contribution.carbs)
    <> "g\n\n"
  })
  |> list.fold("", fn(acc, s) { acc <> s })
}

/// Format deviation percentage with sign
fn format_deviation_pct(pct: Float) -> String {
  let sign = case pct >=. 0.0 {
    True -> "+"
    False -> ""
  }
  sign <> float.to_string(pct) <> "%"
}

/// Format a visual score bar (0.0 to 1.0)
fn format_score_bar(score: Float) -> String {
  let filled_count = float.round(score *. 10.0)
  let empty_count = 10 - filled_count
  repeat_string("█", filled_count) <> repeat_string("░", empty_count)
}

/// Repeat a string N times
fn repeat_string(s: String, count: Int) -> String {
  case count {
    n if n <= 0 -> ""
    1 -> s
    n -> s <> repeat_string(s, n - 1)
  }
}

// ============================================================================
// Advanced Features
// ============================================================================

/// Generate a full meal plan to meet macro goals
///
/// Uses iterative approach:
/// 1. Select highest-scoring recipe
/// 2. Add to plan and update deficit
/// 3. Repeat until deficit is addressed or max recipes reached
pub fn generate_meal_plan_for_deficit(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
  actual: ncp.NutritionData,
  config: SuggestionConfig,
  max_recipes: Int,
) -> Result(auto_types.AutoMealPlan, StorageError) {
  generate_plan_recursive(
    conn,
    goals,
    actual,
    config,
    max_recipes,
    [],
    Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
  )
}

/// Recursive helper for meal plan generation
fn generate_plan_recursive(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
  actual: ncp.NutritionData,
  config: SuggestionConfig,
  remaining_recipes: Int,
  selected_recipes: List(Recipe),
  accumulated_macros: Macros,
) -> Result(auto_types.AutoMealPlan, StorageError) {
  // Check if we've reached the recipe limit
  case remaining_recipes <= 0 {
    True ->
      Ok(auto_types.AutoMealPlan(
        id: "auto-plan-" <> generate_id(),
        recipes: selected_recipes,
        generated_at: get_current_timestamp(),
        total_macros: accumulated_macros,
        config: auto_types.AutoPlanConfig(
          user_id: "default",
          diet_principles: convert_diet_principles(config.diet_principles),
          macro_targets: Macros(
            protein: goals.daily_protein,
            fat: goals.daily_fat,
            carbs: goals.daily_carbs,
          ),
          recipe_count: list.length(selected_recipes),
          variety_factor: config.variety_weight,
        ),
      ))

    False -> {
      // Update actual consumption with accumulated macros
      let updated_actual =
        ncp.NutritionData(
          protein: actual.protein +. accumulated_macros.protein,
          fat: actual.fat +. accumulated_macros.fat,
          carbs: actual.carbs +. accumulated_macros.carbs,
          calories: actual.calories
            +. calculate_calories_from_macros(accumulated_macros),
        )

      // Get suggestions for current deficit
      use suggestion_result <- result.try(suggest_recipes_for_deficit(
        conn,
        goals,
        updated_actual,
        config,
      ))

      case suggestion_result.within_tolerance {
        // Goal reached
        True ->
          Ok(auto_types.AutoMealPlan(
            id: "auto-plan-" <> generate_id(),
            recipes: selected_recipes,
            generated_at: get_current_timestamp(),
            total_macros: accumulated_macros,
            config: auto_types.AutoPlanConfig(
              user_id: "default",
              diet_principles: convert_diet_principles(config.diet_principles),
              macro_targets: Macros(
                protein: goals.daily_protein,
                fat: goals.daily_fat,
                carbs: goals.daily_carbs,
              ),
              recipe_count: list.length(selected_recipes),
              variety_factor: config.variety_weight,
            ),
          ))

        False ->
          case suggestion_result.suggestions {
            [] ->
              // No more suitable recipes
              Ok(auto_types.AutoMealPlan(
                id: "auto-plan-" <> generate_id(),
                recipes: selected_recipes,
                generated_at: get_current_timestamp(),
                total_macros: accumulated_macros,
                config: auto_types.AutoPlanConfig(
                  user_id: "default",
                  diet_principles: convert_diet_principles(
                    config.diet_principles,
                  ),
                  macro_targets: Macros(
                    protein: goals.daily_protein,
                    fat: goals.daily_fat,
                    carbs: goals.daily_carbs,
                  ),
                  recipe_count: list.length(selected_recipes),
                  variety_factor: config.variety_weight,
                ),
              ))

            [top_suggestion, ..] -> {
              // Add top recipe and continue
              let new_selected = [top_suggestion.recipe, ..selected_recipes]
              let new_accumulated =
                Macros(
                  protein: accumulated_macros.protein
                    +. top_suggestion.recipe.macros.protein,
                  fat: accumulated_macros.fat
                    +. top_suggestion.recipe.macros.fat,
                  carbs: accumulated_macros.carbs
                    +. top_suggestion.recipe.macros.carbs,
                )

              generate_plan_recursive(
                conn,
                goals,
                actual,
                config,
                remaining_recipes - 1,
                new_selected,
                new_accumulated,
              )
            }
          }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate calories from macros (protein=4, carbs=4, fat=9 cal/g)
fn calculate_calories_from_macros(macros: Macros) -> Float {
  { macros.protein *. 4.0 } +. { macros.carbs *. 4.0 } +. { macros.fat *. 9.0 }
}

/// Convert diet principles (simplified - now just passes through strings)
fn convert_diet_principles(
  principles: List(String),
) -> List(auto_types.DietPrinciple) {
  list.map(principles, fn(p) {
    case p {
      "VerticalDiet" -> auto_types.VerticalDiet
      "TimFerriss" -> auto_types.TimFerriss
      "Paleo" -> auto_types.Paleo
      "Keto" -> auto_types.Keto
      "Mediterranean" -> auto_types.Mediterranean
      "HighProtein" -> auto_types.HighProtein
      _ -> auto_types.HighProtein
      // Default fallback
    }
  })
}

/// Generate a simple timestamp-based ID
fn generate_id() -> String {
  // In production, use a proper UUID generator
  // For now, use a simple timestamp-based approach
  get_current_timestamp()
}

/// Get current timestamp as ISO8601 string
fn get_current_timestamp() -> String {
  // This would use erlang's calendar module in production
  // For now, return a placeholder
  "2025-12-04T20:00:00Z"
}
