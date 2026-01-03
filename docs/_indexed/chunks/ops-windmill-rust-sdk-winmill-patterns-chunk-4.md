---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-4
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Return types and output serialization"]
chunk_type: code
tokens: 127
summary: "Return types and output serialization"
---

## Return types and output serialization

Return types **must implement `serde::Serialize`**. Windmill automatically serializes the return value to JSON.

### Primitive returns

```rust
fn main(x: i32) -> anyhow::Result<i32> {
    Ok(x * 2)
}
```rust

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
```text

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
```yaml

---
