---
doc_id: ops/windmill/rust-sdk-winmill-patterns
chunk_id: ops/windmill/rust-sdk-winmill-patterns#chunk-8
heading_path: ["Windmill Rust SDK: Complete Reference Guide for AI Coding Agents", "Error handling patterns"]
chunk_type: code
tokens: 248
summary: "Error handling patterns"
---

## Error handling patterns

### Recommended pattern with anyhow

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! ```rust

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
```rust

### Custom error types with thiserror

```rust
//! ```cargo
//! [dependencies]
//! thiserror = "1.0"
//! ```rust

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
```text

**Best practice**: Always prefer `Result` over `panic!()`. Windmill catches panics but they provide less context.

---
