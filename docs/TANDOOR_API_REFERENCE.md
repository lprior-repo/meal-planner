# Tandoor API Quick Reference

**Version:** 1.0
**Last Updated:** 2025-12-14

---

## Base URLs

- **Local Development:** `http://localhost:3000`
- **Status Check:** `GET /tandoor/status`
- **API Prefix:** `/api/tandoor/`

---

## Authentication

All API endpoints (except `/tandoor/status`) require Tandoor authentication configured via environment variables:

```bash
export TANDOOR_URL="http://localhost:8080"
export TANDOOR_USERNAME="your_username"
export TANDOOR_PASSWORD="your_password"
```

---

## Endpoints

### 1. Status Check

**Endpoint:** `GET /tandoor/status`

**Description:** Check Tandoor connection and configuration status

**Authentication:** None required

**Response:**
```json
{
  "connected": true,
  "configured": true,
  "base_url": "http://localhost:8080"
}
```

**Status Codes:**
- `200 OK` - Always returns 200 with status information

**Example:**
```bash
curl http://localhost:3000/tandoor/status
```

---

### 2. List Recipes

**Endpoint:** `GET /api/tandoor/recipes`

**Description:** Get paginated list of recipes from Tandoor

**Authentication:** Required

**Query Parameters:**
- `limit` (optional, integer) - Number of results per page
- `offset` (optional, integer) - Pagination offset

**Response:**
```json
{
  "count": 42,
  "next": "http://tandoor/api/recipe/?limit=20&offset=20",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Chocolate Chip Cookies",
      "description": "Classic chocolate chip cookies",
      "servings": 24,
      "servings_text": "24 cookies",
      "working_time": 15,
      "waiting_time": 12,
      "created_at": "2025-01-01T10:00:00Z",
      "updated_at": "2025-01-02T15:30:00Z",
      "steps": [...],
      "nutrition": {...},
      "keywords": [...]
    }
  ]
}
```

**Status Codes:**
- `200 OK` - Success
- `500 Internal Server Error` - Tandoor not configured
- `502 Bad Gateway` - Tandoor authentication failed

**Example:**
```bash
curl "http://localhost:3000/api/tandoor/recipes?limit=10&offset=0"
```

---

### 3. Get Recipe Detail

**Endpoint:** `GET /api/tandoor/recipes/:id`

**Description:** Get complete recipe details including ingredients, steps, and nutrition

**Authentication:** Required

**Path Parameters:**
- `id` (required, integer) - Recipe ID

**Response:**
```json
{
  "id": 1,
  "name": "Chocolate Chip Cookies",
  "description": "Classic chocolate chip cookies recipe",
  "servings": 24,
  "servings_text": "24 cookies",
  "working_time": 15,
  "waiting_time": 12,
  "created_at": "2025-01-01T10:00:00Z",
  "updated_at": "2025-01-02T15:30:00Z",
  "steps": [
    {
      "id": 1,
      "name": "Mix dry ingredients",
      "instructions": "In a bowl, whisk together flour, baking soda, and salt.",
      "time": 5
    },
    {
      "id": 2,
      "name": "Cream butter and sugar",
      "instructions": "Beat butter and sugars until fluffy.",
      "time": 5
    }
  ],
  "nutrition": {
    "calories": 78.5,
    "carbs": 10.2,
    "protein": 1.1,
    "fats": 3.8,
    "fiber": 0.4,
    "sugars": 6.2,
    "sodium": 55.0
  },
  "keywords": [
    {
      "id": 5,
      "name": "dessert"
    },
    {
      "id": 12,
      "name": "baking"
    }
  ]
}
```

**Status Codes:**
- `200 OK` - Recipe found
- `400 Bad Request` - Invalid recipe ID format
- `404 Not Found` - Recipe not found
- `500 Internal Server Error` - Tandoor not configured
- `502 Bad Gateway` - Tandoor authentication failed

**Example:**
```bash
curl http://localhost:3000/api/tandoor/recipes/1
```

---

### 4. Get Meal Plan

**Endpoint:** `GET /api/tandoor/meal-plan`

**Description:** Get meal plan entries for a date range

**Authentication:** Required

**Query Parameters:**
- `from_date` (optional, string YYYY-MM-DD) - Start date
- `to_date` (optional, string YYYY-MM-DD) - End date

**Response:**
```json
{
  "count": 7,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 101,
      "recipe": 1,
      "recipe_name": "Chocolate Chip Cookies",
      "servings": 2.0,
      "note": "Afternoon snack",
      "from_date": "2025-12-14",
      "to_date": "2025-12-14",
      "meal_type": "snack",
      "created_by": 1
    },
    {
      "id": 102,
      "recipe": null,
      "recipe_name": "Grilled Chicken Salad",
      "servings": 1.0,
      "note": "",
      "from_date": "2025-12-14",
      "to_date": "2025-12-14",
      "meal_type": "lunch",
      "created_by": 1
    }
  ]
}
```

**Status Codes:**
- `200 OK` - Success
- `500 Internal Server Error` - Tandoor not configured
- `502 Bad Gateway` - Tandoor authentication failed

**Example:**
```bash
# Get all meal plan entries
curl http://localhost:3000/api/tandoor/meal-plan

# Get entries for date range
curl "http://localhost:3000/api/tandoor/meal-plan?from_date=2025-12-01&to_date=2025-12-31"
```

---

### 5. Create Meal Plan Entry

**Endpoint:** `POST /api/tandoor/meal-plan`

**Description:** Create a new meal plan entry

**Authentication:** Required

**Request Body:**
```json
{
  "recipe": 1,
  "recipe_name": "Chocolate Chip Cookies",
  "from_date": "2025-12-14",
  "to_date": "2025-12-14",
  "meal_type": "snack",
  "servings": 2.0,
  "note": "Afternoon treat"
}
```

**Request Fields:**
- `recipe` (optional, integer) - Recipe ID to link
- `recipe_name` (required, string) - Name of the meal
- `from_date` (required, string YYYY-MM-DD) - Start date
- `to_date` (required, string YYYY-MM-DD) - End date
- `meal_type` (optional, string) - Meal type (default: "other")
  - Valid values: `breakfast`, `lunch`, `dinner`, `snack`, `other`
- `servings` (optional, float) - Number of servings (default: 1.0)
- `note` (optional, string) - Additional notes (default: "")

**Response:**
```json
{
  "id": 103,
  "recipe": 1,
  "recipe_name": "Chocolate Chip Cookies",
  "servings": 2.0,
  "from_date": "2025-12-14",
  "to_date": "2025-12-14",
  "meal_type": "snack"
}
```

**Status Codes:**
- `201 Created` - Meal plan entry created successfully
- `400 Bad Request` - Invalid request body or missing required fields
- `500 Internal Server Error` - Tandoor not configured
- `502 Bad Gateway` - Tandoor authentication failed

**Example:**
```bash
curl -X POST http://localhost:3000/api/tandoor/meal-plan \
  -H "Content-Type: application/json" \
  -d '{
    "recipe_name": "Breakfast Smoothie",
    "from_date": "2025-12-14",
    "to_date": "2025-12-14",
    "meal_type": "breakfast",
    "servings": 1.0,
    "note": "High protein blend"
  }'
```

---

### 6. Delete Meal Plan Entry

**Endpoint:** `DELETE /api/tandoor/meal-plan/:id`

**Description:** Delete a meal plan entry by ID

**Authentication:** Required

**Path Parameters:**
- `id` (required, integer) - Meal plan entry ID

**Response:**
```json
{
  "success": true,
  "message": "Meal plan entry deleted"
}
```

**Status Codes:**
- `200 OK` - Entry deleted successfully
- `400 Bad Request` - Invalid entry ID format
- `404 Not Found` - Entry not found
- `500 Internal Server Error` - Tandoor not configured
- `502 Bad Gateway` - Tandoor authentication failed

**Example:**
```bash
curl -X DELETE http://localhost:3000/api/tandoor/meal-plan/103
```

---

## Error Responses

All errors return JSON with an `error` field:

```json
{
  "error": "Error message description"
}
```

### Common Error Messages

- `"Tandoor not configured"` - Environment variables not set
- `"Tandoor authentication failed: ..."` - Invalid credentials or connection issue
- `"Invalid recipe ID"` - Recipe ID is not a number
- `"Recipe not found"` - Recipe doesn't exist in Tandoor
- `"Invalid meal plan entry ID"` - Entry ID is not a number
- `"Meal plan entry not found"` - Entry doesn't exist
- `"Invalid request: expected JSON with ..."` - Missing required fields in POST body

---

## Configuration

### Environment Variables

Set these in your `.env` file or environment:

```bash
TANDOOR_URL=http://localhost:8080
TANDOOR_USERNAME=your_username
TANDOOR_PASSWORD=your_password
```

### Tandoor Setup (Docker)

```bash
docker run -d \
  --name tandoor \
  -p 8080:8080 \
  -e SECRET_KEY=your-secret-key \
  -e DB_ENGINE=django.db.backends.postgresql \
  -v tandoor_data:/opt/recipes/mediafiles \
  vabene1111/recipes
```

---

## Testing

### Quick Health Check

```bash
# Check if Tandoor is configured and connected
curl http://localhost:3000/tandoor/status
```

### Integration Test Suite

```bash
cd gleam
gleam test
```

---

## Meal Type Reference

| Value | Description |
|-------|-------------|
| `breakfast` | Morning meal |
| `lunch` | Midday meal |
| `dinner` | Evening meal |
| `snack` | Between-meal snack |
| `other` | Other/unspecified |

---

## Nutrition Data Structure

When available, recipes include nutritional information per serving:

```json
{
  "calories": 78.5,    // kcal
  "carbs": 10.2,       // grams
  "protein": 1.1,      // grams
  "fats": 3.8,         // grams
  "fiber": 0.4,        // grams
  "sugars": 6.2,       // grams (optional)
  "sodium": 55.0       // mg (optional)
}
```

---

## Rate Limiting

Currently no rate limiting is enforced. Future versions may implement:

- 100 requests per minute per IP
- 1000 requests per hour per IP

---

## Support & Feedback

- **Documentation:** `/home/lewis/src/meal-planner/docs/tandoor_validation_report.md`
- **Test Suite:** `/home/lewis/src/meal-planner/gleam/test/tandoor_integration_test.gleam`
- **Handler Code:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/web/handlers/tandoor.gleam`

---

**Last Validated:** 2025-12-14
