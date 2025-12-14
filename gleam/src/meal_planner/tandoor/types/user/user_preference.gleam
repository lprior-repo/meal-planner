/// UserPreference type for Tandoor SDK
///
/// This module defines user preference settings for customizing the Tandoor
/// experience. Preferences control UI theme, units, meal planning, shopping, etc.
import gleam/option.{type Option}
import meal_planner/tandoor/types/user/user.{type User}
import meal_planner/tandoor/types/user/user_file_view.{type UserFileView}

/// User preferences and settings
///
/// Controls various aspects of the Tandoor UI and behavior for a specific user.
/// Most fields have defaults and can be updated by the user.
pub type UserPreference {
  UserPreference(
    /// The user these preferences belong to (readonly)
    user: User,
    /// Optional profile image (nullable)
    image: Option(UserFileView),
    /// UI theme (e.g., "BOOTSTRAP", "FLATLY")
    theme: String,
    /// Navigation bar background color (hex, max 8 chars including #)
    nav_bg_color: String,
    /// Navigation bar text color ("LIGHT" or "DARK")
    nav_text_color: String,
    /// Whether to show logo in navigation bar
    nav_show_logo: Bool,
    /// Default unit for ingredients (max 32 chars, e.g., "g", "ml")
    default_unit: String,
    /// Default page to show on login (e.g., "SEARCH", "PLAN")
    default_page: String,
    /// Whether to use fractions for measurements (e.g., 1/2 cup)
    use_fractions: Bool,
    /// Whether to use kilojoules instead of calories
    use_kj: Bool,
    /// Users to share meal plans with (nullable)
    plan_share: Option(List(User)),
    /// Whether navigation bar should stick to top when scrolling
    nav_sticky: Bool,
    /// Number of decimal places for ingredient amounts
    ingredient_decimals: Int,
    /// Whether to enable comments
    comments: Bool,
    /// Auto-sync interval for shopping list (seconds)
    shopping_auto_sync: Int,
    /// Whether to automatically add meal plan items to shopping list
    mealplan_autoadd_shopping: Bool,
    /// Default food inheritance behavior (readonly, e.g., "ENABLED", "DISABLED")
    food_inherit_default: String,
    /// Default delay for recipe steps (minutes, -10000 to 10000 exclusive)
    default_delay: Float,
    /// Whether to auto-include related recipes in meal plan
    mealplan_autoinclude_related: Bool,
    /// Whether to auto-exclude items marked as "on hand" from meal plan
    mealplan_autoexclude_onhand: Bool,
    /// Users to share shopping lists with (nullable)
    shopping_share: Option(List(User)),
    /// How many days of recent shopping history to show
    shopping_recent_days: Int,
    /// CSV delimiter character (max 2 chars, e.g., ",", ";")
    csv_delim: String,
    /// CSV prefix string (max 10 chars)
    csv_prefix: String,
    /// Whether to filter shopping list items to selected supermarket
    filter_to_supermarket: Bool,
    /// Whether to add "on hand" items to shopping list
    shopping_add_onhand: Bool,
    /// Whether UI should be optimized for left-handed use
    left_handed: Bool,
    /// Whether to show ingredients in each recipe step
    show_step_ingredients: Bool,
    /// Whether any foods have children (readonly, for optimization)
    food_children_exist: Bool,
  )
}
