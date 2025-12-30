---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-5
heading_path: ["Recipe Import Pipeline", "Binary Specifications"]
chunk_type: code
tokens: 292
summary: "Binary Specifications"
---

## Binary Specifications

### `tandoor_scrape_recipe`

**Purpose:** Scrape recipe data from URL using Tandoor's built-in scraper.

**Input:**
```json
{
  "tandoor": {
    "base_url": "http://localhost:8090",
    "api_token": "..."
  },
  "url": "https://www.meatchurch.com/blogs/recipes/texas-style-brisket"
}
```text

**Output (success):**
```json
{
  "success": true,
  "recipe_json": {
    "name": "Texas Style Brisket",
    "description": "...",
    "source_url": "https://...",
    "servings": 8,
    "working_time": 30,
    "waiting_time": 720,
    "steps": [...],
    "keywords": [...]
  },
  "images": ["https://..."]
}
```text

**Output (error):**
```json
{
  "success": false,
  "error": "Failed to scrape recipe: site not supported"
}
```text

**API Call:** `POST /api/recipe-from-source/`

### `tandoor_create_recipe`

**Purpose:** Create a recipe in Tandoor from scraped/provided data.

**Input:**
```json
{
  "tandoor": {
    "base_url": "http://localhost:8090",
    "api_token": "..."
  },
  "recipe": {
    "name": "Texas Style Brisket",
    "description": "...",
    "source_url": "https://...",
    "steps": [...],
    "keywords": [...]
  },
  "additional_keywords": ["smoking", "meat-church", "beef"]
}
```text

**Output (success):**
```json
{
  "success": true,
  "recipe_id": 123,
  "name": "Texas Style Brisket"
}
```text

**API Call:** `POST /api/recipe/`

### `fatsecret_enrich_nutrition` (Phase 2)

**Purpose:** Look up nutrition data for recipe ingredients.

**Input:**
```json
{
  "fatsecret": {
    "consumer_key": "...",
    "consumer_secret": "..."
  },
  "ingredients": [
    {"food": "brisket", "amount": 1, "unit": "lb"},
    {"food": "black pepper", "amount": 2, "unit": "tbsp"}
  ],
  "servings": 8
}
```text

**Output:**
```json
{
  "success": true,
  "per_serving": {
    "calories": 450,
    "protein": 45,
    "carbohydrate": 2,
    "fat": 28
  },
  "auto_tags": ["high-protein", "low-carb"]
}
```text

**Auto-tag Rules:**
- `>30g protein/serving` → `high-protein`
- `<20g carbs/serving` → `low-carb`
- `<10g fat/serving` → `low-fat`
- `>500 cal/serving` → `high-calorie`
