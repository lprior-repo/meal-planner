# API Differences: Mealie vs Tandoor

## Overview

This document provides a detailed comparison of the Mealie Recipe Manager API and the Tandoor Recipe Manager API. This document was created during the migration from Mealie to Tandoor (December 2025) to help developers understand the key differences and handle the transition effectively.

## Quick Comparison Table

| Feature | Mealie | Tandoor | Impact |
|---------|--------|---------|--------|
| **Recipe ID** | slug (string) | id (integer) | Conversion required in mapper |
| **Ingredients** | Nested objects with complex structure | Simplified ingredient list | Transform in mapper |
| **Nutrition Data** | Optional strings | Structured numeric data | Handle missing values gracefully |
| **Pagination** | Query parameter-based (limit, offset) | Cursor-based with `next` URL | Update client pagination logic |
| **Authentication** | Bearer token (Authorization header) | Token header (same approach) | No change to auth mechanism |
| **Base Endpoints** | `/api/recipes/` | `/api/recipes/` | Same prefix |
| **Response Format** | JSON with nested recipe objects | Flatter JSON structure | Adjust JSON parsing |

## Detailed API Differences

### 1. Authentication

#### Mealie
```gleam
// Authorization header with Bearer token
Authorization: Bearer {MEALIE_API_TOKEN}

// Token is generated in Mealie UI: Settings → API Tokens
// Format: alphanumeric string, typically 40 characters
```

#### Tandoor
```gleam
// Authorization header with Bearer token (same approach)
Authorization: Bearer {TANDOOR_API_TOKEN}

// Token is generated in Tandoor UI: System → API Tokens
// Format: alphanumeric string, UUID-like format
```

**Migration Impact**: No changes required - both systems use Bearer token authentication in the Authorization header.

---

### 2. Recipe ID Handling

#### Mealie
```json
{
  "id": "pan-seared-salmon",
  "name": "Pan Seared Salmon",
  "slug": "pan-seared-salmon"
}
```

**Characteristics:**
- Uses slug-based IDs (human-readable strings)
- ID format: kebab-case, URL-safe
- Used in URLs: `/api/recipes/pan-seared-salmon`
- Same value in both `id` and `slug` fields

#### Tandoor
```json
{
  "id": 42,
  "name": "Pan Seared Salmon",
  "internal_id": "abc-123-def"
}
```

**Characteristics:**
- Uses numeric IDs (auto-incrementing integers)
- ID format: positive integers (1, 2, 3, ...)
- Used in URLs: `/api/recipes/42`
- Optionally includes `internal_id` for internal references

**Migration Impact**: Critical
- Must convert slug references to integer IDs during migration
- Maintain mapping table: `mealie_slug → tandoor_id` for audit trail
- Update database schema to store numeric recipe IDs
- Update all food logs that reference Mealie recipe slugs

---

### 3. Ingredient Structure

#### Mealie

```json
{
  "id": "11112d52-7a91-43bd-a87a-e1968b6d4b5b",
  "name": "Salmon Fillet",
  "quantity": 1.0,
  "unit": {
    "id": "unit-id",
    "abbreviation": "1",
    "name": "Item"
  },
  "food": {
    "id": "food-id",
    "name": "Salmon, Atlantic, farmed, cooked, dry heat",
    "description": "Raw"
  },
  "referenceId": null,
  "foodId": "food-id",
  "notes": "Skin removed"
}
```

**Characteristics:**
- Complex nested structure with embedded food objects
- UUID-based ingredient IDs
- Separate `food` object with nutritional data
- Quantity stored as decimal float
- Unit is nested object with multiple fields
- Optional `referenceId` for linked recipes
- Notes field for preparation instructions

#### Tandoor

```json
{
  "id": 42,
  "food": {
    "id": 10,
    "name": "Salmon, Atlantic, cooked"
  },
  "unit": {
    "id": 15,
    "abbreviation": "g"
  },
  "amount": 150.0,
  "note": "Skin removed"
}
```

**Characteristics:**
- Flatter structure with minimal nesting
- Numeric ingredient IDs
- Food reference includes only `id` and `name`
- Amount field instead of quantity (same concept)
- Unit is simpler object (mainly ID and abbreviation)
- Single `note` field (no plural)
- No explicit reference to food nutritional data (must fetch separately)

**Migration Impact**: Moderate
- Parser needs to handle different JSON structure
- Must transform from complex Mealie format to simpler Tandoor format
- Adapt mapper to flatten ingredient hierarchy
- Handle field name differences (`quantity` → `amount`, `notes` → `note`)

---

### 4. Nutrition Data

#### Mealie

```json
{
  "nutrition": {
    "calories": "320",
    "carbohydrates": "0",
    "protein": "35",
    "fat": "18",
    "fiber": "0"
  }
}
```

**Characteristics:**
- Optional field (may be missing entirely)
- All values stored as strings
- Values can be empty strings for missing data
- Limited macronutrient fields (5 standard fields)
- Must be parsed to float/int for calculations
- Accuracy depends on manual entry or food database

#### Tandoor

```json
{
  "nutrition": {
    "calories": 320.5,
    "carbs": 0.0,
    "protein": 35.2,
    "fats": 18.1,
    "fiber": 0.0,
    "sugars": 0.0,
    "sodium": 450.0
  }
}
```

**Characteristics:**
- More complete nutrition data (includes sugars, sodium, etc.)
- All values are numeric (float)
- Structured with field names (carbs instead of carbohydrates)
- Can still be optional or missing
- Better precision (decimal places preserved)
- Computed from ingredient nutrition data

**Migration Impact**: Moderate to High
- Nutrition mapper must handle string parsing for Mealie → float for Tandoor
- Different field names require mapping (carbs vs carbohydrates, fats vs fat)
- Additional fields in Tandoor (sugars, sodium) can be safely ignored for compatibility
- Validation: ensure macro calculations match expectations after conversion

---

### 5. Pagination

#### Mealie

```
GET /api/recipes?limit=10&offset=0

Response Headers (optional):
X-Total-Count: 147

Response Body:
{
  "items": [
    { recipe object 1 },
    { recipe object 2 }
  ],
  "total": 147
}
```

**Characteristics:**
- Limit/offset style pagination
- Limit: number of items per page (default varies)
- Offset: number of items to skip (0-based)
- Total count in response body or headers
- Stateless pagination (any page can be fetched independently)
- Works for any starting position

#### Tandoor

```
GET /api/recipes/?limit=10

Response Body:
{
  "count": 147,
  "next": "http://localhost:8000/api/recipes/?limit=10&offset=10",
  "previous": "http://localhost:8000/api/recipes/?limit=10&offset=0",
  "results": [
    { recipe object 1 },
    { recipe object 2 }
  ]
}
```

**Characteristics:**
- Hybrid pagination (limit/offset with cursor-like URLs)
- `next` and `previous` URLs provided for traversal
- `count` field shows total count
- `results` contains the actual data
- More RESTful with built-in navigation URLs
- Still supports direct offset queries

**Migration Impact**: Low to Moderate
- Update client pagination logic to use `next`/`previous` URLs
- Simpler for sequential traversal (follow links)
- Must handle null `next` value for last page
- Can still use limit/offset directly if preferred
- Total count field remains available

---

### 6. Endpoint Structure

#### Mealie Endpoints

| Operation | Mealie Endpoint | Method | Notes |
|-----------|-----------------|--------|-------|
| List recipes | `GET /api/recipes` | GET | Paginated with limit/offset |
| Get recipe | `GET /api/recipes/{slug}` | GET | Uses slug as identifier |
| Create recipe | `POST /api/recipes` | POST | Returns full recipe object |
| Update recipe | `PUT /api/recipes/{slug}` | PUT | Full recipe update |
| Partial update | `PATCH /api/recipes/{slug}` | PATCH | Partial fields only |
| Delete recipe | `DELETE /api/recipes/{slug}` | DELETE | Soft or hard delete |
| List ingredients | `GET /api/recipes/{slug}/ingredients` | GET | Get recipe ingredients |
| Search | `GET /api/recipes/search` | GET | Query parameter-based |

#### Tandoor Endpoints

| Operation | Tandoor Endpoint | Method | Notes |
|-----------|------------------|--------|-------|
| List recipes | `GET /api/recipes/` | GET | Paginated with limit/offset |
| Get recipe | `GET /api/recipes/{id}/` | GET | Uses numeric ID |
| Create recipe | `POST /api/recipes/` | POST | Returns full recipe object |
| Update recipe | `PUT /api/recipes/{id}/` | PUT | Full recipe update |
| Partial update | `PATCH /api/recipes/{id}/` | PATCH | Partial fields only |
| Delete recipe | `DELETE /api/recipes/{id}/` | DELETE | Hard delete |
| Get ingredients | `GET /api/recipes/{id}/` | GET | Included in recipe object |
| Search | `GET /api/recipes/?search=query` | GET | Query parameter-based |

**Key Differences:**
- Tandoor uses trailing slashes in endpoints (`/api/recipes/` vs `/api/recipes`)
- Tandoor uses numeric IDs in URLs
- Tandoor includes ingredients in recipe object (no separate endpoint)
- Both support search with query parameters

**Migration Impact**: Low
- Update URLs to use numeric IDs instead of slugs
- Add trailing slashes to Tandoor requests
- Ingredients already included in recipe response (may reduce requests)

---

### 7. Error Handling

#### Mealie Error Responses

```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "Recipe name is required",
      "type": "value_error"
    }
  ]
}
```

**Status Codes:**
- 200 OK - Success
- 201 Created - Resource created
- 204 No Content - Delete successful
- 400 Bad Request - Validation errors
- 401 Unauthorized - Invalid/missing token
- 404 Not Found - Recipe not found
- 422 Unprocessable Entity - Validation error with details
- 500 Internal Server Error - Server error

#### Tandoor Error Responses

```json
{
  "error": "Recipe name is required"
}
```

or

```json
{
  "name": ["This field may not be blank."]
}
```

**Status Codes:**
- 200 OK - Success
- 201 Created - Resource created
- 204 No Content - Delete successful
- 400 Bad Request - Validation errors
- 401 Unauthorized - Invalid/missing token
- 403 Forbidden - Permission denied
- 404 Not Found - Recipe not found
- 500 Internal Server Error - Server error

**Migration Impact**: Low
- Error format slightly different but same general structure
- Same HTTP status codes used
- Error handling logic mostly compatible
- May need to adjust error message parsing

---

### 8. Request/Response Format

#### Mealie Recipe Object

```json
{
  "id": "pan-seared-salmon",
  "name": "Pan Seared Salmon",
  "slug": "pan-seared-salmon",
  "image": "https://...",
  "description": "Quick and easy salmon recipe",
  "recipeYield": "2 servings",
  "prepTime": "PT10M",
  "cookTime": "PT15M",
  "totalTime": "PT25M",
  "ingredients": [ /* ... */ ],
  "instructions": [
    {
      "id": "id1",
      "title": "Preparation",
      "text": "Pat salmon dry"
    }
  ],
  "nutrition": { /* ... */ },
  "tags": ["quick", "protein"],
  "rating": 5
}
```

#### Tandoor Recipe Object

```json
{
  "id": 42,
  "name": "Pan Seared Salmon",
  "internal_id": "abc-123",
  "description": "Quick and easy salmon recipe",
  "servings": 2,
  "servings_text": "2",
  "prep_time": 10,
  "cooking_time": 15,
  "ingredients": [ /* ... */ ],
  "steps": [
    {
      "id": 1,
      "name": "Preparation",
      "instructions": "Pat salmon dry",
      "time": 5
    }
  ],
  "nutrition": { /* ... */ },
  "keywords": [
    {
      "id": 1,
      "name": "quick"
    }
  ]
}
```

**Key Differences:**

| Field | Mealie | Tandoor | Migration |
|-------|--------|---------|-----------|
| ID | slug string | numeric int | Convert to int |
| Image | Direct URL | May require separate request | Update image handling |
| Yield/Servings | `recipeYield` string | `servings` numeric | Parse string to int |
| Time fields | ISO 8601 duration strings | Minutes as numeric | Parse duration strings |
| Instructions | Array with title/text | Array with name/instructions | Rename fields |
| Tags | Array of strings | Array of keyword objects | Transform structure |
| Rating | Numeric | Not included | Handle missing data |
| Internal ID | Not present | `internal_id` present | Store for reference |

**Migration Impact**: Moderate
- Field name mapping required (recipeYield → servings)
- Time format conversion (ISO 8601 → minutes)
- Tag structure transformation (string → object)
- Adapt JSON parser for different structure

---

### 9. Recipe Creation

#### Mealie Create Request

```json
POST /api/recipes
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "New Recipe",
  "slug": "new-recipe",
  "description": "Description",
  "recipeYield": "4",
  "prepTime": "PT15M",
  "cookTime": "PT30M",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "quantity": 1.0,
      "unit": {
        "abbreviation": "1"
      }
    }
  ],
  "instructions": [
    {
      "title": "Step 1",
      "text": "Do something"
    }
  ]
}
```

#### Tandoor Create Request

```json
POST /api/recipes/
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "New Recipe",
  "description": "Description",
  "servings": 4,
  "servings_text": "4",
  "prep_time": 15,
  "cooking_time": 30,
  "ingredients": [
    {
      "food": {
        "name": "Ingredient Name"
      },
      "unit": {
        "name": "item"
      },
      "amount": 1.0
    }
  ],
  "steps": [
    {
      "name": "Step 1",
      "instructions": "Do something"
    }
  ]
}
```

**Migration Impact**: Moderate to High
- Slug not required in Tandoor (auto-generated)
- Time fields must be converted (string duration → minutes)
- Ingredient structure completely different
- Step structure changed (title → name, text → instructions)
- Servings format different (string required in Tandoor)

**Implementation**: Create transformation function in mapper module

---

### 10. Bulk Operations

#### Mealie Bulk API

**Not explicitly documented**, but supports:
- Individual CREATE/PUT/DELETE operations
- Batch migration requires looping through recipes

#### Tandoor Bulk API

**Also supports**: Individual operations primarily
- Consider bulk operations in future versions
- Current implementation: loop through recipe creation

**Migration Impact**: Low
- Both systems require sequential API calls
- No built-in bulk endpoint
- Migration script handles batching

---

## Implementation Strategy

### Type Definitions

```gleam
// Mealie types
pub type MealieRecipe {
  MealieRecipe(
    id: String,
    name: String,
    slug: String,
    description: String,
    ingredients: List(MealieIngredient),
    nutrition: Option(MealieNutrition),
    // ... other fields
  )
}

// Tandoor types
pub type TandoorRecipe {
  TandoorRecipe(
    id: Int,
    name: String,
    description: String,
    ingredients: List(TandoorIngredient),
    nutrition: Option(TandoorNutrition),
    // ... other fields
  )
}

// Internal unified type (no external system dependencies)
pub type Recipe {
  Recipe(
    id: String,
    name: String,
    description: String,
    ingredients: List(Ingredient),
    nutrition: Option(Macros),
    // ... other fields
  )
}
```

### Conversion Functions

```gleam
// Tandoor → Internal
pub fn tandoor_to_recipe(tandoor: TandoorRecipe) -> Recipe {
  let recipe_id = int.to_string(tandoor.id)
  Recipe(
    id: recipe_id,
    name: tandoor.name,
    description: tandoor.description,
    ingredients: list.map(tandoor.ingredients, tandoor_ingredient_to_ingredient),
    nutrition: option.map(tandoor.nutrition, tandoor_nutrition_to_macros),
  )
}

// Handle nutrition data
fn tandoor_nutrition_to_macros(nut: TandoorNutrition) -> Macros {
  Macros(
    calories: nut.calories,
    carbs: nut.carbs,
    protein: nut.protein,
    fat: nut.fats,
  )
}
```

---

## Migration Checklist

- [x] Understand Mealie API structure
- [x] Understand Tandoor API structure
- [x] Document key differences (this document)
- [ ] Implement Tandoor type definitions
- [ ] Implement conversion functions
- [ ] Create Tandoor HTTP client
- [ ] Update auto planner to use Tandoor
- [ ] Update food logging with Tandoor support
- [ ] Migrate recipe data (Mealie → Tandoor)
- [ ] Update database schema
- [ ] Update tests for Tandoor
- [ ] Verify data integrity
- [ ] Remove Mealie code

---

## References

### Mealie API Documentation
- Version: 1.x
- Documentation: https://docs.mealie.io/api/
- Auth: Bearer token via Authorization header
- Base URL (default): http://localhost:9000/api

### Tandoor API Documentation
- Version: 1.5+
- Documentation: https://tandoor.dev/api/
- Auth: Bearer token via Authorization header
- Base URL (default): http://localhost:8000/api

---

## Related Documents

- [Mealie to Tandoor Migration Design](../openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/design.md)
- [Tandoor Integration Specification](../openspec/specs/tandoor-integration/spec.md)
- [Migration Process Guide](./migrations/MIGRATION_PROCESS.md)

---

## Summary Table by Category

### Request Handling
| Category | Mealie | Tandoor | Change |
|----------|--------|---------|--------|
| Auth | Bearer token | Bearer token | None |
| Format | JSON | JSON | None |
| Trailing slash | No | Yes | Add slashes |
| ID type | slug string | numeric int | Convert |

### Response Handling
| Category | Mealie | Tandoor | Change |
|----------|--------|---------|--------|
| Pagination | limit/offset | limit/offset + links | Minor |
| Ingredients | Separate | Nested | Flatten |
| Nutrition | String values | Numeric values | Parse/convert |
| Tags | String array | Object array | Transform |
| Instructions | title/text | name/instructions | Rename |

### Data Format
| Category | Mealie | Tandoor | Change |
|----------|--------|---------|--------|
| Times | ISO 8601 | Minutes | Convert |
| Servings | String | Numeric | Parse |
| Yield | recipeYield | servings | Rename |
| Slug | Required | Auto-generated | Remove |

---

**Document Status**: Complete - meal-planner-gipe
**Last Updated**: December 12, 2025
**Author**: Claude Code Agent
