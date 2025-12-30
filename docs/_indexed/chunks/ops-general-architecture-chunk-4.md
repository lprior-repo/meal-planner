---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-4
heading_path: ["Meal Planner Architecture", "Directory Structure"]
chunk_type: prose
tokens: 171
summary: "Directory Structure"
---

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
```text

Binary naming: `src/bin/<domain>_<operation>.rs` → `bin/<domain>_<operation>`
