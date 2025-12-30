---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-47
heading_path: ["Windmill Deployment Guide", "Or via Windmill script"]
chunk_type: code
tokens: 71
summary: "Or via Windmill script"
---

## Or via Windmill script
wmill script run f/meal-planner/db/run_migrations \
  -d '{"migration": "002_add_oauth_tokens"}'
```

### Windmill Migration Script

```rust
// f/meal-planner/db/run_migrations/script.rs
use sqlx::postgres::PgPool;

pub async fn main(postgres: Postgresql, migration: String) -> Result<String, Error> {
    let pool = PgPool::connect(&postgres.connection_string()).await?;

    let migration_sql = include_str!(concat!("../migrations/", migration, ".sql"));

    sqlx::query(migration_sql)
        .execute(&pool)
        .await?;

    Ok(format!("Migration {} completed successfully", migration))
}
```

---
