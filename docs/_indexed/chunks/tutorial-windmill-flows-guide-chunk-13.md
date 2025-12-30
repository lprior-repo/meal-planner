---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-13
heading_path: ["Windmill Flows Guide", "Pushing Flows via API"]
chunk_type: prose
tokens: 41
summary: "Pushing Flows via API"
---

## Pushing Flows via API

If CLI has issues, use the API directly:

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "http://localhost/api/w/meal-planner/flows/create" \
  -d @flow_payload.json
```text
