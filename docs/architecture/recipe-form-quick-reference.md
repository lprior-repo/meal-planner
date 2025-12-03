# Recipe Form Architecture - Quick Reference Card

## 🎯 Routes

```
GET  /recipes/new           → Render empty form
POST /api/recipes           → Create recipe
GET  /recipes/:id/edit      → Render form with data
PUT  /api/recipes/:id       → Update recipe
```

## 📦 New Modules (3)

```gleam
// 1. Business Logic
gleam/src/meal_planner/recipe_handlers.gleam
├── new_recipe_page() -> wisp.Response
├── edit_recipe_page(id: String) -> wisp.Response
├── create_recipe(req, ctx) -> wisp.Response
└── update_recipe(req, id, ctx) -> wisp.Response

// 2. Validation Layer
gleam/src/meal_planner/recipe_validation.gleam
├── validate_recipe_input(RecipeInput) -> ValidationResult(Recipe)
├── validate_name(String) -> Result(String, ValidationError)
├── validate_ingredients(List) -> Result(List, ValidationError)
├── validate_instructions(List) -> Result(List, ValidationError)
├── validate_macros(p, f, c) -> Result(Macros, ValidationError)
└── validate_servings(Int) -> Result(Int, ValidationError)

// 3. UI Components
gleam/src/meal_planner/recipe_forms.gleam
├── recipe_form_component() -> Element(msg)
├── ingredient_input_list() -> Element(msg)
├── instruction_input_list() -> Element(msg)
└── macro_input_section() -> Element(msg)
```

## ✅ Validation Rules

| Field | Min | Max | Type | Required | Error Code |
|-------|-----|-----|------|----------|------------|
| name | 1 char | 100 chars | String | ✅ | required, too_long |
| category | - | - | Enum | ✅ | required, invalid |
| ingredients | 1 item | 50 items | List | ✅ | required, too_many |
| ingredients[].name | 1 char | 100 chars | String | ✅ | required, too_long |
| ingredients[].quantity | 1 char | 50 chars | String | ✅ | required, too_long |
| instructions | 1 step | 20 steps | List | ✅ | required, too_many |
| instructions[] | 1 char | 500 chars | String | ✅ | required, too_long |
| macros.protein | 0.0 | 1000.0 | Float | ✅ | required, invalid_range |
| macros.fat | 0.0 | 1000.0 | Float | ✅ | required, invalid_range |
| macros.carbs | 0.0 | 1000.0 | Float | ✅ | required, invalid_range |
| servings | 1 | 50 | Int | ✅ | required, invalid_range |
| fodmap_level | - | - | Enum | ✅ | required, invalid |
| vertical_compliant | - | - | Bool | ❌ | - |

## 🔄 Data Flow (Simplified)

```
User Input
    ↓
[Client Validation] ← Optional (progressive enhancement)
    ↓
POST /api/recipes
    ↓
[Parse Form Data]
    ↓
[Server Validation] ← Required (security)
    ↓
  Valid?
   ├─ Yes → [Save to DB] → [Redirect to /recipes/:id]
   └─ No → [Return 400 + Errors] → [Show inline errors]
```

## 🚨 Error Handling

| Status | Cause | Action |
|--------|-------|--------|
| 400 | Validation failed | Show field errors, preserve input |
| 404 | Recipe not found | Show "Not found" page |
| 409 | Duplicate name | Show "Name already exists" |
| 500 | Database error | Show "Try again", log error |

## 📊 Error Response Format

```json
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
```

## 🗂️ Type Definitions

```gleam
// Input Type (from form)
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
  IngredientInput(name: String, quantity: String)
}

// Validation Types
pub type ValidationError {
  ValidationError(
    field: String,
    message: String,
    code: String,
  )
}

pub type ValidationResult(a) {
  Valid(a)
  Invalid(List(ValidationError))
}

// Output Type (saved to DB)
// Uses existing shared/types.Recipe
```

## 🎨 Form Layout

```
┌─────────────────────────────────────────┐
│  Create New Recipe                      │
│                                         │
│  Recipe Name *       [____________]     │
│  Category *          [▼ Select    ]     │
│  FODMAP Level *      ( ) Low ( ) Med    │
│  [ ] Vertical Diet Compliant            │
│                                         │
│  Ingredients *                          │
│  1. [____] [_____] [Remove]             │
│  [+ Add Ingredient]                     │
│                                         │
│  Instructions *                         │
│  1. [__________________] [Remove]       │
│  [+ Add Step]                           │
│                                         │
│  Nutrition (per serving) *              │
│  Protein: [__]g  Fat: [__]g  Carbs: [__]g
│  Calories: 450 kcal (calculated)        │
│                                         │
│  Servings * [__]                        │
│                                         │
│  [Cancel]  [Create Recipe]              │
└─────────────────────────────────────────┘
```

## 📝 Implementation Phases

### Phase 1: Core Create (MVP) ⭐
- [ ] Create recipe_validation.gleam
- [ ] Create recipe_handlers.gleam
- [ ] Create recipe_forms.gleam
- [ ] Add routes to web.gleam
- [ ] Write unit tests
- [ ] Write integration tests

**Acceptance**: User can create valid recipes with full validation

### Phase 2: Edit Flow
- [ ] Implement edit_recipe_page()
- [ ] Implement update_recipe() in storage
- [ ] Add edit routes
- [ ] Reuse form component

**Acceptance**: User can edit and update existing recipes

### Phase 3: Enhanced UX
- [ ] Dynamic ingredient/instruction lists (JS)
- [ ] Real-time calorie calculation
- [ ] Draft autosave (localStorage)
- [ ] Name uniqueness check (AJAX)

**Acceptance**: Enhanced interactions without page reload

### Phase 4: Advanced (Future)
- [ ] JSONB ingredient migration
- [ ] Ingredient autocomplete (USDA)
- [ ] Recipe photo upload
- [ ] Recipe tags/search

## 🔐 Security Checklist

- [ ] HTML escape all user input
- [ ] Use parameterized queries (Pog)
- [ ] Add CSRF token to forms
- [ ] Validate recipe ID format (UUID)
- [ ] Rate limit creation (max 10/min)
- [ ] Sanitize file paths (future photos)

## 📈 Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Form load | <500ms | <1000ms |
| Form submit | <200ms | <500ms |
| Success rate | >95% | >90% |
| Validation error rate | <50% | <70% |

## 🧪 Test Coverage

```
recipe_validation_test.gleam (20+ tests)
├── validate_name tests (4)
├── validate_category tests (3)
├── validate_ingredients tests (6)
├── validate_instructions tests (4)
├── validate_macros tests (5)
└── validate_servings tests (3)

recipe_handlers_test.gleam (15+ tests)
├── create_recipe happy path (3)
├── create_recipe error paths (5)
├── edit_recipe tests (4)
├── update_recipe tests (3)

End-to-end tests (manual)
├── Full create workflow
├── Full edit workflow
├── Error recovery scenarios
└── Accessibility testing
```

## 🏗️ Database (Existing)

```sql
CREATE TABLE recipes (
  id TEXT PRIMARY KEY,                  -- UUID
  name TEXT NOT NULL,                   -- 1-100 chars
  ingredients TEXT NOT NULL,            -- Serialized "name:qty|name:qty"
  instructions TEXT NOT NULL,           -- Serialized "step1|step2"
  protein DOUBLE PRECISION NOT NULL,    -- 0.0-1000.0
  fat DOUBLE PRECISION NOT NULL,        -- 0.0-1000.0
  carbs DOUBLE PRECISION NOT NULL,      -- 0.0-1000.0
  servings INTEGER NOT NULL,            -- 1-50
  category TEXT NOT NULL,               -- From predefined list
  fodmap_level TEXT NOT NULL,           -- 'low', 'medium', 'high'
  vertical_compliant BOOLEAN NOT NULL,  -- Default FALSE
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## 🎭 Architecture Decisions (ADRs)

1. **SSR with Progressive Enhancement** - Consistent with app, SEO-friendly
2. **Dual Validation** - UX (client) + Security (server)
3. **Keep Pipe Serialization** - No migration needed for MVP
4. **Single Reusable Form** - DRY principle for create/edit

## 📚 Documentation Links

- Full architecture: `docs/architecture/recipe-form-architecture.md`
- Data flow diagrams: `docs/architecture/recipe-form-data-flow.md`
- Index: `docs/architecture/README.md`

## 🚀 Getting Started

1. Read full architecture doc (sections 1-6)
2. Review data flow diagrams
3. Start with Phase 1 (recipe_validation.gleam)
4. Follow TDD approach (write tests first)
5. Reference this card for quick lookups

---

**Version**: 1.0
**Date**: 2025-12-03
**Status**: Ready for Implementation
**Priority**: High (Core feature)
