# Rust Skill Guide for Windmill Scripts

## Overview

This project uses Rust for Windmill lambda scripts. These are standalone scripts that run in Windmill's Rust worker.

---

## Script Structure

Every Windmill Rust script follows this pattern:

```rust
//! Script description
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Input {
    pub field: String,
    #[serde(default)]
    pub optional_field: Option<String>,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    pub result: String,
}

pub fn main(input: Input) -> Result<Output> {
    // Implementation
    Ok(Output {
        success: true,
        result: format!("Processed: {}", input.field),
    })
}
```

### Key Points:
1. **Cargo dependencies** in doc comment with triple backticks
2. **Input struct** with `#[derive(Deserialize)]`
3. **Output struct** with `#[derive(Serialize)]`
4. **main function** takes `Input`, returns `Result<Output>`
5. Use `anyhow::Result` for error handling

---

## Common Patterns

### Default Values
```rust
#[derive(Deserialize)]
pub struct Input {
    #[serde(default = "default_timeout")]
    pub timeout_seconds: u64,
    #[serde(default)]
    pub optional: Option<String>,
}

fn default_timeout() -> u64 { 300 }
```

### Error Handling
```rust
use anyhow::{anyhow, Context, Result};

pub fn main(input: Input) -> Result<Output> {
    // Return error with context
    let data = std::fs::read_to_string(&input.path)
        .context("Failed to read input file")?;
    
    // Return custom error
    if data.is_empty() {
        return Err(anyhow!("Input file is empty"));
    }
    
    Ok(Output { success: true })
}
```

### Logging
```rust
pub fn main(input: Input) -> Result<Output> {
    eprintln!("[script] Starting processing");
    eprintln!("[script] Input: {:?}", input);
    
    // Work...
    
    eprintln!("[script] Completed successfully");
    Ok(Output { success: true })
}
```

### Calling External Commands
```rust
use std::process::{Command, Stdio};
use std::io::Write;

fn call_external(input: &str) -> Result<String> {
    let mut child = Command::new("some-command")
        .args(["--flag", "value"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(input.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow!("Command failed: {}", stderr));
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
```

### Standard Error Response
```rust
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: bool,
    pub message: String,
    pub details: Option<String>,
}

impl ErrorResponse {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            error: true,
            message: message.into(),
            details: None,
        }
    }
}
```

---

## Project Types (Shared Library)

The project has shared types in `windmill/src/types.rs`:

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionGoals {
    pub daily_protein: f64,
    pub daily_fat: f64,
    pub daily_carbs: f64,
    pub daily_calories: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionData {
    pub protein: f64,
    pub fat: f64,
    pub carbs: f64,
    pub calories: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviationResult {
    pub protein_pct: f64,
    pub fat_pct: f64,
    pub carbs_pct: f64,
    pub calories_pct: f64,
}
```

---

## Common Dependencies

```toml
# Error handling
anyhow = "1.0"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# HTTP client (if needed)
reqwest = { version = "0.11", features = ["json", "blocking"] }

# Async runtime (if needed)
tokio = { version = "1", features = ["full"] }
```

---

## Testing Scripts Locally

```bash
# Generate metadata
wmill script generate-metadata path/to/script.rs

# Run with arguments
wmill script run f/path/to/script -d '{"field": "value"}'
```

---

## Best Practices

1. **Use `anyhow`** for all error handling - provides context and backtraces
2. **Derive Debug** on all structs for logging
3. **Use `eprintln!`** for logging (goes to Windmill job logs)
4. **Validate inputs early** - fail fast with descriptive errors
5. **Use `#[serde(default)]`** for optional fields with sensible defaults
6. **Keep scripts focused** - one responsibility per script
7. **Use shared types** from `windmill/src/types.rs` for consistency

---

## Script Locations

```
windmill/
├── src/
│   ├── lib.rs          # Shared library exports
│   └── types.rs        # Common types
├── f/
│   ├── fire-flow/      # Flow scripts
│   │   ├── generate/script.rs
│   │   ├── validate/script.rs
│   │   └── ...
│   └── meal-planner/   # Feature scripts
│       └── features/
│           └── nutrition-compliance/
│               └── lambdas/
│                   ├── calculate_deviation/script.rs
│                   └── check_within_tolerance/script.rs
```
