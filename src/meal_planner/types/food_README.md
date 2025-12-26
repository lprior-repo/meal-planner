# Food Module

**Module:** `meal_planner/types/food`

**Purpose:** Food and food log types for meal tracking and database integration.

## Overview

This module provides types for:
- Food source tracking (Recipe, CustomFood, USDA)
- Food search functionality
- Food logging (entries and daily aggregates)
- Meal type classification

## Public API

### Types

```gleam
// Food Source (type-safe source tracking)
pub type FoodSource {
  RecipeSource(recipe_id: RecipeId)
  CustomFoodSource(custom_food_id: CustomFoodId, user_id: UserId)
  UsdaFoodSource(fdc_id: FdcId)
}

// Food Search
pub type FoodSearchResult {
  CustomFoodResult(food: CustomFood)
  UsdaFoodResult(fdc_id: FdcId, description: String, data_type: String,
                 category: String, serving_size: String)
}

pub type FoodSearchResponse {
  FoodSearchResponse(
    results: List(FoodSearchResult),
    total_count: Int,
    custom_count: Int,
    usda_count: Int,
  )
}

pub type FoodSearchError {
  DatabaseError(String)
  InvalidQuery(String)
}

pub type SearchFilters {
  SearchFilters(
    verified_only: Bool,
    branded_only: Bool,
    category: Option(String),
  )
}

// Meal Classification
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

// Food Logging
pub type FoodLogEntry {
  FoodLogEntry(
    id: LogEntryId,
    recipe_id: RecipeId,
    recipe_name: String,
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    source_type: String,
    source_id: String,
  )
}

pub type DailyLog {
  DailyLog(
    date: String,
    entries: List(FoodLogEntry),
    total_macros: Macros,
    total_micronutrients: Option(Micronutrients),
  )
}
```

### Functions

```gleam
// MealType conversion
pub fn meal_type_to_string(m: MealType) -> String
pub fn meal_type_from_string(s: String) -> Result(MealType, String)

// JSON serialization
pub fn food_log_entry_to_json(e: FoodLogEntry) -> Json
pub fn daily_log_to_json(d: DailyLog) -> Json
pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry)
pub fn daily_log_decoder() -> Decoder(DailyLog)
```

## Usage Examples

### Type-Safe Food Source

```gleam
import meal_planner/types/food
import meal_planner/id

// Recipe source
let source = food.RecipeSource(recipe_id: id.recipe_id("123"))

// Custom food (includes user_id for authorization)
let source = food.CustomFoodSource(
  custom_food_id: id.custom_food_id("456"),
  user_id: id.user_id("user-789"),
)

// USDA food
let source = food.UsdaFoodSource(fdc_id: id.fdc_id("1234567"))
```

### Food Logging

```gleam
import meal_planner/types/food
import meal_planner/types/macros

let entry = food.FoodLogEntry(
  id: id.log_entry_id("log-123"),
  recipe_id: id.recipe_id("recipe-456"),
  recipe_name: "Chicken Breast",
  servings: 1.5,
  macros: macros.Macros(protein: 45.0, fat: 6.0, carbs: 0.0),
  micronutrients: None,
  meal_type: food.Lunch,
  logged_at: "2025-01-06T12:30:00Z",
  source_type: "recipe",
  source_id: "recipe-456",
)
```

## Design Notes

### FoodSource Type Safety

`FoodSource` prevents runtime errors by encoding source type at compile time:
- `RecipeSource` - Only accepts RecipeId
- `CustomFoodSource` - Requires both CustomFoodId AND UserId (for authorization)
- `UsdaFoodSource` - Only accepts FdcId

No string-based `source_type` field to mismatch.

### MealType Enum

Simple 4-variant enum for meal classification. Used throughout:
- Food logging
- Meal plans
- Nutrition summaries

## Dependencies

- `meal_planner/id` - ID types (RecipeId, CustomFoodId, etc)
- `meal_planner/types/custom_food` - CustomFood type
- `meal_planner/types/macros` - Macros type
- `meal_planner/types/micronutrients` - Micronutrients type

## Related Modules

- **fatsecret/diary/** - Food diary integration
- **storage/nutrients** - USDA food database
- **types/custom_food** - User-created foods

## File Size

~270 lines (well under target)
