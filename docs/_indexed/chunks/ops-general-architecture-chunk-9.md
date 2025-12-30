---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-9
heading_path: ["Meal Planner Architecture", "Bounded Contexts"]
chunk_type: prose
tokens: 93
summary: "Bounded Contexts"
---

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
