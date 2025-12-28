# Meal Planner - AI Agent Instructions

## Project Overview

This is a meal planning application with:
- **Backend**: Gleam (functional, type-safe) + Rust (Windmill scripts)
- **Automation**: Windmill workflows for scheduling and integrations
- **Database**: PostgreSQL

---

## Knowledge Graph (Graphiti)

**Windmill documentation is indexed.** Search before implementing Windmill features:

```python
# Search for Windmill knowledge
graphiti_search_memory_facts(query="windmill retries error handling", group_ids=["windmill-docs"])

# List all indexed episodes
graphiti_get_episodes(group_ids=["windmill-docs"], max_episodes=30)
```

**Indexed content (group: `windmill-docs`):**
- **Flow Features**: Retries (constant + exponential), Error Handler, Branches (one/all), For Loops (parallel, squash), Early Stop/Break, Sleep/Delays, Priority, Lifetime, Step Mocking, Custom Timeout
- **Core Concepts**: Caching, Concurrency Limits, Job Debouncing, Staging/Prod Deploy, Multiplayer
- **CLI (wmill)**: Installation, Scripts, Flows, Resources, Variables, Workspace Management
- **Python SDK**: get_resource, get_variable, run_script, run_flow, S3 integration

**Key relationships:**
- Error Handler depends on Retries (called after retries exhausted)
- Branches + Early Stop for conditional flow termination
- Caching vs Step Mocking (production vs development optimization)
- Concurrency Limits vs Job Debouncing (queue vs cancel strategies)

---

## Documentation

| Document | Purpose |
|----------|---------|
| `AGENTS.md` | Quick reference for bd (beads) task tracking |
| `docs/windmill/INDEXED_KNOWLEDGE.json` | RAG chunks for Windmill features, CLI, Python SDK |
| `docs/windmill/flows/*.md` | Windmill flow feature documentation |
| `docs/windmill/core_concepts/*.md` | Windmill core concept documentation |
| `docs/windmill/advanced/3_cli/*.md` | Windmill CLI documentation |

---

## Toolchain

| Tool | Usage |
|------|-------|
| `gleam test` | Run Gleam tests |
| `gleam build` | Build Gleam project |
| `cargo test` | Run Rust tests |
| `wmill` | Windmill CLI |
| `bd` | Beads task tracking |

---

## Project Structure

```
src/meal_planner/     # Gleam source code
windmill/             # Windmill scripts and flows
schema/               # PostgreSQL migrations
test/                 # Test files
docs/windmill/        # Indexed Windmill documentation
```

---

## Workflow

1. Check for existing knowledge: `graphiti_search_memory_facts`
2. Read relevant documentation
3. Write tests first (TDD)
4. Implement changes
5. Run tests: `gleam test` or `cargo test`
6. Commit with clear message
