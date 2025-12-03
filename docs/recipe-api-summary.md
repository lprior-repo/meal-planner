# Recipe Creation API - Summary

## Overview
Documentation for recipe creation endpoints in the Meal Planner application.

## Files Created
1. **`/home/lewis/src/meal-planner/docs/recipe-api.yaml`** - Complete OpenAPI 3.0 specification
2. **`/home/lewis/src/meal-planner/docs/recipe-api-curl-examples.md`** - Practical cURL examples with error cases

## Endpoints Documented

### 1. GET /recipes/new
- **Purpose**: Displays HTML form for creating new recipes
- **Status**: ✅ Implemented
- **Response**: Server-side rendered HTML form with JavaScript for dynamic fields
- **Status Code**: 200 OK

### 2. POST /api/recipes
- **Purpose**: Creates a new recipe with nutritional data
- **Status**: ⚠️ NOT YET IMPLEMENTED (form exists, handler needed)
- **Request Format**: `application/x-www-form-urlencoded`
- **Response Format**: `application/json`
- **Status Codes**:
  - **201 Created**: Recipe successfully created
  - **400 Bad Request**: Validation failed
  - **500 Internal Server Error**: Database or system failure

## Request Schema

### Required Fields
| Field | Type | Validation | Example |
|-------|------|------------|---------|
| name | string | Non-empty, max 255 chars | "Chicken and Rice" |
| category | enum | chicken/beef/pork/seafood/vegetarian/other | "chicken" |
| servings | integer | >= 1 | 1 |
| protein | float | >= 0.0 | 45.0 |
| fat | float | >= 0.0 | 8.0 |
| carbs | float | >= 0.0 | 45.0 |
| fodmap_level | enum | low/medium/high | "low" |

### Optional Fields
| Field | Type | Default | Example |
|-------|------|---------|---------|
| vertical_compliant | boolean | false | true |

### Dynamic Fields (1-indexed)
- **Ingredients**: `ingredient_name_N`, `ingredient_quantity_N`
- **Instructions**: `instruction_N`

## Response Schema

### Recipe Object
```json
{
  "id": "abc123-def456",
  "name": "Chicken and Rice",
  "category": "chicken",
  "servings": 1,
  "macros": {
    "protein": 45.0,
    "fat": 8.0,
    "carbs": 45.0,
    "calories": 472.0
  },
  "fodmap_level": "low",
  "vertical_compliant": true,
  "ingredients": [
    {
      "name": "Chicken breast",
      "quantity": "8 oz"
    }
  ],
  "instructions": [
    "Cook rice according to package directions"
  ]
}
```

## Validation Rules

### Name
- ✅ Required
- ✅ Non-empty string
- ✅ Max length: 255 characters

### Category
- ✅ Required
- ✅ Must be one of: `chicken`, `beef`, `pork`, `seafood`, `vegetarian`, `other`

### Servings
- ✅ Required
- ✅ Integer >= 1
- ✅ Max: 100

### Macros (Protein, Fat, Carbs)
- ✅ Required
- ✅ Float >= 0.0
- ✅ Allows decimal values (step: 0.1)

### FODMAP Level
- ✅ Required
- ✅ Must be one of: `low`, `medium`, `high`

### Vertical Compliant
- ✅ Optional boolean
- ✅ Default: false

### Ingredients
- ✅ At least one required
- ✅ Each ingredient needs both name and quantity
- ✅ Supports unlimited ingredients (numbered fields)

### Instructions
- ✅ At least one required
- ✅ Supports unlimited steps (numbered fields)

## Calorie Calculation

Calories are automatically calculated using the formula:
```
calories = (protein × 4) + (fat × 9) + (carbs × 4)
```

Example:
- Protein: 45g × 4 = 180 cal
- Fat: 8g × 9 = 72 cal
- Carbs: 45g × 4 = 180 cal
- **Total: 432 calories**

## Error Response Format

### 400 Bad Request - Validation Error
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "name",
      "message": "Recipe name is required"
    },
    {
      "field": "servings",
      "message": "Servings must be at least 1"
    }
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Failed to save recipe to database"
}
```

## Example Requests

### Simple Recipe
```bash
curl -X POST http://localhost:8080/api/recipes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Chicken and Rice" \
  -d "category=chicken" \
  -d "servings=1" \
  -d "protein=45.0" \
  -d "fat=8.0" \
  -d "carbs=45.0" \
  -d "fodmap_level=low" \
  -d "vertical_compliant=true" \
  -d "ingredient_name_0=Chicken breast" \
  -d "ingredient_quantity_0=8 oz" \
  -d "ingredient_name_1=White rice" \
  -d "ingredient_quantity_1=1 cup" \
  -d "instruction_0=Cook rice" \
  -d "instruction_1=Grill chicken" \
  -d "instruction_2=Serve together"
```

## Testing Checklist

- ✅ Test form rendering at `/recipes/new`
- ⚠️ Test POST endpoint (needs implementation)
- ⚠️ Test validation for all required fields
- ⚠️ Test negative macro values rejection
- ⚠️ Test invalid category rejection
- ⚠️ Test zero/negative servings rejection
- ⚠️ Test missing ingredients/instructions rejection
- ⚠️ Test database error handling
- ⚠️ Verify calorie calculation
- ⚠️ Test dynamic ingredient fields
- ⚠️ Test dynamic instruction fields
- ⚠️ Test Location header in 201 response

## Implementation Status

### ✅ Completed
- GET /recipes/new HTML form rendering
- Form UI with dynamic JavaScript for adding ingredients/instructions
- Form validation on client side (HTML5 required attributes)

### ⚠️ Pending Implementation
The POST handler for `/api/recipes` is not yet implemented. The handler needs to:

1. **Parse form data** - Extract all form fields from request body
2. **Validate inputs** - Check all validation rules
3. **Generate ID** - Create unique identifier (UUID)
4. **Calculate calories** - From macro values
5. **Parse dynamic fields** - Collect all numbered ingredient/instruction fields
6. **Save to database** - Use storage module functions
7. **Return response** - 201 with Location header, or 400/500 on error

### Implementation Location
Add handler in `/home/lewis/src/meal-planner/gleam/src/meal_planner/web.gleam`:
- Update `handle_api()` function to handle POST requests to `/api/recipes`
- Add form parsing logic
- Add validation logic
- Add database save operation

## Related Files

### Source Code
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/web.gleam` - Web handlers
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage.gleam` - Database operations
- `/home/lewis/src/meal-planner/shared/src/shared/types.gleam` - Type definitions

### Documentation
- `/home/lewis/src/meal-planner/docs/recipe-api.yaml` - OpenAPI specification
- `/home/lewis/src/meal-planner/docs/recipe-api-curl-examples.md` - cURL examples
- `/home/lewis/src/meal-planner/docs/recipe-api-summary.md` - This file

## Memory Keys (Claude Flow)

Documentation stored in memory for agent coordination:
- `docs/recipe-api/openapi-spec` - OpenAPI YAML specification
- `docs/recipe-api/curl-examples` - cURL examples and error cases

## Notes

1. **Form Submission**: The HTML form at `/recipes/new` submits to `/api/recipes` but the POST handler is not implemented
2. **Database Schema**: Recipe table should already exist from migrations
3. **ID Generation**: Use UUID for recipe IDs
4. **Macro Validation**: Server-side validation should mirror client-side HTML5 validation
5. **Dynamic Fields**: Form supports unlimited ingredients/instructions via numbered fields
6. **FODMAP & Vertical Diet**: These are specific dietary tracking features for the Vertical Diet methodology
7. **Calorie Calculation**: Always calculate server-side, don't trust client values

## Quick Reference

**Base URL**: `http://localhost:8080`

**Endpoints**:
- `GET /recipes/new` - Recipe creation form
- `POST /api/recipes` - Create recipe (NOT IMPLEMENTED)

**Categories**: chicken, beef, pork, seafood, vegetarian, other
**FODMAP Levels**: low, medium, high
**Macros**: protein (g), fat (g), carbs (g)
**Calories**: Auto-calculated (P×4 + F×9 + C×4)
