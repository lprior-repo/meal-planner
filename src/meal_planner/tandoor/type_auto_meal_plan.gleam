/// Tandoor AutoMealPlan type definition
///
/// This module defines the AutoMealPlan type for autonomous meal plan generation requests.
/// AutoMealPlan specifies parameters for the Tandoor API's auto-generate endpoint.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}

/// Request parameters for automatic meal plan generation
///
/// AutoMealPlan encapsulates the input parameters for Tandoor's autonomous
/// meal plan generation algorithm. It specifies what meals should be generated,
/// for whom, and under what constraints.
///
/// Fields:
/// - start_date: Start date for the meal plan (ISO 8601 datetime, required)
/// - end_date: End date for the meal plan (ISO 8601 datetime, required)
/// - meal_type_id: Type of meals to generate (references MealType.id)
/// - keyword_ids: List of keyword IDs to filter recipes (e.g., cuisines, diets)
/// - servings: Number of servings per meal (Float, required)
/// - shared: Optional list of user IDs with whom to share the plan
/// - addshopping: Whether to automatically add ingredients to shopping list
pub type AutoMealPlan {
  AutoMealPlan(
    start_date: String,
    end_date: String,
    meal_type_id: Int,
    keyword_ids: List(Int),
    servings: Float,
    shared: Option(List(Int)),
    addshopping: Bool,
  )
}
