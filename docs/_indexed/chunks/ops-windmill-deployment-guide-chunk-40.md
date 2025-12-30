---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-40
heading_path: ["Windmill Deployment Guide", "Delete schedule"]
chunk_type: prose
tokens: 117
summary: "Delete schedule"
---

## Delete schedule
wmill schedule delete f/meal-planner/schedules/old_schedule
```text

### Cron Syntax Reference

| Expression | Meaning |
|------------|---------|
| `0 0 * * * *` | Every hour |
| `0 0 8 * * *` | Daily at 8:00 AM |
| `0 0 8 * * 1-5` | Weekdays at 8:00 AM |
| `0 0 8 1 * *` | Monthly on 1st at 8:00 AM |
| `0 */15 * * * *` | Every 15 minutes |

Note: Windmill uses 6-field cron (seconds included).

---
