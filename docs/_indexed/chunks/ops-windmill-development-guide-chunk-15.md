---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-15
heading_path: ["Windmill Development Guide", "Rust Script Structure"]
chunk_type: code
tokens: 286
summary: "Rust Script Structure"
---

## Rust Script Structure

### Simple Sync Script (Recommended)

Use sync `fn main()` with arguments - no tokio needed for simple HTTP:

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ureq = { version = "2.10", features = ["json"] }
//! ```rust

use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Config {
    pub base_url: String,
    pub api_token: String,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    pub message: String,
}

fn main(config: Config) -> anyhow::Result<Output> {
    let resp = ureq::get(&config.base_url)
        .set("Authorization", &format!("Bearer {}", config.api_token))
        .call()?
        .into_string()?;
    
    Ok(Output {
        success: true,
        message: format!("Response: {} chars", resp.len()),
    })
}
```rust

### Key Points

1. **Use `ureq` for HTTP** - No OpenSSL dependency (uses rustls)
2. **Sync `fn main(args)`** - Arguments become script inputs automatically
3. **`#[derive(Deserialize)]` for inputs** - Defines the input schema
4. **`#[derive(Serialize)]` for output** - Result is JSON serialized
5. **Return `anyhow::Result<T>`** - Standard error handling

### Script YAML Schema

The `.script.yaml` defines input schema for the UI:

```yaml
summary: My Script
description: Does something useful
kind: script
schema:
  $schema: 'https://json-schema.org/draft/2020-12/schema'
  type: object
  properties:
    config:
      type: object
      description: API configuration
      format: resource-mytype  # Links to resource type
      properties:
        base_url:
          type: string
        api_token:
          type: string
      required:
        - base_url
        - api_token
  required:
    - config
```text
