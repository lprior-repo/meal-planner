---
id: ops/general/architecture
title: "Architecture"
category: ops
tags: ["operations", "architecture", "windmill", "rust"]
---

# Architecture

> **Context**: Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.

Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.

**For both humans and AI agents**: This doc links to related docs so you can follow the thread without getting lost.

## Design Principles (CUPID)

- **Composable**: Small binaries that work standalone or via Windmill
- **Unix philosophy**: Each binary does ONE thing well
- **Predictable**: Same input = same output, explicit error handling
- **Idiomatic**: Standard Rust, serde, thiserror
- **Domain-based**: Organized by business domain, not technical layers

## Project Structure

```
src/bin/              # Binary sources
src/tandoor/          # Domain: Recipes
src/fatsecret/        # Domain: Nutrition
windmill/f/           # Flows (orchestration)
```

## Binary Contract

Every binary follows this pattern:

1. **Read JSON from stdin**
2. **Do one thing** (~50 lines max)
3. **Write JSON to stdout** or error JSON to stdout with exit code 1

### Example

```rust
fn main() {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input).unwrap();
    
    let config: MyConfig = serde_json::from_str(&input).unwrap();
    match do_work(&config) {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            println!(r#"{{"success": false, "error": "{}"}}"#, e);
            std::process::exit(1);
        }
    }
}
```

## Domains (Bounded Contexts)

| Domain | Purpose | API |
|--------|---------|-----|
| `tandoor` | Recipe management | Tandoor Recipes |
| `fatsecret` | Nutrition tracking | FatSecret Platform |

Each domain has its own:
- Types (no cross-domain sharing)
- HTTP client
- Binaries

Cross-domain coordination happens in **Windmill flows**, never in Rust code.

## Windmill Integration

Flows compose binaries:

```yaml
steps:
  - get_recipes: tandoor/list_recipes
  - get_nutrition: fatsecret/search
    foreach: ${steps.get_recipes}
  - calculate: nutrition/macros
    input: ${steps.get_nutrition}
```

## Deployment

Binaries are built by Moon, deployed to Windmill worker containers via volume mount at `/usr/local/bin/meal-planner/`.

See: [MOON_CI_PIPELINE.md](./ops-general-moon-ci-pipeline.md)

## Adding a New Domain

1. Create `src/<domain>/` with `mod.rs`, `client.rs`, `types.rs`
2. Add binaries in `src/bin/<domain>_<operation>.rs`
3. Register in `Cargo.toml` and `src/lib.rs`
4. Create Windmill scripts in `windmill/f/<domain>/`

## Testing

- **Unit tests**: In domain modules
- **Integration tests**: In `tests/`, test binaries end-to-end
- **Run all**: `moon run :test`

See: [MOON_CI_PIPELINE.md](./ops-general-moon-ci-pipeline.md) for local testing


## See Also

- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md)
- [MOON_CI_PIPELINE.md](MOON_CI_PIPELINE.md)
