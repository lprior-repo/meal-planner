# API Documentation

## Base URL
`http://localhost:8080` (development)

## Endpoints

### Food Search
```
GET /api/foods?q={query}
```
Search USDA food database.

**Query Parameters:**
- `q` - Search query (min 2 characters)

**Response:**
```json
[
  {
    "id": "171705",
    "name": "Chicken breast, grilled",
    "category": "Poultry"
  }
]
```

### Food Detail
```
GET /api/foods/:id
```
Get detailed nutrition info for a food.

**Response:**
```json
{
  "id": "171705",
  "name": "Chicken breast, grilled",
  "nutrients": [
    {"name": "Protein", "value": 31.0, "unit": "g"},
    {"name": "Fat", "value": 3.6, "unit": "g"}
  ]
}
```

### Daily Log
```
GET /dashboard?date=YYYY-MM-DD
```
Get daily meal log and macro totals (rendered as HTML).

### Recipe CRUD
```
GET  /api/recipes          # List all recipes
GET  /api/recipes/:id      # Get recipe detail
POST /api/recipes          # Create recipe
PUT  /api/recipes/:id      # Update recipe
DELETE /api/recipes/:id    # Delete recipe
```

## Authentication

Currently no authentication. User auth planned for future release.

## Error Responses

```json
{
  "error": "Food not found",
  "status": 404
}
```
