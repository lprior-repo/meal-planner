//// Advanced scheduler types for meal planning
////
//// This module defines advanced scheduling capabilities:
//// - Recurring meal plan scheduling
//// - Nutrition-based meal planning
//// - Preference-aware scheduling
//// - Constraint satisfaction (dietary, budget)
//// - Conflict detection and resolution
//// - Schedule optimization algorithms

import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/id.{type RecipeId, type UserId}
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Recurrence Patterns
// ============================================================================

/// Pattern for recurring meal plans
pub type RecurrencePattern {
  /// Repeat every N days
  EveryNDays(days: Int)
  /// Repeat weekly on specific days (0=Sunday, 6=Saturday)
  WeeklyOnDays(days: List(Int))
  /// Repeat monthly on specific day of month
  MonthlyOnDay(day: Int)
  /// Custom cron-like pattern
  Custom(pattern: String)
}

/// Recurrence rule for meal plans
pub type RecurrenceRule {
  RecurrenceRule(
    pattern: RecurrencePattern,
    start_date: String,
    end_date: Option(String),
    max_occurrences: Option(Int),
  )
}

// ============================================================================
// Nutrition Constraints
// ============================================================================

/// Nutrition targets for meal planning
pub type NutritionTarget {
  NutritionTarget(
    calories: FloatRange,
    protein: FloatRange,
    carbs: FloatRange,
    fat: FloatRange,
    fiber: Option(FloatRange),
  )
}

/// Float range with min/max bounds
pub type FloatRange {
  FloatRange(min: Float, max: Float)
}

/// Nutrition optimization strategy
pub type NutritionStrategy {
  /// Maximize protein intake
  MaximizeProtein
  /// Minimize carbs (keto-friendly)
  MinimizeCarbs
  /// Balance macros evenly
  BalancedMacros
  /// Hit specific macro ratios
  MacroRatio(protein_pct: Float, carb_pct: Float, fat_pct: Float)
}

// ============================================================================
// User Preferences
// ============================================================================

/// User meal preferences
pub type MealPreferences {
  MealPreferences(
    /// Preferred meal times (hour:minute)
    meal_times: List(MealTime),
    /// Cuisine preferences (weights 0-1)
    cuisines: List(CuisinePreference),
    /// Recipe variety preference (0=repetitive, 1=maximum variety)
    variety: Float,
    /// Maximum prep time in minutes
    max_prep_time: Option(Int),
    /// Dietary restrictions
    dietary_restrictions: List(DietaryRestriction),
  )
}

/// Meal time specification
pub type MealTime {
  MealTime(meal_type: MealType, hour: Int, minute: Int)
}

/// Type of meal
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// Cuisine preference with weight
pub type CuisinePreference {
  CuisinePreference(cuisine: String, weight: Float)
}

/// Dietary restriction types
pub type DietaryRestriction {
  /// Vegetarian diet
  Vegetarian
  /// Vegan diet
  Vegan
  /// Gluten-free diet
  GlutenFree
  /// Dairy-free diet
  DairyFree
  /// Low-carb/keto diet
  LowCarb
  /// Custom restriction with excluded ingredients
  Custom(excluded_ingredients: List(String))
}

// ============================================================================
// Constraints
// ============================================================================

/// Constraint type for meal planning
pub type Constraint {
  /// Budget constraint (total cost per week)
  Budget(max_cost: Float, currency: String)
  /// Time constraint (max total prep time per week in minutes)
  TimeLimit(max_minutes: Int)
  /// Ingredient availability constraint
  IngredientAvailability(available_ingredients: List(String))
  /// Must include specific recipes
  MustInclude(recipe_ids: List(RecipeId))
  /// Must exclude specific recipes
  MustExclude(recipe_ids: List(RecipeId))
  /// Nutrition constraint
  Nutrition(target: NutritionTarget)
  /// Dietary restriction constraint
  Dietary(restrictions: List(DietaryRestriction))
  /// Maximum recipe repetition per week
  MaxRepetition(max_times: Int)
}

/// Constraint satisfaction result
pub type ConstraintResult {
  /// Constraint is satisfied
  Satisfied
  /// Constraint is violated with reason
  Violated(reason: String, severity: ConstraintSeverity)
  /// Constraint is partially satisfied
  PartiallySatisfied(score: Float, reason: String)
}

/// Severity of constraint violation
pub type ConstraintSeverity {
  /// Soft constraint (preference)
  Soft
  /// Hard constraint (must satisfy)
  Hard
}

// ============================================================================
// Scheduling Conflicts
// ============================================================================

/// Conflict between scheduled meals
pub type ScheduleConflict {
  /// Time slot conflict (two meals at same time)
  TimeSlotConflict(meal1: String, meal2: String, time: String)
  /// Nutrition conflict (exceeds daily limits)
  NutritionConflict(date: String, nutrient: String, actual: Float, limit: Float)
  /// Budget conflict (exceeds budget)
  BudgetConflict(week: String, actual: Float, limit: Float)
  /// Ingredient conflict (ingredient not available)
  IngredientConflict(recipe: String, ingredient: String)
}

/// Conflict resolution strategy
pub type ConflictResolution {
  /// Override earlier meal
  OverrideEarlier
  /// Override later meal
  OverrideLater
  /// Skip conflicting meal
  Skip
  /// Reschedule to next available slot
  Reschedule
  /// Ask user for manual resolution
  ManualResolve
}

// ============================================================================
// Optimization
// ============================================================================

/// Optimization objective for meal scheduling
pub type OptimizationObjective {
  /// Minimize total cost
  MinimizeCost
  /// Minimize total prep time
  MinimizePrepTime
  /// Maximize nutrition score
  MaximizeNutrition
  /// Maximize variety
  MaximizeVariety
  /// Weighted combination of multiple objectives
  Weighted(weights: List(ObjectiveWeight))
}

/// Weighted objective
pub type ObjectiveWeight {
  ObjectiveWeight(objective: OptimizationObjective, weight: Float)
}

/// Optimization result
pub type OptimizationResult {
  OptimizationResult(
    /// Optimized meal schedule
    schedule: MealSchedule,
    /// Optimization score (0-1, higher is better)
    score: Float,
    /// Objectives achieved
    objectives_met: List(String),
    /// Constraints satisfied
    constraints_satisfied: Bool,
  )
}

// ============================================================================
// Meal Schedule
// ============================================================================

/// Complete meal schedule with metadata
pub type MealSchedule {
  MealSchedule(
    /// User ID
    user_id: UserId,
    /// Schedule start date
    start_date: String,
    /// Schedule end date
    end_date: String,
    /// Scheduled meals
    meals: List(ScheduledMeal),
    /// Total nutrition summary
    nutrition_summary: Macros,
    /// Total cost
    total_cost: Option(Float),
    /// Recurrence rule (if recurring)
    recurrence: Option(RecurrenceRule),
  )
}

/// Single scheduled meal
pub type ScheduledMeal {
  ScheduledMeal(
    /// Recipe ID
    recipe_id: RecipeId,
    /// Date (ISO 8601)
    date: String,
    /// Time (HH:MM)
    time: String,
    /// Meal type
    meal_type: MealType,
    /// Nutrition info
    nutrition: Macros,
    /// Estimated prep time in minutes
    prep_time: Option(Int),
    /// Estimated cost
    cost: Option(Float),
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Check if value is within range
pub fn in_range(value: Float, range: FloatRange) -> Bool {
  value >= range.min && value <= range.max
}

/// Calculate constraint satisfaction score (0-1)
pub fn constraint_score(result: ConstraintResult) -> Float {
  case result {
    Satisfied -> 1.0
    Violated(_, _) -> 0.0
    PartiallySatisfied(score, _) -> score
  }
}

/// Convert meal type to string
pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

/// Convert dietary restriction to string
pub fn dietary_restriction_to_string(restriction: DietaryRestriction) -> String {
  case restriction {
    Vegetarian -> "vegetarian"
    Vegan -> "vegan"
    GlutenFree -> "gluten_free"
    DairyFree -> "dairy_free"
    LowCarb -> "low_carb"
    Custom(_) -> "custom"
  }
}

// ============================================================================
// JSON Encoders
// ============================================================================

/// Encode FloatRange to JSON
pub fn float_range_to_json(range: FloatRange) -> Json {
  json.object([#("min", json.float(range.min)), #("max", json.float(range.max))])
}

/// Encode NutritionTarget to JSON
pub fn nutrition_target_to_json(target: NutritionTarget) -> Json {
  let base_fields = [
    #("calories", float_range_to_json(target.calories)),
    #("protein", float_range_to_json(target.protein)),
    #("carbs", float_range_to_json(target.carbs)),
    #("fat", float_range_to_json(target.fat)),
  ]

  let fields = case target.fiber {
    option.Some(fiber) -> [
      #("fiber", float_range_to_json(fiber)),
      ..base_fields
    ]
    option.None -> base_fields
  }

  json.object(fields)
}

/// Encode MealType to JSON
pub fn meal_type_to_json(meal_type: MealType) -> Json {
  json.string(meal_type_to_string(meal_type))
}

/// Encode ScheduledMeal to JSON
pub fn scheduled_meal_to_json(meal: ScheduledMeal) -> Json {
  let base_fields = [
    #("recipe_id", id.recipe_id_to_json(meal.recipe_id)),
    #("date", json.string(meal.date)),
    #("time", json.string(meal.time)),
    #("meal_type", meal_type_to_json(meal.meal_type)),
    #("nutrition", macros.to_json(meal.nutrition)),
  ]

  let fields = case meal.prep_time {
    option.Some(time) -> [#("prep_time", json.int(time)), ..base_fields]
    option.None -> base_fields
  }

  let fields = case meal.cost {
    option.Some(cost) -> [#("cost", json.float(cost)), ..fields]
    option.None -> fields
  }

  json.object(fields)
}
