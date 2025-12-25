# Nutrition Module

**Module:** `meal_planner/types/nutrition`

**Purpose:** Nutrition tracking, goals, calculations, and trend analysis.

## Overview

Comprehensive nutrition tracking system with:
- Daily nutrition goals and actual consumption tracking
- Deviation calculations (% from targets)
- Recipe suggestions to correct deviations
- Trend analysis (increasing/decreasing/stable)
- Reconciliation between consumed and target nutrition

## Public API

### Core Types

```gleam
pub type NutritionGoals {
  NutritionGoals(
    daily_protein: Float,
    daily_fat: Float,
    daily_carbs: Float,
    daily_calories: Float,
  )
}

pub type NutritionData {
  NutritionData(
    protein: Float,
    fat: Float,
    carbs: Float,
    calories: Float,
  )
}

pub type DeviationResult {
  DeviationResult(
    protein_pct: Float,
    fat_pct: Float,
    carbs_pct: Float,
    calories_pct: Float,
  )
}
```

### Suggestion & Reconciliation Types

```gleam
pub type RecipeSuggestion {
  RecipeSuggestion(
    recipe_name: String,
    reason: String,
    score: Float,
  )
}

pub type AdjustmentPlan {
  AdjustmentPlan(
    deviation: DeviationResult,
    suggestions: List(RecipeSuggestion),
  )
}

pub type ReconciliationResult {
  ReconciliationResult(
    date: String,
    average_consumed: NutritionData,
    goals: NutritionGoals,
    deviation: DeviationResult,
    plan: AdjustmentPlan,
    within_tolerance: Bool,
  )
}
```

### Trend Analysis Types

```gleam
pub type TrendDirection {
  Increasing
  Decreasing
  Stable
}

pub type TrendAnalysis {
  TrendAnalysis(
    protein_trend: TrendDirection,
    fat_trend: TrendDirection,
    carbs_trend: TrendDirection,
    calories_trend: TrendDirection,
    protein_change: Float,
    fat_change: Float,
    carbs_change: Float,
    calories_change: Float,
  )
}
```

### Functions

```gleam
// Goal/Data conversion
pub fn goals_to_data(goals: NutritionGoals) -> NutritionData
pub fn data_to_macros(data: NutritionData) -> Macros
pub fn macros_to_data(macros: Macros) -> NutritionData

// Validation
pub fn validate_goals(goals: NutritionGoals) -> Result(Nil, String)
pub fn validate_data(data: NutritionData) -> Result(Nil, String)

// Calculations
pub fn calculate_deviation(
  actual: NutritionData,
  goals: NutritionGoals,
) -> DeviationResult

pub fn is_within_tolerance(
  deviation: DeviationResult,
  tolerance: Float,
) -> Bool

// Aggregation
pub fn sum_nutrition(data_list: List(NutritionData)) -> NutritionData
pub fn average_nutrition(data_list: List(NutritionData)) -> NutritionData

// Display
pub fn format_nutrition_data(data: NutritionData) -> String
pub fn format_goals(goals: NutritionGoals) -> String
pub fn format_deviation(dev: DeviationResult) -> String
```

## Usage Examples

### Setting Goals

```gleam
import meal_planner/types/nutrition

let goals = nutrition.NutritionGoals(
  daily_protein: 150.0,
  daily_fat: 60.0,
  daily_carbs: 200.0,
  daily_calories: 1840.0,
)

// Validate goals
case nutrition.validate_goals(goals) {
  Ok(_) -> // Goals are valid
  Error(msg) -> // Invalid: negative values or zero calories
}
```

### Tracking Consumption

```gleam
let consumed = nutrition.NutritionData(
  protein: 145.0,
  fat: 58.0,
  carbs: 210.0,
  calories: 1850.0,
)

// Calculate deviation from goals
let deviation = nutrition.calculate_deviation(consumed, goals)
// DeviationResult with percentage deviations for each macro

// Check if within tolerance (default ±10%)
let within_tolerance = nutrition.is_within_tolerance(deviation, 0.1)
```

### Deviation Calculation

```gleam
// Deviation is calculated as: (actual - target) / target * 100
let deviation = nutrition.calculate_deviation(consumed, goals)

// Example results:
// protein_pct: -3.33% (145 vs 150)
// fat_pct: -3.33% (58 vs 60)
// carbs_pct: +5.0% (210 vs 200)
// calories_pct: +0.54% (1850 vs 1840)
```

### Aggregating Daily Data

```gleam
let breakfast = nutrition.NutritionData(
  protein: 40.0, fat: 15.0, carbs: 50.0, calories: 470.0
)
let lunch = nutrition.NutritionData(
  protein: 50.0, fat: 20.0, carbs: 60.0, calories: 590.0
)
let dinner = nutrition.NutritionData(
  protein: 55.0, fat: 23.0, carbs: 90.0, calories: 782.0
)

let daily_total = nutrition.sum_nutrition([breakfast, lunch, dinner])
// Total for the day

let avg = nutrition.average_nutrition([breakfast, lunch, dinner])
// Average per meal
```

### Converting Between Types

```gleam
import meal_planner/types/macros

// Convert goals to data for comparison
let goal_data = nutrition.goals_to_data(goals)

// Convert macros to nutrition data
let macros = macros.Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
let data = nutrition.macros_to_data(macros)
// Calculates calories automatically

// Convert nutrition data to macros
let macros_again = nutrition.data_to_macros(data)
```

### Display Formatting

```gleam
let data = nutrition.NutritionData(
  protein: 150.0,
  fat: 60.0,
  carbs: 200.0,
  calories: 1840.0,
)

let formatted = nutrition.format_nutrition_data(data)
// "P: 150g | F: 60g | C: 200g | Cal: 1840"

let dev = nutrition.DeviationResult(
  protein_pct: -3.33,
  fat_pct: -3.33,
  carbs_pct: 5.0,
  calories_pct: 0.54,
)

let dev_formatted = nutrition.format_deviation(dev)
// "P: -3.3% | F: -3.3% | C: +5.0% | Cal: +0.5%"
```

## Design Notes

### NutritionGoals vs NutritionData

- **NutritionGoals** - Targets for the day (daily_protein, daily_fat, etc)
- **NutritionData** - Actual values consumed or calculated (protein, fat, etc)

Both have same fields, but semantic difference in usage.

### Deviation Calculation

Deviation is percentage difference from target:
```
deviation_pct = ((actual - target) / target) * 100
```

Positive = over target, Negative = under target

### Tolerance Checking

`is_within_tolerance()` checks if ALL macros are within tolerance:
- Default tolerance: 0.1 (±10%)
- ALL four metrics (protein, fat, carbs, calories) must be within range
- Returns `True` only if all within tolerance

### Trend Analysis

TrendDirection is determined by comparing recent vs historical averages:
- **Increasing** - Metric trending upward
- **Decreasing** - Metric trending downward
- **Stable** - No significant change

Change values are absolute differences (not percentages).

## Validation Rules

### NutritionGoals
- All values must be non-negative
- daily_calories must be > 0

### NutritionData
- All values must be non-negative
- No zero-calorie requirement (allows empty meals)

## Dependencies

- `meal_planner/types/macros` - Macros type and operations
- `meal_planner/nutrition_constants` - Standard nutrition constants
- `gleam/float` - Float operations
- `gleam/list` - Aggregation operations

## Related Modules

- **advisor/recommendations** - Uses reconciliation for suggestions
- **fatsecret/diary/** - Provides NutritionData from food logs
- **automation/macro_optimizer** - Optimizes to meet NutritionGoals

## File Size

~550 lines (slightly over 500-line target, acceptable for comprehensive nutrition system)
