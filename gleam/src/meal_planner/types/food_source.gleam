/// Food source tracking
///
/// Type-safe food source identification preventing mismatched source_type and source_id.
import meal_planner/id.{
  type CustomFoodId, type FdcId, type RecipeId, type UserId,
}

/// Type-safe food source tracking for food logs
/// Prevents mismatched source_type and source_id through compile-time checking
pub type FoodSource {
  /// Food from recipe database
  RecipeSource(recipe_id: RecipeId)
  /// Food from custom_foods table (includes user_id for authorization)
  CustomFoodSource(custom_food_id: CustomFoodId, user_id: UserId)
  /// Food from USDA database (foods/food_nutrients tables)
  UsdaFoodSource(fdc_id: FdcId)
}
