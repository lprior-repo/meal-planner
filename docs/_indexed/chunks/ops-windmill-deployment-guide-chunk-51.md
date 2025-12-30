---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-51
heading_path: ["Windmill Deployment Guide", "Add error handler to critical schedules"]
chunk_type: code
tokens: 289
summary: "Add error handler to critical schedules"
---

## Add error handler to critical schedules
wmill schedule update f/meal-planner/schedules/critical_sync \
  --on-failure f/meal-planner/handlers/notifications/slack_error \
  --on-recovery f/meal-planner/handlers/notifications/slack_recovery
```text

### Health Check Endpoints

Create a health check script for monitoring:

```rust
// f/meal-planner/handlers/health/check.rs
use serde_json::json;

pub async fn main(postgres: Postgresql, tandoor: Tandoor) -> Result<serde_json::Value, Error> {
    let mut status = json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "checks": {}
    });

    // Database check
    let db_ok = check_database(&postgres).await.is_ok();
    status["checks"]["database"] = json!({
        "status": if db_ok { "up" } else { "down" }
    });

    // Tandoor check
    let tandoor_ok = check_tandoor(&tandoor).await.is_ok();
    status["checks"]["tandoor"] = json!({
        "status": if tandoor_ok { "up" } else { "down" }
    });

    if !db_ok || !tandoor_ok {
        status["status"] = json!("degraded");
    }

    Ok(status)
}
```text

### Metrics Collection

```rust
// f/meal-planner/handlers/metrics/collect.rs
pub async fn main(postgres: Postgresql) -> Result<serde_json::Value, Error> {
    let pool = postgres.connect().await?;

    let metrics = json!({
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "recipes_count": count_recipes(&pool).await?,
        "meal_plans_count": count_meal_plans(&pool).await?,
        "active_users": count_active_users(&pool).await?,
        "jobs_last_hour": count_jobs_last_hour().await?
    });

    // Push to monitoring
    push_to_prometheus(&metrics).await?;

    Ok(metrics)
}
```text

### Alerting Rules

| Metric | Threshold | Action |
|--------|-----------|--------|
| Job failure rate | > 5% in 1h | Slack alert |
| Database connection errors | > 3 in 5m | PagerDuty |
| API response time | > 5s avg | Warning log |
| OAuth token expiry | < 24h | Email reminder |
| Disk usage | > 80% | Slack warning |

---
