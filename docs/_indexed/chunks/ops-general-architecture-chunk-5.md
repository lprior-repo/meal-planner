---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-5
heading_path: ["Architecture", "Domains (Bounded Contexts)"]
chunk_type: prose
tokens: 71
summary: "Domains (Bounded Contexts)"
---

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
