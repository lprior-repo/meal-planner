import gleam/option.{type Option}
import meal_planner/tandoor/types/mealplan/meal_type.{type MealType}
import meal_planner/tandoor/types/mealplan/user.{type User}
import meal_planner/tandoor/types/recipe/recipe_overview.{type RecipeOverview}

/// Complete meal plan entry with all metadata
/// Represents a planned meal for a specific date/time
pub type MealPlan {
  MealPlan(
    /// Tandoor meal plan ID
    id: Int,
    /// Meal plan title (max 64 characters)
    title: String,
    /// Optional recipe reference (can be null if just a note/reminder)
    recipe: Option(RecipeOverview),
    /// Number of servings for this meal
    servings: Float,
    /// Plain text note about the meal
    note: String,
    /// Markdown-formatted note (read-only, computed from note)
    note_markdown: String,
    /// Start date/time for the meal (ISO 8601 format)
    from_date: String,
    /// End date/time for the meal (ISO 8601 format)
    to_date: String,
    /// Meal type categorization (breakfast, lunch, dinner, etc)
    meal_type: MealType,
    /// User ID who created this meal plan
    created_by: Int,
    /// Users this meal plan is shared with
    shared: Option(List(User)),
    /// Recipe name (read-only, denormalized for performance)
    recipe_name: String,
    /// Meal type name (read-only, denormalized for performance)
    meal_type_name: String,
    /// Whether this meal plan is on the shopping list
    shopping: Bool,
  )
}

pub type MealPlanListResponse {
  MealPlanListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(MealPlan),
  )
}
