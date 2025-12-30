---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-58
heading_path: ["Windmill Deployment Guide", "View schedule runs"]
chunk_type: prose
tokens: 68
summary: "View schedule runs"
---

## View schedule runs
wmill run list --schedule=f/meal-planner/schedules/daily_meal_plan
```text

**Resolution:**
1. Verify schedule is enabled
2. Check cron expression is valid
3. Verify timezone is correct
4. Re-enable schedule:
   ```bash
   wmill schedule disable f/meal-planner/schedules/daily_meal_plan
   wmill schedule enable f/meal-planner/schedules/daily_meal_plan
   ```yaml

---

### Issue: Sync Push Conflicts

**Symptoms:** `wmill sync push` shows conflicts

**Diagnosis:**
```bash
