# Vertical Diet Compliance API Endpoint

## Overview

The `GET /api/diet/vertical/compliance/{recipe_id}` endpoint returns vertical diet compliance analysis for a recipe based on Stan Efferding's Vertical Diet principles.

## Endpoint Details

**URL:** `GET /api/diet/vertical/compliance/{recipe_id}`

**Method:** GET

**Path Parameters:**
- `recipe_id` (string): The ID of the recipe to check (currently returns mock data for demonstration)

## Response Format

```json
{
  "recipe_id": "123",
  "recipe_name": "Grass-Fed Beef with White Rice and Spinach",
  "compliant": true,
  "score": 75,
  "reasons": [
    "Has red meat detected as primary protein source",
    "Has simple carbs (white rice, potatoes) detected"
  ],
  "recommendations": [
    "Consider adding low FODMAP vegetables"
  ]
}
```

## Response Fields

- **recipe_id** (string): The recipe ID from the request
- **recipe_name** (string): Name of the recipe being analyzed
- **compliant** (boolean): Whether the recipe meets vertical diet guidelines (score >= 70)
- **score** (integer): Compliance score from 0-100 based on:
  - Red meat detection (0-25 points)
  - Simple carbs detection (0-25 points)
  - Low FODMAP vegetables (0-20 points)
  - Ingredient simplicity (<=8 ingredients: 15 points, else 5 points)
  - Preparation simplicity (<=6 steps: 10 points, else 5 points)
  - Recipe quality rating (>=4 stars: 5 points, else 2 points)
- **reasons** (array): List of reasons explaining non-compliance or missing elements
- **recommendations** (array): Suggestions for improving vertical diet compliance

## Compliance Scoring

The endpoint evaluates recipes against the following vertical diet principles:

1. **Protein Source**: Must contain red meat (beef, lamb, bison, venison)
2. **Carbohydrates**: Should include simple carbs (white rice, potatoes)
3. **Vegetables**: Low FODMAP vegetables (spinach, carrots, kale, etc.)
4. **Simplicity**: 5-8 core ingredients
5. **Preparation**: Simple, straightforward cooking instructions

## Implementation Notes

**Current Status:** Prototype with mock data

The current implementation:
- Returns mock recipe data for testing
- Uses the vertical_diet_compliance module to perform the actual analysis
- Ignores the recipe_id parameter and returns the same mock response

**Future Enhancements:**
1. Integrate with Tandoor recipe database to fetch actual recipes
2. Support dynamic recipe analysis based on ingredient list
3. Cache compliance results
4. Add batch compliance checking
5. Support custom compliance profiles

## Example Usage

### Request
```bash
curl -X GET "http://localhost:8080/api/diet/vertical/compliance/123"
```

### Response
```json
{
  "recipe_id": "123",
  "recipe_name": "Grass-Fed Beef with White Rice and Spinach",
  "compliant": true,
  "score": 95,
  "reasons": [],
  "recommendations": []
}
```

## Testing

The endpoint can be tested with:

```bash
# Test the vertical diet compliance endpoint
curl http://localhost:8080/api/diet/vertical/compliance/test-recipe-1

# With recipe ID parameter
curl http://localhost:8080/api/diet/vertical/compliance/my-beef-recipe
```

## Error Handling

Currently, the endpoint doesn't return error responses. Future versions should handle:
- Invalid recipe IDs (404 Not Found)
- Database connection errors (503 Service Unavailable)
- Invalid recipe data format (400 Bad Request)

## Files Modified

- `gleam/src/meal_planner/web.gleam`: Added `vertical_diet_compliance_handler` function
- Route handler added to `handle_request` function

## Related Files

- `gleam/src/meal_planner/vertical_diet_compliance.gleam`: Core compliance checking logic
- `gleam/test/vertical_diet_compliance_test.gleam`: Comprehensive unit tests for compliance checks
