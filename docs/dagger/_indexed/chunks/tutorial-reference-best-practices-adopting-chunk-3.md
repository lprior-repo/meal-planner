---
doc_id: tutorial/reference/best-practices-adopting
chunk_id: tutorial/reference/best-practices-adopting#chunk-3
heading_path: ["best-practices-adopting", "Phase 2: The POC"]
chunk_type: prose
tokens: 213
summary: "The ideal first workflow has three properties:

1."
---
### Scoping your POC

The ideal first workflow has three properties:

1. It suffers from a **hair-on-fire problem** which daggerizing can solve
2. It can be daggerized within a week
3. You have the authority to daggerize it

### Choosing a language

- **Optimize for participation** - The more people on the team can participate, the better
- **Check SDK availability** - Go, Python, TypeScript are official; others are community-supported
- **Polyglot workflows for a polyglot stack** - Write different modules for each team's preferred language

### Integrating with CI

1. Decide which event should trigger which Dagger workflow
2. Map inputs from the environment into arguments to the Dagger functions
3. Write the resulting `dagger call` command for each workflow

**Key notes:**
- Don't hesitate to run both daggerized and non-daggerized workflows in parallel
- Dagger workflows are not distributed - each `dagger call` executes on a single Dagger engine
- Caching makes everything faster but is harder in CI with ephemeral runners
