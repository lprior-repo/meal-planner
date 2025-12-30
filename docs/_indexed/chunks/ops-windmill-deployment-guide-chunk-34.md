---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-34
heading_path: ["Windmill Deployment Guide", "Daily meal plan generation (8:00 AM)"]
chunk_type: prose
tokens: 42
summary: "Daily meal plan generation (8:00 AM)"
---

## Daily meal plan generation (8:00 AM)
wmill schedule create \
  --path f/meal-planner/schedules/daily_meal_plan \
  --schedule "0 0 8 * * *" \
  --timezone "America/Los_Angeles" \
  --script-path f/meal-planner/handlers/meal_planning/generate_plan \
  --args '{"days": 7, "regenerate": false}'
