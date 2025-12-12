# Tandoor API Implementation Guide

## Introduction

This guide provides practical examples and code patterns for implementing Tandoor API integration based on the differences documented in `API_DIFFERENCES.md`. It serves as a reference for developers implementing the Tandoor client and converters.

## Table of Contents

1. [Setup & Configuration](#setup--configuration)
2. [HTTP Client Implementation](#http-client-implementation)
3. [Type Definitions](#type-definitions)
4. [Conversion & Mapping](#conversion--mapping)
5. [Common Patterns](#common-patterns)
6. [Error Handling](#error-handling)
7. [Testing](#testing)

---

## Setup & Configuration

### Environment Variables

Add these to your `.env` file:

```bash
# Tandoor Configuration
TANDOOR_BASE_URL=http://localhost:8000
TANDOOR_API_TOKEN=your-api-token-here

# Optional: timeout and retry settings
TANDOOR_TIMEOUT_MS=30000
TANDOOR_MAX_RETRIES=3
```

### Config Module Integration

```gleam
// config.gleam - ensure Tandoor settings are loaded
pub type Config {
  Config(
    tandoor_base_url: String,
    tandoor_api_token: String,
    tandoor_timeout_ms: Int,
    tandoor_max_retries: Int,
  )
}

pub fn from_env() -> Result(Config, String) {
  use base_url <- result.try(
    env.get("TANDOOR_BASE_URL")
    |> result.replace_error("TANDOOR_BASE_URL not set")
  )
  use api_token <- result.try(
    env.get("TANDOOR_API_TOKEN")
    |> result.replace_error("TANDOOR_API_TOKEN not set")
  )

  let timeout =
    env.get("TANDOOR_TIMEOUT_MS")
    |> result.unwrap("30000")
    |> int.parse
    |> result.unwrap(30000)

  let max_retries =
    env.get("TANDOOR_MAX_RETRIES")
    |> result.unwrap("3")
    |> int.parse
    |> result.unwrap(3)

  Ok(Config(
    tandoor_base_url: base_url,
    tandoor_api_token: api_token,
    tandoor_timeout_ms: timeout,
    tandoor_max_retries: max_retries,
  ))
}
```

---

## HTTP Client Implementation

### Basic Client Structure

```gleam
// tandoor/client.gleam
import gleam/http
import gleam/httpc
import gleam/json
import gleam/result

pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(TandoorRecipe),
  )
}

pub fn get_recipes(
  config: Config,
  limit: Int,
  offset: Int,
) -> Result(RecipeListResponse, Error) {
  let url =
    config.tandoor_base_url
    <> "/api/recipes/?limit="
    <> int.to_string(limit)
    <> "&offset="
    <> int.to_string(offset)

  use response <- result.try(
    make_request(config, "GET", url, "")
  )

  parse_recipe_list_response(response.body)
}

pub fn get_recipe_by_id(
  config: Config,
  recipe_id: Int,
) -> Result(TandoorRecipe, Error) {
  let url =
    config.tandoor_base_url
    <> "/api/recipes/"
    <> int.to_string(recipe_id)
    <> "/"

  use response <- result.try(
    make_request(config, "GET", url, "")
  )

  parse_recipe(response.body)
}

fn make_request(
  config: Config,
  method: String,
  url: String,
  body: String,
) -> Result(http.Response(String), Error) {
  let headers = [
    #("Authorization", "Bearer " <> config.tandoor_api_token),
    #("Content-Type", "application/json"),
    #("Accept", "application/json"),
  ]

  case method {
    "GET" ->
      httpc.get(url)
      |> httpc.header_append("Authorization", "Bearer " <> config.tandoor_api_token)
      |> httpc.header_append("Accept", "application/json")
      |> httpc.send

    "POST" ->
      httpc.post(url, body)
      |> httpc.header_append("Authorization", "Bearer " <> config.tandoor_api_token)
      |> httpc.header_append("Content-Type", "application/json")
      |> httpc.header_append("Accept", "application/json")
      |> httpc.send

    _ ->
      Error(UnsupportedMethod(method))
  }
}
```

### Pagination Helper

```gleam
// tandoor/pagination.gleam
pub type Pagination {
  Pagination(
    count: Int,           // Total count of items
    next: Option(String), // URL to next page
    previous: Option(String), // URL to previous page
  )
}

// Fetch all recipes with automatic pagination
pub fn fetch_all_recipes(
  config: Config,
  callback: fn(List(TandoorRecipe)) -> Nil,
) -> Result(List(TandoorRecipe), Error) {
  let mut all_recipes = []
  let mut url = Some(config.tandoor_base_url <> "/api/recipes/?limit=50")

  // Use while loop pattern with result
  let result = loop(config, url, all_recipes, callback)

  result
}

fn loop(
  config: Config,
  url: Option(String),
  acc: List(TandoorRecipe),
  callback: fn(List(TandoorRecipe)) -> Nil,
) -> Result(List(TandoorRecipe), Error) {
  case url {
    None -> Ok(acc)
    Some(full_url) -> {
      use response <- result.try(
        fetch_page(config, full_url)
      )

      callback(response.results)

      loop(config, response.next, list.append(acc, response.results), callback)
    }
  }
}

fn fetch_page(config: Config, url: String) -> Result(RecipeListResponse, Error) {
  use response <- result.try(
    make_request(config, "GET", url, "")
  )

  parse_recipe_list_response(response.body)
}
```

---

## Type Definitions

### Tandoor API Types

```gleam
// tandoor/types.gleam

pub type TandoorRecipe {
  TandoorRecipe(
    id: Int,
    name: String,
    description: String,
    servings: Int,
    servings_text: String,
    prep_time: Int,      // Minutes
    cooking_time: Int,   // Minutes
    ingredients: List(TandoorIngredient),
    steps: List(TandoorStep),
    nutrition: Option(TandoorNutrition),
    keywords: List(TandoorKeyword),
    image: Option(String),
    internal_id: Option(String),
    created_at: String,
    updated_at: String,
  )
}

pub type TandoorIngredient {
  TandoorIngredient(
    id: Int,
    food: TandoorFood,
    unit: TandoorUnit,
    amount: Float,
    note: String,
  )
}

pub type TandoorFood {
  TandoorFood(
    id: Int,
    name: String,
  )
}

pub type TandoorUnit {
  TandoorUnit(
    id: Int,
    name: String,
    abbreviation: String,
  )
}

pub type TandoorStep {
  TandoorStep(
    id: Int,
    name: String,
    instructions: String,
    time: Int,  // Minutes
  )
}

pub type TandoorNutrition {
  TandoorNutrition(
    calories: Float,
    carbs: Float,
    protein: Float,
    fats: Float,
    fiber: Float,
    sugars: Option(Float),
    sodium: Option(Float),
  )
}

pub type TandoorKeyword {
  TandoorKeyword(
    id: Int,
    name: String,
  )
}

pub type TandoorRecipeCreateRequest {
  TandoorRecipeCreateRequest(
    name: String,
    description: String,
    servings: Int,
    servings_text: String,
    prep_time: Int,
    cooking_time: Int,
    ingredients: List(TandoorIngredientCreateRequest),
    steps: List(TandoorStepCreateRequest),
  )
}

pub type TandoorIngredientCreateRequest {
  TandoorIngredientCreateRequest(
    food: TandoorFoodCreateRequest,
    unit: TandoorUnitCreateRequest,
    amount: Float,
    note: String,
  )
}

pub type TandoorFoodCreateRequest {
  TandoorFoodCreateRequest(
    name: String,
  )
}

pub type TandoorUnitCreateRequest {
  TandoorUnitCreateRequest(
    name: String,
  )
}

pub type TandoorStepCreateRequest {
  TandoorStepCreateRequest(
    name: String,
    instructions: String,
    time: Option(Int),
  )
}
```

### Internal Recipe Types

```gleam
// meal_planner/types.gleam

pub type Recipe {
  Recipe(
    id: String,
    name: String,
    description: String,
    servings: Int,
    prep_time_minutes: Int,
    cooking_time_minutes: Int,
    ingredients: List(Ingredient),
    steps: List(Step),
    nutrition: Option(Macros),
    tags: List(String),
    image_url: Option(String),
  )
}

pub type Ingredient {
  Ingredient(
    food_name: String,
    amount: Float,
    unit: String,
    note: String,
  )
}

pub type Step {
  Step(
    name: String,
    instructions: String,
    time_minutes: Int,
  )
}

pub type Macros {
  Macros(
    calories: Float,
    carbs: Float,
    protein: Float,
    fat: Float,
  )
}
```

---

## Conversion & Mapping

### Tandoor → Internal Conversion

```gleam
// tandoor/mapper.gleam
import gleam/list
import gleam/option

pub fn tandoor_to_recipe(tandoor: TandoorRecipe) -> Recipe {
  Recipe(
    id: int.to_string(tandoor.id),
    name: tandoor.name,
    description: tandoor.description,
    servings: tandoor.servings,
    prep_time_minutes: tandoor.prep_time,
    cooking_time_minutes: tandoor.cooking_time,
    ingredients: list.map(
      tandoor.ingredients,
      tandoor_ingredient_to_ingredient,
    ),
    steps: list.map(tandoor.steps, tandoor_step_to_step),
    nutrition: option.map(
      tandoor.nutrition,
      tandoor_nutrition_to_macros,
    ),
    tags: list.map(tandoor.keywords, fn(k) { k.name }),
    image_url: tandoor.image,
  )
}

fn tandoor_ingredient_to_ingredient(
  ingredient: TandoorIngredient,
) -> Ingredient {
  Ingredient(
    food_name: ingredient.food.name,
    amount: ingredient.amount,
    unit: ingredient.unit.abbreviation,
    note: ingredient.note,
  )
}

fn tandoor_step_to_step(step: TandoorStep) -> Step {
  Step(
    name: step.name,
    instructions: step.instructions,
    time_minutes: step.time,
  )
}

fn tandoor_nutrition_to_macros(nut: TandoorNutrition) -> Macros {
  Macros(
    calories: nut.calories,
    carbs: nut.carbs,
    protein: nut.protein,
    fat: nut.fats,
  )
}
```

### Internal → Tandoor Conversion

```gleam
// tandoor/mapper.gleam (continued)

pub fn recipe_to_tandoor_create_request(recipe: Recipe) -> TandoorRecipeCreateRequest {
  TandoorRecipeCreateRequest(
    name: recipe.name,
    description: recipe.description,
    servings: recipe.servings,
    servings_text: int.to_string(recipe.servings),
    prep_time: recipe.prep_time_minutes,
    cooking_time: recipe.cooking_time_minutes,
    ingredients: list.map(
      recipe.ingredients,
      ingredient_to_tandoor_ingredient_request,
    ),
    steps: list.map(
      recipe.steps,
      step_to_tandoor_step_request,
    ),
  )
}

fn ingredient_to_tandoor_ingredient_request(
  ingredient: Ingredient,
) -> TandoorIngredientCreateRequest {
  TandoorIngredientCreateRequest(
    food: TandoorFoodCreateRequest(name: ingredient.food_name),
    unit: TandoorUnitCreateRequest(name: ingredient.unit),
    amount: ingredient.amount,
    note: ingredient.note,
  )
}

fn step_to_tandoor_step_request(step: Step) -> TandoorStepCreateRequest {
  TandoorStepCreateRequest(
    name: step.name,
    instructions: step.instructions,
    time: case step.time_minutes {
      0 -> None
      t -> Some(t)
    },
  )
}
```

### JSON Parsing

```gleam
// tandoor/decoder.gleam
import gleam/json

pub fn decode_recipe(json_str: String) -> Result(TandoorRecipe, json.DecodeError) {
  json.decode(json_str, recipe_decoder())
}

pub fn decode_recipe_list(
  json_str: String,
) -> Result(RecipeListResponse, json.DecodeError) {
  json.decode(json_str, recipe_list_decoder())
}

fn recipe_decoder() -> json.Decoder(TandoorRecipe) {
  json.decode9(
    TandoorRecipe,
    json.field("id", json.int),
    json.field("name", json.string),
    json.field("description", json.string),
    json.field("servings", json.int),
    json.field("servings_text", json.string),
    json.field("prep_time", json.int),
    json.field("cooking_time", json.int),
    json.field("ingredients", json.list(ingredient_decoder())),
    json.field("steps", json.list(step_decoder())),
    // ... additional fields
  )
}

fn ingredient_decoder() -> json.Decoder(TandoorIngredient) {
  json.decode5(
    TandoorIngredient,
    json.field("id", json.int),
    json.field("food", food_decoder()),
    json.field("unit", unit_decoder()),
    json.field("amount", json.float),
    json.field("note", json.string),
  )
}

fn nutrition_decoder() -> json.Decoder(TandoorNutrition) {
  json.decode7(
    TandoorNutrition,
    json.field("calories", json.float),
    json.field("carbs", json.float),
    json.field("protein", json.float),
    json.field("fats", json.float),
    json.field("fiber", json.float),
    json.optional_field("sugars", json.float),
    json.optional_field("sodium", json.float),
  )
}
```

### JSON Encoding

```gleam
// tandoor/encoder.gleam
import gleam/json

pub fn encode_recipe_create_request(
  req: TandoorRecipeCreateRequest,
) -> String {
  json.object([
    #("name", json.string(req.name)),
    #("description", json.string(req.description)),
    #("servings", json.int(req.servings)),
    #("servings_text", json.string(req.servings_text)),
    #("prep_time", json.int(req.prep_time)),
    #("cooking_time", json.int(req.cooking_time)),
    #("ingredients", json.array(
      req.ingredients,
      encode_ingredient_create_request,
    )),
    #("steps", json.array(
      req.steps,
      encode_step_create_request,
    )),
  ])
  |> json.to_string
}

fn encode_ingredient_create_request(
  ingredient: TandoorIngredientCreateRequest,
) -> json.Json {
  json.object([
    #("food", json.object([
      #("name", json.string(ingredient.food.name)),
    ])),
    #("unit", json.object([
      #("name", json.string(ingredient.unit.name)),
    ])),
    #("amount", json.float(ingredient.amount)),
    #("note", json.string(ingredient.note)),
  ])
}
```

---

## Common Patterns

### Pattern 1: Fetch Recipe and Convert

```gleam
pub fn get_recipe_as_internal(
  config: Config,
  recipe_id: Int,
) -> Result(Recipe, Error) {
  use tandoor_recipe <- result.try(
    get_recipe_by_id(config, recipe_id)
  )

  Ok(mapper.tandoor_to_recipe(tandoor_recipe))
}
```

### Pattern 2: Create Recipe from Internal Format

```gleam
pub fn create_recipe_from_internal(
  config: Config,
  recipe: Recipe,
) -> Result(Recipe, Error) {
  let create_req = mapper.recipe_to_tandoor_create_request(recipe)

  use response <- result.try(
    create_recipe(config, create_req)
  )

  Ok(mapper.tandoor_to_recipe(response))
}
```

### Pattern 3: Fetch All with Progress Tracking

```gleam
pub fn fetch_and_process_all_recipes(
  config: Config,
  process_fn: fn(Recipe) -> Nil,
) -> Result(Int, Error) {
  use recipes <- result.try(
    fetch_all_recipes(config)
  )

  let count = list.length(recipes)

  list.each(recipes, fn(recipe) {
    process_fn(mapper.tandoor_to_recipe(recipe))
  })

  Ok(count)
}
```

---

## Error Handling

### Error Types

```gleam
pub type Error {
  // Network errors
  NetworkError(String)
  ConnectionTimeout

  // HTTP errors
  HttpError(status_code: Int, body: String)
  Unauthorized
  NotFound

  // Parsing errors
  JsonParseError(String)
  InvalidRecipeFormat(String)

  // Business logic errors
  RecipeNotFound
  CreationFailed(String)
}
```

### Error Recovery Pattern

```gleam
pub fn get_recipe_with_fallback(
  config: Config,
  recipe_id: Int,
  fallback: fn() -> Result(Recipe, Error),
) -> Result(Recipe, Error) {
  case get_recipe_by_id(config, recipe_id) {
    Ok(tandoor_recipe) ->
      Ok(mapper.tandoor_to_recipe(tandoor_recipe))

    Error(NotFound) ->
      fallback()

    Error(ConnectionTimeout) ->
      fallback()

    Error(other) ->
      Error(other)
  }
}
```

---

## Testing

### Mock Tandoor Responses

```gleam
// test/tandoor_mock.gleam

pub fn mock_recipe() -> TandoorRecipe {
  TandoorRecipe(
    id: 42,
    name: "Pan Seared Salmon",
    description: "Quick salmon recipe",
    servings: 2,
    servings_text: "2",
    prep_time: 10,
    cooking_time: 15,
    ingredients: [
      TandoorIngredient(
        id: 1,
        food: TandoorFood(id: 10, name: "Salmon fillet"),
        unit: TandoorUnit(id: 15, name: "grams", abbreviation: "g"),
        amount: 200.0,
        note: "Skin removed",
      ),
    ],
    steps: [
      TandoorStep(
        id: 1,
        name: "Prepare",
        instructions: "Pat salmon dry",
        time: 5,
      ),
    ],
    nutrition: Some(TandoorNutrition(
      calories: 320.0,
      carbs: 0.0,
      protein: 35.0,
      fats: 18.0,
      fiber: 0.0,
      sugars: None,
      sodium: None,
    )),
    keywords: [TandoorKeyword(id: 1, name: "quick")],
    image: Some("https://..."),
    internal_id: Some("abc-123"),
    created_at: "2025-01-01T10:00:00Z",
    updated_at: "2025-01-01T10:00:00Z",
  )
}

pub fn mock_recipe_json() -> String {
  // Valid JSON representation of mock_recipe
  "{ \"id\": 42, ... }"
}
```

### Test Conversion

```gleam
// test/tandoor_mapper_test.gleam

pub fn tandoor_to_recipe_test() {
  let tandoor = mock_recipe()
  let recipe = mapper.tandoor_to_recipe(tandoor)

  assert recipe.id == "42"
  assert recipe.name == "Pan Seared Salmon"
  assert recipe.servings == 2
  assert recipe.prep_time_minutes == 10
  assert recipe.cooking_time_minutes == 15

  // Check ingredients converted
  assert list.length(recipe.ingredients) == 1
  let first_ingredient = list.first(recipe.ingredients)
  assert first_ingredient.food_name == "Salmon fillet"
  assert first_ingredient.amount == 200.0
  assert first_ingredient.unit == "g"

  // Check nutrition converted
  let nutrition = option.unwrap(recipe.nutrition)
  assert nutrition.calories == 320.0
  assert nutrition.protein == 35.0
}
```

---

## Related Documents

- [API Differences: Mealie vs Tandoor](./API_DIFFERENCES.md)
- [Design: Mealie to Tandoor Migration](../openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/design.md)

---

**Document Status**: Complete - meal-planner-gipe
**Last Updated**: December 12, 2025
**Author**: Claude Code Agent
