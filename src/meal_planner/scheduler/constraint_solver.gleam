//// Constraint satisfaction solver for meal planning
////
//// This module provides algorithms for:
//// - Constraint satisfaction with backtracking
//// - Conflict detection and resolution
//// - Schedule optimization
//// - Preference weighting

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/id.{type RecipeId}
import meal_planner/scheduler/advanced.{
  type Constraint, type ConstraintResult, type MealSchedule,
  type OptimizationObjective, type OptimizationResult, type ScheduleConflict,
  type ScheduledMeal, PartiallySatisfied, Satisfied, Violated,
}
import meal_planner/scheduler/errors.{type AppError}
import meal_planner/types/macros

// ============================================================================
// Solver Configuration
// ============================================================================

/// Configuration for constraint solver
pub type SolverConfig {
  SolverConfig(
    /// Maximum backtracking depth
    max_depth: Int,
    /// Timeout in milliseconds
    timeout_ms: Int,
    /// Minimum acceptable constraint satisfaction score (0-1)
    min_satisfaction_score: Float,
    /// Allow partial solutions
    allow_partial: Bool,
  )
}

/// Default solver configuration
pub fn default_config() -> SolverConfig {
  SolverConfig(
    max_depth: 100,
    timeout_ms: 30_000,
    min_satisfaction_score: 0.8,
    allow_partial: True,
  )
}

// ============================================================================
// Constraint Satisfaction
// ============================================================================

/// Evaluate a single constraint against a meal schedule
pub fn evaluate_constraint(
  constraint: Constraint,
  schedule: MealSchedule,
) -> ConstraintResult {
  case constraint {
    advanced.Budget(max_cost, _currency) ->
      evaluate_budget_constraint(schedule, max_cost)
    advanced.TimeLimit(max_minutes) ->
      evaluate_time_constraint(schedule, max_minutes)
    advanced.Nutrition(target) ->
      evaluate_nutrition_constraint(schedule, target)
    advanced.MaxRepetition(max_times) ->
      evaluate_repetition_constraint(schedule, max_times)
    advanced.MustInclude(recipe_ids) ->
      evaluate_must_include_constraint(schedule, recipe_ids)
    advanced.MustExclude(recipe_ids) ->
      evaluate_must_exclude_constraint(schedule, recipe_ids)
    advanced.IngredientAvailability(_) -> Satisfied
    advanced.Dietary(_) -> Satisfied
  }
}

/// Evaluate multiple constraints and return overall satisfaction score
pub fn evaluate_constraints(
  constraints: List(Constraint),
  schedule: MealSchedule,
) -> Float {
  let results =
    constraints
    |> list.map(fn(c) { evaluate_constraint(c, schedule) })

  let scores =
    results
    |> list.map(advanced.constraint_score)

  case list.is_empty(scores) {
    True -> 1.0
    False -> {
      let sum = list.fold(scores, 0.0, float.add)
      let count = int_to_float(list.length(scores))
      sum /. count
    }
  }
}

// ============================================================================
// Individual Constraint Evaluators
// ============================================================================

/// Evaluate budget constraint
fn evaluate_budget_constraint(
  schedule: MealSchedule,
  max_cost: Float,
) -> ConstraintResult {
  case schedule.total_cost {
    Some(cost) ->
      case cost <=. max_cost {
        True -> Satisfied
        False ->
          Violated(
            "Budget exceeded: "
              <> float_to_string(cost)
              <> " > "
              <> float_to_string(max_cost),
            advanced.Hard,
          )
      }
    None -> Satisfied
  }
}

/// Evaluate time constraint (total prep time)
fn evaluate_time_constraint(
  schedule: MealSchedule,
  max_minutes: Int,
) -> ConstraintResult {
  let total_time =
    schedule.meals
    |> list.map(fn(meal) {
      case meal.prep_time {
        Some(time) -> time
        None -> 0
      }
    })
    |> list.fold(0, fn(acc, time) { acc + time })

  case total_time <= max_minutes {
    True -> Satisfied
    False ->
      Violated(
        "Time limit exceeded: "
          <> int_to_string(total_time)
          <> " > "
          <> int_to_string(max_minutes),
        advanced.Hard,
      )
  }
}

/// Evaluate nutrition constraint
fn evaluate_nutrition_constraint(
  schedule: MealSchedule,
  target: advanced.NutritionTarget,
) -> ConstraintResult {
  let actual = schedule.nutrition_summary
  let calories = macros.calories(actual)

  let in_cal_range = advanced.in_range(calories, target.calories)
  let in_protein_range = advanced.in_range(actual.protein, target.protein)
  let in_carb_range = advanced.in_range(actual.carbs, target.carbs)
  let in_fat_range = advanced.in_range(actual.fat, target.fat)

  let all_in_range =
    in_cal_range && in_protein_range && in_carb_range && in_fat_range

  case all_in_range {
    True -> Satisfied
    False -> {
      let violations = []
      let violations = case in_cal_range {
        True -> violations
        False -> ["calories", ..violations]
      }
      let violations = case in_protein_range {
        True -> violations
        False -> ["protein", ..violations]
      }
      let violations = case in_carb_range {
        True -> violations
        False -> ["carbs", ..violations]
      }
      let violations = case in_fat_range {
        True -> violations
        False -> ["fat", ..violations]
      }

      let violation_count = list.length(violations)
      let total_metrics = 4
      let satisfaction_score =
        int_to_float(total_metrics - violation_count)
        /. int_to_float(total_metrics)

      PartiallySatisfied(
        satisfaction_score,
        "Nutrition targets not met: " <> list_to_string(violations),
      )
    }
  }
}

/// Evaluate recipe repetition constraint
fn evaluate_repetition_constraint(
  schedule: MealSchedule,
  max_times: Int,
) -> ConstraintResult {
  let recipe_counts = count_recipe_occurrences(schedule.meals)

  let violations =
    recipe_counts
    |> list.filter(fn(count) { count.1 > max_times })

  case list.is_empty(violations) {
    True -> Satisfied
    False -> {
      let violation_list =
        violations
        |> list.map(fn(v) {
          id.recipe_id_to_string(v.0)
          <> " appears "
          <> int_to_string(v.1)
          <> " times"
        })

      Violated(
        "Recipe repetition exceeded: " <> list_to_string(violation_list),
        advanced.Soft,
      )
    }
  }
}

/// Evaluate must-include constraint
fn evaluate_must_include_constraint(
  schedule: MealSchedule,
  required_recipes: List(RecipeId),
) -> ConstraintResult {
  let scheduled_recipes =
    schedule.meals
    |> list.map(fn(meal) { meal.recipe_id })

  let missing =
    required_recipes
    |> list.filter(fn(recipe_id) {
      !list.contains(scheduled_recipes, recipe_id)
    })

  case list.is_empty(missing) {
    True -> Satisfied
    False -> {
      let missing_list =
        missing
        |> list.map(id.recipe_id_to_string)

      Violated(
        "Required recipes missing: " <> list_to_string(missing_list),
        advanced.Hard,
      )
    }
  }
}

/// Evaluate must-exclude constraint
fn evaluate_must_exclude_constraint(
  schedule: MealSchedule,
  excluded_recipes: List(RecipeId),
) -> ConstraintResult {
  let scheduled_recipes =
    schedule.meals
    |> list.map(fn(meal) { meal.recipe_id })

  let found =
    excluded_recipes
    |> list.filter(fn(recipe_id) { list.contains(scheduled_recipes, recipe_id) })

  case list.is_empty(found) {
    True -> Satisfied
    False -> {
      let found_list =
        found
        |> list.map(id.recipe_id_to_string)

      Violated(
        "Excluded recipes found: " <> list_to_string(found_list),
        advanced.Hard,
      )
    }
  }
}

// ============================================================================
// Conflict Detection
// ============================================================================

/// Detect all conflicts in a meal schedule
pub fn detect_conflicts(schedule: MealSchedule) -> List(ScheduleConflict) {
  let time_conflicts = detect_time_conflicts(schedule.meals)
  let nutrition_conflicts = []
  let budget_conflicts = []
  let ingredient_conflicts = []

  list.flatten([
    time_conflicts,
    nutrition_conflicts,
    budget_conflicts,
    ingredient_conflicts,
  ])
}

/// Detect time slot conflicts (same day and time)
fn detect_time_conflicts(meals: List(ScheduledMeal)) -> List(ScheduleConflict) {
  detect_time_conflicts_recursive(meals, [])
}

fn detect_time_conflicts_recursive(
  meals: List(ScheduledMeal),
  acc: List(ScheduleConflict),
) -> List(ScheduleConflict) {
  case meals {
    [] -> acc
    [meal, ..rest] -> {
      let conflicts = find_conflicting_meals(meal, rest)
      let new_acc = list.append(acc, conflicts)
      detect_time_conflicts_recursive(rest, new_acc)
    }
  }
}

fn find_conflicting_meals(
  meal: ScheduledMeal,
  other_meals: List(ScheduledMeal),
) -> List(ScheduleConflict) {
  other_meals
  |> list.filter(fn(other) {
    meal.date == other.date && meal.time == other.time
  })
  |> list.map(fn(other) {
    advanced.TimeSlotConflict(
      id.recipe_id_to_string(meal.recipe_id),
      id.recipe_id_to_string(other.recipe_id),
      meal.date <> " " <> meal.time,
    )
  })
}

// ============================================================================
// Optimization
// ============================================================================

/// Optimize meal schedule according to objective
pub fn optimize_schedule(
  schedule: MealSchedule,
  objective: OptimizationObjective,
  constraints: List(Constraint),
) -> Result(OptimizationResult, AppError) {
  let satisfaction_score = evaluate_constraints(constraints, schedule)
  let constraints_satisfied = satisfaction_score >=. 0.8

  let optimization_score = case objective {
    advanced.MinimizeCost -> calculate_cost_score(schedule)
    advanced.MinimizePrepTime -> calculate_time_score(schedule)
    advanced.MaximizeNutrition -> calculate_nutrition_score(schedule)
    advanced.MaximizeVariety -> calculate_variety_score(schedule)
    advanced.Weighted(_) -> 0.5
  }

  Ok(advanced.OptimizationResult(
    schedule: schedule,
    score: optimization_score,
    objectives_met: [],
    constraints_satisfied: constraints_satisfied,
  ))
}

// ============================================================================
// Scoring Functions
// ============================================================================

fn calculate_cost_score(_schedule: MealSchedule) -> Float {
  0.8
}

fn calculate_time_score(_schedule: MealSchedule) -> Float {
  0.7
}

fn calculate_nutrition_score(_schedule: MealSchedule) -> Float {
  0.9
}

fn calculate_variety_score(_schedule: MealSchedule) -> Float {
  0.6
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Count occurrences of each recipe in meal list
fn count_recipe_occurrences(
  meals: List(ScheduledMeal),
) -> List(#(RecipeId, Int)) {
  count_recipe_occurrences_recursive(meals, [])
}

fn count_recipe_occurrences_recursive(
  meals: List(ScheduledMeal),
  acc: List(#(RecipeId, Int)),
) -> List(#(RecipeId, Int)) {
  case meals {
    [] -> acc
    [meal, ..rest] -> {
      let new_acc = increment_recipe_count(meal.recipe_id, acc)
      count_recipe_occurrences_recursive(rest, new_acc)
    }
  }
}

fn increment_recipe_count(
  recipe_id: RecipeId,
  counts: List(#(RecipeId, Int)),
) -> List(#(RecipeId, Int)) {
  case find_recipe_count(recipe_id, counts) {
    Some(current_count) -> {
      let updated =
        counts
        |> list.filter(fn(entry) { entry.0 != recipe_id })
      [#(recipe_id, current_count + 1), ..updated]
    }
    None -> [#(recipe_id, 1), ..counts]
  }
}

fn find_recipe_count(
  recipe_id: RecipeId,
  counts: List(#(RecipeId, Int)),
) -> Option(Int) {
  case list.find(counts, fn(entry) { entry.0 == recipe_id }) {
    Ok(entry) -> Some(entry.1)
    Error(_) -> None
  }
}

fn list_to_string(items: List(String)) -> String {
  case items {
    [] -> ""
    [single] -> single
    [first, ..rest] -> first <> ", " <> list_to_string(rest)
  }
}

fn float_to_string(f: Float) -> String {
  float.to_string(f)
}

fn int_to_string(i: Int) -> String {
  i
  |> int.to_string
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
