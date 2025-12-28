# Meal Planner - AI Agent Instructions

## Project Overview

- **Backend**: Gleam (functional, type-safe) + Rust (Windmill scripts)
- **Automation**: Windmill workflows for scheduling and integrations
- **Database**: PostgreSQL

---

## IMPORTANT: Read Skill Guides

When working on Windmill or Rust code, **READ THESE FILES FIRST**:

- **`CLAUDE_WINDMILL.md`** - Windmill flows, CLI, Python SDK, best practices
- **`CLAUDE_RUST.md`** - Rust script patterns for Windmill lambdas

---

## Knowledge Graph (Graphiti)

**Windmill documentation is indexed.** Search before implementing:

```python
graphiti_search_memory_facts(query="windmill retries", group_ids=["windmill-docs"])
graphiti_get_episodes(group_ids=["windmill-docs"], max_episodes=30)
```

**Indexed (group `windmill-docs`):**
- Flow Features: Retries, Error Handler, Branches, For Loops, Early Stop, Sleep, Priority, Lifetime, Step Mocking, Custom Timeout
- Core Concepts: Caching, Concurrency Limits, Job Debouncing, Staging/Prod, Multiplayer
- CLI: Scripts, Flows, Resources, Variables, Workspace Management
- Python SDK: get_resource, get_variable, run_script, run_flow, S3

**RAG chunks**: `docs/windmill/INDEXED_KNOWLEDGE.json`

---

## Quick Reference: Windmill

### Flow Features
| Feature | Use Case |
|---------|----------|
| Retries | API calls, transient failures (constant or exponential backoff) |
| Error Handler | Notifications, fallback actions after all retries fail |
| Branches | Conditional execution (Branch One) or parallel execution (Branch All) |
| For Loops | Iterate items, parallel option, squash for no cold starts |
| Early Stop | Stop flow based on predicate expression |
| Caching | Store results for duration, reduce redundant computation |
| Concurrency Limits | Prevent exceeding API rate limits |
| Job Debouncing | Cancel pending duplicates, only newest runs |

### CLI Commands
```bash
wmill workspace switch <name>     # Switch workspace
wmill script push <path>          # Push script
wmill script run <path> -d '{}'   # Run with args
wmill flow push <file> <path>     # Push flow
wmill script generate-metadata    # Regenerate locks
```

### Python SDK
```python
import wmill
db = wmill.get_resource('u/user/db_config')
result = wmill.run_script_by_path('f/scripts/calc', args={'x': 10})
wmill.set_state({'last_run': '2025-01-01'})
```

---

## Quick Reference: Rust Scripts

### Script Structure
```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Input { pub field: String }

#[derive(Serialize)]
pub struct Output { pub success: bool }

pub fn main(input: Input) -> Result<Output> {
    Ok(Output { success: true })
}
```

### Key Patterns
- Use `#[serde(default)]` for optional fields
- Use `anyhow::Result` for error handling
- Use `eprintln!` for logging
- Shared types in `windmill/src/types.rs`

---

## Project Structure

```
src/meal_planner/     # Gleam source
windmill/             # Windmill scripts
  ├── src/            # Shared Rust library
  └── f/              # Flow scripts
schema/               # PostgreSQL migrations
docs/windmill/        # Indexed documentation
```

---

## Toolchain

| Tool | Usage |
|------|-------|
| `gleam test` | Run Gleam tests |
| `cargo test` | Run Rust tests (in windmill/) |
| `wmill` | Windmill CLI |
| `bd` | Beads task tracking |
