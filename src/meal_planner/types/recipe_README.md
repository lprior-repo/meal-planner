# Recipe Types Module

**Module:** `meal_planner/types/recipe`

**Purpose:** Recipe types for meal planning - supports both legacy Tandoor recipes and simplified meal planning recipes.

## Overview

This module provides two recipe type systems:

1. **Legacy Recipe System** (Tandoor API)
   - `Ingredient` - Name and quantity
   - `Recipe` - Full recipe with instructions, nutrition, dietary info
   - `FodmapLevel` - Digestive health classification
   - Used for recipe management and food logging

2. **Meal Planning System** (Simplified)
   - `MealPlanRecipe` - Opaque type for meal plan generation
   - Per-serving macros with validation
   - Prep/cook time tracking for scheduling
   - Links to Tandoor via RecipeId

## Public API

### Legacy Types

```gleam
// Types
pub type Ingredient {
  Ingredient(name: String, quantity: String)
}

pub type FodmapLevel {
  Low
  Medium
  High
}

pub type Recipe {
  Recipe(
    id: RecipeId,
    name: String,
    ingredients: List(Ingredient),
    instructions: List(String),
    macros: Macros,
    servings: Int,
    category: String,
    fodmap_level: FodmapLevel,
    vertical_compliant: Bool,
  )
}

// Functions
pub fn is_vertical_diet_compliant(recipe: Recipe) -> Bool
pub fn macros_per_serving(recipe: Recipe) -> Macros
pub fn total_macros(recipe: Recipe) -> Macros
```

### Meal Planning Recipe (Opaque)

```gleam
pub opaque type MealPlanRecipe

// Constructor
pub fn new_meal_plan_recipe(
  id id: RecipeId,
  name name: String,
  servings servings: Int,
  macros macros: Macros,
  image image: Option(String),
  prep_time prep_time: Int,
  cook_time cook_time: Int,
) -> Result(MealPlanRecipe, String)

// Accessors
pub fn recipe_id(recipe: MealPlanRecipe) -> RecipeId
pub fn recipe_name(recipe: MealPlanRecipe) -> String
pub fn recipe_servings(recipe: MealPlanRecipe) -> Int
pub fn recipe_macros_per_serving(recipe: MealPlanRecipe) -> Macros
pub fn recipe_total_macros(recipe: MealPlanRecipe) -> Macros
pub fn recipe_image(recipe: MealPlanRecipe) -> Option(String)
pub fn recipe_prep_time(recipe: MealPlanRecipe) -> Int
pub fn recipe_cook_time(recipe: MealPlanRecipe) -> Int
pub fn recipe_total_time(recipe: MealPlanRecipe) -> Int

// Constraints
pub fn is_quick_prep(recipe: MealPlanRecipe) -> Bool
```

### Serialization

#### Legacy Recipe
```gleam
pub fn ingredient_to_json(i: Ingredient) -> Json
pub fn recipe_to_json(r: Recipe) -> Json
pub fn ingredient_decoder() -> Decoder(Ingredient)
pub fn fodmap_level_decoder() -> Decoder(FodmapLevel)
pub fn recipe_decoder() -> Decoder(Recipe)
```

#### MealPlanRecipe
```gleam
pub fn meal_plan_recipe_to_json(recipe: MealPlanRecipe) -> Json
pub fn meal_plan_recipe_decoder() -> Decoder(MealPlanRecipe)
```

### Display Formatting

#### Legacy Recipe
```gleam
pub fn fodmap_level_to_string(f: FodmapLevel) -> String
pub fn fodmap_level_to_display_string(level: FodmapLevel) -> String
pub fn ingredient_to_display_string(ing: Ingredient) -> String
pub fn ingredient_to_shopping_list_line(ing: Ingredient) -> String
pub fn recipe_to_display_string(recipe: Recipe) -> String
```

#### MealPlanRecipe
```gleam
pub fn to_string(recipe: MealPlanRecipe) -> String
```

## Usage Examples

### Legacy Recipe (from Tandoor)

```gleam
import meal_planner/types/recipe
import meal_planner/types/macros
import meal_planner/id

let ingredient = recipe.Ingredient(name: "Chicken breast", quantity: "2 lbs")

let tandoor_recipe = recipe.Recipe(
  id: id.recipe_id("tandoor-456"),
  name: "Grilled Chicken",
  ingredients: [ingredient],
  instructions: ["Season chicken", "Grill to 165F"],
  macros: macros.new(protein: 40.0, fat: 8.0, carbs: 0.0),
  servings: 2,
  category: "Protein",
  fodmap_level: recipe.Low,
  vertical_compliant: True,
)

// Check dietary compliance
case recipe.is_vertical_diet_compliant(tandoor_recipe) {
  True -> // Meets both vertical_compliant AND Low FODMAP
  False -> // Fails one or both requirements
}

// Get nutrition
let per_serving = recipe.macros_per_serving(tandoor_recipe)
let total = recipe.total_macros(tandoor_recipe)
```

### Meal Planning Recipe (Simplified)

```gleam
import meal_planner/types/recipe
import meal_planner/types/macros
import meal_planner/id
import gleam/option.{Some}

let recipe_result = recipe.new_meal_plan_recipe(
  id: id.recipe_id("tandoor-123"),
  name: "Chicken Stir Fry",
  servings: 4,
  macros: macros.new(protein: 30.0, fat: 12.0, carbs: 45.0),
  image: Some("https://example.com/stir-fry.jpg"),
  prep_time: 15,
  cook_time: 20,
)

case recipe_result {
  Ok(recipe) -> {
    // Access recipe data
    let total_time = recipe.recipe_total_time(recipe)  // 35 minutes
    let is_quick = recipe.is_quick_prep(recipe)        // True (<=15 min prep)

    // Get macros
    let per_serving = recipe.recipe_macros_per_serving(recipe)
    let total = recipe.recipe_total_macros(recipe)

    // Display
    let summary = recipe.to_string(recipe)
    // "Chicken Stir Fry (4 servings, 35 min) - 30g P | 12g F | 45g C per serving"
  }
  Error(msg) -> // Validation failed
}
```

### Quick Prep Filter

```gleam
// Filter recipes for busy mornings
let quick_breakfast_recipes =
  recipes
  |> list.filter(recipe.is_quick_prep)
// Returns only recipes with prep_time <= 15 minutes
```

## Validation Rules

### MealPlanRecipe Constructor

The `new_meal_plan_recipe()` function validates:

1. **Servings > 0**
   - Error: "Recipe servings must be greater than 0, got N"

2. **Prep time >= 0**
   - Error: "Prep time must be >= 0, got N"

3. **Cook time >= 0**
   - Error: "Cook time must be >= 0, got N"

All validations must pass to create a MealPlanRecipe.

### Vertical Diet Compliance

```gleam
is_vertical_diet_compliant(recipe)
```

Returns `True` only when:
- `vertical_compliant == True` AND
- `fodmap_level == Low`

Both conditions must be met.

### Quick Prep Constraint

```gleam
is_quick_prep(recipe)
```

Returns `True` when `prep_time <= 15` minutes.

Used by meal plan generator to filter breakfast options.

## Design Notes

### Two Recipe Systems

**Legacy Recipe** is used for:
- Tandoor API integration
- Recipe browsing and management
- Food logging with full instructions
- Dietary compliance tracking (FODMAP, Vertical Diet)

**MealPlanRecipe** is used for:
- Meal plan generation (NORTH STAR epic)
- Scheduling (prep/cook time constraints)
- Quick macro calculations
- Simplified data model for planning algorithms

### Macros Per Serving

Both recipe types store **macros per serving**, not total macros.

To get total macros, use:
- Legacy: `total_macros(recipe)`
- Meal Plan: `recipe_total_macros(recipe)`

Both scale per-serving macros by servings count.

### Opaque MealPlanRecipe

MealPlanRecipe is opaque to enforce:
- Positive servings count
- Non-negative time values
- Immutability (no direct field access)

Use accessor functions to read fields.

## FODMAP Levels

FODMAP classification for digestive health:

- **Low** - Safe for most people with IBS
- **Medium** - May cause issues for sensitive individuals
- **High** - Likely to trigger digestive discomfort

Used with Vertical Diet compliance for meal filtering.

## Dependencies

- `meal_planner/id` - RecipeId type
- `meal_planner/types/macros` - Macros type and operations
- `gleam/json` - JSON serialization
- `gleam/dynamic/decode` - JSON deserialization
- `gleam/option` - Optional image URL

## Related Modules

- **tandoor/client/recipes** - Fetches Recipe from Tandoor API
- **generator/** - Uses MealPlanRecipe for meal planning
- **types/meal_plan** - Consumes MealPlanRecipe in DayMeals
- **advisor/** - Analyzes recipes for dietary compliance

## File Size

536 lines (target: <500 lines - slightly over, acceptable for dual type system)
