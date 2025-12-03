# Auto Meal Planner API Routes Architecture

## Overview

This document defines the RESTful API routes for the auto meal planner feature. The API follows the existing routing patterns established in `/gleam/src/meal_planner/web.gleam` and integrates with the auto planner data model defined in `/gleam/src/meal_planner/auto_planner/`.

## Existing Routing Structure

The application currently uses:
- **SSR Pages**: Direct routes (e.g., `/recipes`, `/dashboard`, `/profile`)
- **API Routes**: Prefixed with `/api` (e.g., `/api/recipes`, `/api/foods`)
- **Static Assets**: Served from `/static`

## Auto Planner Route Design

### 1. Generate Auto Meal Plan

**Endpoint**: `POST /api/auto-plans/generate`

**Purpose**: Generate a new auto meal plan based on user preferences and macro targets.

**Request Body**:
```json
{
  "diet_principles": ["vertical_diet", "high_protein"],
  "macro_targets": {
    "protein": 180.0,
    "fat": 60.0,
    "carbs": 200.0
  },
  "recipe_count": 7,
  "variety_factor": 0.7,
  "recipe_sources": ["database", "api"]
}
```

**Request Body Fields**:
- `diet_principles` (array of strings, optional): Dietary principles to follow
  - Valid values: `"vertical_diet"`, `"tim_ferriss"`, `"paleo"`, `"keto"`, `"mediterranean"`, `"high_protein"`
  - Default: `["vertical_diet"]`
- `macro_targets` (object, required): Daily macro nutrient targets
  - `protein` (float): Grams of protein per day
  - `fat` (float): Grams of fat per day
  - `carbs` (float): Grams of carbs per day
- `recipe_count` (integer, optional): Number of recipes to generate
  - Range: 1-20
  - Default: 7 (one per day of week)
- `variety_factor` (float, optional): How much variety to include (0.0 = repetitive, 1.0 = maximum variety)
  - Range: 0.0-1.0
  - Default: 0.7
- `recipe_sources` (array of strings, optional): Which recipe sources to use
  - Valid values: `"database"`, `"api"`, `"user_provided"`
  - Default: `["database"]`

**Response** (201 Created):
```json
{
  "id": "plan-2025-12-03-abc123",
  "recipes": [
    {
      "id": "chicken-rice",
      "name": "Chicken and Rice",
      "macros": { "protein": 45.0, "fat": 8.0, "carbs": 45.0, "calories": 428 },
      "servings": 1,
      "category": "chicken",
      "fodmap_level": "low",
      "vertical_compliant": true
    }
  ],
  "generated_at": "2025-12-03T10:30:00Z",
  "total_macros": {
    "protein": 180.0,
    "fat": 60.0,
    "carbs": 200.0,
    "calories": 2020
  },
  "config": {
    "diet_principles": ["vertical_diet"],
    "macro_targets": { "protein": 180.0, "fat": 60.0, "carbs": 200.0 },
    "recipe_count": 7,
    "variety_factor": 0.7
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid configuration (e.g., recipe_count out of range, negative macros)
  ```json
  {
    "error": "recipe_count must be between 1 and 20",
    "field": "recipe_count"
  }
  ```
- `500 Internal Server Error`: Database or generation failure
  ```json
  {
    "error": "Failed to generate meal plan: insufficient recipes matching criteria"
  }
  ```

**Implementation Notes**:
- Parse request body using `auto_planner/types.auto_plan_config_decoder()`
- Validate configuration using `auto_planner/types.validate_config()`
- Generate plan using auto planner algorithm
- Save to database using `auto_planner/storage.save_auto_plan()`
- Return JSON response with `auto_planner/types.auto_meal_plan_to_json()`

---

### 2. Retrieve Saved Auto Plan

**Endpoint**: `GET /api/auto-plans/:id`

**Purpose**: Retrieve a previously generated auto meal plan by ID.

**Path Parameters**:
- `id` (string): The auto plan ID (e.g., `"plan-2025-12-03-abc123"`)

**Response** (200 OK):
```json
{
  "id": "plan-2025-12-03-abc123",
  "recipes": [ /* array of recipes */ ],
  "generated_at": "2025-12-03T10:30:00Z",
  "total_macros": { "protein": 180.0, "fat": 60.0, "carbs": 200.0, "calories": 2020 },
  "config": { /* configuration used */ }
}
```

**Error Responses**:
- `404 Not Found`: Plan ID does not exist
  ```json
  {
    "error": "Auto plan not found",
    "id": "plan-2025-12-03-abc123"
  }
  ```
- `500 Internal Server Error`: Database error

**Implementation Notes**:
- Load from database using `auto_planner/storage.get_auto_plan()`
- Handle `NotFound` error with 404 response
- Return JSON using `auto_planner/types.auto_meal_plan_to_json()`

---

### 3. List User's Auto Plans

**Endpoint**: `GET /api/auto-plans`

**Purpose**: List all auto meal plans for the current user, sorted by generation date (newest first).

**Query Parameters**:
- `limit` (integer, optional): Maximum number of plans to return
  - Default: 10
  - Range: 1-50
- `offset` (integer, optional): Number of plans to skip (for pagination)
  - Default: 0

**Example**: `GET /api/auto-plans?limit=5&offset=0`

**Response** (200 OK):
```json
{
  "plans": [
    {
      "id": "plan-2025-12-03-abc123",
      "generated_at": "2025-12-03T10:30:00Z",
      "recipe_count": 7,
      "total_macros": { "protein": 180.0, "fat": 60.0, "carbs": 200.0, "calories": 2020 },
      "diet_principles": ["vertical_diet"]
    }
  ],
  "total": 15,
  "limit": 10,
  "offset": 0
}
```

**Implementation Notes**:
- Add new storage function `get_all_auto_plans()` with pagination support
- Sort by `generated_at DESC`
- Return summary data (not full recipe details for performance)

---

### 4. Delete Auto Plan

**Endpoint**: `DELETE /api/auto-plans/:id`

**Purpose**: Delete a saved auto meal plan.

**Path Parameters**:
- `id` (string): The auto plan ID to delete

**Response** (204 No Content): Empty response on successful deletion

**Error Responses**:
- `404 Not Found`: Plan ID does not exist
  ```json
  {
    "error": "Auto plan not found",
    "id": "plan-2025-12-03-abc123"
  }
  ```
- `500 Internal Server Error`: Database error

**Implementation Notes**:
- Add storage function `delete_auto_plan()`
- Use SQL: `DELETE FROM auto_meal_plans WHERE id = $1`

---

### 5. Get User Preferences for Auto Planning

**Endpoint**: `GET /api/auto-plans/preferences`

**Purpose**: Retrieve the user's saved preferences for auto meal plan generation.

**Response** (200 OK):
```json
{
  "diet_principles": ["vertical_diet", "high_protein"],
  "default_recipe_count": 7,
  "default_variety_factor": 0.7,
  "preferred_recipe_sources": ["database"],
  "excluded_categories": ["seafood"],
  "max_fodmap_level": "medium"
}
```

**Error Responses**:
- `404 Not Found`: User preferences not configured yet
  ```json
  {
    "error": "User preferences not found. Please configure preferences first."
  }
  ```

**Implementation Notes**:
- New table required: `auto_planner_preferences`
- Link to user profile (currently single user system)
- Return default preferences if not configured

---

### 6. Update User Preferences for Auto Planning

**Endpoint**: `PUT /api/auto-plans/preferences`

**Purpose**: Update the user's preferences for auto meal plan generation.

**Request Body**:
```json
{
  "diet_principles": ["vertical_diet", "high_protein"],
  "default_recipe_count": 7,
  "default_variety_factor": 0.7,
  "preferred_recipe_sources": ["database", "api"],
  "excluded_categories": ["seafood"],
  "max_fodmap_level": "medium"
}
```

**Request Body Fields** (all optional):
- `diet_principles` (array of strings): Preferred dietary principles
- `default_recipe_count` (integer): Default number of recipes to generate
- `default_variety_factor` (float): Default variety factor
- `preferred_recipe_sources` (array of strings): Preferred recipe sources
- `excluded_categories` (array of strings): Recipe categories to exclude
  - Valid values: `"chicken"`, `"beef"`, `"pork"`, `"seafood"`, `"vegetarian"`, `"other"`
- `max_fodmap_level` (string): Maximum FODMAP level to include
  - Valid values: `"low"`, `"medium"`, `"high"`

**Response** (200 OK):
```json
{
  "message": "Preferences updated successfully",
  "preferences": { /* updated preferences */ }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid preference values
  ```json
  {
    "error": "Invalid diet principle: invalid_diet",
    "field": "diet_principles"
  }
  ```

**Implementation Notes**:
- New table: `auto_planner_preferences` with user_id foreign key
- Use UPSERT pattern (INSERT ... ON CONFLICT DO UPDATE)
- Validate all fields before saving

---

### 7. Get Available Recipe Sources

**Endpoint**: `GET /api/auto-plans/recipe-sources`

**Purpose**: List all available recipe sources that can be used for auto plan generation.

**Response** (200 OK):
```json
{
  "sources": [
    {
      "id": "local-db",
      "name": "Local Recipe Database",
      "type": "database",
      "recipe_count": 156,
      "enabled": true
    },
    {
      "id": "spoonacular-api",
      "name": "Spoonacular API",
      "type": "api",
      "enabled": false,
      "requires_configuration": true
    },
    {
      "id": "user-recipes",
      "name": "My Custom Recipes",
      "type": "user_provided",
      "recipe_count": 12,
      "enabled": true
    }
  ]
}
```

**Implementation Notes**:
- Load from `recipe_sources` table using `auto_planner/storage.get_recipe_sources()`
- Add recipe count for database sources
- Include enabled/disabled status
- Show configuration requirements for API sources

---

## Integration with Existing Routes

### Update `handle_api()` in web.gleam

The `handle_api()` function needs to be extended to route auto planner requests:

```gleam
fn handle_api(
  req: wisp.Request,
  path: List(String),
  ctx: Context,
) -> wisp.Response {
  case path {
    // Existing routes
    ["recipes"] -> api_recipes(req, ctx)
    ["recipes", id] -> api_recipe(req, id, ctx)
    ["profile"] -> api_profile(req, ctx)
    ["foods"] -> api_foods(req, ctx)
    ["foods", id] -> api_food(req, id, ctx)

    // New auto planner routes
    ["auto-plans", "generate"] -> api_auto_plans_generate(req, ctx)
    ["auto-plans", "preferences"] -> api_auto_plans_preferences(req, ctx)
    ["auto-plans", "recipe-sources"] -> api_auto_plans_recipe_sources(req, ctx)
    ["auto-plans", id] -> api_auto_plan(req, id, ctx)
    ["auto-plans"] -> api_auto_plans_list(req, ctx)

    _ -> wisp.not_found()
  }
}
```

---

## Database Schema Updates

### New Table: `auto_planner_preferences`

```sql
CREATE TABLE IF NOT EXISTS auto_planner_preferences (
    user_id TEXT PRIMARY KEY,  -- Link to users table (single user for now)
    diet_principles TEXT NOT NULL,  -- JSON array of diet principles
    default_recipe_count INTEGER NOT NULL DEFAULT 7,
    default_variety_factor REAL NOT NULL DEFAULT 0.7,
    preferred_recipe_sources TEXT NOT NULL,  -- JSON array of source types
    excluded_categories TEXT,  -- JSON array of excluded categories
    max_fodmap_level TEXT CHECK (max_fodmap_level IN ('low', 'medium', 'high')),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Update: `auto_meal_plans` Table

Add user_id column for multi-user support (future):
```sql
ALTER TABLE auto_meal_plans ADD COLUMN user_id TEXT DEFAULT 'default';
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_user_id ON auto_meal_plans(user_id);
```

---

## SSR Pages (Optional - Phase 2)

Future SSR pages to complement the API:

1. **`/auto-planner`** - Auto planner dashboard
   - Show saved plans
   - Quick generate button
   - Preferences summary

2. **`/auto-planner/generate`** - Generate new plan form
   - Form for configuration options
   - Preview macro targets
   - Submit to generate

3. **`/auto-planner/preferences`** - Preferences configuration page
   - Edit diet principles
   - Set defaults
   - Manage recipe sources

4. **`/auto-planner/:id`** - View specific auto plan
   - Display all recipes
   - Show total macros
   - Options to edit or regenerate

---

## HTTP Method Summary

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/api/auto-plans/generate` | Generate new plan | Yes (future) |
| GET | `/api/auto-plans` | List user's plans | Yes (future) |
| GET | `/api/auto-plans/:id` | Get specific plan | Yes (future) |
| DELETE | `/api/auto-plans/:id` | Delete plan | Yes (future) |
| GET | `/api/auto-plans/preferences` | Get preferences | Yes (future) |
| PUT | `/api/auto-plans/preferences` | Update preferences | Yes (future) |
| GET | `/api/auto-plans/recipe-sources` | List recipe sources | No |

---

## Error Handling Standards

All API endpoints follow consistent error response format:

```json
{
  "error": "Human-readable error message",
  "field": "field_name",  // Optional: which field caused the error
  "code": "ERROR_CODE"    // Optional: machine-readable error code
}
```

### Common Error Codes:
- `VALIDATION_ERROR` - Invalid input data
- `NOT_FOUND` - Resource not found
- `DATABASE_ERROR` - Database operation failed
- `GENERATION_ERROR` - Plan generation failed
- `INSUFFICIENT_RECIPES` - Not enough recipes match criteria

---

## Implementation Priority

### Phase 1 (MVP):
1. `POST /api/auto-plans/generate` - Core functionality
2. `GET /api/auto-plans/:id` - Retrieve saved plans
3. `GET /api/auto-plans` - List plans

### Phase 2 (Enhanced):
4. `GET /api/auto-plans/preferences` - Get preferences
5. `PUT /api/auto-plans/preferences` - Update preferences
6. `DELETE /api/auto-plans/:id` - Delete plans

### Phase 3 (Advanced):
7. `GET /api/auto-plans/recipe-sources` - Manage sources
8. SSR pages for auto planner
9. Real-time plan regeneration
10. Multi-user support

---

## Testing Checklist

- [ ] Generate plan with valid configuration
- [ ] Generate plan with invalid configuration (validation errors)
- [ ] Generate plan with insufficient recipes in database
- [ ] Retrieve existing plan
- [ ] Retrieve non-existent plan (404)
- [ ] List plans with pagination
- [ ] Update preferences with valid data
- [ ] Update preferences with invalid data
- [ ] Delete existing plan
- [ ] Delete non-existent plan (404)
- [ ] Get recipe sources list

---

## Security Considerations

1. **Input Validation**: All user inputs validated before processing
2. **SQL Injection Prevention**: Use parameterized queries (Pog library)
3. **Rate Limiting**: Consider limiting plan generation to prevent abuse
4. **Authentication**: Add user authentication in future phases
5. **Data Privacy**: Plans are user-specific (when auth is implemented)

---

## Performance Considerations

1. **Database Indexes**: Already defined in migration
   - `idx_auto_meal_plans_generated_at`
   - `idx_recipe_sources_type`

2. **Caching**: Consider caching recipe data during generation

3. **Pagination**: List endpoints use offset/limit

4. **Async Generation**: For complex plans, consider background job processing

---

## Architecture Decision Records

### ADR-001: RESTful API Design
**Decision**: Use RESTful API patterns with `/api` prefix
**Rationale**: Consistent with existing codebase, clear separation between API and SSR routes
**Status**: Accepted

### ADR-002: JSON Configuration Storage
**Decision**: Store configuration as JSON text in database
**Rationale**: Flexible schema, easy to extend without migrations
**Status**: Accepted
**Trade-offs**: Less type safety, requires careful parsing

### ADR-003: Preferences Table
**Decision**: Separate preferences table instead of user_profile expansion
**Rationale**: Clean separation of concerns, easier to extend
**Status**: Accepted

### ADR-004: Recipe Sources Architecture
**Decision**: Pluggable recipe source system with types (database, api, user_provided)
**Rationale**: Allows future integration with recipe APIs, flexible architecture
**Status**: Accepted

---

## Related Documentation

- [Recipe API Documentation](/docs/recipe-api.yaml)
- [Auto Planner Algorithm](/docs/architecture/auto-planner-algorithm.md) (TODO)
- [Database Schema](/docs/database-schema.md) (TODO)
- [Type Definitions](/gleam/src/meal_planner/auto_planner/types.gleam)
- [Storage Layer](/gleam/src/meal_planner/auto_planner/storage.gleam)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Author**: System Architecture Designer
**Status**: Ready for Implementation Review
