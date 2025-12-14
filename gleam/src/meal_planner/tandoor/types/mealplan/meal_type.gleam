import gleam/option.{type Option, None}

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

pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type.name {
    "Breakfast" -> "BREAKFAST"
    "Lunch" -> "LUNCH"
    "Dinner" -> "DINNER"
    "Snack" -> "SNACK"
    _ -> "OTHER"
  }
}

pub fn meal_type_from_string(s: String) -> MealType {
  case s {
    "BREAKFAST" ->
      MealType(
        id: 1,
        name: "Breakfast",
        order: 1,
        time: None,
        color: None,
        default: False,
        created_by: 0,
      )
    "LUNCH" ->
      MealType(
        id: 2,
        name: "Lunch",
        order: 2,
        time: None,
        color: None,
        default: False,
        created_by: 0,
      )
    "DINNER" ->
      MealType(
        id: 3,
        name: "Dinner",
        order: 3,
        time: None,
        color: None,
        default: False,
        created_by: 0,
      )
    "SNACK" ->
      MealType(
        id: 4,
        name: "Snack",
        order: 4,
        time: None,
        color: None,
        default: False,
        created_by: 0,
      )
    _ ->
      MealType(
        id: 5,
        name: "Other",
        order: 5,
        time: None,
        color: None,
        default: False,
        created_by: 0,
      )
  }
}
