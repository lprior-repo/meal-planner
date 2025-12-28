# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Knowledge Base

This project has indexed documentation in the Graphiti knowledge graph. Search before implementing:

```bash
# Search Windmill documentation
graphiti_search_memory_facts(query="windmill retries error handling", group_ids=["windmill-docs"])

# Get indexed episodes
graphiti_get_episodes(group_ids=["windmill-docs"])
```

**Indexed Documentation:**
- `docs/windmill/INDEXED_KNOWLEDGE.json` - RAG chunks with embedding text
- Graphiti group `windmill-docs` - 23 feature episodes + 5 relationship episodes

**What's indexed:**
- Windmill Flow Features: Retries, Error Handler, Branches, For Loops, Early Stop, Sleep, Priority, Lifetime, Step Mocking, Custom Timeout
- Windmill Core Concepts: Caching, Concurrency Limits, Job Debouncing, Staging/Prod, Multiplayer
- Windmill CLI: Installation, Scripts, Flows, Resources, Variables, Workspace Management
- Windmill Python Client: SDK functions, S3 integration

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

