---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-6
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "State management between runs"]
chunk_type: code
tokens: 205
summary: "State management between runs"
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
