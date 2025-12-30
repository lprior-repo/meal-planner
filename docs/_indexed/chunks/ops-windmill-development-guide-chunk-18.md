---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-18
heading_path: ["Windmill Development Guide", "Create resource instance"]
chunk_type: prose
tokens: 42
summary: "Create resource instance"
---

## Create resource instance
curl -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "f/meal-planner/tandoor_api",
    "resource_type": "tandoor",
    "value": {
      "base_url": "http://tandoor-web_recipes-1:80",
      "api_token": "your_token"
    }
  }'
```
