---
id: ops/windmill/development-guide
title: "Windmill Development Guide"
category: ops
tags: ["windmill", "advanced", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Windmill Development Guide</title>
  <description>This guide covers the essential workflow for developing Windmill scripts in this repository.</description>
  <created_at>2026-01-02T19:55:27.356035</created_at>
  <updated_at>2026-01-02T19:55:27.356035</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="Prerequisites" level="2"/>
    <section name="Workspace Setup" level="2"/>
    <section name="CLI Workflow" level="2"/>
    <section name="Creating Scripts" level="3"/>
    <section name="Syncing with Remote" level="3"/>
    <section name="Running Scripts" level="3"/>
    <section name="Rust Script Structure" level="2"/>
    <section name="Simple Sync Script (Recommended)" level="3"/>
    <section name="Key Points" level="3"/>
    <section name="Script YAML Schema" level="3"/>
  </sections>
  <features>
    <feature>cargo_not_found_error</feature>
    <feature>cli_workflow</feature>
    <feature>creating_scripts</feature>
    <feature>cross-container_networking</feature>
    <feature>docker_setup</feature>
    <feature>file_structure</feature>
    <feature>js_resp</feature>
    <feature>key_points</feature>
    <feature>network_connectivity</feature>
    <feature>openssl_build_errors</feature>
    <feature>prerequisites</feature>
    <feature>required_image</feature>
    <feature>resources</feature>
    <feature>running_scripts</feature>
    <feature>rust_main</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="crate">tokio</dependency>
    <dependency type="crate">anyhow</dependency>
    <dependency type="crate">serde</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,advanced,operations</tags>
</doc_metadata>
-->

# Windmill Development Guide

> **Context**: This guide covers the essential workflow for developing Windmill scripts in this repository.

This guide covers the essential workflow for developing Windmill scripts in this repository.

## Prerequisites

- Windmill running with `windmill-full` image (required for Rust)
- `wmill` CLI installed: `npm install -g windmill-cli`
- Windmill workspace configured (see below)

## Workspace Setup

```bash
## Add workspace (one-time setup)
wmill workspace add <name> <workspace_id> <url> --token <token>

## Example for local development:
wmill workspace add meal-planner meal-planner http://localhost --token <your_token>

## Initialize wmill.yaml in windmill/ directory
cd windmill && wmill init
```text

## CLI Workflow

### Creating Scripts

```bash
## Bootstrap a new Rust script
wmill script bootstrap f/meal-planner/my_script rust --summary "Script summary"

## Bootstrap other languages: python3, bun, deno, bash, go
wmill script bootstrap f/meal-planner/my_script python3
```text

This creates:
- `f/meal-planner/my_script.rs` - Script code
- `f/meal-planner/my_script.script.yaml` - Metadata (summary, description, schema)

### Syncing with Remote

```bash
## Push local changes to remote
wmill sync push --yes

## Pull remote changes locally
wmill sync pull --yes

## Push specific script
wmill script push f/meal-planner/my_script.rs
```text

### Running Scripts

```bash
## Run with inline args
wmill script run f/meal-planner/my_script -d '{"param": "value"}'

## Run with resource reference
wmill script run f/meal-planner/my_script -d '{"config": "$res:f/meal-planner/my_resource"}'
```text

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

## Resources

Create resource types and resources via Windmill UI or API:

```bash
## Create resource type
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

## Create resource instance
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
```bash

## Docker Setup

### Required Image

Windmill workers must use `windmill-full` for Rust support:

```bash
## In .env
WM_IMAGE=ghcr.io/windmill-labs/windmill-full:latest
```text

### Cross-Container Networking

Connect containers to shared network for inter-service communication:

```bash
## Create shared network (one-time)
docker network create shared-services

## Connect Windmill workers
docker network connect shared-services lewis-windmill_worker-1
docker network connect shared-services lewis-windmill_worker-2
docker network connect shared-services lewis-windmill_worker-3

## Connect other services
docker network connect shared-services tandoor-web_recipes-1
```text

Services can then reach each other by container name:
- Tandoor: `http://tandoor-web_recipes-1:80`

## File Structure

```text
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


## See Also

- [Documentation Index](./COMPASS.md)
