---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-17
heading_path: ["Windmill Development Guide", "Create resource type"]
chunk_type: prose
tokens: 55
summary: "Create resource type"
---

## Create resource type
curl -X POST "http://localhost/api/w/meal-planner/resources/type/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tandoor",
    "description": "Tandoor API",
    "schema": {
      "type": "object",
      "properties": {
        "base_url": {"type": "string"},
        "api_token": {"type": "string"}
      },
      "required": ["base_url", "api_token"]
    }
  }'
