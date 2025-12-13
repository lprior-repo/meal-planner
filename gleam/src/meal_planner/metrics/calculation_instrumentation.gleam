/// Instrumented wrappers for business logic and calculations with metrics
///
/// These functions wrap macro calculations, meal generation, and other
/// business logic to automatically collect performance metrics.
import gleam/result
import meal_planner/meal_plan.{type DailyPlan, type Meal, type WeeklyMealPlan}
import meal_planner/meal_selection
import meal_planner/metrics/calculations.{
  end_calculation_timing, record_calculation, start_calculation_timing,
  time_pure_calculation,
}
import meal_planner/metrics/mod.{type MetricsRegistry}
import meal_planner/types.{type Macros, type Recipe, type UserProfile}

// ============================================================================
// Macro Calculation Instrumentation
// ============================================================================

/// Calculate macros for a meal with performance monitoring
pub fn meal_macros(
  registry: MetricsRegistry,
  meal: Meal,
) -> #(Macros, MetricsRegistry) {
  time_pure_calculation(registry, "meal_macros", fn() {
    meal_plan.meal_macros(meal)
  })
}

/// Calculate daily plan macros with performance monitoring
pub fn daily_plan_macros(
  registry: MetricsRegistry,
  plan: DailyPlan,
) -> #(Macros, MetricsRegistry) {
  time_pure_calculation(registry, "daily_plan_macros", fn() {
    meal_plan.daily_plan_macros(plan)
  })
}

/// Calculate weekly plan macros with performance monitoring
pub fn weekly_plan_macros(
  registry: MetricsRegistry,
  plan: WeeklyMealPlan,
) -> #(Macros, MetricsRegistry) {
  time_pure_calculation(registry, "weekly_plan_macros", fn() {
    meal_plan.weekly_plan_macros(plan)
  })
}

// ============================================================================
// Meal Selection Instrumentation
// ============================================================================

/// Get meal category with performance monitoring
pub fn get_meal_category(
  registry: MetricsRegistry,
  recipe: Recipe,
) -> #(meal_selection.MealCategory, MetricsRegistry) {
  time_pure_calculation(registry, "get_meal_category", fn() {
    meal_selection.get_meal_category(recipe)
  })
}

/// Analyze distribution with performance monitoring
pub fn analyze_distribution(
  registry: MetricsRegistry,
  selected_recipes: List(Recipe),
) -> #(meal_selection.MealSelectionResult, MetricsRegistry) {
  time_pure_calculation(registry, "analyze_distribution", fn() {
    meal_selection.analyze_distribution(selected_recipes)
  })
}

// ============================================================================
// Generic Calculation Timing
// ============================================================================

/// Time any pure calculation (no side effects)
pub fn time_calculation_pure(
  registry: MetricsRegistry,
  operation_name: String,
  operation: fn() -> a,
) -> #(a, MetricsRegistry) {
  time_pure_calculation(registry, operation_name, operation)
}

/// Time a calculation that may fail
pub fn time_calculation_result(
  registry: MetricsRegistry,
  operation_name: String,
  operation: fn() -> Result(a, e),
) -> #(Result(a, e), MetricsRegistry) {
  let context = start_calculation_timing(operation_name)
  let result = operation()
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_calculation_timing(context, success)
  let updated_registry = record_calculation(registry, metric)
  #(result, updated_registry)
}
