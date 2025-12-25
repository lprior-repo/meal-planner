# Refactoring Patterns Library

**Project:** meal-planner
**Language:** Gleam
**Generated:** 2024-12-24
**Purpose:** Document refactoring patterns, module split strategies, and error handling approaches discovered during codebase evolution.

---

## Table of Contents

1. [Module Split Strategy](#1-module-split-strategy)
2. [Opaque Types for Type Safety](#2-opaque-types-for-type-safety)
3. [Centralized Error Handling](#3-centralized-error-handling)
4. [Result Pipelines with 'use'](#4-result-pipelines-with-use)
5. [Pipe-First Data Transformations](#5-pipe-first-data-transformations)
6. [Decoder Module Separation](#6-decoder-module-separation)
7. [Validation at Construction](#7-validation-at-construction)
8. [3-Phase Refactoring Strategy](#8-3-phase-refactoring-strategy)
9. [mod.gleam Aggregator Pattern](#9-modgleam-aggregator-pattern)
10. [Anti-Patterns to Avoid](#10-anti-patterns-to-avoid)

---

## 1. Module Split Strategy

### Pattern
Transform monolithic modules into domain-driven hierarchies with specialized submodules.

### Standard Structure
```
domain_name/
├── types.gleam       # Opaque types, domain types, validation
├── client.gleam      # HTTP/API calls, external integration
├── decoders.gleam    # JSON parsing, dynamic decoders
├── handlers.gleam    # Request/response handlers
├── service.gleam     # Business logic, orchestration
└── mod.gleam         # Public API aggregator, re-exports
```

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/`
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/foods/`
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/clients/`

### Benefits
- **Single Responsibility:** Each file <300 lines
- **Clear Dependencies:** types → decoders → client → service → handlers
- **Parallel Development:** Multiple agents can work simultaneously
- **Easier Testing:** Mock each layer independently

### When to Apply
- Modules >500 lines
- Mixed concerns (types + HTTP + business logic + handlers)
- Difficulty testing components in isolation
- Merge conflicts from multiple developers/agents

---

## 2. Opaque Types for Type Safety

### Pattern
Use opaque types for IDs and domain primitives to prevent type confusion at compile time.

### Implementation
```gleam
/// Opaque type for FatSecret food entry IDs
pub opaque type FoodEntryId {
  FoodEntryId(String)
}

/// Constructor - only way to create a FoodEntryId
pub fn food_entry_id(id: String) -> FoodEntryId {
  FoodEntryId(id)
}

/// Converter - extract internal value
pub fn food_entry_id_to_string(id: FoodEntryId) -> String {
  let FoodEntryId(s) = id
  s
}
```

### Use Cases
- **RecipeId, FoodId, ServingId:** Prevents mixing IDs from different domains
- **FoodEntryId, MealPlanRecipe:** Encapsulates validation logic
- **All domain identifiers** across Tandoor/FatSecret APIs

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/types.gleam` (FoodEntryId)
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/foods/types.gleam` (FoodId, ServingId)
- `/home/lewis/src/meal-planner/src/meal_planner/types/recipe.gleam` (MealPlanRecipe)

### Benefits
- **Compile-Time Safety:** Cannot pass wrong ID type to functions
- **Validation at Construction:** `new_meal_plan_recipe` validates servings>0
- **Encapsulation:** Internal representation can change without breaking callers
- **Self-Documenting:** Type signature shows exactly what ID is expected

---

## 3. Centralized Error Handling

### Pattern
Single error type with conversion functions from all error domains and shared error-to-HTTP-response logic.

### Architecture
```
Central AppError Type (meal_planner/errors.gleam)
    ↓
Conversion Functions:
  - from_tandoor_error(TandoorError) -> AppError
  - from_fatsecret_error(FatSecretError) -> AppError
  - from_database_error(op, msg) -> AppError
    ↓
HTTP Mapping:
  - http_status_code(AppError) -> Int (400/401/404/500)
  - to_json(AppError) -> Json (consistent error format)
    ↓
Error Handlers Module (shared/error_handlers.gleam):
  - app_error_to_response(AppError) -> wisp.Response
  - tandoor_error_to_response(TandoorError) -> wisp.Response
  - fatsecret_api_error_to_response(FatSecretError) -> wisp.Response
  - validation_error_to_response(field, reason) -> wisp.Response
```

### Example Usage
```gleam
// In a handler
pub fn handle_create_food_entry(req: Request) -> Response {
  case fatsecret.create_food_entry(config, token, input) {
    Ok(entry_id) -> json_response(entry_id, 201)
    Error(fs_error) ->
      error_handlers.fatsecret_api_error_to_response(fs_error)
  }
}
```

### Files
- `/home/lewis/src/meal-planner/src/meal_planner/shared/error_handlers.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/errors.gleam` (central AppError)

### Benefits
- **No Duplicate Error Handling:** Single source of truth for error responses
- **Consistent Error JSON:** All API errors follow same format
- **Easy to Extend:** Add new error types without touching handlers
- **Clear Propagation:** `Result(T, AppError)` everywhere in application

---

## 4. Result Pipelines with 'use'

### Pattern
Chain Result operations using Gleam's `use` keyword for early returns, avoiding nested case expressions.

### Example
```gleam
pub fn create_food_entry(
  config: FatSecretConfig,
  token: AccessToken,
  input: FoodEntryInput,
) -> Result(FoodEntryId, FatSecretError) {
  // Step 1: Prepare request parameters
  let params = case input {
    FromFood(food_id, name, serving_id, units, meal, date) ->
      dict.new()
      |> dict.insert("food_id", food_id)
      |> dict.insert("serving_id", serving_id)
      ...
    Custom(...) -> ...
  }

  // Step 2: Make HTTP request (fails early on network error)
  use body <- result.try(http.make_authenticated_request(
    config, token, "food_entry.create", params,
  ))

  // Step 3: Parse response and map to domain type
  json.parse(body, decode.at(["food_entry_id", "value"], decode.string))
  |> result.map(diary_types.food_entry_id)
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse food entry ID")
  })
}
```

### Pattern Steps
1. **Prepare:** Build request data (non-Result operations)
2. **Use for HTTP:** `use body <- result.try(http_call)` (early return on Error)
3. **Parse:** Use `json.parse` with decoders
4. **Map:** Transform success/error to domain types

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/client.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/clients/auth.gleam`

### Benefits
- **Flat Control Flow:** No deeply nested case expressions
- **Early Returns:** Failed steps short-circuit immediately
- **Readability:** Read top-to-bottom like imperative code
- **Type Safety:** Compiler ensures error propagation

---

## 5. Pipe-First Data Transformations

### Pattern
Use `|>` pipe operator for multi-step data transformations with clear top-down flow.

### Example: Building Parameters
```gleam
let params =
  dict.new()
  |> dict.insert("food_id", food_id)
  |> dict.insert("food_entry_name", food_entry_name)
  |> dict.insert("serving_id", serving_id)
  |> dict.insert("number_of_units", float.to_string(number_of_units))
  |> dict.insert("meal", diary_types.meal_type_to_string(meal))
  |> dict.insert("date_int", int.to_string(date_int))
```

### Example: Optional Chaining
```gleam
let initial_csrf =
  extract_csrf_from_body(login_page.body)
  |> option.lazy_or(fn() {
    extract_csrf_from_cookies(login_page.headers)
  })
```

### Example: List Transformations
```gleam
let ingredients_str =
  recipe.ingredients
  |> list.map(ingredient_to_display_string)
  |> string.join("\n")
```

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/client.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/clients/auth.gleam`

### Benefits
- **Top-Down Readability:** Read transformations in execution order
- **Easy to Modify:** Add/remove steps without restructuring
- **Clear Data Flow:** Input → step1 → step2 → output
- **Follows Gleam Commandments:** "Pipe Everything"

---

## 6. Decoder Module Separation

### Pattern
Extract JSON decoders to dedicated `decoders.gleam` file, separate from type definitions.

### Structure
- **types.gleam:** Type definitions only (no decode dependencies)
- **decoders.gleam:** All JSON parsing logic using `gleam/dynamic/decode`

### Example
```gleam
// types.gleam
pub type FoodEntry {
  FoodEntry(
    food_entry_id: FoodEntryId,
    food_entry_name: String,
    date_int: Int,
    calories: Float,
    protein: Float,
    ...
  )
}

// decoders.gleam
import gleam/dynamic/decode.{type Decoder}

pub fn food_entry_decoder() -> Decoder(FoodEntry) {
  use food_entry_id <- decode.field("food_entry_id", decode.string)
  use food_entry_name <- decode.field("food_entry_name", decode.string)
  use date_int <- decode.field("date_int", decode.int)
  use calories <- decode.field("calories", decode.float)
  use protein <- decode.field("protein", decode.float)
  ...
  decode.success(FoodEntry(
    food_entry_id: food_entry_id(food_entry_id),
    food_entry_name: food_entry_name,
    date_int: date_int,
    calories: calories,
    protein: protein,
    ...
  ))
}
```

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/types.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/decoders.gleam`
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/foods/decoders.gleam`

### Benefits
- **Pure Types:** Types module has no serialization dependencies
- **Independent Evolution:** Decoders can change without affecting type definitions
- **Easier Testing:** Test parsing separately from business logic
- **Clear Separation:** Data structure vs serialization concerns

---

## 7. Validation at Construction

### Pattern
Constructor functions return `Result` with validation instead of exposing raw type constructors.

### Example
```gleam
/// Simplified recipe for meal planning with nutrition per serving
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

/// Constructor with validation
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
      Error("Recipe servings must be greater than 0, got "
        <> int.to_string(servings))
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
```

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/types/recipe.gleam` (MealPlanRecipe)
- `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/types.gleam` (validation functions)

### Benefits
- **Impossible States:** Cannot construct invalid data
- **Clear Error Messages:** Validation failures provide context
- **Type System Enforcement:** Compiler ensures validation is checked
- **No Runtime Checks:** Once constructed, data is guaranteed valid

---

## 8. 3-Phase Refactoring Strategy

### Overview
Systematic approach to refactoring monolithic modules into focused submodules while maintaining working code at each phase.

### PHASE 1: Extract Domain Submodules
**Goal:** Split monolithic file into focused modules

**Steps:**
1. Create `types.gleam` (type definitions only, no logic)
2. Create `decoders.gleam` (JSON parsing)
3. Create `helpers.gleam` (utility functions)
4. Create `commands/` subdirectory for complex domains
5. Delete monolithic source file
6. Update all imports in dependent files
7. Run `gleam build` and fix compilation errors
8. Run `make test` to ensure behavior unchanged

**Example:** cli/domains/diary refactoring (commit 6bd189f4)
- Deleted 267-line diary.gleam
- Created types, formatters, helpers, commands/
- Updated 6 files with new imports
- Result: Clean compilation, same behavior

### PHASE 2: Refactor API Handlers
**Goal:** Standardize handler structure and extract shared logic

**Steps:**
1. Split handlers into `handlers.gleam` per domain
2. Extract `error_response` helpers to handlers module
3. Update handler tests to use new structure
4. Consolidate duplicate error handling
5. Run tests to verify behavior

**Example:** FatSecret handlers refactoring (commit 75ef8ffd)
- Created consistent handler structure
- Extracted error_response pattern
- All handlers follow same template

### PHASE 3: Create Client Aggregators
**Goal:** Provide clean public API with backward compatibility

**Steps:**
1. Create `mod.gleam` as public entry point
2. Re-export commonly used types
3. Add module documentation
4. Update external imports to use mod
5. Preserve backward compatibility where needed

**Example:** tandoor/client/mod.gleam (commit 3d17ec6b)
- Aggregates auth, recipes, meal_plans
- Re-exports core types
- Documented submodule structure

### Result Metrics
- **Before:** Monolithic 500+ line files
- **After:** Focused <200 line modules
- **Benefit:** Enables parallel development by multiple agents without conflicts

### Commits Reference
- PHASE 1: `6bd189f4` (diary submodules)
- PHASE 2: `75ef8ffd` (FatSecret handlers)
- PHASE 3: `3d17ec6b` (Tandoor client aggregator)

---

## 9. mod.gleam Aggregator Pattern

### Pattern
Create `mod.gleam` as single public entry point for module hierarchy.

### Purpose
- Re-export commonly used types from submodules
- Provide backward compatibility during refactoring
- Document module organization
- Hide internal implementation details

### Example Structure
```gleam
//// Tandoor Client Module
////
//// This module aggregates all Tandoor API operations.
////
//// ## Submodules
//// - `auth` - Authentication and session management
//// - `recipes` - Recipe CRUD operations
//// - `meal_plans` - Meal planning operations
////
//// ## Quick Start
//// ```gleam
//// import meal_planner/tandoor/client
////
//// let config = client.session_config(url, user, pass)
//// use auth_config <- result.try(client.login(config))
//// client.get_recipe(auth_config, recipe_id)
//// ```

// Re-export core types
pub type TandoorError {
  AuthenticationError(String)
  NetworkError(String)
  NotFoundError(String)
  ParseError(String)
}

pub type ClientConfig {
  ClientConfig(
    base_url: String,
    auth: AuthMethod,
    timeout_ms: Int,
  )
}

// Re-export submodule functions
pub use auth.{
  login,
  session_config,
  bearer_config,
  is_authenticated,
}

pub use recipes.{
  get_recipe,
  create_recipe,
  update_recipe,
  delete_recipe,
}

pub use meal_plans.{
  get_meal_plan,
  create_meal_entry,
}
```

### Examples in Codebase
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/client/mod.gleam` (if created)
- Pattern visible in domain organization

### Benefits
- **Single Import:** Users import from one place: `import tandoor/client`
- **Refactoring Freedom:** Internal structure changes don't break external code
- **Clear Documentation:** Module docstring explains capabilities
- **Progressive Disclosure:** Common operations easily discoverable

---

## 10. Anti-Patterns to Avoid

### Anti-Pattern 1: Deep Nesting

**Problem:** Deeply nested case expressions become unreadable and error-prone.

**Bad Example:**
```gleam
case result {
  Ok(data) -> {
    case parse(data) {
      Ok(parsed) -> {
        case validate(parsed) {
          Ok(valid) -> {
            case process(valid) {
              Ok(processed) -> Ok(processed)
              Error(e) -> Error(e)
            }
          }
          Error(e) -> Error(e)
        }
      }
      Error(e) -> Error(e)
    }
  }
  Error(e) -> Error(e)
}
```

**Solution:** Use `use` for early returns:
```gleam
use data <- result.try(result)
use parsed <- result.try(parse(data))
use valid <- result.try(validate(parsed))
use processed <- result.try(process(valid))
Ok(processed)
```

**Discovered In:**
- Old diary.gleam (267 lines, deleted in commit 6bd189f4)
- Handler functions before extraction

**Fix:** Flatten with `use` or extract helper functions. See `/home/lewis/src/meal-planner/src/meal_planner/fatsecret/diary/client.gleam` for good examples.

---

### Anti-Pattern 2: Mixed Concerns in Single File

**Problem:** Single file contains types, HTTP logic, business rules, and handlers.

**Symptoms:**
- Files >500 lines
- Difficult to test individual components
- Merge conflicts from multiple developers
- Circular import issues

**Solution:** Apply Module Split Strategy (Pattern #1)

**Example Refactoring:**
- **Before:** `cli/domains/diary.gleam` (267 lines, everything mixed)
- **After:** Separate `types.gleam`, `formatters.gleam`, `helpers.gleam`, `commands/`
- **Commit:** 6bd189f4

---

### Anti-Pattern 3: String-Based IDs

**Problem:** Using raw strings for IDs allows mixing IDs from different domains.

**Bad Example:**
```gleam
pub fn get_recipe(recipe_id: String) -> Result(Recipe, Error)
pub fn get_food(food_id: String) -> Result(Food, Error)

// Oops! Compiler doesn't catch this:
let food = get_recipe(food_id)  // Wrong ID type!
```

**Solution:** Use Opaque Types (Pattern #2)
```gleam
pub opaque type RecipeId { RecipeId(String) }
pub opaque type FoodId { FoodId(String) }

pub fn get_recipe(recipe_id: RecipeId) -> Result(Recipe, Error)
pub fn get_food(food_id: FoodId) -> Result(Food, Error)

// Compiler catches this:
let food = get_recipe(food_id)  // Compile error!
```

**Examples in Codebase:**
- FoodId, ServingId, FoodEntryId all use opaque types
- RecipeId used throughout meal planning

---

### Anti-Pattern 4: Duplicate Error Handling

**Problem:** Every handler duplicates error-to-HTTP-response conversion logic.

**Bad Example:**
```gleam
// Handler 1
case tandoor.get_recipe(id) {
  Ok(recipe) -> json_response(recipe, 200)
  Error(NotFoundError(msg)) ->
    json_response(json.object([#("error", json.string(msg))]), 404)
  Error(AuthenticationError(msg)) ->
    json_response(json.object([#("error", json.string(msg))]), 401)
  ...
}

// Handler 2 (duplicates same logic)
case tandoor.create_recipe(data) {
  Ok(recipe) -> json_response(recipe, 201)
  Error(NotFoundError(msg)) ->
    json_response(json.object([#("error", json.string(msg))]), 404)
  Error(AuthenticationError(msg)) ->
    json_response(json.object([#("error", json.string(msg))]), 401)
  ...
}
```

**Solution:** Centralized Error Handling (Pattern #3)
```gleam
// Handler 1
case tandoor.get_recipe(id) {
  Ok(recipe) -> json_response(recipe, 200)
  Error(error) -> error_handlers.tandoor_error_to_response(error)
}

// Handler 2
case tandoor.create_recipe(data) {
  Ok(recipe) -> json_response(recipe, 201)
  Error(error) -> error_handlers.tandoor_error_to_response(error)
}
```

**Example:** `/home/lewis/src/meal-planner/src/meal_planner/shared/error_handlers.gleam`

---

### Anti-Pattern 5: Validation After Construction

**Problem:** Types can be constructed with invalid data, requiring runtime checks everywhere.

**Bad Example:**
```gleam
pub type MealPlanRecipe {
  MealPlanRecipe(
    id: RecipeId,
    servings: Int,  // Could be 0 or negative!
    prep_time: Int,  // Could be negative!
  )
}

// Every function must validate:
pub fn calculate_total_time(recipe: MealPlanRecipe) -> Result(Int, String) {
  case recipe.servings > 0, recipe.prep_time >= 0 {
    True, True -> Ok(recipe.prep_time + recipe.cook_time)
    False, _ -> Error("Invalid servings")
    _, False -> Error("Invalid prep_time")
  }
}
```

**Solution:** Validation at Construction (Pattern #7)
```gleam
pub opaque type MealPlanRecipe { ... }

pub fn new_meal_plan_recipe(
  servings servings: Int,
  prep_time prep_time: Int,
  ...
) -> Result(MealPlanRecipe, String) {
  case servings > 0 {
    False -> Error("Servings must be > 0")
    True -> {
      case prep_time >= 0 {
        False -> Error("Prep time must be >= 0")
        True -> Ok(MealPlanRecipe(...))
      }
    }
  }
}

// No validation needed - data is guaranteed valid:
pub fn calculate_total_time(recipe: MealPlanRecipe) -> Int {
  recipe.prep_time + recipe.cook_time
}
```

**Example:** `/home/lewis/src/meal-planner/src/meal_planner/types/recipe.gleam`

---

## Summary

These patterns emerged from refactoring a large Gleam codebase (meal-planner) from monolithic structure to modular, maintainable architecture. Key themes:

1. **Type Safety First:** Opaque types, validation at construction
2. **Clear Separation:** types → decoders → client → service → handlers
3. **Flat Control Flow:** `use` instead of nesting, pipes for transformations
4. **Centralize Common Logic:** Error handling, response building
5. **Progressive Refactoring:** 3-phase strategy maintains working code

Apply these patterns when:
- Files exceed 300-500 lines
- Testing becomes difficult
- Multiple developers cause conflicts
- Adding features requires touching many files

The result: A codebase that compiles fast, tests easily, and scales with team size.
