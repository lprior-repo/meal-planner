---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-10
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Complete code examples"]
chunk_type: code
tokens: 642
summary: "Complete code examples"
---

## Complete code examples

### HTTP requests with reqwest

```rust
//! ```cargo
//! [dependencies]
//! reqwest = { version = "0.12", features = ["json"] }
//! tokio = { version = "1", features = ["full"] }
//! serde = { version = "1.0", features = ["derive"] }
//! anyhow = "1.0"
//! ```rust

use reqwest::Client;
use serde::Deserialize;
use anyhow::{Result, Context};

#[derive(Deserialize)]
struct ApiResponse {
    data: serde_json::Value,
}

#[tokio::main]
async fn main(url: String, api_key: String) -> Result<serde_json::Value> {
    let client = Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()?;
    
    let response: ApiResponse = client
        .get(&url)
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .send()
        .await
        .context("HTTP request failed")?
        .error_for_status()
        .context("API returned error status")?
        .json()
        .await
        .context("Failed to parse JSON")?;
    
    Ok(response.data)
}
```

### Database queries with tokio-postgres

```rust
//! ```cargo
//! [dependencies]
//! wmill = "^1.0"
//! tokio-postgres = "0.7"
//! tokio = { version = "1", features = ["full"] }
//! serde = { version = "1.0", features = ["derive"] }
//! anyhow = "1.0"
//! ```rust

use wmill::Windmill;
use tokio_postgres::NoTls;
use serde::Deserialize;
use anyhow::Result;

#[derive(Deserialize)]
struct DbConfig {
    host: String,
    port: u16,
    user: String,
    password: String,
    dbname: String,
}

#[tokio::main]
async fn main(db_resource: String, query: String) -> Result<serde_json::Value> {
    let wm = Windmill::default()?;
    let config: DbConfig = wm.get_resource(&db_resource).await?;
    
    let conn_str = format!(
        "host={} port={} user={} password={} dbname={}",
        config.host, config.port, config.user, config.password, config.dbname
    );
    
    let (client, connection) = tokio_postgres::connect(&conn_str, NoTls).await?;
    tokio::spawn(async move { connection.await.ok(); });
    
    let rows = client.query(&query, &[]).await?;
    let results: Vec<serde_json::Value> = rows.iter()
        .map(|row| {
            let mut obj = serde_json::Map::new();
            for (i, col) in row.columns().iter().enumerate() {
                let val: serde_json::Value = match col.type_().name() {
                    "int4" | "int8" => serde_json::json!(row.get::<_, i64>(i)),
                    "text" | "varchar" => serde_json::json!(row.get::<_, String>(i)),
                    "bool" => serde_json::json!(row.get::<_, bool>(i)),
                    _ => serde_json::Value::Null,
                };
                obj.insert(col.name().to_string(), val);
            }
            serde_json::Value::Object(obj)
        })
        .collect();
    
    Ok(serde_json::json!({"rows": results}))
}
```

### Full script with resources, state, and progress

```rust
//! ```cargo
//! [dependencies]
//! wmill = "^1.0"
//! reqwest = { version = "0.12", features = ["json"] }
//! tokio = { version = "1", features = ["full"] }
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! anyhow = "1.0"
//! ```rust

use wmill::Windmill;
use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Deserialize)]
struct ApiConfig {
    base_url: String,
    api_key: String,
}

#[derive(Deserialize, Serialize, Default)]
struct ScriptState {
    processed_count: u64,
    last_cursor: Option<String>,
}

#[derive(Serialize)]
struct Output {
    items_processed: u64,
    new_items: Vec<serde_json::Value>,
}

#[tokio::main]
async fn main(api_resource: String) -> Result<Output> {
    let wm = Windmill::default()?;
    
    // Get API config from resource
    let config: ApiConfig = wm.get_resource(&api_resource).await?;
    
    // Get previous state
    let mut state: ScriptState = wm.get_state().await.unwrap_or_default();
    
    wm.set_progress(10, None).await?;
    
    // Fetch new data
    let client = reqwest::Client::new();
    let mut url = format!("{}/items", config.base_url);
    if let Some(cursor) = &state.last_cursor {
        url = format!("{}?after={}", url, cursor);
    }
    
    let response: serde_json::Value = client
        .get(&url)
        .header("Authorization", format!("Bearer {}", config.api_key))
        .send()
        .await?
        .json()
        .await?;
    
    wm.set_progress(70, None).await?;
    
    let items = response["items"].as_array()
        .map(|a| a.clone())
        .unwrap_or_default();
    
    // Update state
    state.processed_count += items.len() as u64;
    state.last_cursor = response["next_cursor"].as_str().map(String::from);
    wm.set_state(Some(serde_json::to_value(&state)?)).await?;
    
    wm.set_progress(100, None).await?;
    
    Ok(Output {
        items_processed: items.len() as u64,
        new_items: items,
    })
}
```

---
