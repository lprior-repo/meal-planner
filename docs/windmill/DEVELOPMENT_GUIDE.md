# Windmill Development Guide

This guide covers the essential workflow for developing Windmill scripts in this repository.

## Prerequisites

- Windmill running with `windmill-full` image (required for Rust)
- `wmill` CLI installed: `npm install -g windmill-cli`
- Windmill workspace configured (see below)

## Workspace Setup

```bash
# Add workspace (one-time setup)
wmill workspace add <name> <workspace_id> <url> --token <token>

# Example for local development:
wmill workspace add meal-planner meal-planner http://localhost --token <your_token>

# Initialize wmill.yaml in windmill/ directory
cd windmill && wmill init
```

## CLI Workflow

### Creating Scripts

```bash
# Bootstrap a new Rust script
wmill script bootstrap f/meal-planner/my_script rust --summary "Script summary"

# Bootstrap other languages: python3, bun, deno, bash, go
wmill script bootstrap f/meal-planner/my_script python3
```

This creates:
- `f/meal-planner/my_script.rs` - Script code
- `f/meal-planner/my_script.script.yaml` - Metadata (summary, description, schema)

### Syncing with Remote

```bash
# Push local changes to remote
wmill sync push --yes

# Pull remote changes locally
wmill sync pull --yes

# Push specific script
wmill script push f/meal-planner/my_script.rs
```

### Running Scripts

```bash
# Run with inline args
wmill script run f/meal-planner/my_script -d '{"param": "value"}'

# Run with resource reference
wmill script run f/meal-planner/my_script -d '{"config": "$res:f/meal-planner/my_resource"}'
```

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
//! ```

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
```

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
```

## Resources

Create resource types and resources via Windmill UI or API:

```bash
# Create resource type
curl -X POST "http://localhost/api/w/meal-planner/resources/type/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tandoor",
    "description": "Tandoor API",
    "schema": {
      "type": "object",
      "properties": {
        "base_url": {"type": "string"},
        "api_token": {"type": "string"}
      },
      "required": ["base_url", "api_token"]
    }
  }'

# Create resource instance
curl -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "f/meal-planner/tandoor_api",
    "resource_type": "tandoor",
    "value": {
      "base_url": "http://tandoor-web_recipes-1:80",
      "api_token": "your_token"
    }
  }'
```

## Docker Setup

### Required Image

Windmill workers must use `windmill-full` for Rust support:

```bash
# In .env
WM_IMAGE=ghcr.io/windmill-labs/windmill-full:latest
```

### Cross-Container Networking

Connect containers to shared network for inter-service communication:

```bash
# Create shared network (one-time)
docker network create shared-services

# Connect Windmill workers
docker network connect shared-services lewis-windmill_worker-1
docker network connect shared-services lewis-windmill_worker-2
docker network connect shared-services lewis-windmill_worker-3

# Connect other services
docker network connect shared-services tandoor-web_recipes-1
```

Services can then reach each other by container name:
- Tandoor: `http://tandoor-web_recipes-1:80`

## File Structure

```
windmill/
├── wmill.yaml                    # Sync configuration
├── wmill-lock.yaml               # Workspace lock
└── f/
    └── meal-planner/
        └── tandoor/
            ├── test_connection.rs           # Script code
            ├── test_connection.script.yaml  # Metadata & schema
            └── test_connection.script.lock  # Dependency lock
```

## Troubleshooting

### "cargo not found" Error
Use `windmill-full:latest` image instead of `windmill:main`

### OpenSSL Build Errors
Use `ureq` instead of `reqwest` to avoid OpenSSL dependency

### Script Not Found
Run `wmill sync push --yes` to ensure script is deployed

### Network Connectivity
Add `Host: localhost` header if target service validates hostname
