# Types Module Import Reference Guide

## Quick Reference

### Common Import Patterns

```gleam
// Macros for nutrition calculations
import meal_planner/types/macros.{type Macros}
import meal_planner/types/macros  // For macros.calories(), etc.

// Recipes for meal planning
import meal_planner/types/recipe.{type Recipe, type MealPlanRecipe}

// Food tracking
import meal_planner/types/food.{type Food, type FoodEntry, type FoodLogEntry}

// Meal planning
import meal_planner/types/meal_plan.{type MealPlan, type MealSlot}

// JSON encoding/decoding
import meal_planner/types/json
```

## Import by Use Case

### Use Case: Nutrition Calculations

**Scenario:** Working with macronutrients and calorie calculations

```gleam
import meal_planner/types/macros.{type Macros}
import meal_planner/types/macros  // For functions

// Example usage
pub fn calculate_daily_total(meals: List(Macros)) -> Macros {
  meals
  |> list.fold(macros.zero(), macros.add)
}

pub fn get_calories(m: Macros) -> Float {
  macros.calories(m)  // 4cal/g protein, 9cal/g fat, 4cal/g carbs
}
```

**Modules to import:**
- `types/macros` - Core type and operations
- `types/nutrition` - If using NutritionGoals or NutritionData

---

### Use Case: Recipe Management

**Scenario:** Working with recipes from Tandoor API

```gleam
import meal_planner/types/recipe.{
  type Recipe,
  type Ingredient,
  type FodmapLevel,
}
import meal_planner/types/macros.{type Macros}
import meal_planner/id.{type RecipeId}

// Example usage
pub fn is_high_protein(recipe: Recipe) -> Bool {
  recipe.macros.protein >=. 30.0
}

pub fn get_prep_time(recipe: Recipe) -> Int {
  recipe.prep_time_minutes
}
```

**Modules to import:**
- `types/recipe` - Recipe, Ingredient, FodmapLevel
- `types/macros` - For macronutrient data
- `id` - For RecipeId type

---

### Use Case: Meal Planning

**Scenario:** Building weekly meal plans

```gleam
import meal_planner/types/meal_plan.{
  type MealPlan,
  type MealSlot,
  type DayMeals,
  type DailyMacros,
}
import meal_planner/types/recipe.{type MealPlanRecipe}
import meal_planner/types/macros.{type Macros}
import birl.{type Time}

// Example usage
pub fn create_plan(
  start_date: Time,
  recipes: List(MealPlanRecipe),
  target_macros: Macros,
) -> Result(MealPlan, String) {
  // Plan generation logic
  todo
}
```

**Modules to import:**
- `types/meal_plan` - MealPlan, MealSlot, DayMeals, DailyMacros
- `types/recipe` - MealPlanRecipe
- `types/macros` - For macro targets
- `birl` - For date/time handling

---

### Use Case: Food Logging

**Scenario:** Tracking daily food intake from FatSecret

```gleam
import meal_planner/types/food.{
  type Food,
  type FoodEntry,
  type FoodLogEntry,
  type DailyLog,
}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/micronutrients.{type Micronutrients}
import birl.{type Time}

// Example usage
pub fn log_food(
  food: Food,
  serving_size: Float,
  meal_time: Time,
) -> FoodLogEntry {
  // Create log entry
  todo
}

pub fn get_daily_macros(log: DailyLog) -> Macros {
  log.entries
  |> list.map(fn(entry) { entry.food.macros })
  |> list.fold(macros.zero(), macros.add)
}
```

**Modules to import:**
- `types/food` - Food, FoodEntry, FoodLogEntry, DailyLog
- `types/macros` - For macro totals
- `types/micronutrients` - For vitamin/mineral tracking
- `birl` - For timestamps

---

### Use Case: Custom Foods

**Scenario:** User-created foods with custom nutrition data

```gleam
import meal_planner/types/custom_food.{type CustomFood, CustomFood}
import meal_planner/types/macros.{type Macros, Macros}
import meal_planner/types/micronutrients.{type Micronutrients}
import meal_planner/id.{type CustomFoodId}

// Example usage
pub fn create_custom_food(
  name: String,
  serving: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> CustomFood {
  CustomFood(
    id: custom_food_id("new"),
    name: name,
    serving_description: serving,
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    micronutrients: None,
  )
}
```

**Modules to import:**
- `types/custom_food` - CustomFood type
- `types/macros` - For macronutrient data
- `types/micronutrients` - Optional micronutrient data
- `id` - For CustomFoodId type

---

### Use Case: JSON Serialization

**Scenario:** Encoding/decoding types for API or storage

```gleam
import meal_planner/types/json
import meal_planner/types/recipe.{type Recipe}
import meal_planner/types/food.{type Food}
import gleam/json.{type Json}
import gleam/dynamic/decode

// Example usage
pub fn save_recipe(recipe: Recipe) -> String {
  recipe
  |> json.encode_recipe
  |> json.to_string
}

pub fn parse_food(json_string: String) -> Result(Food, String) {
  json_string
  |> json.decode_food
}
```

**Modules to import:**
- `types/json` - All encoders/decoders
- Specific type modules as needed
- `gleam/json` - Core JSON type
- `gleam/dynamic/decode` - For decoders

---

### Use Case: Search and Discovery

**Scenario:** Searching for foods or recipes

```gleam
import meal_planner/types/search.{
  type SearchFilters,
  type SearchResponse,
  type SearchResult,
}
import meal_planner/types/food.{type Food}
import meal_planner/types/custom_food.{type CustomFood}

// Example usage
pub fn search_foods(
  query: String,
  filters: SearchFilters,
) -> Result(SearchResponse, String) {
  // Search implementation
  todo
}
```

**Modules to import:**
- `types/search` - SearchFilters, SearchResponse, SearchResult
- `types/food` - For Food results
- `types/custom_food` - For CustomFood results

---

### Use Case: User Profiles and Preferences

**Scenario:** Managing user settings and goals

```gleam
import meal_planner/types/user_profile.{
  type UserProfile,
  type DietaryPreference,
  UserProfile,
}
import meal_planner/types/macros.{type Macros}

// Example usage
pub fn get_macro_targets(profile: UserProfile) -> Macros {
  profile.daily_macro_goals
}

pub fn is_vegetarian(profile: UserProfile) -> Bool {
  case profile.dietary_preference {
    Vegetarian -> True
    _ -> False
  }
}
```

**Modules to import:**
- `types/user_profile` - UserProfile, DietaryPreference
- `types/macros` - For macro goals

---

### Use Case: Storage/Database Operations

**Scenario:** Persisting and retrieving data

```gleam
import meal_planner/types/food.{type Food, type DailyLog}
import meal_planner/types/recipe.{type Recipe}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/json
import pog.{type Connection}

// Example usage
pub fn save_daily_log(
  db: Connection,
  log: DailyLog,
) -> Result(Nil, String) {
  log
  |> json.encode_daily_log
  |> store_in_database(db, _)
}

pub fn load_recipes(
  db: Connection,
) -> Result(List(Recipe), String) {
  load_from_database(db)
  |> result.then(list.try_map(_, json.decode_recipe))
}
```

**Modules to import:**
- `types/json` - For all encoding/decoding
- Specific type modules as needed
- `pog` - PostgreSQL driver

---

### Use Case: Scheduler/Automation

**Scenario:** Generating meal plans automatically

```gleam
import meal_planner/types/recipe.{type MealPlanRecipe}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/meal_plan.{type MealPlan, type DailyMacros}
import meal_planner/scheduler/types.{type SchedulerConfig}

// Example usage
pub fn generate_weekly_plan(
  config: SchedulerConfig,
  available_recipes: List(MealPlanRecipe),
  target_macros: DailyMacros,
) -> Result(MealPlan, String) {
  // Generation logic
  todo
}
```

**Modules to import:**
- `types/recipe` - MealPlanRecipe
- `types/macros` - For macro calculations
- `types/meal_plan` - MealPlan, DailyMacros
- `scheduler/types` - Scheduler configuration

---

## Module-Specific Import Patterns

### macros.gleam

```gleam
// Type-only import
import meal_planner/types/macros.{type Macros}

// Type + constructors
import meal_planner/types/macros.{type Macros, Macros}

// Module import for functions
import meal_planner/types/macros

// Common usage
let total = macros.add(meal1_macros, meal2_macros)
let cals = macros.calories(total)
```

**Exported:**
- `type Macros` - Macronutrient type
- `Macros(..)` - Constructor
- `calories()`, `add()`, `subtract()`, `scale()`, `zero()` - Functions

---

### recipe.gleam

```gleam
// Minimal imports
import meal_planner/types/recipe.{type Recipe}

// Full imports
import meal_planner/types/recipe.{
  type Recipe,
  type MealPlanRecipe,
  type Ingredient,
  type FodmapLevel,
  Low,
  Medium,
  High,
}

// Module import for functions
import meal_planner/types/recipe

// Common usage
let is_compliant = recipe.is_vertical_diet_compliant(my_recipe)
let has_chicken = recipe.has_ingredient(my_recipe, "chicken")
```

**Exported:**
- `type Recipe` - Full Tandoor recipe
- `type MealPlanRecipe` - Simplified opaque type
- `type Ingredient` - Recipe ingredient
- `type FodmapLevel` - Low, Medium, High
- `new_meal_plan_recipe()`, `is_vertical_diet_compliant()`, etc.

---

### food.gleam

```gleam
// Common imports
import meal_planner/types/food.{
  type Food,
  type FoodEntry,
  type FoodLogEntry,
  type DailyLog,
}

// With constructors
import meal_planner/types/food.{
  type Food,
  Food,
  type FoodEntry,
  FoodEntry,
}
```

**Exported:**
- `type Food` - FatSecret food item
- `type FoodEntry` - Food with serving size
- `type FoodLogEntry` - Food with timestamp
- `type DailyLog` - Collection of entries

---

### meal_plan.gleam

```gleam
// Standard import
import meal_planner/types/meal_plan.{
  type MealPlan,
  type MealSlot,
  type DayMeals,
  type DailyMacros,
}

// Module import for functions
import meal_planner/types/meal_plan

// Common usage
let plan = meal_plan.get_meal_plan(config, filters)
let meals = meal_plan.get_todays_meals(config)
```

**Exported:**
- `type MealPlan` - Weekly plan
- `type MealSlot` - Single meal
- `type DayMeals` - Day of meals
- `type DailyMacros` - Daily targets
- `get_meal_plan()`, `create_meal()`, `remove_meal()`, etc.

---

### json.gleam

```gleam
// Always use module import
import meal_planner/types/json

// Common usage
let encoded = json.encode_recipe(recipe)
let decoded = json.decode_food(json_string)
```

**Exported:**
- `encode_*()` - Encoders for all types
- `decode_*()` - Decoders for all types

---

## Anti-Patterns to Avoid

### ❌ Don't: Import entire types module
```gleam
// OLD STYLE - Deprecated
import meal_planner/types.{type Macros, type Recipe}
```

### ✅ Do: Import from specific modules
```gleam
// NEW STYLE - Preferred
import meal_planner/types/macros.{type Macros}
import meal_planner/types/recipe.{type Recipe}
```

---

### ❌ Don't: Duplicate type definitions
```gleam
// Creating local type alias
pub type MyMacros = Macros  // Unnecessary indirection
```

### ✅ Do: Use types directly
```gleam
import meal_planner/types/macros.{type Macros}

pub fn process(m: Macros) -> Float {
  macros.calories(m)
}
```

---

### ❌ Don't: Import unused types
```gleam
import meal_planner/types/recipe.{
  type Recipe,
  type MealPlanRecipe,  // Not used in this module
  type Ingredient,      // Not used in this module
}
```

### ✅ Do: Import only what you need
```gleam
import meal_planner/types/recipe.{type Recipe}
```

---

### ❌ Don't: Mix module and type imports confusingly
```gleam
import meal_planner/types/macros.{type Macros, Macros, calories}
import meal_planner/types/macros  // Duplicate!

// Now you have: Macros(..), macros.calories(), and calories()
```

### ✅ Do: Choose one pattern consistently
```gleam
// Option 1: Type import + module import
import meal_planner/types/macros.{type Macros}
import meal_planner/types/macros

let m = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
let cals = macros.calories(m)

// Option 2: Explicit imports (for single-file scripts)
import meal_planner/types/macros.{type Macros, Macros, calories}

let m = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
let cals = calories(m)
```

---

## Import Cheat Sheet

| Type Needed | Import Statement |
|-------------|------------------|
| Macros | `import meal_planner/types/macros.{type Macros}` |
| Macros + functions | Add: `import meal_planner/types/macros` |
| Recipe | `import meal_planner/types/recipe.{type Recipe}` |
| MealPlanRecipe | `import meal_planner/types/recipe.{type MealPlanRecipe}` |
| Food | `import meal_planner/types/food.{type Food}` |
| FoodLogEntry | `import meal_planner/types/food.{type FoodLogEntry}` |
| MealPlan | `import meal_planner/types/meal_plan.{type MealPlan}` |
| Micronutrients | `import meal_planner/types/micronutrients.{type Micronutrients}` |
| CustomFood | `import meal_planner/types/custom_food.{type CustomFood}` |
| JSON utilities | `import meal_planner/types/json` |
| UserProfile | `import meal_planner/types/user_profile.{type UserProfile}` |
| SearchFilters | `import meal_planner/types/search.{type SearchFilters}` |
| Pagination | `import meal_planner/types/pagination.{type Pagination}` |

---

## Migration from Old Import Style

### Before (Deprecated)
```gleam
import meal_planner/types.{
  type Macros,
  type Recipe,
  type Food,
  type MealPlan,
}
```

### After (Current)
```gleam
import meal_planner/types/macros.{type Macros}
import meal_planner/types/recipe.{type Recipe}
import meal_planner/types/food.{type Food}
import meal_planner/types/meal_plan.{type MealPlan}
```

**Benefits of new style:**
- Explicit about which module provides which type
- Easier to trace dependencies
- Better IDE autocomplete
- Clearer code reviews

---

## Common Import Combinations

### Meal Planning Workflow
```gleam
import meal_planner/types/recipe.{type MealPlanRecipe}
import meal_planner/types/meal_plan.{type MealPlan, type DailyMacros}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/macros  // For calculations
```

### Food Logging Workflow
```gleam
import meal_planner/types/food.{type Food, type FoodLogEntry, type DailyLog}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/micronutrients.{type Micronutrients}
import meal_planner/types/json  // For persistence
```

### Nutrition Analysis Workflow
```gleam
import meal_planner/types/macros.{type Macros}
import meal_planner/types/macros  // For operations
import meal_planner/types/nutrition.{type NutritionData, type NutritionGoals}
import meal_planner/types/micronutrients.{type Micronutrients}
```

### API Integration Workflow
```gleam
import meal_planner/types/json  // For all encoding/decoding
import meal_planner/types/pagination.{type Pagination}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
```

---

**Guide Version:** 1.0
**Last Updated:** 2024-12-24
**Maintained By:** Agent-Doc-1 (55/96)
