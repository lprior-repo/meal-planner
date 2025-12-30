---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-36
heading_path: ["Windmill Deployment Guide", "Weekly nutrition report (Sunday 9:00 PM)"]
chunk_type: prose
tokens: 49
summary: "Weekly nutrition report (Sunday 9:00 PM)"
---

## Weekly nutrition report (Sunday 9:00 PM)
wmill schedule create \
  --path f/meal-planner/schedules/weekly_nutrition_report \
  --schedule "0 0 21 * * 0" \
  --timezone "America/Los_Angeles" \
  --script-path f/meal-planner/handlers/nutrition/generate_report \
  --args '{"period": "weekly"}'
```

### Schedule with Error Handler

```bash
