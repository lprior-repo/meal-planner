# Refactoring Examples from meal-planner Codebase

**Generated:** 2024-12-24
**Purpose:** Real-world code examples demonstrating refactoring patterns from this codebase

See [REFACTORING_PATTERNS.md](./REFACTORING_PATTERNS.md) for pattern descriptions and theory.

---

## Table of Contents

1. [Module Split: FatSecret Diary](#1-module-split-fatsecret-diary)
2. [Opaque Type: FoodEntryId](#2-opaque-type-foodentryid)
3. [Error Handling Pipeline](#3-error-handling-pipeline)
4. [Result Pipeline with 'use'](#4-result-pipeline-with-use)
5. [Validation at Construction](#5-validation-at-construction)
6. [PHASE 1 Refactoring: CLI Diary](#6-phase-1-refactoring-cli-diary)

---

## 1. Module Split: FatSecret Diary

### Before: Monolithic Structure
Everything in one file, 500+ lines mixing concerns.

### After: Modular Structure

**File:** `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/`

```
diary/
├── types.gleam       # 312 lines - Types, opaque IDs, validation
├── decoders.gleam    # JSON parsing with dynamic decoders
├── client.gleam      # 406 lines - HTTP API calls
├── service.gleam     # Business logic orchestration
└── mod.gleam         # Public API aggregator (future)
```

### types.gleam - Excerpt
```gleam
/// FatSecret Food Diary types
///
/// These types represent food entries logged in the user's food diary,
/// along with daily and monthly summaries.

import gleam/option.{type Option}

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque food entry ID from FatSecret API
pub opaque type FoodEntryId {
  FoodEntryId(String)
}

pub fn food_entry_id(id: String) -> FoodEntryId {
  FoodEntryId(id)
}

pub fn food_entry_id_to_string(id: FoodEntryId) -> String {
  let FoodEntryId(s) = id
  s
}

// ============================================================================
// Domain Types
// ============================================================================

pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

pub type FoodEntry {
  FoodEntry(
    food_entry_id: FoodEntryId,
    food_entry_name: String,
    food_entry_description: String,
    meal: MealType,
    date_int: Int,
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
    ...
  )
}
```

### client.gleam - Excerpt
```gleam
/// FatSecret SDK Food Diary API client
///
/// 3-legged authenticated API calls for food diary management.

import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type FoodEntryId, type FoodEntryInput,
} as diary_types

pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  let params = case input {
    diary_types.FromFood(food_id, name, serving_id, units, meal, date) ->
      dict.new()
      |> dict.insert("food_id", food_id)
      |> dict.insert("serving_id", serving_id)
      ...
  }

  use body <- result.try(http.make_authenticated_request(
    config, token, "food_entry.create", params,
  ))

  json.parse(body, decode.at(["food_entry_id", "value"], decode.string))
  |> result.map(diary_types.food_entry_id)
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry ID")
  })
}
```

**Benefits Achieved:**
- Types module: 312 lines, no HTTP dependencies
- Client module: 406 lines, focused on API calls
- Easy to mock client for testing service layer
- Clear dependency: types ← client ← service

---

## 2. Opaque Type: FoodEntryId

**File:** `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/types.gleam`

### Full Implementation

```gleam
// ============================================================================
// Food Entry ID (opaque type for type safety)
// ============================================================================

/// Opaque food entry ID from FatSecret API
pub opaque type FoodEntryId {
  FoodEntryId(String)
}

/// Create a FoodEntryId from a string
pub fn food_entry_id(id: String) -> FoodEntryId {
  FoodEntryId(id)
}

/// Convert FoodEntryId to string for API calls
pub fn food_entry_id_to_string(id: FoodEntryId) -> String {
  let FoodEntryId(s) = id
  s
}
```

### Usage Example

```gleam
// Creating an ID (constructor)
let entry_id = diary_types.food_entry_id("12345")

// Using in function signature (type safety)
pub fn delete_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  entry_id: FoodEntryId,  // Can't pass wrong type!
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "food_entry_id",
      diary_types.food_entry_id_to_string(entry_id),  // Convert for API
    )
  ...
}
```

### Prevented Bug Example

```gleam
// Without opaque types (DANGEROUS):
pub fn delete_food_entry(entry_id: String)
pub fn get_recipe(recipe_id: String)

let recipe_id = "tandoor-123"
delete_food_entry(recipe_id)  // BUG! Wrong ID type, compiles anyway

// With opaque types (SAFE):
pub fn delete_food_entry(entry_id: FoodEntryId)
pub fn get_recipe(recipe_id: RecipeId)

let recipe_id = id.recipe_id("tandoor-123")
delete_food_entry(recipe_id)  // COMPILE ERROR! Type mismatch caught
```

---

## 3. Error Handling Pipeline

**Files:**
- `/home/lewis/src/meal-planner/src/meal_planner/shared/error_handlers.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/errors.gleam`

### Centralized Error Handler

```gleam
/// Consolidated Error-to-Response Handler
///
/// This module centralizes all error-to-HTTP-response conversions

import meal_planner/errors.{type AppError}
import meal_planner/fatsecret/core/errors as fatsecret_errors
import meal_planner/tandoor/core/error as tandoor_error

// ============================================================================
// Primary Error-to-Response Conversion
// ============================================================================

/// Convert an AppError to a Wisp HTTP response with JSON body
pub fn app_error_to_response(error: AppError) -> wisp.Response {
  let status = errors.http_status_code(error)
  let body = errors.to_json(error) |> json.to_string
  wisp.json_response(body, status)
}

// ============================================================================
// Tandoor Error Conversion
// ============================================================================

pub fn tandoor_error_to_response(
  error: tandoor_error.TandoorError,
) -> wisp.Response {
  error
  |> errors.from_tandoor_error
  |> app_error_to_response
}

// ============================================================================
// FatSecret Error Conversion
// ============================================================================

pub fn fatsecret_api_error_to_response(
  error: fatsecret_errors.FatSecretError,
) -> wisp.Response {
  error
  |> errors.from_fatsecret_error
  |> app_error_to_response
}

// ============================================================================
// Validation Error Conversion
// ============================================================================

pub fn validation_error_to_response(
  field: String,
  reason: String,
) -> wisp.Response {
  errors.ValidationError(field, reason)
  |> app_error_to_response
}
```

### Handler Usage Example

```gleam
// Before refactoring (DUPLICATE LOGIC EVERYWHERE):
pub fn handle_get_recipe(req: Request) -> Response {
  case tandoor.get_recipe(id) {
    Ok(recipe) -> json_response(recipe, 200)
    Error(NotFoundError(msg)) ->
      json_response(
        json.object([#("error", json.string(msg))]),
        404
      )
    Error(AuthenticationError(msg)) ->
      json_response(
        json.object([#("error", json.string(msg))]),
        401
      )
    Error(NetworkError(msg)) ->
      json_response(
        json.object([#("error", json.string(msg))]),
        502
      )
  }
}

// After refactoring (CLEAN, NO DUPLICATION):
import meal_planner/shared/error_handlers

pub fn handle_get_recipe(req: Request) -> Response {
  case tandoor.get_recipe(id) {
    Ok(recipe) -> json_response(recipe, 200)
    Error(error) ->
      error_handlers.tandoor_error_to_response(error)
  }
}
```

---

## 4. Result Pipeline with 'use'

**File:** `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/client.gleam`

### Real Implementation

```gleam
pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  // Step 1: Prepare request parameters
  let params = case input {
    diary_types.FromFood(
      food_id,
      food_entry_name,
      serving_id,
      number_of_units,
      meal,
      date_int,
    ) -> {
      dict.new()
      |> dict.insert("food_id", food_id)
      |> dict.insert("food_entry_name", food_entry_name)
      |> dict.insert("serving_id", serving_id)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("meal", diary_types.meal_type_to_string(meal))
      |> dict.insert("date_int", int.to_string(date_int))
    }
    diary_types.Custom(
      food_entry_name,
      serving_description,
      number_of_units,
      meal,
      date_int,
      calories,
      carbohydrate,
      protein,
      fat,
    ) -> {
      dict.new()
      |> dict.insert("food_entry_name", food_entry_name)
      |> dict.insert("serving_description", serving_description)
      |> dict.insert("number_of_units", float.to_string(number_of_units))
      |> dict.insert("meal", diary_types.meal_type_to_string(meal))
      |> dict.insert("date_int", int.to_string(date_int))
      |> dict.insert("calories", float.to_string(calories))
      |> dict.insert("carbohydrate", float.to_string(carbohydrate))
      |> dict.insert("protein", float.to_string(protein))
      |> dict.insert("fat", float.to_string(fat))
    }
  }

  // Step 2: Make HTTP request (fails early on network error)
  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "food_entry.create",
    params,
  ))

  // Step 3: Parse response - FatSecret returns {"food_entry_id": {"value": "12345"}}
  json.parse(body, decode.at(["food_entry_id", "value"], decode.string))
  |> result.map(diary_types.food_entry_id)
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry ID from create response")
  })
}
```

### Tandoor Login Example (Complex Flow)

**File:** `/home/lewis/src/meal-planner/src/meal_planner/tandoor/clients/auth.gleam`

```gleam
pub fn login(config: ClientConfig) -> Result(ClientConfig, TandoorError) {
  case config.auth {
    BearerAuth(_) -> Ok(config)
    SessionAuth(username, password, _, _) -> {
      // Step 1: Get login page to extract CSRF token
      let login_url = config.base_url <> "/accounts/login/"

      use login_req <- result.try(case uri.parse(login_url) {
        Ok(parsed) -> {
          // Build request from parsed URI
          ...
          Ok(req_with_port)
        }
        Error(_) -> Error(NetworkError("Failed to parse login URL"))
      })

      use login_page <- result.try(execute_request(login_req))

      // Extract CSRF token from response
      let initial_csrf =
        extract_csrf_from_body(login_page.body)
        |> option.lazy_or(fn() { extract_csrf_from_cookies(login_page.headers) })

      use csrf_token <- result.try(case initial_csrf {
        Some(csrf) -> Ok(csrf)
        None -> Error(AuthenticationError("Could not extract CSRF token"))
      })

      // Step 2: POST login credentials
      let form_body =
        "csrfmiddlewaretoken=" <> uri_encode(csrf_token)
        <> "&login=" <> uri_encode(username)
        <> "&password=" <> uri_encode(password)

      use post_req <- result.try(...)
      use login_resp <- result.try(execute_request(post_req))

      // Step 3: Extract session and CSRF from cookies
      let session_id = extract_session_from_cookies(login_resp.headers)
      let new_csrf = extract_csrf_from_cookies(login_resp.headers)

      case session_id, new_csrf {
        Some(sid), Some(csrf) -> Ok(with_session(config, sid, csrf))
        _, _ -> Error(AuthenticationError("Login failed"))
      }
    }
  }
}
```

**Flow:**
1. Parse URL → early return on error
2. Execute GET request → early return on network error
3. Extract CSRF → early return if not found
4. Build POST request → early return on error
5. Execute POST → early return on network error
6. Extract session cookies → return new config

No deeply nested case expressions, flat and readable.

---

## 5. Validation at Construction

**File:** `/home/lewis/src/meal-planner/src/meal_planner/types/recipe.gleam`

### MealPlanRecipe with Validation

```gleam
/// Simplified recipe for meal planning with nutrition per serving.
///
/// Opaque type that wraps Tandoor recipe data with per-serving macros.
///
/// ## Key Properties
/// - Macros are PER SERVING (not total)
/// - Servings must be > 0
/// - Prep/cook time must be >= 0
pub opaque type MealPlanRecipe {
  MealPlanRecipe(
    id: RecipeId,
    name: String,
    servings: Int,
    macros: Macros,
    image: Option(String),
    prep_time: Int,
    cook_time: Int,
  )
}

/// Constructor for MealPlanRecipe with validation.
///
/// Creates a MealPlanRecipe with validation for:
/// - Servings > 0
/// - Prep time >= 0
/// - Cook time >= 0
///
/// Returns:
/// - Ok(MealPlanRecipe) if all validations pass
/// - Error(String) with descriptive message if validation fails
pub fn new_meal_plan_recipe(
  id id: RecipeId,
  name name: String,
  servings servings: Int,
  macros macros: Macros,
  image image: Option(String),
  prep_time prep_time: Int,
  cook_time cook_time: Int,
) -> Result(MealPlanRecipe, String) {
  // Validate servings > 0
  case servings > 0 {
    False ->
      Error(
        "Recipe servings must be greater than 0, got "
        <> int.to_string(servings),
      )
    True -> {
      // Validate prep_time >= 0
      case prep_time >= 0 {
        False ->
          Error("Prep time must be >= 0, got " <> int.to_string(prep_time))
        True -> {
          // Validate cook_time >= 0
          case cook_time >= 0 {
            False ->
              Error("Cook time must be >= 0, got " <> int.to_string(cook_time))
            True ->
              Ok(MealPlanRecipe(
                id: id,
                name: name,
                servings: servings,
                macros: macros,
                image: image,
                prep_time: prep_time,
                cook_time: cook_time,
              ))
          }
        }
      }
    }
  }
}

/// Get total time (prep + cook).
///
/// No validation needed - data is guaranteed valid at construction.
pub fn recipe_total_time(recipe: MealPlanRecipe) -> Int {
  recipe.prep_time + recipe.cook_time
}
```

### Validation Functions (types.gleam)

**File:** `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/types.gleam`

```gleam
/// Validate custom food entry data
///
/// Ensures all nutrition values are valid (allows zero for things like water).
/// Checks that names are not empty and serving descriptions are present.
///
/// Returns Ok(Nil) if valid, Error(String) with validation message otherwise.
pub fn validate_custom_entry(
  food_entry_name food_entry_name: String,
  serving_description serving_description: String,
  number_of_units number_of_units: Float,
  calories calories: Float,
  carbohydrate carbohydrate: Float,
  protein protein: Float,
  fat fat: Float,
) -> Result(Nil, String) {
  // Validate name is not empty
  case food_entry_name {
    "" -> Error("food_entry_name cannot be empty")
    _ -> {
      // Validate serving description is not empty
      case serving_description {
        "" -> Error("serving_description cannot be empty")
        _ -> {
          // Validate number of units
          case validate_number_of_units(number_of_units) {
            Error(e) -> Error(e)
            Ok(_) -> {
              // Validate nutrition values are non-negative (zero is allowed)
              case
                calories <. 0.0
                || carbohydrate <. 0.0
                || protein <. 0.0
                || fat <. 0.0
              {
                True -> Error("Nutrition values cannot be negative")
                False -> Ok(Nil)
              }
            }
          }
        }
      }
    }
  }
}
```

---

## 6. PHASE 1 Refactoring: CLI Diary

### Commit Details
- **Commit:** `6bd189f4` - "fix: Complete PHASE 1 diary refactoring"
- **Date:** Wed Dec 24 22:59:55 2025
- **Changes:** 6 files changed, 97 insertions(+), 294 deletions(-)

### Before

**File:** `src/meal_planner/cli/domains/diary.gleam` (267 lines, DELETED)
- Mixed types, formatting, helpers, and commands in one file
- Difficult to test individual components
- Unclear dependencies

### After

**New Structure:**
```
cli/domains/diary/
├── types.gleam          # Domain types: DayNutrition, calculations
├── formatters.gleam     # Display formatting: format_food_entry_row, etc.
├── helpers.gleam        # Utilities: parse_date_to_int, DB connections
├── commands/
│   ├── view.gleam       # View diary command
│   ├── add.gleam        # Add entry command
│   ├── delete.gleam     # Delete entry command
│   └── sync.gleam       # Sync command
└── mod.gleam            # Command registration
```

### Files Changed

```
 src/meal_planner/cli/domains/diary.gleam  | 267 ------------------------------
 src/meal_planner/cli/glint_commands.gleam |   2 +-
 src/meal_planner/generator/weekly.gleam   |  13 +-
 test/cli/diary_test.gleam                 |  38 +++--
```

### Commit Message (Pattern Example)
```
fix: Complete PHASE 1 diary refactoring - finalize modular structure

PHASE 1 COMPLETION: Refactored cli/domains/diary from monolithic structure
to fully modular architecture. This resolves all diary-related compilation
issues and enables independent testing of diary functionality.

Changes:
- Delete legacy diary.gleam (267 lines of duplicates)
- Update glint_commands.gleam import to use new diary/mod.gleam structure
- Update diary_test.gleam to import from refactored submodules
- Fix generator/weekly.gleam imports to use split types modules

Module Structure (NEW):
├── cli/domains/diary/
│   ├── types.gleam (DayNutrition, calculate_day_nutrition)
│   ├── formatters.gleam (format_food_entry_row, format_nutrition_summary)
│   ├── helpers.gleam (parse_date_to_int, db connection utilities)
│   ├── commands/
│   │   ├── view.gleam
│   │   ├── add.gleam
│   │   ├── delete.gleam
│   │   └── sync.gleam
│   └── mod.gleam (command registration)

Build Status: Compiles successfully
```

### Results
- **Before:** 1 file, 267 lines, mixed concerns
- **After:** 8+ files, <100 lines each, clear separation
- **Benefit:** Multiple developers/agents can work on different commands simultaneously
- **Testing:** Each component can be tested in isolation

---

## Summary

These examples demonstrate real refactoring patterns applied to a production Gleam codebase:

1. **Module Split:** From 267-line monolith to focused <100-line modules
2. **Opaque Types:** Type-safe IDs prevent mixing FoodEntryId with RecipeId
3. **Error Handling:** Single error_handlers module eliminates duplication
4. **Result Pipelines:** `use` keyword flattens nested case expressions
5. **Validation:** Construction-time validation guarantees data integrity
6. **3-Phase Strategy:** Systematic refactoring maintains working code

All patterns work together to create a maintainable, testable, scalable codebase.
