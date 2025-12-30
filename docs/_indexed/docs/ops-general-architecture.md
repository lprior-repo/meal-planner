---
id: ops/general/architecture
title: "Meal Planner Architecture"
category: ops
tags: ["rust", "meal", "windmill", "advanced", "operations"]
---

# Meal Planner Architecture

> **Context**: This project follows a **domain-based architecture** with small, composable Rust binaries orchestrated by Windmill flows. The design is guided by CUPI

## Overview

This project follows a **domain-based architecture** with small, composable Rust binaries orchestrated by Windmill flows. The design is guided by CUPID principles.

## CUPID Principles

All code in this project should embody these properties:

- **Composable**: Small binaries that pipe JSON in/out, work with Windmill or CLI
- **Unix philosophy**: Each binary does one thing well
- **Predictable**: Same input = same output, clear error handling
- **Idiomatic**: Standard Rust patterns, serde for JSON, thiserror for errors
- **Domain-based**: Organized by business domain, not technical layers

## Directory Structure

```text
meal-planner/
├── bin/                          # Compiled binaries (gitignored)
│   ├── tandoor_test_connection
│   ├── tandoor_list_recipes
│   └── fatsecret_oauth_auth
├── src/
│   ├── mod.rs                    # Library root, exports all domains
│   ├── bin/                      # Binary source files
│   │   ├── tandoor_test_connection.rs
│   │   ├── tandoor_list_recipes.rs
│   │   └── fatsecret_oauth_auth.rs
│   ├── tandoor/                  # Domain: Tandoor Recipes
│   │   ├── mod.rs                # Domain exports
│   │   ├── client.rs             # HTTP client
│   │   └── types.rs              # Domain types
│   └── fatsecret/                # Domain: FatSecret Nutrition
│       ├── mod.rs
│       ├── core/                 # Shared client code
│       ├── diary/                # Subdomain
│       └── foods/                # Subdomain
├── windmill/                     # Windmill flows (orchestration)
│   └── f/meal-planner/
├── dagger/                       # CI/CD pipeline
└── docs/
    └── ARCHITECTURE.md           # This file
```

Binary naming: `src/bin/<domain>_<operation>.rs` → `bin/<domain>_<operation>`

## Binary Contract

Every binary follows the same contract:

### Input
- Reads JSON from **stdin**
- Schema defined by a `*Input` or `*Config` struct

### Output
- Writes JSON to **stdout** on success
- Schema defined by a `*Output` or `*Result` struct

### Errors
- Writes JSON error to **stdout** (not stderr) with exit code 1
- Format: `{"success": false, "error": "message"}`

### Example Binary (~50 lines max)

```rust
//! tandoor/bin/test_connection.rs
//! Does one thing: tests Tandoor API authentication

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use std::io::{self, Read};

fn main() {
    let result = run();
    match result {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            println!(r#"{{"success": false, "error": "{}"}}"#, e);
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<serde_json::Value> {
    // 1. Read input
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    let config: TandoorConfig = serde_json::from_str(&input)?;

    // 2. Do one thing
    let client = TandoorClient::new(&config)?;
    let result = client.test_connection()?;

    // 3. Return output
    Ok(serde_json::to_value(result)?)
}
```text

## Windmill Integration

### Orchestration Model

```
┌─────────────────────────────────────────────────────────┐
│                    Windmill Flow                        │
│  (Orchestration, scheduling, retries, error handling)   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Rust Binary                          │
│  (Pure function: JSON in → JSON out)                    │
│  Deployed to worker container via Dagger                │
└─────────────────────────────────────────────────────────┘
```text

### Flows for Composition

Complex operations are Windmill **flows** that compose multiple binaries:

```yaml
## Example: Daily meal sync flow
steps:
  - name: get_recipes
    script: tandoor/list_recipes
  - name: get_nutrition
    script: fatsecret/foods_search
    foreach: ${steps.get_recipes.results}
  - name: calculate_macros
    script: nutrition/calculate_macros
    input: ${steps.get_nutrition}
```text

## Deployment

### Dagger Pipeline

Dagger builds binaries and deploys to Windmill worker containers:

```
┌──────────┐    ┌──────────┐    ┌─────────────────────┐
│  Source  │───▶│  Dagger  │───▶│  Windmill Workers   │
│  (Rust)  │    │  Build   │    │  /usr/local/bin/*   │
└──────────┘    └──────────┘    └─────────────────────┘
```text

Binaries are statically linked and copied into the worker container image or mounted as a volume.

## Bounded Contexts

Each domain is a bounded context with its own:
- Types (no sharing across domains)
- Client (HTTP, auth specific to that API)
- Binaries (domain operations)

Cross-domain coordination happens in Windmill flows, not in Rust code.

### Current Domains

| Domain | Purpose | External API |
|--------|---------|--------------|
| `tandoor` | Recipe management | Tandoor Recipes API |
| `fatsecret` | Nutrition tracking | FatSecret Platform API |

## Adding a New Domain

1. Create domain directory: `src/<domain>/`
2. Add module files: `mod.rs`, `client.rs`, `types.rs`
3. Create `bin/` subdirectory for binaries
4. Add binaries to `Cargo.toml`
5. Export domain in `src/lib.rs`
6. Create Windmill scripts in `windmill/f/meal-planner/<domain>/`

## Adding a New Binary

1. Create file: `src/<domain>/bin/<operation>.rs`
2. Follow the binary contract (stdin JSON → stdout JSON)
3. Keep it under ~100 lines, doing ONE thing
4. Add to `Cargo.toml`:
   ```toml
   [[bin]]
   name = "<domain>-<operation>"
   path = "src/<domain>/bin/<operation>.rs"
   ```text
5. Create corresponding Windmill script

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

## Docker Deployment

Binaries are built and mounted into Windmill worker containers:

```dockerfile
FROM ghcr.io/windmill-labs/windmill-full:latest
COPY target/release/tandoor-* /usr/local/bin/
COPY target/release/fatsecret-* /usr/local/bin/
```text

Or use volume mounts for development:
```yaml
volumes:
  - ./target/release:/app/bin
```


## See Also

- [Documentation Index](./COMPASS.md)
