---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-15
heading_path: ["Windmill Flows Guide", "Async via API"]
chunk_type: code
tokens: 46
summary: "Async via API"
---

## Async via API
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost/api/w/meal-planner/jobs/run/f/f/fatsecret/oauth_setup" \
  -d '{}'
```text

### Cancel suspended flow
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  "http://localhost/api/w/meal-planner/jobs_u/cancel/<job_id>" \
  -d '{"reason": "Cancelled"}'
```
