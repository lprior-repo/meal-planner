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

## ⚠️ CRITICAL: FatSecret OAuth Token Setup (Do This First!)

**This must be done ONCE to enable all FatSecret features. Follow exactly.**

### Step 1: Get Authorization URL

```bash
wmill script run f/fatsecret/oauth_start -d '{"fatsecret": "$res:u/admin/fatsecret_api", "callback_url": "oob"}' 2>&1 | tail -5
```

**Output will show:**
```json
{
  "success": true,
  "auth_url": "https://authentication.fatsecret.com/oauth/authorize?oauth_token=XXX",
  "oauth_token": "REQUEST_TOKEN_HERE",
  "oauth_token_secret": "REQUEST_TOKEN_SECRET_HERE"
}
```

**Copy these values:**
- `auth_url` → Visit in browser
- `oauth_token` → Save temporarily
- `oauth_token_secret` → Save temporarily

### Step 2: Authorize in Browser

1. **Visit the `auth_url`** in your browser
2. Log in with FatSecret account
3. Click "Authorize"
4. **Copy the verifier code** (6-8 digits shown on screen)

### Step 3: Exchange Verifier for Access Token

```bash
wmill script run f/fatsecret/oauth_complete -d '{
  "fatsecret": "$res:u/admin/fatsecret_api",
  "oauth_token": "REQUEST_TOKEN_HERE",
  "oauth_token_secret": "REQUEST_TOKEN_SECRET_HERE",
  "oauth_verifier": "YOUR_VERIFIER_CODE"
}' 2>&1 | tail -10
```

**Output will show access tokens:**
```json
{
  "success": true,
  "oauth_token": "ACCESS_TOKEN_HERE",
  "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
}
```

**Copy these values** - they are your permanent access tokens.

### Step 4: Store in Windmill (SECURELY) ⭐ EXACTLY WHERE TOKENS LIVE

**The OAuth tokens MUST be stored as a Windmill Resource for all scripts to access them.**

#### Database Location (Encrypted)
```
PostgreSQL: windmill database
  ↓
  Table: resource
  ↓
  Path: u/admin/fatsecret_oauth
  ↓
  Fields: consumer_key, consumer_secret, oauth_token, oauth_token_secret
  ↓
  Encryption: AES-256 with ENCRYPTION_KEY from docker-compose.yml
```

#### Quick Copy-Paste (Replace Values)

```bash
# 1. Get Windmill token
TOKEN="hLg0fT2LyCggnu7ViGVFnmqejPF1uWsI"  # From ~/.config/windmill/remotes.ndjson

# 2. Create resource with OAuth tokens
curl -s -X POST "http://localhost/api/w/meal-planner/resources/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "u/admin/fatsecret_oauth",
    "resource_type": "fatsecret",
    "value": {
      "consumer_key": "YOUR_CONSUMER_KEY_HERE",
      "consumer_secret": "YOUR_CONSUMER_SECRET_HERE",
      "oauth_token": "ACCESS_TOKEN_HERE",
      "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
    }
  }'

# 3. Verify it's stored (encrypted in database)
curl -s "http://localhost/api/w/meal-planner/resources/get/u/admin/fatsecret_oauth" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 4. Direct DB verification (shows encrypted values)
docker exec lewis-db-1 psql -U postgres -d windmill \
  -c "SELECT path, workspace_id FROM resource WHERE path = 'u/admin/fatsecret_oauth';"
```

**Security Guarantee:**
- ✅ Values encrypted at rest in PostgreSQL
- ✅ Encryption key: `ENCRYPTION_KEY` from `/home/lewis/docker-compose.yml`
- ✅ Only Windmill workers with matching key can decrypt
- ✅ Resource ID: `u/admin/fatsecret_oauth` (readable path for scripts)
- ✅ All scripts reference: `$res:u/admin/fatsecret_oauth`

### Step 5: Verify Connection

```bash
wmill script run f/fatsecret/get_profile -d '{
  "fatsecret": "$res:u/admin/fatsecret_oauth",
  "oauth_token": "ACCESS_TOKEN_HERE",
  "oauth_token_secret": "ACCESS_TOKEN_SECRET_HERE"
}' 2>&1 | tail -15
```

**Success = User profile data appears**

### Reference: Where Everything Lives

| Item | Location | Secure? | Access |
|------|----------|---------|--------|
| Consumer Key/Secret | **Windmill Resource** `u/admin/fatsecret_api` | ✅ Encrypted at rest | `$res:u/admin/fatsecret_api` |
| OAuth Access Tokens | **Windmill Resource** `u/admin/fatsecret_oauth` | ✅ Encrypted at rest | `$res:u/admin/fatsecret_oauth` |
| Windmill DB | PostgreSQL `windmill` database → `resource` table | ✅ AES-256 encrypted | `docker exec lewis-db-1 psql` |
| Encryption Key | `/home/lewis/docker-compose.yml` → `ENCRYPTION_KEY` env var | ⚠️ CRITICAL | Must match in workers |
| Pass Store | `pass show meal-planner/fatsecret/{consumer_key,consumer_secret,oauth_encryption_key}` | ✅ GPG Encrypted | Local only |

### Using Tokens in Scripts

**All FatSecret scripts use the resource path syntax:**

```bash
# In wmill script calls:
wmill script run f/fatsecret/get_profile -d '{
  "fatsecret": "$res:u/admin/fatsecret_oauth"
}'

# In flow inputs:
input_transforms:
  fatsecret:
    type: static
    value: '$res:u/admin/fatsecret_oauth'
```

**NO hardcoding of tokens in code. ALWAYS use `$res:u/admin/fatsecret_oauth`.**

## Overview

The meal-planner project uses **Beads** (bd) for issue tracking, dependency management, and agent coordination. All work must go through Beads to ensure proper tracking and visibility.

## Documentation Retrieval (Token-Efficient)

**204 docs, 1532 chunks** indexed at `docs/_indexed/`. Optimized for minimal token usage.

### Retrieval Priority (use in order)

1. **CodeAnna semantic search** (best for natural language queries)
   ```
   # Via MCP tool: semantic_search_docs
   Query: "how to create windmill flow with approval"
   ```

2. **QUICKREF.md** (~400 tokens) - category overview, direct paths
   ```
   docs/_indexed/QUICKREF.md
   ```

3. **Targeted chunks** (~170 tokens each) - specific sections
   ```bash
   # Find chunks by topic
   ls docs/_indexed/chunks/*oauth*
   ls docs/_indexed/chunks/*flow-approval*
   ```

4. **Full docs** (~1300 tokens avg) - only when needed
   ```
   docs/_indexed/docs/{category}-{topic}-{slug}.md
   ```

### DO NOT LOAD (too expensive)

| File | Tokens | Why |
|------|--------|-----|
| `INDEX.json` | ~110,000 | Use CodeAnna search instead |
| `COMPASS.md` | ~8,000 | Use QUICKREF.md instead |

### Category Prefixes

| Prefix | Use For |
|--------|---------|
| `tutorial-*` | Step-by-step guides |
| `concept-*` | Understanding features |
| `ref-*` | API/config reference |
| `ops-*` | Install/deploy/troubleshoot |
| `meta-*` | Index files, overviews |

### Common Lookups (Direct Paths)

| Need | Path |
|------|------|
| Rust SDK patterns | `docs/_indexed/docs/ref-core_concepts-rust-sdk-winmill-patterns.md` |
| Flow approval | `docs/_indexed/docs/concept-flows-11-flow-approval.md` |
| Scheduling | `docs/_indexed/docs/meta-1_scheduling-index.md` |
| Error handling | `docs/_indexed/docs/meta-10_error_handling-index.md` |
| Tandoor setup | `docs/_indexed/docs/ops-install-docker.md` |

### CodeAnna MCP Tools

CodeAnna indexes both code AND docs. Use these MCP tools:

| Tool | Use For |
|------|---------|
| `semantic_search_docs` | Natural language doc search |
| `find_symbol` | Find code definitions |
| `get_calls` | What a function calls |
| `find_callers` | Who calls a function |
| `analyze_impact` | Change impact analysis |

**Example workflow:**
1. `semantic_search_docs("windmill flow error handler")` → finds relevant chunks
2. Read the specific chunk returned
3. If need more context, read the full doc

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

This project uses **Windmill** for workflow orchestration. Scripts are Rust, flows coordinate them.

### Key Documentation

| Doc | Purpose |
|-----|---------|
| **[Development Guide](docs/windmill/DEVELOPMENT_GUIDE.md)** | Scripts, CLI, resources, Rust patterns |
| **[Flows Guide](docs/windmill/FLOWS_GUIDE.md)** | Creating flows, approval/prompt patterns, OAuth |
| **[Rust Quickstart](docs/windmill/getting_started/0_scripts_quickstart/9_rust_quickstart/index.mdx)** | Rust script basics |

### Quick Commands

```bash
# Scripts
wmill script run f/fatsecret/oauth_start -d '{"fatsecret": "$res:u/admin/fatsecret_api", "callback_url": "oob"}'
wmill sync push --yes

# Flows (use directory path, not file)
wmill flow push f/fatsecret/oauth_setup.flow f/fatsecret/oauth_setup
wmill flow run f/fatsecret/oauth_setup -d '{}'
```

### File Structure

```
windmill/
├── wmill.yaml
├── f/<domain>/
│   ├── script.rs                 # Rust script
│   ├── script.script.yaml        # Script metadata
│   └── flow_name.flow/
│       └── flow.yaml             # Flow definition
└── u/admin/
    └── resource.resource.yaml    # Resources
```

### Gotchas

- **Flow push**: Use `.flow` directory, not `flow.yaml` file (causes ENOTDIR error)
- **Prompt UI**: Requires TypeScript/Python for `getResumeUrls()` - not in Rust SDK
- **Suspended flows**: CLI hangs - use Windmill UI or async API calls

## Moon Build System

This project uses **Moon** for task orchestration. Moon caches task outputs for speed - repeated runs skip unchanged work.

### ABSOLUTE RULE: Always Use Moon

**NEVER run individual cargo/rustc commands directly. ALL builds, tests, and CI tasks MUST go through Moon.**

This is non-negotiable:
- `moon run :build` - NOT `cargo build --release`
- `moon run :test` - NOT `cargo test`
- `moon run :ci` - NOT individual lint/test/build commands

Moon parallelizes everything and caches results. Direct commands bypass this and are slower.

### Common Commands

```bash
moon run :ci      # Full CI pipeline (lint, test, build)
moon run :quick   # Fast lint checks only
moon run :deploy  # CI + Windmill push
moon run :build   # Build release binaries (parallelized, cached)
moon run :test    # Run tests
```

### Why Moon?

- **Caching**: Tasks are cached based on inputs - if nothing changed, it skips
- **Parallelization**: Independent tasks run in parallel automatically
- **Consistency**: Same commands work locally and in CI
- **Dependency tracking**: Moon knows task dependencies and runs them in order

### Configuration

Moon config lives in:
- `.moon/workspace.yml` - Workspace settings
- `.moon/toolchain.yml` - Tool versions (Rust, etc.)
- `moon.yml` - Project-level task definitions

## Resources

- [Beads Documentation](https://github.com/steveyegge/beads)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Windmill Documentation](https://www.windmill.dev/docs)
- [Moon Documentation](https://moonrepo.dev/docs)

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed):
   ```bash
   moon run :ci      # Full CI pipeline (lint, test, build)
   # Or for quick validation:
   moon run :quick   # Fast lint checks only
   ```
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   jj git fetch --all-remotes
   bd sync
   jj git push
   jj log -r @       # Verify push succeeded
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
