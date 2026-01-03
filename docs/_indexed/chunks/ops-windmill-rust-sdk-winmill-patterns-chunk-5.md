---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-5
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Resource and secret access"]
chunk_type: code
tokens: 237
summary: "Resource and secret access"
---

## Resource and secret access

Resources store structured configuration (database credentials, API endpoints) while variables store simple values (API keys, feature flags).

### Initializing the Windmill client

```rust
use wmill::Windmill;

// Auto-configure from environment variables (recommended)
let wm = Windmill::default()?;

// Explicit configuration (for external applications)
let wm = Windmill::new(
    Some("your_token".to_string()),
    Some("workspace_name".to_string()),
    Some("http://localhost:8000".to_string())
)?;
```bash

### Typed resource access

```rust
use serde::Deserialize;
use wmill::Windmill;

#[derive(Deserialize)]
struct PostgresResource {
    host: String,
    port: u16,
    user: String,
    password: String,
    dbname: String,
}

async fn main(db_resource: String) -> anyhow::Result<String> {
    let wm = Windmill::default()?;
    let config: PostgresResource = wm.get_resource(&db_resource).await?;
    Ok(format!("Connected to {}:{}/{}", config.host, config.port, config.dbname))
}
```bash

### Raw resource access

```rust
let wm = Windmill::default()?;
let raw: serde_json::Value = wm.get_resource_any("u/admin/api_config").await?;
let api_key = raw["api_key"].as_str().unwrap_or("");
```text

### Variable and secret access

```rust
// Get variable as parsed JSON
let config: serde_json::Value = wm.get_variable("u/admin/config").await?;

// Get variable as raw string (for API keys, tokens)
let api_key: String = wm.get_variable_raw("u/admin/openai_key").await?;

// Set a variable
wm.set_variable("new_value".to_string(), "u/admin/my_var", false).await?;
```text

### Creating and updating resources

```rust
use serde_json::json;

wm.set_resource(
    Some(json!({"host": "db.example.com", "port": 5432})),
    "u/admin/new_database",
    "postgresql"  // resource type
).await?;
```yaml

---
