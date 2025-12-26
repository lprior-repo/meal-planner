# Meal Plan Types Module

**Module:** `meal_planner/types/meal_plan`

**Purpose:** Core types for autonomous meal planning with validated macro tracking.

## Overview

Defines three opaque types for the meal planning system:
- **DailyMacros** - Tracks actual vs target macros with status indicators
- **DayMeals** - Single day's meals (breakfast, lunch, dinner) with totals
- **MealPlan** - Complete 7-day meal plan with weekly tracking

All types use opaque constructors to enforce validation at creation time.

## Public API

### Types

```gleam
pub opaque type DailyMacros
pub opaque type DayMeals
pub opaque type MealPlan
```

### Constructors

```gleam
// DailyMacros
pub fn new_daily_macros(
  actual: Macros,
  target: Macros,
) -> Result(DailyMacros, String)

// DayMeals
pub fn new_day_meals(
  day day: String,
  breakfast breakfast: MealPlanRecipe,
  lunch lunch: MealPlanRecipe,
  dinner dinner: MealPlanRecipe,
  target_macros target_macros: Macros,
) -> Result(DayMeals, String)

// MealPlan
pub fn new_meal_plan(
  week_of week_of: String,
  days days: List(DayMeals),
  target_macros target_macros: Macros,
) -> Result(MealPlan, String)
```

### Accessors

#### DailyMacros
```gleam
pub fn daily_macros_actual(dm: DailyMacros) -> Macros
pub fn daily_macros_calories(dm: DailyMacros) -> Float
pub fn daily_macros_protein_status(dm: DailyMacros) -> MacroComparison
pub fn daily_macros_fat_status(dm: DailyMacros) -> MacroComparison
pub fn daily_macros_carbs_status(dm: DailyMacros) -> MacroComparison
```

#### DayMeals
```gleam
pub fn day_meals_day(dm: DayMeals) -> String
pub fn day_meals_breakfast(dm: DayMeals) -> MealPlanRecipe
pub fn day_meals_lunch(dm: DayMeals) -> MealPlanRecipe
pub fn day_meals_dinner(dm: DayMeals) -> MealPlanRecipe
pub fn day_meals_macros(dm: DayMeals) -> DailyMacros
```

#### MealPlan
```gleam
pub fn meal_plan_week_of(plan: MealPlan) -> String
pub fn meal_plan_days(plan: MealPlan) -> List(DayMeals)
pub fn meal_plan_target_macros(plan: MealPlan) -> Macros
pub fn meal_plan_total_macros(plan: MealPlan) -> Macros
pub fn meal_plan_avg_daily_macros(plan: MealPlan) -> Macros
```

### Serialization

```gleam
// JSON Encoding
pub fn daily_macros_to_json(dm: DailyMacros) -> Json
pub fn day_meals_to_json(dm: DayMeals) -> Json
pub fn meal_plan_to_json(plan: MealPlan) -> Json

// JSON Decoding
pub fn daily_macros_decoder() -> Decoder(DailyMacros)
pub fn day_meals_decoder() -> Decoder(DayMeals)
pub fn meal_plan_decoder() -> Decoder(MealPlan)
```

### Display

```gleam
pub fn daily_macros_to_string(dm: DailyMacros) -> String
```

## Usage Examples

### Creating a Day's Meals

```gleam
import meal_planner/types/macros
import meal_planner/types/meal_plan
import meal_planner/types/recipe

let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)

// Create recipes (see recipe.gleam for MealPlanRecipe construction)
let breakfast = // ... MealPlanRecipe
let lunch = // ... MealPlanRecipe
let dinner = // ... MealPlanRecipe

let day_result = meal_plan.new_day_meals(
  day: "Monday",
  breakfast: breakfast,
  lunch: lunch,
  dinner: dinner,
  target_macros: target,
)

case day_result {
  Ok(day) -> {
    // Macros automatically calculated and validated
    let macros = meal_plan.day_meals_macros(day)
    let protein_status = meal_plan.daily_macros_protein_status(macros)
    // Check if OnTarget, Over, or Under
  }
  Error(msg) -> // Handle validation error
}
```

### Creating a Full Week Plan

```gleam
let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)
let days = [monday, tuesday, wednesday, thursday, friday, saturday, sunday]

let plan_result = meal_plan.new_meal_plan(
  week_of: "2025-01-06",
  days: days,
  target_macros: target,
)

case plan_result {
  Ok(plan) -> {
    // Get weekly totals
    let total = meal_plan.meal_plan_total_macros(plan)
    let avg_daily = meal_plan.meal_plan_avg_daily_macros(plan)
  }
  Error(msg) -> // "MealPlan must have exactly 7 days, got N"
}
```

## Validation Rules

### DailyMacros
- Automatically compares actual vs target macros
- Calculates status for each macro: `OnTarget`, `Over`, or `Under`
- Status determined by `macros.compare_to_target()` function

### DayMeals
- Validates by summing breakfast + lunch + dinner macros
- Creates DailyMacros instance with calculated totals
- All three meals required (no Optional)

### MealPlan
- **Must have exactly 7 days** - Returns Error if not 7
- Calculates total weekly macros by summing all days
- Stores target macros for weekly tracking

## Design Notes

### Opaque Types
All three types are opaque to enforce validation through constructors. This ensures:
- Macro calculations are always correct
- Weekly plans always have 7 days
- Status indicators always reflect current state

### Immutability
All types are immutable. To modify a meal plan:
1. Extract the days list
2. Create new DayMeals instances
3. Create new MealPlan with updated days

### Macro Status
Status indicators use the `MacroComparison` type from `macros.gleam`:
- `OnTarget` - Within acceptable range of target
- `Over` - Exceeds target by threshold
- `Under` - Below target by threshold

## Dependencies

- `meal_planner/types/macros` - Macros type and calculations
- `meal_planner/types/recipe` - MealPlanRecipe type
- `gleam/json` - JSON serialization
- `gleam/dynamic/decode` - JSON deserialization

## Related Modules

- **generator/** - Generates meal plans using these types
- **advisor/** - Analyzes meal plans for compliance
- **automation/macro_optimizer** - Optimizes meal plans to hit targets

## Part of Epic

NORTH STAR Epic (meal-planner-918): Autonomous meal planning system

## File Size

426 lines (target: <500 lines, ideal: <300 lines)
