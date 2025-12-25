# Macros Module

**Module:** `meal_planner/types/macros`

**Purpose:** Macronutrient calculations and operations using standard calorie conversions.

## Overview

Provides the `Macros` type (protein, fat, carbs in grams) with comprehensive operations:
- Calorie calculations (4cal/g protein, 9cal/g fat, 4cal/g carbs)
- Arithmetic operations (add, subtract, scale)
- Ratio calculations (P/F/C as % of calories)
- Comparison and validation
- Balance checking and analysis

## Public API

### Types

```gleam
pub type Macros {
  Macros(protein: Float, fat: Float, carbs: Float)
}

pub type MacroComparison {
  OnTarget  // Within ±10% of target
  Under     // Below 90% of target
  Over      // Above 110% of target
}
```

### Construction

```gleam
// Direct construction
let macros = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

// Zero macros
pub fn zero() -> Macros
```

### Calorie Calculations

```gleam
pub fn calories(m: Macros) -> Float
pub fn protein_calories(m: Macros) -> Float
pub fn fat_calories(m: Macros) -> Float
pub fn carb_calories(m: Macros) -> Float
```

### Arithmetic Operations

```gleam
pub fn add(a: Macros, b: Macros) -> Macros
pub fn subtract(a: Macros, b: Macros) -> Macros
pub fn scale(m: Macros, factor: Float) -> Macros
pub fn negate(m: Macros) -> Macros
pub fn abs(m: Macros) -> Macros
```

### Aggregate Operations

```gleam
pub fn sum(macros: List(Macros)) -> Macros
pub fn average(macros: List(Macros)) -> Macros
pub fn min(a: Macros, b: Macros) -> Macros
pub fn max(a: Macros, b: Macros) -> Macros
pub fn clamp(m: Macros, min_val: Float, max_val: Float) -> Macros
```

### Ratio Calculations

```gleam
pub fn protein_ratio(m: Macros) -> Float  // 0.0 to 1.0
pub fn fat_ratio(m: Macros) -> Float      // 0.0 to 1.0
pub fn carb_ratio(m: Macros) -> Float     // 0.0 to 1.0
```

### Validation & Analysis

```gleam
pub fn is_balanced(m: Macros) -> Bool
pub fn is_empty(m: Macros) -> Bool
pub fn has_negative_values(m: Macros) -> Bool
pub fn approximately_equal(a: Macros, b: Macros) -> Bool
```

### Comparison

```gleam
pub fn compare_to_target(actual: Float, target: Float) -> MacroComparison
```

### Serialization

```gleam
// JSON Encoding
pub fn to_json(m: Macros) -> Json
pub fn macro_comparison_to_json(mc: MacroComparison) -> Json

// JSON Decoding
pub fn decoder() -> Decoder(Macros)
pub fn macro_comparison_decoder() -> Decoder(MacroComparison)
```

### Display

```gleam
pub fn to_string(m: Macros) -> String
pub fn to_string_with_calories(m: Macros) -> String
pub fn macro_comparison_to_string(mc: MacroComparison) -> String
```

## Usage Examples

### Basic Calculations

```gleam
import meal_planner/types/macros

let daily = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

// Calculate calories
let total_cals = macros.calories(daily)  // 1840.0
let protein_cals = macros.protein_calories(daily)  // 600.0
let fat_cals = macros.fat_calories(daily)  // 540.0
let carb_cals = macros.carb_calories(daily)  // 800.0

// Calculate ratios
let p_ratio = macros.protein_ratio(daily)  // ~0.33 (33%)
let f_ratio = macros.fat_ratio(daily)      // ~0.29 (29%)
let c_ratio = macros.carb_ratio(daily)     // ~0.43 (43%)
```

### Arithmetic Operations

```gleam
let breakfast = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
let lunch = Macros(protein: 50.0, fat: 20.0, carbs: 60.0)
let dinner = Macros(protein: 60.0, fat: 25.0, carbs: 90.0)

// Sum meals
let total = breakfast
  |> macros.add(lunch)
  |> macros.add(dinner)
// Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

// Calculate deficit
let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
let actual = Macros(protein: 145.0, fat: 58.0, carbs: 210.0)
let deficit = macros.subtract(target, actual)
// Macros(protein: 5.0, fat: 2.0, carbs: -10.0)

// Scale recipe (2 servings → 4 servings)
let doubled = macros.scale(breakfast, 2.0)
// Macros(protein: 80.0, fat: 30.0, carbs: 100.0)
```

### List Operations

```gleam
let meals = [breakfast, lunch, dinner, snack]

// Sum all meals
let total = macros.sum(meals)

// Average macros per meal
let avg = macros.average(meals)

// Returns zero if empty list
let empty_avg = macros.average([])  // Macros(0.0, 0.0, 0.0)
```

### Balance Checking

```gleam
// Check if macros are balanced (30% P, 30% F, 40% C ±10%)
let balanced = Macros(protein: 150.0, fat: 67.0, carbs: 200.0)
macros.is_balanced(balanced)  // True

let unbalanced = Macros(protein: 200.0, fat: 30.0, carbs: 100.0)
macros.is_balanced(unbalanced)  // False (too much protein)
```

### Comparison to Target

```gleam
let target = 150.0  // target protein grams
let actual = 145.0  // actual protein grams

let status = macros.compare_to_target(actual, target)
// Returns: Under (145/150 = 0.97, which is < 0.9 threshold)

// Status can be:
// - OnTarget: 90% - 110% of target
// - Under: < 90% of target
// - Over: > 110% of target
```

### Used with DailyMacros

```gleam
import meal_planner/types/meal_plan

let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
let actual = Macros(protein: 145.0, fat: 58.0, carbs: 210.0)

let daily_result = meal_plan.new_daily_macros(actual, target)
case daily_result {
  Ok(daily) -> {
    let p_status = meal_plan.daily_macros_protein_status(daily)
    // Under (145 vs 150)
    let f_status = meal_plan.daily_macros_fat_status(daily)
    // OnTarget (58 vs 60, within 10%)
    let c_status = meal_plan.daily_macros_carbs_status(daily)
    // Over (210 vs 200)
  }
  Error(msg) -> // Handle error
}
```

### Display Formatting

```gleam
let macros = Macros(protein: 150.5, fat: 60.2, carbs: 200.8)

let compact = macros.to_string(macros)
// "P:151g F:60g C:201g"

let with_cals = macros.to_string_with_calories(macros)
// "P:151g F:60g C:201g (1847 cal)"

let status = macros.compare_to_target(145.0, 150.0)
let status_str = macros.macro_comparison_to_string(status)
// "Under Target"
```

## Calorie Conversion Constants

The module uses standard macronutrient calorie conversions:

- **Protein:** 4 calories per gram
- **Fat:** 9 calories per gram
- **Carbohydrates:** 4 calories per gram

These are hardcoded as per nutritional science standards.

## Balance Definition

`is_balanced()` checks for:
- **Protein:** 20-40% of calories (±10% from 30%)
- **Fat:** 20-40% of calories (±10% from 30%)
- **Carbs:** 30-50% of calories (±10% from 40%)

This represents a moderate balanced macro split. All three conditions must be true.

## Comparison Thresholds

`compare_to_target()` uses ±10% tolerance:
- **OnTarget:** 90% - 110% of target
- **Under:** < 90% of target
- **Over:** > 110% of target

Zero or negative targets always return `OnTarget`.

## Approximate Equality

`approximately_equal()` uses **0.1g tolerance** per macro:

```gleam
let a = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
let b = Macros(protein: 150.05, fat: 60.02, carbs: 200.08)

macros.approximately_equal(a, b)  // True (all within 0.1g)
```

## Design Notes

### Public Type
`Macros` is a public type (not opaque) for direct construction and pattern matching. This allows:
- Simple construction: `Macros(protein: 150.0, fat: 60.0, carbs: 200.0)`
- Pattern matching: `case m { Macros(p, f, c) -> ... }`
- Direct field access: `m.protein`

No validation is enforced at construction time. Use `has_negative_values()` to validate if needed.

### Immutability
All operations return new `Macros` instances. Original values never mutate.

### Zero Division Safety
Ratio functions (`protein_ratio`, `fat_ratio`, `carb_ratio`) handle zero calories gracefully:
- If total calories = 0, returns 0.0 ratio
- Prevents division by zero errors

### List Operations
`sum()` and `average()` handle empty lists:
- `sum([])` returns `zero()` (Macros(0.0, 0.0, 0.0))
- `average([])` returns `zero()` (Macros(0.0, 0.0, 0.0))

## Dependencies

- `gleam/float` - Float operations and rounding
- `gleam/int` - Integer conversions
- `gleam/list` - List operations (fold, map)
- `gleam/json` - JSON serialization
- `gleam/dynamic/decode` - JSON deserialization

## Related Modules

- **types/meal_plan** - Uses Macros for DailyMacros and tracking
- **types/recipe** - Stores Macros in Recipe and MealPlanRecipe
- **types/nutrition** - NutritionData includes Macros
- **automation/macro_optimizer** - Optimizes meal plans using macro operations

## File Size

339 lines (well under 500-line target)
