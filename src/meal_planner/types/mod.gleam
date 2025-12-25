/// Central type definitions module
///
/// This module serves as the entry point for all type definitions.
/// Specific type modules are split for better organization and reduced coupling:
///
/// - **macros.gleam**: Macros type and calorie/ratio calculations
/// - **micronutrients.gleam**: Micronutrients type (vitamins, minerals)
/// - **food.gleam**: Food, FoodEntry, FoodSource types
/// - **custom_food.gleam**: CustomFood type for user-created foods
/// - **recipe.gleam**: Recipe and Ingredient types
/// - **meal_plan.gleam**: MealPlan and MealSlot types
/// - **nutrition.gleam**: NutritionData and NutritionGoals types
/// - **measurements.gleam**: Measurement and Unit types
/// - **food_log.gleam**: FoodLog type
/// - **food_source.gleam**: FoodSourceType enumeration
/// - **grocery_item.gleam**: GroceryItem type
/// - **pagination.gleam**: Pagination type for API responses
/// - **search.gleam**: Search filter and response types
/// - **user_profile.gleam**: UserProfile type
/// - **json.gleam**: JSON encoding/decoding utilities
///
/// Import specific type modules directly in your code:
/// ```gleam
/// import meal_planner/types/macros.{type Macros}
/// import meal_planner/types/food.{type FoodLogEntry}
/// ```

