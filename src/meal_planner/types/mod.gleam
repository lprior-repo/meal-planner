//// Central re-export module for all types.
////
//// This module provides a unified namespace for all type definitions and their
//// associated functions. It imports from all types/* submodules, implicitly
//// re-exporting their public items for backward compatibility while allowing
//// individual module organization.
////
//// ## Organization
////
//// The module re-exports types and functions from:
//// - macros: Macronutrient calculations and operations
//// - micronutrients: Vitamin and mineral tracking
//// - user_profile: User fitness goals and nutrition targets
//// - recipe: Recipe definitions for meal planning
//// - meal_plan: Complete meal plan structures
//// - food_log: Food consumption tracking
//// - custom_food: User-defined foods
//// - food_source: Type-safe food source tracking
//// - measurements: Validated measurement types
//// - pagination: Cursor-based pagination
//// - grocery_item: Shopping list management
//// - search: Food search functionality
////
//// ## Example
////
//// ```gleam
//// import meal_planner/types.{type Macros, type Micronutrients, type UserProfile}
//// import meal_planner/types.{calories, add, zero}
//// ```

import meal_planner/types/macros.{
  type MacroComparison, type Macros, OnTarget, Over, Under, abs, add,
  approximately_equal, average, calories, carb_calories, carb_ratio, clamp,
  compare_to_target, decoder as macros_decoder, fat_calories, fat_ratio,
  has_negative_values, is_balanced, is_empty, macro_comparison_decoder,
  macro_comparison_to_json, macro_comparison_to_string, max, min, negate,
  protein_calories, protein_ratio, scale, subtract, sum,
  to_json as macros_to_json, to_string as macros_to_string,
  to_string_with_calories as macros_to_string_with_calories, zero,
}

import meal_planner/types/micronutrients.{
  type MicronutrientGoals, type Micronutrients, add as micronutrients_add,
  calcium, cholesterol, decoder as micronutrients_decoder, fda_rda_defaults,
  fiber, folate, iron, magnesium, new, new_unchecked, niacin, phosphorus,
  potassium, riboflavin, scale as micronutrients_scale, sodium, sugar,
  sum as micronutrients_sum, thiamin, to_json as micronutrients_to_json,
  vitamin_a, vitamin_b12, vitamin_b6, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
  zero as micronutrients_zero, zinc,
}

import meal_planner/types/user_profile.{
  type ActivityLevel, type Goal, type UserProfile, Active, Gain, Lose, Maintain,
  Moderate, Sedentary, daily_calorie_target, daily_carb_target, daily_fat_target,
  daily_macro_targets, daily_protein_target, decoder as user_profile_decoder,
  new_user_profile, to_display_string, to_json as user_profile_to_json,
  user_profile_activity_level, user_profile_bodyweight, user_profile_goal,
  user_profile_id, user_profile_meals_per_day, user_profile_micronutrient_goals,
}

import meal_planner/types/recipe.{
  type MealPlanRecipe, is_quick_prep, meal_plan_recipe_decoder,
  meal_plan_recipe_to_json, new_meal_plan_recipe, recipe_cook_time, recipe_id,
  recipe_image, recipe_macros_per_serving, recipe_name, recipe_prep_time,
  recipe_servings, recipe_total_macros, recipe_total_time,
  to_string as recipe_to_string,
}

import meal_planner/types/meal_plan.{
  type DailyMacros, type DayMeals, type MealPlan, daily_macros_actual,
  daily_macros_calories, daily_macros_carbs_status, daily_macros_decoder,
  daily_macros_fat_status, daily_macros_protein_status, daily_macros_to_json,
  daily_macros_to_string, day_meals_breakfast, day_meals_day, day_meals_decoder,
  day_meals_dinner, day_meals_lunch, day_meals_macros, day_meals_to_json,
  meal_plan_avg_daily_macros, meal_plan_days, meal_plan_decoder,
  meal_plan_target_macros, meal_plan_to_json, meal_plan_total_macros,
  meal_plan_week_of, new_daily_macros, new_day_meals, new_meal_plan,
}

import meal_planner/types/food_log.{
  type DailyLog, type FoodLogEntry, type MealType, Breakfast, Dinner, Lunch,
  Snack, daily_log_decoder, daily_log_to_json, food_log_entry_decoder,
  food_log_entry_to_json,
}

import meal_planner/types/custom_food.{
  type CustomFood, decoder as custom_food_decoder,
  to_json as custom_food_to_json,
}

import meal_planner/types/food_source.{
  type FoodSource, CustomFoodSource, RecipeSource, UsdaFoodSource,
}

import meal_planner/types/measurements.{
  type Calories, type Grams, type Micrograms, type Milligrams, type Percentage,
  type PortionMultiplier, calories as calories_constructor, calories_to_string,
  calories_value, grams, grams_to_string, grams_value, micrograms,
  micrograms_to_string, micrograms_value, milligrams, milligrams_to_string,
  milligrams_value, percentage, percentage_to_string, percentage_value,
  portion_multiplier, portion_multiplier_to_string, portion_multiplier_value,
}

import meal_planner/types/pagination.{
  type Cursor, type PageInfo, type PaginatedResponse, type PaginationParams,
  cursor_value, new_cursor, new_page_info, new_pagination_params,
  page_info_has_next, page_info_has_previous, page_info_next_cursor,
  page_info_previous_cursor, page_info_total_items, pagination_cursor,
  pagination_limit,
}

import meal_planner/types/grocery_item.{
  type GroceryItem, type GroceryList, grocery_item_category,
  grocery_item_decoder, grocery_item_name, grocery_item_quantity,
  grocery_item_sources, grocery_item_to_json, grocery_item_to_string,
  grocery_item_unit, grocery_list_all_items, grocery_list_by_category,
  grocery_list_categories, grocery_list_count, grocery_list_decoder,
  grocery_list_items_for_category, grocery_list_to_json, grocery_list_to_string,
  merge_grocery_lists, new_grocery_item, new_grocery_list,
}

import meal_planner/types/search.{
  type FoodSearchError, type FoodSearchResponse, type FoodSearchResult,
  type SearchFilters, food_search_response_decoder, food_search_response_to_json,
  food_search_result_decoder, food_search_result_to_json,
}
