---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-35
heading_path: ["Windmill Deployment Guide", "Hourly FatSecret sync"]
chunk_type: prose
tokens: 36
summary: "Hourly FatSecret sync"
---

## Hourly FatSecret sync
wmill schedule create \
  --path f/meal-planner/schedules/fatsecret_sync \
  --schedule "0 0 * * * *" \
  --timezone "UTC" \
  --script-path f/meal-planner/handlers/fatsecret/sync_foods \
  --args '{"full_sync": false}'
