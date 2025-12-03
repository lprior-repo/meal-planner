# Recipe Creation Form - System Architecture

**Status**: Design Phase
**Date**: 2025-12-03
**Architect**: System Architecture Designer
**Component**: Recipe Creation & Management

---

## 1. Overview

This document defines the complete architecture for recipe creation functionality in the meal planner application, including routes, data flow, validation, and error handling strategies.

### 1.1 Business Requirements

- Allow users to create custom recipes with complete nutritional information
- Support FODMAP level tracking and Vertical Diet compliance
- Dynamic ingredient and instruction list management
- Client-side and server-side validation
- Seamless integration with existing storage layer

### 1.2 Quality Attributes

| Attribute | Target | Rationale |
|-----------|--------|-----------|
| **Reliability** | 99.9% uptime | Recipe creation is core functionality |
| **Performance** | <200ms response | Form submission should feel instant |
| **Usability** | 0 training needed | Must be intuitive for non-technical users |
| **Maintainability** | <500 LOC per module | Keep modules small and focused |
| **Security** | Input sanitization | Prevent XSS and injection attacks |

---

## 2. Route Structure

### 2.1 HTTP Endpoints

```gleam
// SSR Page Routes
GET  /recipes/new                    -> new_recipe_page()
GET  /recipes/:id/edit              -> edit_recipe_page(id)

// API Routes
POST   /api/recipes                 -> create_recipe(req)
PUT    /api/recipes/:id             -> update_recipe(req, id)
DELETE /api/recipes/:id             -> delete_recipe(req, id)
GET    /api/recipes/:id/validate    -> validate_recipe_draft(req, id)
```

### 2.2 Route Handlers

```
web.gleam (routing layer)
    ↓
recipe_handlers.gleam (business logic)
    ↓
recipe_validation.gleam (validation rules)
    ↓
storage.gleam (persistence)
```

### 2.3 URL Design Rationale

**Decision**: Use separate `/recipes/new` route instead of SPA approach

**Rationale**:
- Consistent with existing SSR architecture (`/recipes`, `/profile`, `/foods`)
- SEO-friendly for recipe discovery
- Simpler state management without client-side routing
- Progressive enhancement friendly

---

## 3. Data Flow Architecture

### 3.1 Component Diagram (C4 Level 3)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser (User)                            │
└────────────┬────────────────────────────────────┬────────────────┘
             │                                    │
             │ HTTP GET /recipes/new              │ HTTP POST /api/recipes
             │                                    │ (form data)
             ↓                                    ↓
┌─────────────────────────────────────────────────────────────────┐
│                     web.gleam (Router)                           │
│  ┌─────────────────────────────┐  ┌────────────────────────┐   │
│  │ new_recipe_page()           │  │ api_create_recipe()    │   │
│  │  - Render empty form        │  │  - Parse form data     │   │
│  │  - Include validation JS    │  │  - Validate input      │   │
│  └─────────────────────────────┘  └─────────┬──────────────┘   │
└──────────────────────────────────────────────┼──────────────────┘
                                                │
                                                ↓
┌─────────────────────────────────────────────────────────────────┐
│              recipe_validation.gleam                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ validate_recipe_input()                                  │   │
│  │  - Name: required, 1-100 chars                          │   │
│  │  - Category: required, predefined list                  │   │
│  │  - Ingredients: min 1, max 50                           │   │
│  │  - Instructions: min 1, max 20                          │   │
│  │  - Macros: all >= 0.0, max 1000.0                       │   │
│  │  - Servings: >= 1, <= 50                                │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Valid Recipe
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    storage.gleam                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ save_recipe(conn, recipe)                                │   │
│  │  - Generate UUID for recipe.id                          │   │
│  │  - Insert into PostgreSQL recipes table                 │   │
│  │  - Handle constraint violations                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Success
                           ↓
                    Redirect to /recipes/:id
```

### 3.2 Data Flow Sequence

**Happy Path - Recipe Creation**:

1. User navigates to `/recipes/new`
2. Server renders form with empty fields
3. User fills form fields (client-side validation on blur)
4. User submits form
5. Client-side validation runs (immediate feedback)
6. Form data POST to `/api/recipes`
7. Server-side validation runs
8. Recipe saved to database
9. Server responds with 201 + Location header
10. Client redirects to `/recipes/:new-id`

**Error Path - Validation Failure**:

1. Steps 1-6 same as happy path
2. Server-side validation fails
3. Server responds with 400 + error details JSON
4. Client displays inline error messages
5. User corrects errors
6. Retry from step 4

---

## 4. Component Hierarchy

### 4.1 Frontend Components (SSR with Lustre)

```
recipe_form.gleam
├── form_layout()
│   ├── page_header()
│   ├── error_summary()  // Shows validation errors at top
│   ├── basic_info_section()
│   │   ├── text_input("name", required=True)
│   │   ├── select_input("category", options=categories)
│   │   ├── select_input("fodmap_level", options=levels)
│   │   └── checkbox_input("vertical_compliant")
│   ├── ingredients_section()
│   │   ├── ingredient_list()
│   │   │   └── ingredient_item() (repeated)
│   │   └── add_ingredient_button()
│   ├── instructions_section()
│   │   ├── instruction_list()
│   │   │   └── instruction_item() (repeated)
│   │   └── add_instruction_button()
│   ├── macros_section()
│   │   ├── number_input("protein", min=0, step=0.1)
│   │   ├── number_input("fat", min=0, step=0.1)
│   │   ├── number_input("carbs", min=0, step=0.1)
│   │   └── calculated_calories_display()
│   ├── servings_input(min=1, max=50)
│   └── form_actions()
│       ├── submit_button("Create Recipe")
│       └── cancel_link("/recipes")
└── client_validation_script()
```

### 4.2 Backend Modules

```
gleam/src/meal_planner/
├── web.gleam
│   └── Routes: /recipes/new, /recipes/:id/edit
├── recipe_handlers.gleam (NEW)
│   ├── new_recipe_page()
│   ├── edit_recipe_page()
│   ├── create_recipe()
│   ├── update_recipe()
│   └── render_recipe_form()
├── recipe_validation.gleam (NEW)
│   ├── validate_recipe_input()
│   ├── validate_name()
│   ├── validate_ingredients()
│   ├── validate_instructions()
│   ├── validate_macros()
│   └── validate_servings()
├── recipe_forms.gleam (NEW)
│   ├── recipe_form_component()
│   ├── ingredient_input()
│   ├── instruction_input()
│   └── macro_inputs()
└── storage.gleam
    ├── save_recipe() (EXISTING)
    ├── get_recipe_by_id() (EXISTING)
    └── update_recipe() (NEW)
```

---

## 5. Validation Rules

### 5.1 Validation Strategy

**Decision**: Dual validation (client + server)

**Rationale**:
- Client-side: Immediate feedback, better UX
- Server-side: Security, data integrity, single source of truth
- Never trust client-side validation alone

### 5.2 Field Validation Rules

| Field | Type | Client Rules | Server Rules | Error Messages |
|-------|------|-------------|--------------|----------------|
| **name** | String | Required, 1-100 chars | Required, 1-100 chars, trim whitespace | "Recipe name required", "Name too long (max 100)" |
| **category** | String | Required, from list | Required, whitelist validation | "Category required", "Invalid category" |
| **ingredients** | List | Min 1, max 50 items | Min 1, max 50, each 1-200 chars | "At least 1 ingredient required", "Too many ingredients (max 50)" |
| **ingredients[].name** | String | Required, 1-100 chars | Required, 1-100 chars | "Ingredient name required" |
| **ingredients[].quantity** | String | Required, 1-50 chars | Required, 1-50 chars | "Quantity required" |
| **instructions** | List | Min 1, max 20 items | Min 1, max 20, each 1-500 chars | "At least 1 instruction required", "Too many steps (max 20)" |
| **instructions[]** | String | Required, 1-500 chars | Required, 1-500 chars | "Instruction cannot be empty" |
| **macros.protein** | Float | Required, >= 0, <= 1000 | Required, >= 0.0, <= 1000.0 | "Protein required", "Invalid protein value" |
| **macros.fat** | Float | Required, >= 0, <= 1000 | Required, >= 0.0, <= 1000.0 | "Fat required", "Invalid fat value" |
| **macros.carbs** | Float | Required, >= 0, <= 1000 | Required, >= 0.0, <= 1000.0 | "Carbs required", "Invalid carbs value" |
| **servings** | Int | Required, >= 1, <= 50 | Required, >= 1, <= 50 | "Servings required", "Invalid servings (1-50)" |
| **fodmap_level** | Enum | Required, from list | Required, enum validation | "FODMAP level required" |
| **vertical_compliant** | Bool | Optional, default false | Bool, default false | N/A |

### 5.3 Validation Error Structure

```gleam
pub type ValidationError {
  ValidationError(
    field: String,          // "name", "ingredients[2].quantity"
    message: String,        // Human-readable error message
    code: String,           // "required", "too_long", "invalid_format"
  )
}

pub type ValidationResult(a) {
  Valid(a)
  Invalid(List(ValidationError))
}
```

### 5.4 Validation Implementation

```gleam
// recipe_validation.gleam

pub type RecipeInput {
  RecipeInput(
    name: String,
    category: String,
    ingredients: List(IngredientInput),
    instructions: List(String),
    protein: Float,
    fat: Float,
    carbs: Float,
    servings: Int,
    fodmap_level: String,
    vertical_compliant: Bool,
  )
}

pub type IngredientInput {
  IngredientInput(
    name: String,
    quantity: String,
  )
}

pub fn validate_recipe_input(
  input: RecipeInput,
) -> ValidationResult(Recipe) {
  // Collect all validation errors
  let errors = []

  // Validate each field
  let errors = case validate_name(input.name) {
    Ok(_) -> errors
    Error(e) -> [e, ..errors]
  }

  let errors = case validate_category(input.category) {
    Ok(_) -> errors
    Error(e) -> [e, ..errors]
  }

  // ... validate all fields

  case errors {
    [] -> Valid(build_recipe(input))
    errors -> Invalid(errors)
  }
}

pub fn validate_name(name: String) -> Result(String, ValidationError) {
  let trimmed = string.trim(name)
  case string.length(trimmed) {
    0 -> Error(ValidationError(
      field: "name",
      message: "Recipe name is required",
      code: "required",
    ))
    n if n > 100 -> Error(ValidationError(
      field: "name",
      message: "Recipe name too long (max 100 characters)",
      code: "too_long",
    ))
    _ -> Ok(trimmed)
  }
}

pub fn validate_ingredients(
  ingredients: List(IngredientInput),
) -> Result(List(Ingredient), ValidationError) {
  case list.length(ingredients) {
    0 -> Error(ValidationError(
      field: "ingredients",
      message: "At least 1 ingredient is required",
      code: "required",
    ))
    n if n > 50 -> Error(ValidationError(
      field: "ingredients",
      message: "Too many ingredients (max 50)",
      code: "too_many",
    ))
    _ -> validate_each_ingredient(ingredients, [])
  }
}

// ... more validation functions
```

---

## 6. Error Handling Strategy

### 6.1 Error Classification

| Error Type | HTTP Status | User Action | System Action |
|------------|-------------|-------------|---------------|
| **Validation Error** | 400 | Fix input, resubmit | Log warning, return field errors |
| **Duplicate Recipe** | 409 | Choose different name | Check unique constraints |
| **Database Error** | 500 | Retry or contact support | Log error, alert ops team |
| **Not Found** | 404 | Check URL | Log access attempt |
| **Server Error** | 500 | Retry later | Log error, alert ops team |

### 6.2 Error Response Format

```json
// Validation Errors (400)
{
  "error": "validation_failed",
  "message": "Recipe validation failed",
  "details": [
    {
      "field": "name",
      "message": "Recipe name is required",
      "code": "required"
    },
    {
      "field": "ingredients[0].quantity",
      "message": "Quantity is required",
      "code": "required"
    }
  ]
}

// Database Error (500)
{
  "error": "internal_error",
  "message": "Failed to save recipe. Please try again.",
  "request_id": "uuid-here"
}
```

### 6.3 Error Display Strategy

**Client-Side**:
1. **Inline errors**: Display under each field with validation error
2. **Error summary**: Show all errors at top of form
3. **Field highlighting**: Red border on invalid fields
4. **Focus management**: Auto-focus first invalid field

**Server-Side**:
1. **Preserve form state**: Return all valid input back to user
2. **Pre-populate fields**: User doesn't lose their work
3. **Clear error messages**: Technical details logged, user-friendly messages shown

### 6.4 Error Recovery Patterns

```gleam
// recipe_handlers.gleam

fn create_recipe(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)

  // Parse form data
  let input = parse_recipe_form(form_data)

  // Validate input
  case recipe_validation.validate_recipe_input(input) {
    Invalid(errors) -> {
      // Validation failed - return 400 with errors
      render_form_with_errors(input, errors)
    }
    Valid(recipe) -> {
      // Save to database
      case storage.save_recipe(ctx.db, recipe) {
        Ok(_) -> {
          // Success - redirect to recipe detail
          wisp.redirect("/recipes/" <> recipe.id)
        }
        Error(storage.DatabaseError(msg)) -> {
          // Database error - return 500
          log_error("Recipe save failed", msg)
          render_error_page("Failed to save recipe", 500)
        }
        Error(storage.NotFound) -> {
          // Should not happen on create
          wisp.internal_server_error()
        }
      }
    }
  }
}
```

---

## 7. Integration with Storage Layer

### 7.1 Database Schema

```sql
-- Table: recipes (EXISTING)
CREATE TABLE recipes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  ingredients TEXT NOT NULL,        -- Serialized as "name:quantity|name:quantity"
  instructions TEXT NOT NULL,       -- Serialized as "step1|step2|step3"
  protein DOUBLE PRECISION NOT NULL,
  fat DOUBLE PRECISION NOT NULL,
  carbs DOUBLE PRECISION NOT NULL,
  servings INTEGER NOT NULL,
  category TEXT NOT NULL,
  fodmap_level TEXT NOT NULL,       -- 'low', 'medium', 'high'
  vertical_compliant BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_recipes_category ON recipes(category);
CREATE INDEX idx_recipes_fodmap ON recipes(fodmap_level);
CREATE INDEX idx_recipes_vertical ON recipes(vertical_compliant);
```

### 7.2 Storage Functions

**Existing Functions** (already implemented in storage.gleam):
- `save_recipe(conn, recipe)` - Create or update
- `get_recipe_by_id(conn, id)` - Fetch single recipe
- `get_all_recipes(conn)` - Fetch all recipes
- `delete_recipe(conn, id)` - Delete recipe
- `get_recipes_by_category(conn, category)` - Filter by category

**New Functions Needed**:

```gleam
// storage.gleam

/// Update existing recipe
pub fn update_recipe(
  conn: pog.Connection,
  id: String,
  recipe: Recipe,
) -> Result(Nil, StorageError) {
  let sql =
    "UPDATE recipes SET
       name = $1,
       ingredients = $2,
       instructions = $3,
       protein = $4,
       fat = $5,
       carbs = $6,
       servings = $7,
       category = $8,
       fodmap_level = $9,
       vertical_compliant = $10,
       updated_at = NOW()
     WHERE id = $11"

  // Same parameter binding as save_recipe
  case pog.execute(...) {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(_) -> Ok(Nil)
  }
}

/// Check if recipe name exists (for uniqueness validation)
pub fn recipe_name_exists(
  conn: pog.Connection,
  name: String,
  exclude_id: Option(String),
) -> Result(Bool, StorageError) {
  let sql = case exclude_id {
    None -> "SELECT COUNT(*) FROM recipes WHERE name = $1"
    Some(_) -> "SELECT COUNT(*) FROM recipes WHERE name = $1 AND id != $2"
  }

  // Execute query and return true if count > 0
  ...
}
```

### 7.3 Data Serialization Strategy

**Current Implementation** (from storage.gleam lines 371-377):
```gleam
// Ingredients serialized as: "name:quantity|name:quantity"
let ingredients_json =
  string.join(
    list.map(recipe.ingredients, fn(i) { i.name <> ":" <> i.quantity }),
    "|",
  )

// Instructions serialized as: "step1|step2|step3"
let instructions_json = string.join(recipe.instructions, "|")
```

**Trade-offs**:
- ✅ Simple, no additional dependencies
- ✅ Works with existing schema
- ✅ Easy to parse on read
- ⚠️ Limited query capabilities (can't search within ingredients)
- ⚠️ Manual escaping needed for pipe characters

**Alternative**: JSON columns (PostgreSQL supports JSONB)
- Would enable complex queries
- Better type safety
- Requires migration

**Decision**: Keep current serialization for MVP, plan JSON migration for v2

---

## 8. Form UI Specification

### 8.1 Layout Design

```
┌────────────────────────────────────────────────────────────┐
│  ← Back to Recipes                                         │
│                                                            │
│  Create New Recipe                                         │
│  ══════════════════                                        │
│                                                            │
│  [Error Summary Box - only if validation errors]          │
│                                                            │
│  Basic Information                                         │
│  ─────────────────                                         │
│  Recipe Name *                                             │
│  [_________________________________________]               │
│                                                            │
│  Category *                                                │
│  [▼ Select category          ]                             │
│                                                            │
│  FODMAP Level *                                            │
│  ( ) Low  ( ) Medium  ( ) High                             │
│                                                            │
│  [ ] Vertical Diet Compliant                               │
│                                                            │
│  Ingredients *                                             │
│  ────────────                                              │
│  1. Name: [____________] Qty: [_______] [Remove]           │
│  2. Name: [____________] Qty: [_______] [Remove]           │
│  [+ Add Ingredient]                                        │
│                                                            │
│  Instructions *                                            │
│  ──────────────                                            │
│  1. [________________________________________] [Remove]     │
│  2. [________________________________________] [Remove]     │
│  [+ Add Step]                                              │
│                                                            │
│  Nutrition Information (per serving) *                     │
│  ────────────────────────────────                          │
│  Protein: [____] g    Fat: [____] g    Carbs: [____] g     │
│  Total Calories: 450 kcal (calculated)                     │
│                                                            │
│  Servings *                                                │
│  [__] servings                                             │
│                                                            │
│  [Cancel]  [Create Recipe]                                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 8.2 Interactive Behaviors

| Interaction | Behavior |
|-------------|----------|
| **Add Ingredient** | Append new ingredient row, focus on name field |
| **Remove Ingredient** | Remove row, renumber remaining items |
| **Add Instruction** | Append new instruction row, focus on textarea |
| **Remove Instruction** | Remove row, renumber remaining items |
| **Macro Input** | Update calculated calories on blur |
| **Form Submit** | Disable button, show loading state |
| **Validation Error** | Scroll to first error, focus field |

### 8.3 Accessibility Requirements

- All form fields have associated `<label>` elements
- Required fields marked with `*` and `aria-required="true"`
- Error messages have `role="alert"` and `aria-live="polite"`
- Keyboard navigation: Tab order follows visual flow
- Dynamic list items: Use `aria-label` for remove buttons
- Focus management: On error, focus first invalid field
- Color is not the only indicator (use icons + text)

---

## 9. Technology Choices

### 9.1 Frontend Stack

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Rendering** | Server-Side (Lustre) | Consistent with existing app, simpler state management |
| **Validation** | Progressive Enhancement | Works without JS, enhanced with JS |
| **State Management** | Form serialization | No complex client state needed |
| **Styling** | CSS (existing styles) | Leverage existing design system |

### 9.2 Backend Stack

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Language** | Gleam | Existing codebase language |
| **Web Framework** | Wisp | Existing framework choice |
| **Validation** | Custom validators | Type-safe, composable |
| **Database** | PostgreSQL | Existing database |
| **ORM/Query** | Pog | Existing database library |

### 9.3 Dependencies

**New Dependencies**: None required

**Leverage Existing**:
- `wisp` - Web framework
- `pog` - PostgreSQL client
- `lustre` - SSR HTML generation
- `gleam/string` - String manipulation
- `gleam/list` - List operations
- `gleam/result` - Error handling
- `gleam/option` - Optional values
- `shared/types` - Shared type definitions

---

## 10. Architecture Decision Records (ADRs)

### ADR-001: Server-Side Rendering with Progressive Enhancement

**Status**: Accepted
**Date**: 2025-12-03

**Context**: Need to decide between SPA (client-side) vs SSR approach for recipe form.

**Decision**: Use server-side rendering with progressive enhancement (JavaScript optional).

**Consequences**:
- ✅ Consistent with existing architecture
- ✅ Better SEO and initial load time
- ✅ Simpler state management
- ✅ Works without JavaScript
- ⚠️ Requires full page refresh on error (mitigated with AJAX enhancement)

---

### ADR-002: Dual Validation (Client + Server)

**Status**: Accepted
**Date**: 2025-12-03

**Context**: Need to decide validation strategy.

**Decision**: Implement validation on both client and server, with server as source of truth.

**Consequences**:
- ✅ Better user experience (immediate feedback)
- ✅ Security (server validates all input)
- ⚠️ Code duplication (mitigated with shared validation rules documentation)

---

### ADR-003: Keep Current Ingredient Serialization

**Status**: Accepted (with future review)
**Date**: 2025-12-03

**Context**: Current implementation uses pipe-delimited strings. Could migrate to JSONB.

**Decision**: Keep current serialization for MVP, plan JSONB migration for v2.

**Consequences**:
- ✅ No migration needed now
- ✅ Faster development
- ⚠️ Limited query capabilities (defer advanced search to v2)

---

### ADR-004: Single Form for Create and Edit

**Status**: Accepted
**Date**: 2025-12-03

**Context**: Need to decide if create and edit use same form component.

**Decision**: Use single reusable form component for both operations.

**Consequences**:
- ✅ DRY principle (less code duplication)
- ✅ Consistent UX
- ⚠️ Slightly more complex logic (mitigated with clear parameter design)

---

## 11. Implementation Plan

### 11.1 Phase 1: Core Create Flow (MVP)

**Scope**: Basic recipe creation with validation

**Tasks**:
1. Create `recipe_validation.gleam` module
   - Implement validation functions
   - Define error types
2. Create `recipe_handlers.gleam` module
   - Implement `new_recipe_page()`
   - Implement `create_recipe()`
3. Create `recipe_forms.gleam` module
   - Build form components with Lustre
   - Wire up to handlers
4. Update `web.gleam`
   - Add `/recipes/new` route
   - Add `POST /api/recipes` route
5. Write tests
   - Unit tests for validation
   - Integration tests for handlers

**Acceptance Criteria**:
- [ ] User can navigate to `/recipes/new`
- [ ] User can fill out recipe form
- [ ] Client-side validation shows errors inline
- [ ] Server-side validation rejects invalid input
- [ ] Valid recipes are saved to database
- [ ] User is redirected to recipe detail page
- [ ] All fields validate correctly per rules

### 11.2 Phase 2: Edit Flow

**Scope**: Edit existing recipes

**Tasks**:
1. Implement `edit_recipe_page()` in handlers
2. Implement `update_recipe()` in storage
3. Add `GET /recipes/:id/edit` route
4. Add `PUT /api/recipes/:id` route
5. Reuse form component with pre-populated data

**Acceptance Criteria**:
- [ ] User can navigate to `/recipes/:id/edit`
- [ ] Form pre-populates with existing recipe data
- [ ] User can modify recipe
- [ ] Updates are saved to database
- [ ] User is redirected to updated recipe detail

### 11.3 Phase 3: Enhanced UX

**Scope**: Progressive enhancement, better interactions

**Tasks**:
1. Add client-side dynamic list management
   - Add/remove ingredients without page reload
   - Add/remove instructions without page reload
2. Add calculated calories display (real-time)
3. Add autosave draft feature (localStorage)
4. Add recipe name uniqueness check (AJAX)
5. Add keyboard shortcuts (Ctrl+S to save)

**Acceptance Criteria**:
- [ ] Adding/removing items updates UI instantly
- [ ] Calories calculate in real-time as user types
- [ ] Form drafts persist across page refreshes
- [ ] User gets immediate feedback if name exists

### 11.4 Phase 4: Advanced Features (Future)

**Scope**: Nice-to-have enhancements

**Tasks**:
1. Migrate to JSONB ingredient storage
2. Add ingredient autocomplete (from USDA database)
3. Add recipe photo upload
4. Add recipe tags/search
5. Add recipe sharing

---

## 12. Testing Strategy

### 12.1 Unit Tests

**Module**: `recipe_validation.gleam`

```gleam
// recipe_validation_test.gleam

import gleam/should
import recipe_validation

pub fn validate_name_empty_test() {
  validate_name("")
  |> should.be_error()
  |> should.equal(ValidationError(
    field: "name",
    code: "required",
    ..
  ))
}

pub fn validate_name_too_long_test() {
  let long_name = string.repeat("a", 101)
  validate_name(long_name)
  |> should.be_error()
}

pub fn validate_name_valid_test() {
  validate_name("Chicken and Rice")
  |> should.be_ok()
}

// ... more tests for each validation function
```

### 12.2 Integration Tests

**Module**: `recipe_handlers_test.gleam`

```gleam
import gleam/http
import wisp/testing
import recipe_handlers

pub fn create_recipe_valid_input_test() {
  let form_data = [
    #("name", "Test Recipe"),
    #("category", "chicken"),
    #("protein", "45.0"),
    #("fat", "12.0"),
    #("carbs", "30.0"),
    #("servings", "2"),
    #("fodmap_level", "low"),
    #("vertical_compliant", "true"),
    #("ingredients[0][name]", "Chicken"),
    #("ingredients[0][quantity]", "1 lb"),
    #("instructions[0]", "Cook chicken"),
  ]

  let request =
    testing.post("/api/recipes", [], form_data)

  let response = recipe_handlers.create_recipe(request, test_ctx)

  response.status
  |> should.equal(http.Created)

  response.headers
  |> should.contain(#("location", "/recipes/" <> _))
}

pub fn create_recipe_invalid_input_test() {
  let form_data = [
    #("name", ""),  // Invalid: empty name
  ]

  let request =
    testing.post("/api/recipes", [], form_data)

  let response = recipe_handlers.create_recipe(request, test_ctx)

  response.status
  |> should.equal(http.BadRequest)
}
```

### 12.3 End-to-End Tests

**Tool**: Manual testing checklist (future: automated with Playwright)

**Test Cases**:
1. Navigate to `/recipes/new`, verify form renders
2. Submit empty form, verify errors appear
3. Fill valid data, submit, verify redirect
4. Edit recipe, change name, save, verify update
5. Add 10 ingredients, verify all saved
6. Remove ingredient, verify list updates
7. Test all validation rules (name, macros, etc.)
8. Test error recovery (database failure)

---

## 13. Monitoring & Observability

### 13.1 Metrics to Track

| Metric | Type | Alert Threshold |
|--------|------|----------------|
| Recipe creation success rate | Counter | < 95% |
| Recipe creation latency | Histogram | p99 > 500ms |
| Validation error rate | Counter | > 50% (indicates UX issues) |
| Database save errors | Counter | > 1 per hour |

### 13.2 Logging Strategy

**Log Levels**:
- `DEBUG`: Form data parsing, validation steps
- `INFO`: Recipe created, recipe updated
- `WARN`: Validation failed, duplicate recipe name
- `ERROR`: Database error, unexpected failures

**Log Format**:
```gleam
log.info("Recipe created", [
  #("recipe_id", recipe.id),
  #("user_id", user_id),
  #("category", recipe.category),
  #("servings", int.to_string(recipe.servings)),
])

log.error("Recipe save failed", [
  #("error", error_msg),
  #("recipe_name", recipe.name),
  #("request_id", request_id),
])
```

---

## 14. Security Considerations

### 14.1 Input Sanitization

| Attack Vector | Mitigation |
|---------------|------------|
| **XSS** | HTML-escape all user input before rendering |
| **SQL Injection** | Use parameterized queries (Pog handles this) |
| **CSRF** | Add CSRF token to form (Wisp middleware) |
| **Path Traversal** | Validate recipe ID format (UUID only) |
| **DoS** | Rate limit recipe creation (max 10/minute) |

### 14.2 Authorization

**Current State**: Single-user application (no auth)

**Future Considerations**:
- Add user authentication
- Associate recipes with user_id
- Implement recipe privacy (public/private)
- Add sharing/collaboration features

### 14.3 Data Privacy

- Recipe names may contain personal info (e.g., "Mom's Soup")
- No PII collected in MVP
- Future: Add user consent for recipe sharing

---

## 15. Performance Considerations

### 15.1 Expected Load

| Metric | Estimate | Notes |
|--------|----------|-------|
| Concurrent users | 1-10 | Single-user MVP |
| Recipes created/day | 1-5 | Low frequency operation |
| Form submission time | <200ms | Critical UX metric |
| Page load time | <500ms | Including form render |

### 15.2 Optimization Strategies

1. **Database**:
   - Index on `category` for filtering
   - Index on `fodmap_level` for filtering
   - Limit text field sizes (prevent large payloads)

2. **Frontend**:
   - Minimize JavaScript bundle (progressive enhancement)
   - Use browser caching for static assets
   - Defer non-critical JS (autosave, analytics)

3. **Backend**:
   - Connection pooling (already configured)
   - Validate early (fail fast on invalid input)
   - Use prepared statements (Pog optimization)

### 15.3 Scalability Path

**Current**: Monolithic SSR application
**Future** (if needed):
- Add Redis for session/draft caching
- Extract recipe service as microservice
- Add CDN for static assets
- Implement async job queue for heavy operations

---

## 16. Maintenance & Operations

### 16.1 Deployment Process

1. Run tests: `npm test`
2. Build: `npm run build`
3. Run migrations: `gleam run -m migrate`
4. Deploy: `gleam run -m meal_planner/web`
5. Health check: `curl http://localhost:8080/`

### 16.2 Rollback Plan

1. Revert code deployment
2. Roll back database migration (if schema changed)
3. Clear application cache
4. Verify recipes still load

### 16.3 Documentation

**User Documentation**:
- Recipe creation guide (how-to)
- Recipe editing guide
- FAQ (common errors, tips)

**Developer Documentation**:
- Architecture overview (this document)
- API documentation (OpenAPI spec)
- Database schema documentation
- Validation rules reference

---

## 17. Future Enhancements

### 17.1 Short-term (Next Quarter)

1. Recipe photo upload
2. Ingredient autocomplete from USDA database
3. Duplicate recipe detection
4. Recipe import from URL
5. Nutrition label generation (FDA format)

### 17.2 Medium-term (Next Year)

1. Multi-user support with authentication
2. Recipe sharing and collaboration
3. Recipe ratings and reviews
4. Meal plan integration (schedule recipes)
5. Shopping list auto-generation from recipes

### 17.3 Long-term (2+ Years)

1. Mobile app (native or PWA)
2. Voice-controlled recipe entry
3. AI-powered recipe suggestions
4. Integration with grocery delivery services
5. Nutrition goal tracking and coaching

---

## 18. Appendix

### 18.1 Category Options

Predefined categories for recipe.category field:

- chicken
- beef
- pork
- seafood
- vegetarian
- vegan
- eggs
- dairy
- snacks
- desserts
- other

### 18.2 FODMAP Level Options

- low: Safe for low-FODMAP diet
- medium: Moderate FODMAP content
- high: High FODMAP content (avoid on low-FODMAP diet)

### 18.3 Example Recipe JSON

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Grilled Chicken with Rice",
  "category": "chicken",
  "ingredients": [
    {
      "name": "Chicken breast",
      "quantity": "8 oz"
    },
    {
      "name": "White rice",
      "quantity": "1 cup uncooked"
    },
    {
      "name": "Olive oil",
      "quantity": "1 tbsp"
    }
  ],
  "instructions": [
    "Cook rice according to package directions",
    "Season chicken with salt and pepper",
    "Grill chicken for 6-7 minutes per side",
    "Let chicken rest for 5 minutes, then slice",
    "Serve chicken over rice"
  ],
  "macros": {
    "protein": 45.0,
    "fat": 12.0,
    "carbs": 55.0,
    "calories": 508.0
  },
  "servings": 2,
  "fodmap_level": "low",
  "vertical_compliant": true
}
```

### 18.4 Database Migration

```sql
-- No migration needed for MVP (table already exists)

-- Future enhancement: Add indexes
CREATE INDEX CONCURRENTLY idx_recipes_name
  ON recipes(name text_pattern_ops);

CREATE INDEX CONCURRENTLY idx_recipes_created_at
  ON recipes(created_at DESC);

-- Future enhancement: Add full-text search
ALTER TABLE recipes
  ADD COLUMN name_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('english', name)) STORED;

CREATE INDEX idx_recipes_name_fts
  ON recipes USING GIN(name_vector);
```

---

## 19. Summary

This architecture provides a robust, maintainable foundation for recipe creation functionality that:

1. **Aligns with existing codebase** patterns (Gleam, Wisp, SSR, PostgreSQL)
2. **Prioritizes user experience** with dual validation and clear error handling
3. **Maintains data integrity** with comprehensive validation rules
4. **Enables future growth** through modular design and clear extension points
5. **Ensures reliability** with proper error handling and monitoring
6. **Supports accessibility** with semantic HTML and ARIA attributes

The phased implementation plan allows for iterative delivery while maintaining quality and minimizing risk.

**Next Steps**: Review and approve architecture, begin Phase 1 implementation.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Status**: Pending Review
**Approver**: Tech Lead / Product Owner
