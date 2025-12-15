/// AI-powered meal prep planning using Claude API
///
/// This module generates optimized, step-by-step meal prep instructions
/// considering recipes, cookware, and minimal work principles.
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{type RecipeDetail}

// ============================================================================
// Types
// ============================================================================

/// A meal prep plan with optimized instructions
pub type MealPrepPlan {
  MealPrepPlan(
    meal_count: Int,
    total_prep_time_min: Int,
    cookware_needed: List(String),
    instructions: List(PrepStep),
    notes: String,
  )
}

/// A single step in the meal prep process
pub type PrepStep {
  PrepStep(
    step_number: Int,
    title: String,
    description: String,
    recipes_involved: List(String),
    time_estimate_min: Int,
    parallel_possible: Bool,
  )
}

// ============================================================================
// Claude API Integration
// ============================================================================

/// Generate meal prep instructions using Claude API
pub fn generate_meal_prep_plan(
  recipes: List(RecipeDetail),
  cookware: List(String),
) -> Result(MealPrepPlan, String) {
  case list.is_empty(recipes) {
    True -> Error("No recipes provided for meal prep planning")
    False -> {
      // Build prompt for Claude
      let prompt = build_meal_prep_prompt(recipes, cookware)

      // For now, return a placeholder
      // In production, this would call Claude API
      Ok(placeholder_meal_prep_plan(recipes))
    }
  }
}

// ============================================================================
// Prompt Construction
// ============================================================================

fn build_meal_prep_prompt(
  recipes: List(RecipeDetail),
  cookware: List(String),
) -> String {
  let recipe_list =
    recipes
    |> list.map(fn(recipe) { "- " <> recipe.name })
    |> string.join("\n")

  let cookware_list =
    cookware
    |> string.join(", ")

  "Create an optimized meal prep plan for the following recipes:

Recipes to prepare:
" <> recipe_list <> "

Available cookware:
" <> cookware_list <> "

Please provide:
1. Step-by-step instructions that minimize total cook time
2. Identify steps that can be done in parallel
3. Suggest efficient use of cookware
4. Group similar tasks together
5. Estimate time for each step

Format as a structured JSON with the following schema:
{
  \"meal_count\": <number>,
  \"total_prep_time_min\": <number>,
  \"cookware_needed\": [<list of strings>],
  \"instructions\": [
    {
      \"step_number\": <number>,
      \"title\": \"<string>\",
      \"description\": \"<string>\",
      \"recipes_involved\": [<list of recipe names>],
      \"time_estimate_min\": <number>,
      \"parallel_possible\": <boolean>
    }
  ],
  \"notes\": \"<string>\"
}"
}

// ============================================================================
// Response Parsing
// ============================================================================

/// Parse Claude's response into a MealPrepPlan
pub fn parse_meal_prep_response(
  response: String,
) -> Result(MealPrepPlan, String) {
  case json.decode(response, meal_prep_decoder()) {
    Ok(plan) -> Ok(plan)
    Error(_) -> Error("Failed to parse meal prep plan from Claude response")
  }
}

fn meal_prep_decoder() {
  // Placeholder decoder - would need full JSON schema implementation
  // This is a simplified version
  fn(json_value) { Error("JSON decoding not yet implemented") }
}

// ============================================================================
// Formatting
// ============================================================================

/// Format a meal prep plan as readable text
pub fn format_meal_prep_plan(plan: MealPrepPlan) -> String {
  let header =
    "🍳 MEAL PREP PLAN\n"
    <> "================\n"
    <> "Meals: "
    <> int_to_string(plan.meal_count)
    <> " | Total Time: "
    <> int_to_string(plan.total_prep_time_min)
    <> " minutes\n\n"

  let cookware_items =
    plan.cookware_needed
    |> list.map(fn(item) { "  • " <> item })
    |> string.join("\n")

  let cookware_section = "🔧 Cookware needed:\n" <> cookware_items <> "\n\n"

  let instructions_text =
    plan.instructions
    |> list.map(format_prep_step)
    |> string.join("\n")

  let instructions_section = "📝 Instructions:\n" <> instructions_text <> "\n"

  let notes_section = case plan.notes {
    "" -> ""
    notes -> "\n💡 Notes: " <> notes
  }

  header <> cookware_section <> instructions_section <> notes_section
}

fn format_prep_step(step: PrepStep) -> String {
  let parallel_note = case step.parallel_possible {
    True -> " (can be done in parallel)"
    False -> ""
  }

  let recipes_str = case step.recipes_involved {
    [] -> ""
    recipes -> " [" <> string.join(recipes, ", ") <> "]"
  }

  int_to_string(step.step_number)
  <> ". "
  <> step.title
  <> " ("
  <> int_to_string(step.time_estimate_min)
  <> " min)"
  <> recipes_str
  <> parallel_note
  <> "\n   "
  <> step.description
}

// ============================================================================
// Placeholder Implementation
// ============================================================================

fn placeholder_meal_prep_plan(recipes: List(RecipeDetail)) -> MealPrepPlan {
  let recipe_names = recipes |> list.map(fn(r) { r.name })

  MealPrepPlan(
    meal_count: list.length(recipes),
    total_prep_time_min: 60,
    cookware_needed: ["Large pot", "Cutting board", "Mixing bowl"],
    instructions: [
      PrepStep(
        step_number: 1,
        title: "Prep ingredients",
        description: "Wash, peel, and chop all vegetables",
        recipes_involved: recipe_names,
        time_estimate_min: 15,
        parallel_possible: False,
      ),
      PrepStep(
        step_number: 2,
        title: "Start cooking",
        description: "Begin cooking the main components",
        recipes_involved: recipe_names,
        time_estimate_min: 30,
        parallel_possible: True,
      ),
      PrepStep(
        step_number: 3,
        title: "Finish and portion",
        description: "Complete cooking and divide into portions",
        recipes_involved: recipe_names,
        time_estimate_min: 15,
        parallel_possible: False,
      ),
    ],
    notes: "This is a placeholder plan. Full Claude integration coming soon.",
  )
}

// ============================================================================
// Helpers
// ============================================================================

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}
