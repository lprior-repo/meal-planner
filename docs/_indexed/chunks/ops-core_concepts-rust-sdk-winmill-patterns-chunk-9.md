---
doc_id: ops/core_concepts/rust-sdk-winmill-patterns
chunk_id: ops/core_concepts/rust-sdk-winmill-patterns#chunk-9
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Flow composition and data passing"]
chunk_type: code
tokens: 159
summary: "Flow composition and data passing"
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
```text

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
```text

**Exponential backoff:**
```yaml
retry:
  exponential:
    attempts: 5
    base: 2
    multiplier: 3
```yaml

---
