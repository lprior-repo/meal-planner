---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-3
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Main function signature patterns"]
chunk_type: code
tokens: 416
summary: "Main function signature patterns"
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
```text

### Async script with SDK access

```rust
//! ```cargo
//! [dependencies]
//! wmill = "^1.0"
//! tokio = { version = "1", features = ["full"] }
//! anyhow = "1.0"
//! serde_json = "1.0"
//! ```rust

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
```javascript

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
```yaml

---
