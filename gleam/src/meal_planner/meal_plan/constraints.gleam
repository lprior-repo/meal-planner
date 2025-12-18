/// Constraint types for weekly meal planning
///
/// This module defines the complete type system for constraint input that feeds
/// the meal planning generation engine. Constraints allow users to specify:
/// - Travel dates where they need quick or no meals
/// - Locked meals (specific recipes on specific days)
/// - Macro adjustments (high protein, low carb, balanced)
/// - Dietary preferences (avoid/prefer certain foods)
/// - Meal skips (no breakfast on certain days)
import birl.{type Time}
import gleam/option.{type Option}

/// Complete constraint set for a weekly meal plan
///
/// Represents all constraints for generating a single week's meal plan.
/// All constraints are optional except week_of which identifies the target week.
///
/// # Example
/// ```gleam
/// Constraint(
///   week_of: week_start_date,
///   travel_dates: [monday, tuesday],
///   locked_meals: [LockedMeal(Friday, Dinner, RecipeId(42))],
///   macro_adjustment: HighProtein,
///   preferences: [Avoid("seafood"), Prefer("vegetarian")],
///   meal_skips: [MealSkip(Saturday, Breakfast)],
/// )
/// ```
pub type Constraint {
  Constraint(
    /// Start date of the week (Monday) for this meal plan
    week_of: Time,
    /// Dates when traveling (need quick/no meals)
    travel_dates: List(Time),
    /// Specific meals locked to specific recipes
    locked_meals: List(LockedMeal),
    /// Macro nutrient adjustment preference
    macro_adjustment: MacroAdjustment,
    /// General dietary preferences
    preferences: List(Preference),
    /// Meals to skip (no meal planned)
    meal_skips: List(MealSkip),
  )
}

/// A meal locked to a specific recipe on a specific day
///
/// When a user wants a particular recipe on a particular day/meal type.
///
/// # Example
/// ```gleam
/// LockedMeal(
///   day: Friday,
///   meal_type: Dinner,
///   recipe_id: 42,
/// )
/// ```
pub type LockedMeal {
  LockedMeal(day: DayOfWeek, meal_type: MealType, recipe_id: Int)
}

/// A meal to skip (no meal planned for this day/meal type)
///
/// When a user doesn't want a meal planned for a specific day/meal type.
///
/// # Example
/// ```gleam
/// MealSkip(
///   day: Saturday,
///   meal_type: Breakfast,
/// )
/// ```
pub type MealSkip {
  MealSkip(day: DayOfWeek, meal_type: MealType)
}

/// Meal type categorization
///
/// Maps to Tandoor meal types but simplified for constraint input.
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// Day of week enumeration
///
/// Represents days of the week for constraint specifications.
pub type DayOfWeek {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

/// Macro nutrient adjustment presets
///
/// Predefined macro balance strategies for the week.
/// Each preset adjusts target macros accordingly:
/// - Balanced: Standard 40/30/30 protein/carb/fat split
/// - HighProtein: 45/30/25 split for muscle building
/// - LowCarb: 35/20/45 split for fat loss
pub type MacroAdjustment {
  Balanced
  HighProtein
  LowCarb
}

/// Dietary preferences for meal generation
///
/// Flexible preference system supporting:
/// - Avoid: Hard constraint (exclude these foods)
/// - Prefer: Soft constraint (prioritize these foods)
/// - Restrict: Dietary restriction (allergen/intolerance)
///
/// # Examples
/// ```gleam
/// Avoid("seafood")       // Don't plan any seafood meals
/// Prefer("vegetarian")   // Prioritize vegetarian options
/// Restrict("dairy")      // Dietary restriction (lactose intolerance)
/// ```
pub type Preference {
  Avoid(String)
  Prefer(String)
  Restrict(String)
}

/// Convert MealType to string for JSON serialization
///
/// Maps meal type variants to lowercase string representation.
pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

/// Convert string to MealType for JSON deserialization
///
/// Case-insensitive parsing. Defaults to Breakfast for unknown values.
pub fn meal_type_from_string(s: String) -> MealType {
  case s {
    "breakfast" -> Breakfast
    "Breakfast" -> Breakfast
    "lunch" -> Lunch
    "Lunch" -> Lunch
    "dinner" -> Dinner
    "Dinner" -> Dinner
    "snack" -> Snack
    "Snack" -> Snack
    _ -> Breakfast
  }
}

/// Convert DayOfWeek to string for JSON serialization
pub fn day_of_week_to_string(day: DayOfWeek) -> String {
  case day {
    Monday -> "Monday"
    Tuesday -> "Tuesday"
    Wednesday -> "Wednesday"
    Thursday -> "Thursday"
    Friday -> "Friday"
    Saturday -> "Saturday"
    Sunday -> "Sunday"
  }
}

/// Convert string to DayOfWeek for JSON deserialization
///
/// Case-sensitive parsing. Defaults to Monday for unknown values.
pub fn day_of_week_from_string(s: String) -> DayOfWeek {
  case s {
    "Monday" -> Monday
    "Tuesday" -> Tuesday
    "Wednesday" -> Wednesday
    "Thursday" -> Thursday
    "Friday" -> Friday
    "Saturday" -> Saturday
    "Sunday" -> Sunday
    _ -> Monday
  }
}

/// Convert MacroAdjustment to string for JSON serialization
pub fn macro_adjustment_to_string(adjustment: MacroAdjustment) -> String {
  case adjustment {
    Balanced -> "balanced"
    HighProtein -> "high_protein"
    LowCarb -> "low_carb"
  }
}

/// Convert string to MacroAdjustment for JSON deserialization
///
/// Case-insensitive parsing. Defaults to Balanced for unknown values.
pub fn macro_adjustment_from_string(s: String) -> MacroAdjustment {
  case s {
    "balanced" -> Balanced
    "Balanced" -> Balanced
    "high_protein" -> HighProtein
    "HighProtein" -> HighProtein
    "high-protein" -> HighProtein
    "low_carb" -> LowCarb
    "LowCarb" -> LowCarb
    "low-carb" -> LowCarb
    _ -> Balanced
  }
}

/// Convert Preference to type/value tuple for JSON serialization
pub fn preference_to_tuple(pref: Preference) -> #(String, String) {
  case pref {
    Avoid(value) -> #("avoid", value)
    Prefer(value) -> #("prefer", value)
    Restrict(value) -> #("restrict", value)
  }
}

/// Convert type/value tuple to Preference for JSON deserialization
///
/// Defaults to Prefer for unknown types.
pub fn preference_from_tuple(tuple: #(String, String)) -> Preference {
  let #(type_str, value) = tuple
  case type_str {
    "avoid" -> Avoid(value)
    "prefer" -> Prefer(value)
    "restrict" -> Restrict(value)
    _ -> Prefer(value)
  }
}
