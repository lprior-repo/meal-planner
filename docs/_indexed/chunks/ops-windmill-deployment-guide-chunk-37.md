---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-37
heading_path: ["Windmill Deployment Guide", "Create schedule with Slack error notification"]
chunk_type: prose
tokens: 49
summary: "Create schedule with Slack error notification"
---

## Create schedule with Slack error notification
wmill schedule create \
  --path f/meal-planner/schedules/critical_sync \
  --schedule "0 */15 * * * *" \
  --timezone "UTC" \
  --script-path f/meal-planner/handlers/tandoor/sync \
  --args '{}' \
  --on-failure f/meal-planner/handlers/notifications/slack_error
```text

### Manage Schedules

```bash
