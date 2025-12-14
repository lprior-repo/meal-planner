import gleam/option.{type Option}

/// Meal type categorization (breakfast, lunch, dinner, etc)
/// Used to organize meal plans by time of day
pub type MealType {
  MealType(
    /// Tandoor meal type ID
    id: Int,
    /// Meal type name (e.g., "Breakfast", "Lunch", "Dinner")
    name: String,
    /// Display order for sorting meal types
    order: Int,
    /// Optional time of day for this meal type (HH:MM format)
    time: Option(String),
    /// Optional color hex code for UI display (e.g., "#FF5733")
    color: Option(String),
    /// Whether this is the default meal type for the user
    default: Bool,
    /// User ID who created this meal type
    created_by: Int,
  )
}
