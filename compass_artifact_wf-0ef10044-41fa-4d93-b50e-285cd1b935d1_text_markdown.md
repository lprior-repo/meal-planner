<!--
<doc_metadata>
  <type>reference</type>
  <category>sdk</category>
  <title>Windmill Rust SDK: Complete Reference Guide</title>
  <description>Complete reference guide for Windmill Rust scripts including SDK fundamentals, patterns, resources, state, and job management</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="SDK fundamentals and crate setup" level="1"/>
    <section name="Main function signature patterns" level="1"/>
    <section name="Return types and output serialization" level="1"/>
    <section name="Resource and secret access" level="1"/>
    <section name="State management between runs" level="1"/>
    <section name="Calling other scripts and managing jobs" level="1"/>
    <section name="Error handling patterns" level="1"/>
    <section name="Flow composition and data passing" level="1"/>
    <section name="Complete code examples" level="1"/>
    <section name="Limitations compared to TypeScript and Python" level="1"/>
  </sections>
  <features>
    <feature>rust_sdk</feature>
    <feature>wmill</feature>
    <feature>windmill_resources</feature>
    <feature>windmill_state</feature>
    <feature>windmill_jobs</feature>
    <feature>error_handling</feature>
    <feature>flow_composition</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">anyhow</dependency>
    <dependency type="crate">serde</dependency>
  </dependencies>
  <code_examples count="10</code_examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>20</estimated_reading_time>
  <tags>windmill,rust,sdk,wmill,crate,anyhow,tokio,serde,resources,state,jobs</tags>
</doc_metadata>
-->

# Windmill Rust SDK: Complete Reference Guide for AI Coding Agents

Windmill's Rust support, introduced in August 2024, enables high-performance script execution with full SDK access for resources, state, and inter-script communication. The `wmill` crate (v1.601.1) provides typed API access, while scripts use a distinctive inline Cargo.toml format within doc comments. This guide covers every pattern needed to write production Windmill Rust scripts.

---

## SDK fundamentals and crate setup

The primary SDK crate is **`wmill`** (not `windmill` or `windmill-api`). The current version is **1.601.1**, published on crates.io with Apache-2.0 licensing. A secondary crate `windmill-api` exists but is used internally by `wmill` for low-level OpenAPI operations.

### Inline dependency declaration

Windmill Rust scripts declare dependencies using a special doc-comment block at the top of the file. This replaces the traditional `Cargo.toml`:

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! reqwest = { version = "0.12", features = ["json"] }
//! wmill = "^1.0"
//! tokio = { version = "1", features = ["full"] }
//! ```

// Your script code follows...
```

**Critical detail**: `serde` with the `derive` feature is included by default—you do not need to declare it unless requiring additional features. You can still import `serde::Serialize` and `serde::Deserialize` directly.

### Environment variables automatically available

| Variable | Purpose |
|----------|---------|
| `WM_TOKEN` | Authentication token for API calls |
| `WM_WORKSPACE` | Current workspace name |
| `BASE_INTERNAL_URL` | Windmill API base URL (without `/api`) |
| `WM_JOB_ID` | Current job identifier |
| `WM_STATE_PATH_NEW` | State storage path |
| `WM_FLOW_PATH` | Parent flow path (if executing within a flow) |
| `WM_ROOT_FLOW_JOB_ID` | Root flow job ID for nested flows |

---

## Main function signature patterns

Every Windmill Rust script requires a `main` function as its entrypoint. Windmill parses the function signature to **automatically generate the input schema** for the script UI.

### Basic synchronous script

```rust
use serde::Serialize;

#[derive(Serialize)]
struct Output {
    message: String,
    count: i32,
}

fn main(name: String, multiplier: i32) -> anyhow::Result<Output> {
    Ok(Output {
        message: format!("Hello, {}!", name),
        count: multiplier * 10,
    })
}
```

### Async script with SDK access

```rust
//! ```cargo
//! [dependencies]
//! wmill = "^1.0"
//! tokio = { version = "1", features = ["full"] }
//! anyhow = "1.0"
//! serde_json = "1.0"
//! ```

use wmill::Windmill;
use anyhow::Result;

#[tokio::main]
async fn main(resource_path: String) -> Result<serde_json::Value> {
    let wm = Windmill::default()?;
    let data = wm.get_resource_any(&resource_path).await?;
    Ok(data)
}
```

### Parameter type mappings

Windmill infers JSON Schema types from Rust types:

| Rust Type | JSON Schema | UI Control |
|-----------|-------------|------------|
| `String` | string | Text input |
| `i32`, `i64`, `i8` | integer | Number input |
| `f32`, `f64` | number | Decimal input |
| `bool` | boolean | Checkbox |
| `Vec<T>` | array | Array editor |
| `Option<T>` | nullable T | Optional field |
| `serde_json::Value` | any | JSON editor |
| Custom struct with `#[derive(Deserialize)]` | object | Nested form |

### Required versus optional parameters

```rust
// Required parameter - must be provided
fn main(required_name: String) -> anyhow::Result<String> { ... }

// Optional parameter - can be omitted
fn main(optional_name: Option<String>) -> anyhow::Result<String> {
    let name = optional_name.unwrap_or_else(|| "default".to_string());
    Ok(format!("Hello, {}!", name))
}
```

**Important**: Rust does not support default values in function signatures. Use `Option<T>` with `unwrap_or` or `unwrap_or_else` for optional parameters with defaults.

### Complex input types

```rust
use serde::Deserialize;

#[derive(Deserialize)]
struct DatabaseConfig {
    host: String,
    port: u16,
    #[serde(default)]
    ssl: bool,
}

fn main(config: DatabaseConfig, query: String) -> anyhow::Result<String> {
    Ok(format!("Connecting to {}:{}", config.host, config.port))
}
```

---

## Return types and output serialization

Return types **must implement `serde::Serialize`**. Windmill automatically serializes the return value to JSON.

### Primitive returns

```rust
fn main(x: i32) -> anyhow::Result<i32> {
    Ok(x * 2)
}
```

### Struct returns

```rust
use serde::Serialize;

#[derive(Serialize, Debug)]
struct ProcessResult {
    status: String,
    processed_count: usize,
    errors: Vec<String>,
}

fn main(items: Vec<String>) -> anyhow::Result<ProcessResult> {
    Ok(ProcessResult {
        status: "complete".to_string(),
        processed_count: items.len(),
        errors: vec![],
    })
}
```

### Returning arbitrary JSON

```rust
use serde_json::json;

fn main(input: String) -> anyhow::Result<serde_json::Value> {
    Ok(json!({
        "input_received": input,
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "nested": {
            "data": [1, 2, 3]
        }
    }))
}
```

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
```

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
```

### Raw resource access

```rust
let wm = Windmill::default()?;
let raw: serde_json::Value = wm.get_resource_any("u/admin/api_config").await?;
let api_key = raw["api_key"].as_str().unwrap_or("");
```

### Variable and secret access

```rust
// Get variable as parsed JSON
let config: serde_json::Value = wm.get_variable("u/admin/config").await?;

// Get variable as raw string (for API keys, tokens)
let api_key: String = wm.get_variable_raw("u/admin/openai_key").await?;

// Set a variable
wm.set_variable("new_value".to_string(), "u/admin/my_var", false).await?;
```

### Creating and updating resources

```rust
use serde_json::json;

wm.set_resource(
    Some(json!({"host": "db.example.com", "port": 5432})),
    "u/admin/new_database",
    "postgresql"  // resource type
).await?;
```

---

## State management between runs

State persists data across script executions, scoped by script path and trigger context.

### Reading state

```rust
use serde::Deserialize;
use wmill::Windmill;

#[derive(Deserialize)]
struct MyState {
    last_processed_id: i64,
    run_count: u32,
}

async fn main() -> anyhow::Result<serde_json::Value> {
    let wm = Windmill::default()?;
    
    // Typed state
    let state: MyState = wm.get_state().await?;
    
    // Or raw state
    let raw_state: serde_json::Value = wm.get_state_any().await?;
    
    Ok(serde_json::json!({"last_id": state.last_processed_id}))
}
```

### Writing state

```rust
use serde_json::json;

// Update state
wm.set_state(Some(json!({
    "last_processed_id": 12345,
    "run_count": 42,
    "last_run": "2025-01-15T10:30:00Z"
}))).await?;

// Clear state
wm.set_state(None).await?;
```

### Trigger script pattern with state

```rust
async fn main() -> anyhow::Result<serde_json::Value> {
    let wm = Windmill::default()?;
    
    // Get last state (or default for first run)
    let last_state = wm.get_state_any().await
        .unwrap_or(serde_json::json!({"cursor": 0}));
    let cursor = last_state["cursor"].as_i64().unwrap_or(0);
    
    // Fetch new items since cursor
    let new_items = fetch_items_since(cursor).await?;
    let new_cursor = new_items.iter()
        .filter_map(|i| i["id"].as_i64())
        .max()
        .unwrap_or(cursor);
    
    // Save new state
    wm.set_state(Some(serde_json::json!({"cursor": new_cursor}))).await?;
    
    // Return items to process
    Ok(serde_json::json!({"items": new_items}))
}
```

---

## Calling other scripts and managing jobs

### Asynchronous execution (fire and forget)

```rust
use serde_json::json;

let job_id = wm.run_script_async(
    "u/user/my_script",     // script path
    false,                   // by_hash: false = use path
    json!({"param": "value"}),
    Some(10)                 // schedule delay in seconds (optional)
).await?;
println!("Started job: {}", job_id);
```

### Synchronous execution (wait for result)

```rust
let result = wm.run_script_sync(
    "f/production/process_data",
    false,                          // by_hash
    json!({"input": data}),
    None,                           // schedule_delay
    Some(120),                      // timeout in seconds
    true,                           // verbose logging
    true                            // assert_result_not_none
).await?;
```

### Job monitoring

```rust
// Wait for job completion
let result = wm.wait_job(&job_id, Some(60), true, true).await?;

// Check job status
let status = wm.get_job_status(&job_id).await?; // Running | Waiting | Completed

// Get result directly
let result = wm.get_result(&job_id).await?;
```

### Progress tracking

```rust
// Set progress (0-100)
wm.set_progress(50, None).await?;

// Get progress
let progress = wm.get_progress(Some(job_id.to_string())).await?;
```

---

## Error handling patterns

### Recommended pattern with anyhow

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! ```

use anyhow::{Result, Context, bail};

fn main(input: String) -> Result<serde_json::Value> {
    if input.is_empty() {
        bail!("Input cannot be empty");
    }
    
    let parsed = parse_input(&input)
        .context("Failed to parse input")?;
    
    let result = process(parsed)
        .context("Processing failed")?;
    
    Ok(serde_json::json!({"result": result}))
}
```

### Custom error types with thiserror

```rust
//! ```cargo
//! [dependencies]
//! thiserror = "1.0"
//! ```

use thiserror::Error;

#[derive(Error, Debug)]
pub enum ScriptError {
    #[error("API request failed: {0}")]
    ApiError(#[from] reqwest::Error),
    
    #[error("Validation failed for {field}: {message}")]
    ValidationError { field: String, message: String },
    
    #[error("Resource not found: {0}")]
    NotFound(String),
}

fn main(id: String) -> Result<serde_json::Value, ScriptError> {
    if id.is_empty() {
        return Err(ScriptError::ValidationError {
            field: "id".into(),
            message: "cannot be empty".into(),
        });
    }
    Ok(serde_json::json!({"status": "ok"}))
}
```

### How Windmill surfaces errors

Windmill captures both `Result::Err` and panics. Errors are displayed in the job run UI with the error message. For rich error display, return errors in this shape:

```rust
serde_json::json!({
    "error": {
        "message": "Detailed error description",
        "name": "ErrorType"
    }
})
```

**Best practice**: Always prefer `Result` over `panic!()`. Windmill catches panics but they provide less context.

---

## Flow composition and data passing

Windmill flows are DAGs where each step can be a Rust script. Data flows between steps via input transforms configured in the flow editor.

### Receiving data from previous steps

```rust
use serde::Deserialize;

#[derive(Deserialize)]
struct PreviousStepOutput {
    user_id: i64,
    name: String,
}

fn main(data: PreviousStepOutput) -> anyhow::Result<String> {
    Ok(format!("Processing user {} (ID: {})", data.name, data.user_id))
}
```

In the flow editor, connect using JavaScript expressions:
- `results.step_a.user_id` - field from step "a"
- `flow_input.param_name` - flow input parameter
- `resource(path)` - direct resource reference

### Retry configuration

Configure retries in flow step Advanced settings:

**Constant retry:**
```yaml
retry:
  constant:
    attempts: 5
    seconds: 60
```

**Exponential backoff:**
```yaml
retry:
  exponential:
    attempts: 5
    base: 2
    multiplier: 3
```

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
//! ```

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
//! ```

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
//! ```

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

## Limitations compared to TypeScript and Python

| Feature | TypeScript/Python | Rust |
|---------|-------------------|------|
| **Dedicated workers** | ✅ Persistent processes | ❌ Not available |
| **Result streaming** | ✅ `wmill.streamResult()` | ❌ Not available |
| **Workflows as code** | ✅ Full support | ❌ Use flow editor or YAML |
| **Native runtime parallelization** | ✅ 8x via nativets | ❌ Different performance model |
| **Cold start time** | Fast | Slower (compilation required) |

### Workarounds

- **No dedicated workers**: Accept cold start overhead; Rust compilation caching mitigates this
- **No result streaming**: Return complete results; use `set_progress()` for status updates
- **No workflows-as-code**: Define flows in the UI or YAML; call Rust scripts as steps
- **Cold starts**: Use debug mode during development (faster), release mode for deployment

---

## Build modes and caching

Windmill optimizes Rust compilation:

- **Preview/test runs**: Debug mode compilation (faster builds, larger binaries)
- **Deployed scripts**: Release mode compilation (optimized performance)
- **Shared build directory**: All Rust scripts share a common build directory for cache efficiency
- **Distributed cache**: Enterprise feature stores Rust bundles in S3 for all workers

---

## Conclusion

Windmill Rust scripts follow a distinctive pattern: inline Cargo dependencies in doc comments, a `main` function entrypoint with typed parameters, and `anyhow::Result<T>` returns where `T: Serialize`. The `wmill` SDK provides complete access to resources, state, variables, and job management through async methods. Key patterns to follow: use `Windmill::default()` for client initialization, `#[derive(Deserialize)]` for input structs, `#[derive(Serialize)]` for output structs, and `Option<T>` for optional parameters. Avoid panics in favor of `Result`, and leverage state management for trigger scripts that need to track processed items across runs.