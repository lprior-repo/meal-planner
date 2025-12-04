# Recipe Fetcher Module Usage

## Overview

The `meal_planner/external/recipe_fetcher` module provides a unified interface for fetching recipes from external recipe APIs. Currently supports TheMealDB (free, no API key required) with placeholder support for Spoonacular.

## Quick Start

```gleam
import meal_planner/external/recipe_fetcher

// Fetch a single recipe by ID
case recipe_fetcher.fetch_recipe(recipe_fetcher.TheMealDB, "52772") {
  Ok(recipe) -> {
    // Use the recipe
    io.println("Found: " <> recipe.name)
  }
  Error(error) -> {
    io.println(recipe_fetcher.error_message(error))
  }
}

// Search for recipes
case recipe_fetcher.search_recipes(recipe_fetcher.TheMealDB, "chicken", 10) {
  Ok(recipes) -> {
    list.each(recipes, fn(recipe) {
      io.println(recipe.name)
    })
  }
  Error(error) -> {
    io.println(recipe_fetcher.error_message(error))
  }
}
```

## API Reference

### Types

#### `RecipeSource`
Supported external recipe sources:
- `TheMealDB` - Free recipe API (no key required)
- `Spoonacular` - Commercial recipe API (requires API key, not yet implemented)

#### `FetchError`
Error types for recipe fetching:
- `NetworkError(String)` - Connection failed, timeout, etc.
- `ParseError(String)` - Invalid JSON response
- `RateLimitError` - Too many requests
- `ApiKeyMissing` - API key required but not provided
- `RecipeNotFound(String)` - Recipe ID not found
- `InvalidQuery(String)` - Invalid query parameters

### Functions

#### `fetch_recipe(source: RecipeSource, recipe_id: String) -> Result(Recipe, FetchError)`
Fetch a single recipe by ID from the specified source.

**Parameters:**
- `source`: The recipe source to query (e.g., `TheMealDB`)
- `recipe_id`: The recipe ID (specific to the source)

**Returns:**
- `Ok(Recipe)`: Successfully fetched recipe
- `Error(FetchError)`: Failed to fetch

**Example:**
```gleam
let result = recipe_fetcher.fetch_recipe(TheMealDB, "52772")
```

#### `search_recipes(source: RecipeSource, query: String, limit: Int) -> Result(List(Recipe), FetchError)`
Search for recipes by query string.

**Parameters:**
- `source`: The recipe source to query
- `query`: Search query string
- `limit`: Maximum number of results (1-100, automatically validated)

**Returns:**
- `Ok(List(Recipe))`: List of matching recipes
- `Error(FetchError)`: Search failed

**Example:**
```gleam
let results = recipe_fetcher.search_recipes(TheMealDB, "pasta", 20)
```

#### `source_name(source: RecipeSource) -> String`
Get the display name for a recipe source.

#### `requires_api_key(source: RecipeSource) -> Bool`
Check if a source requires an API key.

#### `fetch_recipes_batch(source: RecipeSource, recipe_ids: List(String)) -> Result(List(Recipe), FetchError)`
Batch fetch multiple recipes by ID.

#### `error_message(error: FetchError) -> String`
Convert a FetchError to a user-friendly error message.

## TheMealDB Integration

### Supported Features
- Recipe lookup by ID
- Recipe search by name
- Ingredient extraction with quantities
- Instruction parsing (line-by-line)
- Category information

### Limitations
- **No nutritional data**: TheMealDB doesn't provide detailed nutrition. Macros are estimated based on ingredient count.
- **Limited ingredients**: Only first 5 ingredients are parsed (TheMealDB supports up to 20)
- **Default servings**: All recipes default to 4 servings
- **No FODMAP data**: FODMAP level defaults to Low
- **No Vertical Diet compliance**: Defaults to False

### Example Response Mapping
TheMealDB returns recipes in their own format, which is automatically mapped to the internal `Recipe` type:

```
TheMealDB Recipe → Internal Recipe
==========================================
idMeal         → id: "themealdb-52772"
strMeal        → name: "Teriyaki Chicken"
strIngredient1 → ingredients[0].name
strMeasure1    → ingredients[0].quantity
strInstructions→ instructions (parsed by line)
strCategory    → category
```

## Error Handling

Always handle errors gracefully:

```gleam
case recipe_fetcher.fetch_recipe(TheMealDB, recipe_id) {
  Ok(recipe) -> {
    // Success - use the recipe
  }
  Error(NetworkError(msg)) -> {
    // Retry or show network error to user
  }
  Error(ParseError(msg)) -> {
    // Log error, API format may have changed
  }
  Error(RecipeNotFound(id)) -> {
    // Show "recipe not found" message
  }
  Error(InvalidQuery(msg)) -> {
    // Validate input before calling
  }
  Error(_) -> {
    // Generic error handling
  }
}
```

## Future Enhancements

### Spoonacular Integration
To add Spoonacular support:
1. Add API key configuration
2. Implement `spoonacular_fetch_recipe()` and `spoonacular_search_recipes()` functions
3. Update the `fetch_recipe` and `search_recipes` functions to route to Spoonacular

### Enhanced TheMealDB
- Parse all 20 ingredients instead of just 5
- Add nutrition API integration (e.g., USDA FoodData Central)
- Support filtering by category, area, or main ingredient

### Caching
Add response caching to reduce API calls:
```gleam
// Future enhancement
pub fn fetch_recipe_cached(
  source: RecipeSource,
  recipe_id: String,
  cache: Cache,
) -> Result(Recipe, FetchError)
```

## Testing

The module includes comprehensive unit tests in `test/meal_planner/external/recipe_fetcher_test.gleam`:
- Type validation tests
- Error message formatting tests
- API key requirement tests
- Input validation tests

Run tests with:
```bash
gleam test --target=erlang
```

## Dependencies

- `gleam_httpc` - HTTP client for API requests
- `gleam_json` - JSON parsing
- `gleam/dynamic/decode` - Type-safe JSON decoding

## Contributing

When adding new recipe sources:
1. Add the source to the `RecipeSource` type
2. Implement fetch and search functions for that source
3. Add comprehensive tests
4. Update this documentation
