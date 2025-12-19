# Memory Integration - Quick Reference

## TL;DR

**Before starting task**: Search memories for context
**After completing task**: Save learnings if they match any trigger

---

## Quick Decision Tree

### Should I Save a Memory?

```
Did task involve:
├─ Architecture decision?       → YES, save as Schema 1
├─ Bug fix with root cause?     → YES, save as Schema 2
├─ Code consolidation (>50 LOC)? → YES, save as Schema 3
├─ Reusable test pattern?       → YES, save as Schema 4
└─ Gleam idiom learned?         → YES, save as Schema 5

Otherwise → NO, don't save
```

---

## 5 Memory Schemas

### 1. Architecture Decision
```
meal-planner: [Component] uses [Pattern] instead of [Alternative] - rationale: [Why]
```

### 2. Bug Fix
```
meal-planner: [Component] bug - cause: [Root cause], fix: [Solution], impact: [Scope]
```

### 3. Project Context
```
meal-planner: [Category] update - [What changed], [Why], [Files affected]
```

### 4. Test Pattern
```
meal-planner: test pattern - [Name], usage: [When to use], pattern: [Code snippet]
```

### 5. Gleam Idiom
```
meal-planner: gleam idiom - [Pattern name], do: [What to do], avoid: [What not to do]
```

---

## Common Search Queries

### By Component
```
search_memory_facts("tandoor handlers")
search_memory_facts("auth module")
search_memory_facts("query_builders")
search_memory_facts("scheduler")
```

### By Pattern
```
search_memory_facts("CrudHandler abstraction")
search_memory_facts("pagination logic")
search_memory_facts("session_config pattern")
```

### By Problem
```
search_memory_facts("pagination bug")
search_memory_facts("compilation error")
search_memory_facts("type error")
```

### By Test
```
search_memory_facts("test pattern")
search_memory_facts("HTTP mocking")
search_memory_facts("snapshot testing")
```

### By Idiom
```
search_memory_facts("gleam idiom")
search_memory_facts("result chaining")
search_memory_facts("pipe operator")
search_memory_facts("use expression")
```

### By Task
```
search_memory_facts("bd-xxx")
search_memory_facts("auth extraction")
search_memory_facts("encoder consolidation")
```

---

## Task Start Workflow

```bash
# 1. Get task
bd ready --json

# 2. Search memories
search_memory_facts("[task_keywords]")
search_memory_facts("[component_name]")

# 3. Start task
bd update bd-xxx --status in_progress

# 4. Code with context
```

---

## Task Completion Workflow

```bash
# 1. Review changes
git status
git diff --stat

# 2. Check memory triggers
# Architecture? Bug? Consolidation? Test? Idiom?

# 3. Save memory (if applicable)
save_memory("""
meal-planner: [formatted_entry]
""")

# 4. Close task
bd close bd-xxx --reason "description"

# 5. Commit + push
git add .
git commit -m "message"
git push
```

---

## MCP Tools Reference

### Save Memory
```
mcp__local-graph__add_memory(
  name: "title",
  episode_body: "content",
  source: "text"
)
```

### Search Memories
```
mcp__local-graph__search_memory_facts(
  query: "search terms",
  max_facts: 10
)
```

### Search Nodes
```
mcp__local-graph__search_nodes(
  query: "search terms",
  max_nodes: 10
)
```

### List Episodes
```
mcp__local-graph__get_episodes(
  max_episodes: 10
)
```

---

## Helper Scripts

### Search Wrapper
```bash
./scripts/memory-search "query"
./scripts/memory-search list
./scripts/memory-search stats
```

### BD Wrapper (with memory prompts)
```bash
./scripts/bd-with-memory update bd-xxx --status in_progress
./scripts/bd-with-memory close bd-xxx --reason "done"
```

---

## Good vs Bad Examples

### GOOD Memory
```
meal-planner: tandoor/handlers uses CrudHandler abstraction instead of inline handlers - rationale: reduces 2000+ lines duplication, consistent error handling, testable. Pattern: CrudHandler(config, list_fn, get_fn, create_fn, update_fn, delete_fn) with generic operations. Files: src/meal_planner/tandoor/crud_handler.gleam + 9 handlers. Benefits: DRY, single source of truth, easier testing. Related: bd-xxx
```

**Why good**: Specific, quantified, actionable, searchable

### BAD Memory
```
Refactored handlers
Made code better
Used abstractions
```

**Why bad**: Vague, no details, not searchable, not actionable

---

## DO NOT Save

- ❌ Trivial syntax fixes
- ❌ Obvious one-liners
- ❌ Things already in Beads task
- ❌ Generic knowledge
- ❌ Temporary debug notes

---

## File Locations

- **Specification**: `/home/lewis/src/meal-planner/MEMORY_INTEGRATION.md`
- **Examples**: `/home/lewis/src/meal-planner/MEMORY_EXAMPLES.md`
- **BD Wrapper**: `/home/lewis/src/meal-planner/scripts/bd-with-memory`
- **Search Tool**: `/home/lewis/src/meal-planner/scripts/memory-search`
- **This Reference**: `/home/lewis/src/meal-planner/MEMORY_QUICK_REFERENCE.md`

---

## Setup Requirements

1. **mem0 MCP Server**: Running locally (Ollama + Qdrant)
2. **OpenCode**: Configured with local-graph MCP
3. **Beads**: Initialized in project (`.beads/`)
4. **Scripts**: Executable (`chmod +x scripts/*`)

---

## Troubleshooting

### Memory search returns nothing
- Check mem0 MCP server is running
- Verify local-graph is initialized
- Try broader search terms

### Too many duplicate results
- Run consolidation (see MEMORY_INTEGRATION.md)
- Use more specific search terms

### Unclear what to save
- Review MEMORY_EXAMPLES.md for templates
- Use decision tree (top of this file)
- When in doubt, save (better than losing knowledge)

---

## Advanced Usage

### Consolidate Memories
```bash
# Find duplicates
search_memory_facts("pagination")

# Review results, create consolidated entry
save_memory("[consolidated_entry]")

# Archive old entries (keep for history)
```

### Memory Statistics
```bash
# Total memories
search_memory_facts("meal-planner") | wc -l

# By category
search_memory_facts("architecture") | wc -l
search_memory_facts("bug fix") | wc -l
```

### Bulk Export (future)
```bash
# Export all memories to markdown
mcp__local-graph__get_episodes(max_episodes: 1000) > memories.json
jq -r '.[] | "## \(.name)\n\n\(.body)\n"' memories.json > MEMORIES.md
```

---

## Cheat Sheet

| Action | Command |
|--------|---------|
| Search component | `search_memory_facts("component_name")` |
| Search pattern | `search_memory_facts("pattern_name")` |
| Search bug | `search_memory_facts("bug_keyword")` |
| Search test | `search_memory_facts("test pattern")` |
| Search idiom | `search_memory_facts("gleam idiom")` |
| Search task | `search_memory_facts("bd-xxx")` |
| Save memory | `save_memory("[entry]")` |
| List all | `get_episodes(max_episodes: 50)` |

---

## Integration Status

- ✅ Specification complete (MEMORY_INTEGRATION.md)
- ✅ Examples complete (MEMORY_EXAMPLES.md)
- ✅ Scripts created (bd-with-memory, memory-search)
- ✅ Quick reference complete (this file)
- ⏳ mem0 MCP server setup (pending)
- ⏳ OpenCode integration (pending)
- ⏳ Beads hooks automation (pending)

---

## Next Steps

1. **Setup mem0 MCP Server**
   - Install Ollama (local LLM)
   - Install Qdrant (vector DB)
   - Configure mem0 MCP in OpenCode

2. **Test Memory Operations**
   - Save 5 example memories (one per schema)
   - Test search queries
   - Validate retrieval

3. **Integrate with Workflow**
   - Use bd-with-memory wrapper
   - Search before starting tasks
   - Save after completing tasks

4. **Iterate and Refine**
   - Adjust search queries based on usage
   - Consolidate duplicate entries
   - Update schemas if needed

---

**Remember**: Memory system is about capturing WHY decisions were made, not just WHAT code was written. Focus on insights that will help future work.
