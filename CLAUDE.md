# Meal Planner - AI Agent Instructions

## Project Overview

This is a meal planning application with:
- **Backend**: Gleam (functional, type-safe) + Rust (Windmill scripts)
- **Automation**: Windmill workflows for scheduling and integrations
- **Database**: PostgreSQL

---

## Skill Guides

| Document | Purpose |
|----------|---------|
| `CLAUDE_WINDMILL.md` | Windmill flows, CLI, Python SDK, best practices |
| `CLAUDE_RUST.md` | Rust script patterns for Windmill lambdas |
| `AGENTS.md` | Task tracking with bd (beads) |

---

## Knowledge Graph (Graphiti)

**Windmill documentation is indexed.** Search before implementing Windmill features:

```python
# Search for Windmill knowledge
graphiti_search_memory_facts(
    query="windmill retries error handling",
    group_ids=["windmill-docs"]
)

# List all indexed episodes
graphiti_get_episodes(group_ids=["windmill-docs"], max_episodes=30)
```

**Indexed content (group: `windmill-docs`):**
- **Flow Features**: Retries, Error Handler, Branches, For Loops, Early Stop, Sleep, Priority, Lifetime, Step Mocking, Custom Timeout
- **Core Concepts**: Caching, Concurrency Limits, Job Debouncing, Staging/Prod Deploy, Multiplayer
- **CLI (wmill)**: Installation, Scripts, Flows, Resources, Variables, Workspace Management
- **Python SDK**: get_resource, get_variable, run_script, run_flow, S3 integration

**RAG chunks**: `docs/windmill/INDEXED_KNOWLEDGE.json`

---

## Project Structure

```
src/meal_planner/     # Gleam source code
windmill/             # Windmill scripts and flows
  ├── src/            # Shared Rust library (types.rs)
  └── f/              # Flow scripts (Rust)
schema/               # PostgreSQL migrations
test/                 # Test files
docs/windmill/        # Indexed Windmill documentation
```

---

## Toolchain

| Tool | Usage |
|------|-------|
| `gleam test` | Run Gleam tests |
| `gleam build` | Build Gleam project |
| `cargo test` | Run Rust tests (in windmill/) |
| `wmill` | Windmill CLI |
| `bd` | Beads task tracking |

---

## Workflow

1. **Check knowledge**: `graphiti_search_memory_facts` for existing patterns
2. **Read skill guide**: `CLAUDE_WINDMILL.md` or `CLAUDE_RUST.md`
3. **Write tests first** (TDD)
4. **Implement changes**
5. **Run tests**: `gleam test` or `cargo test`
6. **Commit** with clear message
