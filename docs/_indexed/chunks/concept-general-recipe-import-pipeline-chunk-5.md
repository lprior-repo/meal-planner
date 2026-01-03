---
doc_id: concept/general/recipe-import-pipeline
chunk_id: concept/general/recipe-import-pipeline#chunk-5
heading_path: ["Recipe Import Pipeline", "Example: `tandoor_scrape_recipe`"]
chunk_type: code
tokens: 55
summary: "Example: `tandoor_scrape_recipe`"
---

## Example: `tandoor_scrape_recipe`

**Input**:
```json
{
  "tandoor": {"base_url": "http://localhost:8090", "api_token": "..."},
  "url": "https://www.meatchurch.com/blogs/recipes/texas-style-brisket"
}
```

**Output**:
```json
{
  "success": true,
  "recipe_json": {
    "name": "Texas Style Brisket",
    "source_url": "...",
    "servings": 8,
    "working_time": 30,
    "waiting_time": 720,
    "steps": [...],
    "keywords": [...]
  },
  "images": ["https://..."]
}
```
