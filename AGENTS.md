# AI Agent Workflow Guide

This document describes how to work with AI agents in the meal-planner project using Beads.

## Architecture

**READ FIRST**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Domain-based structure, CUPID principles, binary contract.

### Key Concepts

- **CUPID principles**: Composable, Unix philosophy, Predictable, Idiomatic, Domain-based
- **Domain-based layout**: Code organized by business domain (`tandoor/`, `fatsecret/`), not technical layers
- **Small binaries**: Each binary does ONE thing, ~50-100 lines, JSON in → JSON out
- **Windmill orchestration**: Flows compose binaries, handle scheduling/retries/errors

### Quick Reference

```
src/
├── tandoor/              # Domain: Tandoor Recipes
│   ├── client.rs         # Shared HTTP client
│   ├── types.rs          # Domain types
│   └── bin/              # Small, focused binaries
│       └── test_connection.rs
└── fatsecret/            # Domain: FatSecret Nutrition
    └── ...

windmill/                 # Orchestration layer
└── f/meal-planner/
    └── tandoor/          # Bash scripts calling binaries
```

## Overview

The meal-planner project uses **Beads** (bd) for issue tracking, dependency management, and agent coordination. All work must go through Beads to ensure proper tracking and visibility.

## Documentation Indexing System

The project uses **Anthropic XML best practices** combined with **DAG-based referencing** for documentation indexing. This system makes documentation super easy to find, navigate, and use for AI coding agents.

### Key Files

- **`docs/windmill/DOCUMENTATION_INDEX.xml`** - Master XML index with entities, DAG, and RAG chunks
- **`docs/windmill/INDEXED_KNOWLEDGE.json`** - JSON programmatic access with DAG structure
- **`docs/windmill/INDEXING_SYSTEM.md`** - Complete system documentation
- **XML Metadata** in all docs - Structured headers with type, category, difficulty, dependencies

### XML Metadata Schema

Each document includes structured XML metadata:

```xml
<doc_metadata>
  <type>reference|guide|tutorial</type>
  <category>flows|core_concepts|cli|sdk|deployment</category>
  <title>Document Title</title>
  <description>Brief description</description>
  <created_at>ISO-8601 timestamp</created_at>
  <updated_at>ISO-8601 timestamp</updated_at>
  <language>en</language>
  <sections count="N">
    <section name="Section Name" level="1|2|3"/>
  </sections>
  <features>
    <feature>feature_name</feature>
  </features>
  <dependencies>
    <dependency type="feature|tool|service|crate">dependency_id</dependency>
  </dependencies>
  <examples count="N">
    <example>Example description</example>
  </examples>
  <difficulty_level>beginner|intermediate|advanced</difficulty_level>
  <estimated_reading_time>minutes</estimated_reading_time>
  <tags>tag1,tag2,tag3</tags>
</doc_metadata>
```

### DAG Structure

Documents are organized in 4 layers:

1. **Layer 1**: Flow Control Features (retries, error_handler, for_loops, flow_branches, early_stop, step_mocking, sleep, priority, lifetime)
2. **Layer 2**: Core Concepts (caching, concurrency_limits, job_debouncing, staging_prod, multiplayer)
3. **Layer 3**: Tools & SDKs (wmill_cli, python_client, rust_sdk)
4. **Layer 4**: Deployment (windmill_deployment, oauth, schedules)

### Relationship Types

- `uses` - Feature A uses Feature B
- `can-trigger` - Feature A can trigger Feature B
- `continues-on` - Feature A continues to Feature B
- `deploys-to` - Tool A deploys to Feature B
- `accesses` - Tool/SDK A accesses Feature B
- `part-of` - Feature A is part of Feature B
- `required-for` - Feature A is required for Feature B

### Adding New Documentation

When adding new documentation:

1. Add XML metadata header to markdown file
2. Update `DOCUMENTATION_INDEX.xml` with new entity
3. Add DAG node and edges if applicable
4. Update `INDEXED_KNOWLEDGE.json` with document metadata
5. Regenerate RAG chunks if needed

See `docs/windmill/INDEXING_SYSTEM.md` for complete guidelines.

### CodeAnna Integration

The project uses CodeAnna for AI-assisted coding. CodeAnna has indexed the repository and provides context-aware assistance.

- **Indexed**: All source code, documentation, and configuration files
- **Context**: Full understanding of codebase architecture and patterns
- **Available**: Run `anna help` or `anna <command>` for assistance

### Best Practices

1. **Use XML Metadata**: When creating or editing docs, follow the XML schema
2. **Follow DAG Relationships**: Reference related features via DAG edges
3. **Consult Index Files**: Use DOCUMENTATION_INDEX.xml and INDEXED_KNOWLEDGE.json for navigation
4. **Query Properly**: Use entity names and tags from the index for relevant information
5. **Maintain Index**: Keep index files up to date when adding/modifying docs

## Working with Beads

### Creating Issues

```bash
bd add --title "Feature: X" --priority high --label feature
bd add --title "Bug: X fails on Y" --priority high --label bug --description "Steps to reproduce..."
```

### Tracking Progress

```bash
bd claim <issue-id>           # Start working on an issue
bd resolve <issue-id>         # Mark as resolved (needs review)
bd complete <issue-id>        # Mark as completed
```

### Managing Dependencies

```bash
bd link <issue-id-1> <issue-id-2>    # Create dependency
bd unlink <issue-id-1> <issue-id-2>  # Remove dependency
```

## Version Control with JJ

This project uses **jj (Jujutsu)** exclusively for version control. Do NOT use git commands directly.

### Common JJ Commands

```bash
jj status                    # Show working copy status
jj diff                      # Show changes in working copy
jj log                       # Show commit history
jj describe -m "message"     # Set commit message for working copy
jj new                       # Create a new change after current
jj squash                    # Squash changes into parent
jj edit <revision>           # Edit an existing revision
jj bookmark set <name>       # Create/move a bookmark (like git branch)
jj git push                  # Push to remote
jj git fetch                 # Fetch from remote
```

### JJ Workflow

1. Make changes to files (they're automatically tracked)
2. Use `jj status` and `jj diff` to review
3. Use `jj describe -m "type: description"` to set commit message
4. Use `jj new` to start a new change
5. Use `jj git push` to push to remote

## Landing Protocol

After completing work, follow this protocol:

### 1. Commit Your Changes
```bash
jj describe -m "type: description"  # Follow conventional commits
jj new                              # Start fresh change
```

### 2. Update Beads (Source of Truth)
```bash
bd claim <issue-id> --status completed --commit-hash <hash>
```

### 3. Save Decisions to mem0
For architecture decisions, bug solutions, and patterns:
```
mem0_add_memory(text="Decision: X. Rationale: Y. Context: Z")
```

### 4. Push to Remote
```bash
jj git fetch --all-remotes
jj git push
```

## Commit Message Format

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `chore:` Build, dependencies, tooling
- `docs:` Documentation changes
- `test:` Test additions/modifications

Example:
```
feat: add OAuth token storage with SQLx

- Implement secure token persistence
- Add migration scripts
- Update tests

Closes #MP-123
```

## Issue Labels

- `epic` - Large feature spanning multiple tasks
- `feature` - New functionality
- `bug` - Something broken
- `chore` - Maintenance, refactoring, tooling
- `fatsecret` - FatSecret API related
- `windmill` - Windmill script related
- `p0`, `p1`, `p2` - Priority levels

## JJ Workflow

1. Work on issues assigned to you
2. Use `jj describe -m "type: description"` to set commit message
3. Use `jj new` to start next change
4. Update Beads to mark progress
5. Use `jj git push` when ready for review

## Helpful Commands

```bash
bd list              # Show all open issues
bd duplicates        # Find and review duplicates
bd doctor            # Check project health
bd ready             # Mark ready for review
```

## Windmill Development

This project uses **Windmill** for workflow orchestration. Scripts are written in Rust (purely functional style) and deployed via the `wmill` CLI.

### Quick Reference

```bash
# Bootstrap new Rust script
wmill script bootstrap f/meal-planner/my_script rust --summary "Summary"

# Generate metadata after editing
wmill script generate-metadata

# Push to Windmill
wmill sync push --yes

# Run a script
wmill script run f/meal-planner/my_script -d '{"param": "value"}'
```

### Key Documentation

- **[Windmill Development Guide](docs/windmill/DEVELOPMENT_GUIDE.md)** - Complete CLI workflow, Rust patterns, resources
- **[Rust Quickstart](docs/windmill/getting_started/0_scripts_quickstart/9_rust_quickstart/index.mdx)** - Rust script basics
- **[Rust Client SDK](docs/windmill/advanced/2_clients/rust_client.mdx)** - Windmill SDK for Rust
- **[CLI Commands](docs/windmill/advanced/3_cli/script.md)** - Script CLI reference
- **[Sync Commands](docs/windmill/advanced/3_cli/sync.mdx)** - Push/pull operations

### File Structure

```
windmill/
├── wmill.yaml                    # Sync configuration
└── f/meal-planner/
    └── tandoor/
        ├── test_connection.rs           # Script code
        ├── test_connection.script.yaml  # Metadata
        └── test_connection.script.lock  # Dependencies
```

### Rust Script Pattern

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! serde = { version = "1.0", features = ["derive"] }
//! ```

use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Input { field: String }

#[derive(Serialize)]
struct Output { result: String }

fn main(input: Input) -> anyhow::Result<Output> {
    Ok(Output { result: input.field })
}
```

### Docker Networking

Windmill workers and other services communicate via shared Docker network:

```bash
# Create shared network (one-time)
docker network create shared-services

# Connect containers
docker network connect shared-services <container_name>
```

Current services on `shared-services`:
- Windmill workers (`lewis-windmill_worker-*`)
- Tandoor (`tandoor-web_recipes-1` at port 80)

## Resources

- [Beads Documentation](https://github.com/steveyegge/beads)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Windmill Documentation](https://www.windmill.dev/docs)

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
