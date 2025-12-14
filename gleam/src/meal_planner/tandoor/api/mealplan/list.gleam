/// MealPlan List API
///
/// This module provides functions to list meal plans from the Tandoor API.
import gleam/option.{type Option}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlanListResponse}

/// List meal plans from Tandoor API with optional date filtering
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
pub fn list_meal_plans(
  config: ClientConfig,
  from_date from_date: Option(String),
  to_date to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError) {
  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.get_meal_plan(config, from_date, to_date)
}
