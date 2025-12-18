import gleam/option.{type Option}

/// Simplified meal plan entry for list operations
/// Used when fetching multiple meal plans where full details aren't needed
pub type MealPlanEntry {
  MealPlanEntry(
    /// Tandoor meal plan ID
    id: Int,
    /// Meal plan title
    title: String,
    /// Recipe ID if linked to a recipe
    recipe_id: Option(Int),
    /// Recipe name for display
    recipe_name: String,
    /// Number of servings
    servings: Float,
    /// Start date/time (ISO 8601)
    from_date: String,
    /// End date/time (ISO 8601)
    to_date: String,
    /// Meal type ID
    meal_type_id: Int,
    /// Meal type name for display
    meal_type_name: String,
    /// Whether on shopping list
    shopping: Bool,
  )
}
