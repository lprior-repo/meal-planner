---
id: ops/general/architecture
title: "Architecture"
category: ops
tags: ["windmill", "rust", "architecture", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>core</category>
  <title>Architecture</title>
  <description>Domain-based Rust binaries orchestrated by Windmill. Every binary does one thing, takes JSON, outputs JSON.</description>
  <created_at>2026-01-02T19:55:26.819178</created_at>
  <updated_at>2026-01-02T19:55:26.819178</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Design Principles (CUPID)" level="2"/>
    <section name="Project Structure" level="2"/>
    <section name="Binary Contract" level="2"/>
    <section name="Example" level="3"/>
    <section name="Domains (Bounded Contexts)" level="2"/>
    <section name="Windmill Integration" level="2"/>
    <section name="Deployment" level="2"/>
    <section name="Adding a New Domain" level="2"/>
    <section name="Testing" level="2"/>
  </sections>
  <features>
    <feature>adding_a_new_domain</feature>
    <feature>binary_contract</feature>
    <feature>deployment</feature>
    <feature>design_principles_cupid</feature>
    <feature>domains_bounded_contexts</feature>
    <feature>example</feature>
    <feature>js_config</feature>
    <feature>js_mut</feature>
    <feature>project_structure</feature>
    <feature>rust_main</feature>
    <feature>testing</feature>
    <feature>windmill_integration</feature>
  </features>
  <dependencies>
    <dependency type="crate">serde</dependency>
    <dependency type="feature">ops/general/moon-ci-pipeline</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
    <entity relationship="uses">MOON_CI_PIPELINE.md</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,rust,architecture,operations</tags>
</doc_metadata>
-->

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
