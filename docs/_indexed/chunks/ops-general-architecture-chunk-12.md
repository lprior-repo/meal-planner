---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-12
heading_path: ["Meal Planner Architecture", "Testing"]
chunk_type: prose
tokens: 54
summary: "Testing"
---

## Testing

### Unit Tests
In domain modules (`client.rs`, `types.rs`)

### Integration Tests
In `tests/` directory, test binaries end-to-end:

```rust
#[test]
fn test_tandoor_connection() {
    let output = Command::new("./target/debug/tandoor-test-connection")
        .stdin(json!({"base_url": "...", "api_token": "..."}))
        .output()
        .unwrap();
    let result: Value = serde_json::from_slice(&output.stdout).unwrap();
    assert!(result["success"].as_bool().unwrap());
}
```bash
