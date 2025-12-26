# Tandoor Recipe Client

**Module:** `meal_planner/tandoor/client/recipes`

**Purpose:** Recipe operations for the Tandoor API - fetching, creating, and deleting recipes.

## Overview

Handles all recipe-related Tandoor API operations with comprehensive type definitions for:
- Recipe listing and detail fetching
- Recipe creation and deletion
- Complete recipe structure (Steps, Ingredients, Units, Foods, Nutrition)
- JSON encoding/decoding for all recipe components

## Public API

### Recipe Types

```gleam
// Core recipe types
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    // ... additional fields
  )
}

pub type RecipeDetail {
  RecipeDetail(
    id: Int,
    name: String,
    description: String,
    steps: List(Step),
    nutrition: Option(NutritionInfo),
    servings: Int,
    working_time: Int,
    waiting_time: Int,
    // ... additional fields
  )
}

pub type Step {
  Step(
    id: Int,
    name: String,
    instruction: String,
    ingredients: List(Ingredient),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
  )
}

pub type Ingredient {
  Ingredient(
    id: Int,
    food: Option(Food),
    unit: Option(Unit),
    amount: Float,
    note: String,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

pub type Unit {
  Unit(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
  )
}

pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    supermarket_category: Option(SupermarketCategory),
  )
}

pub type NutritionInfo {
  NutritionInfo(
    id: Int,
    carbohydrates: Float,
    fats: Float,
    proteins: Float,
    calories: Float,
    source: String,
  )
}
```

### Recipe Operations

```gleam
// Fetch recipes (paginated)
pub fn list_recipes(
  config: ClientConfig,
  page: Int,
  page_size: Int,
) -> Result(List(Recipe), TandoorError)

// Fetch single recipe detail
pub fn get_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(RecipeDetail, TandoorError)

// Create new recipe
pub fn create_recipe(
  config: ClientConfig,
  recipe: RecipeDetail,
) -> Result(RecipeDetail, TandoorError)

// Delete recipe
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError)
```

### JSON Decoders

```gleam
pub fn recipe_decoder() -> Decoder(Recipe)
pub fn recipe_detail_decoder() -> Decoder(RecipeDetail)
pub fn step_decoder() -> Decoder(Step)
pub fn ingredient_decoder() -> Decoder(Ingredient)
pub fn unit_decoder() -> Decoder(Unit)
pub fn food_decoder() -> Decoder(Food)
pub fn nutrition_info_decoder() -> Decoder(NutritionInfo)
```

### JSON Encoders

```gleam
pub fn recipe_to_json(r: Recipe) -> Json
pub fn recipe_detail_to_json(r: RecipeDetail) -> Json
pub fn step_to_json(s: Step) -> Json
pub fn ingredient_to_json(i: Ingredient) -> Json
// ... (encoders for all types)
```

## Usage Examples

### List Recipes

```gleam
import meal_planner/tandoor/client/mod
import meal_planner/tandoor/client/recipes

let config = mod.session_config(
  base_url: "http://localhost:8000",
  username: "user",
  password: "pass",
)

case recipes.list_recipes(config, page: 1, page_size: 20) {
  Ok(recipe_list) -> {
    // Process recipes
    recipe_list
    |> list.each(fn(r) {
      io.println("Recipe: " <> r.name)
    })
  }
  Error(error) -> {
    let msg = mod.error_to_string(error)
    io.println("Failed to list recipes: " <> msg)
  }
}
```

### Get Recipe Detail

```gleam
case recipes.get_recipe(config, recipe_id: 123) {
  Ok(detail) -> {
    io.println("Recipe: " <> detail.name)
    io.println("Servings: " <> int.to_string(detail.servings))

    // Process steps
    detail.steps
    |> list.each(fn(step) {
      io.println("Step " <> int.to_string(step.order) <> ": " <> step.instruction)

      // Process ingredients in step
      step.ingredients
      |> list.each(fn(ing) {
        case ing.food {
          Some(food) -> io.println("  - " <> food.name)
          None -> Nil
        }
      })
    })

    // Check nutrition
    case detail.nutrition {
      Some(nutr) -> {
        io.println("Calories: " <> float.to_string(nutr.calories))
        io.println("Protein: " <> float.to_string(nutr.proteins))
      }
      None -> io.println("No nutrition info")
    }
  }
  Error(mod.NotFoundError(resource)) -> {
    io.println("Recipe not found: " <> resource)
  }
  Error(error) -> {
    io.println("Error: " <> mod.error_to_string(error))
  }
}
```

### Create Recipe

```gleam
let new_recipe = recipes.RecipeDetail(
  id: 0,  // Will be assigned by server
  name: "Grilled Chicken",
  description: "Simple grilled chicken breast",
  steps: [
    recipes.Step(
      id: 0,
      name: "Prepare",
      instruction: "Season chicken with salt and pepper",
      ingredients: [
        recipes.Ingredient(
          id: 0,
          food: Some(recipes.Food(
            id: 456,
            name: "Chicken breast",
            plural_name: None,
            description: "",
            supermarket_category: None,
          )),
          unit: Some(recipes.Unit(
            id: 789,
            name: "lb",
            plural_name: Some("lbs"),
            description: "pounds",
          )),
          amount: 1.0,
          note: "",
          is_header: False,
          no_amount: False,
          original_text: None,
        ),
      ],
      time: 5,
      order: 1,
      show_as_header: False,
      show_ingredients_table: True,
    ),
  ],
  nutrition: Some(recipes.NutritionInfo(
    id: 0,
    carbohydrates: 0.0,
    fats: 3.0,
    proteins: 30.0,
    calories: 140.0,
    source: "USDA",
  )),
  servings: 2,
  working_time: 5,
  waiting_time: 15,
  // ... other fields
)

case recipes.create_recipe(config, new_recipe) {
  Ok(created) -> {
    io.println("Created recipe with ID: " <> int.to_string(created.id))
  }
  Error(error) -> {
    io.println("Failed to create: " <> mod.error_to_string(error))
  }
}
```

### Delete Recipe

```gleam
case recipes.delete_recipe(config, recipe_id: 123) {
  Ok(_) -> io.println("Recipe deleted")
  Error(mod.NotFoundError(_)) -> io.println("Recipe not found")
  Error(mod.AuthorizationError(_)) -> io.println("Not authorized to delete")
  Error(error) -> io.println("Error: " <> mod.error_to_string(error))
}
```

## Recipe Structure

### Recipe vs RecipeDetail

- **Recipe** - Lightweight list view with basic fields (id, name, description, servings)
- **RecipeDetail** - Complete recipe with steps, ingredients, nutrition, instructions

Use `list_recipes()` for browsing, `get_recipe()` for full details.

### Steps and Ingredients

Recipes are organized as:
- **RecipeDetail** contains list of **Steps**
- Each **Step** contains list of **Ingredients**
- Each **Ingredient** references optional **Food** and **Unit**

This matches Tandoor's data model where ingredients are nested within steps.

### Optional Fields

Many fields are `Option(T)`:
- `description` - Not all recipes have descriptions
- `nutrition` - Nutrition may not be calculated
- `food` - Ingredients may be headers or free text
- `unit` - Some ingredients don't have units (e.g., "to taste")

Always handle `None` case when accessing optional fields.

## Nutrition Info

NutritionInfo provides per-serving macros:
- **carbohydrates** - Carbs in grams
- **fats** - Fat in grams
- **proteins** - Protein in grams
- **calories** - Total calories
- **source** - Where nutrition data came from (e.g., "USDA", "Manual")

Convert to meal_planner/types/macros:
```gleam
let macros = macros.Macros(
  protein: nutrition.proteins,
  fat: nutrition.fats,
  carbs: nutrition.carbohydrates,
)
```

## Error Handling

Common errors:
- **NotFoundError** - Recipe doesn't exist (404)
- **AuthenticationError** - Not logged in (401)
- **AuthorizationError** - No permission to access recipe (403)
- **ParseError** - Invalid JSON response from server
- **NetworkError** - Connection issues
- **TimeoutError** - Request took too long

Always handle at least NotFoundError for get/delete operations.

## Dependencies

- `meal_planner/tandoor/client/mod` - ClientConfig, TandoorError
- `meal_planner/tandoor/client/http` - HTTP request execution
- `gleam/json` - JSON encoding
- `gleam/dynamic/decode` - JSON decoding
- `gleam/option` - Optional fields

## Related Modules

- **types/recipe** - meal_planner Recipe type (different from Tandoor's)
- **tandoor/client/mealplan** - Meal planning operations
- **tandoor/client/foods** - Food/ingredient management

## Design Notes

### Tandoor API Types

This module defines Tandoor-specific types (Recipe, RecipeDetail, Step, etc) that match Tandoor's API schema. These are different from `meal_planner/types/recipe` types.

When integrating with meal planner, convert between:
- `tandoor/client/recipes.RecipeDetail` → `types/recipe.MealPlanRecipe`

### Public Types

All recipe types are public (not opaque) to allow:
- Direct construction for create operations
- Pattern matching for data extraction
- Easy testing and mocking

### ID Assignment

When creating recipes, set `id: 0` in all nested objects. Tandoor assigns IDs on creation and returns them in the response.

## File Size

~600 lines (slightly over 500-line target, acceptable for comprehensive API client with full type definitions)
