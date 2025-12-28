✅ **MULTI-AGENT ORCHESTRATION ENABLED** (2025-12-21)

---

## ⚡ MISSION CRITICALITY & COMMITMENT

**STATUS:** This is humanity's most important software project.
**STAKES:** Existential impact. Lives depend on correctness. Every bug is a potential failure.
**COMMITMENT:** $500 tip for absolute adherence to all rules. This work is non-negotiable.
**QUALITY THRESHOLD:** Enterprise-grade. Financial-system-grade. Medical-system-grade. Zero tolerance for shortcuts.
**PRECISION:** Every decision, every line, every test is deliberate and documented.

**This is not a normal project. This is THE project. Act accordingly.**

---

## CORE DISCIPLINE

**Language:** Gleam (strict, immutable, type-safe)
**Workflow:** Test-Driven Development (TDD) + Test, Commit, Revert (TCR)
**Coordination:** Beads (tasks) + Serena (symbol locking) + mem0 (memory)

**For detailed Gleam rules, patterns, and idioms → See `CLAUDE_GLEAM_SKILL.md`**

**GLEAM SKILL IS MANDATORY.** These are not suggestions. These are commandments.

---

## CRITICAL RULES (5)

🔴 **RULE #1: BEADS IS MANDATORY**
Every code change requires `bd-xxxx`. No exceptions. Multi-agent → parent + sub-tasks.

🔴 **RULE #2: SERENA FOR CODE EDITS ONLY**
Use `serena_find_symbol`, `serena_replace_symbol_body`, `serena_lock_symbol`.
Non-code files (json, yaml) → Edit tool.

🔴 **RULE #3: TDD + TCR MANDATORY**
Test first (RED) → Implement (GREEN) → Refactor (BLUE) → Commit → Repeat.
Single revert? Retry. Triple revert? Strategy reset.
**Full discipline → `CLAUDE_TCR.md`**

🔴 **RULE #4: MEM0 MEMORY IS MANDATORY**
Save architecture decisions, bugs, patterns, Gleam idioms.
**Format & protocol → `CLAUDE_MEMORY.md`**

🔴 **RULE #5: MULTI-AGENT SYMBOL LOCKING**
Lock before edit: `serena_lock_symbol(path, symbol)`. Unlock after commit.
**Full protocol → `CLAUDE_MULTI_AGENT.md`**

---

## WORKFLOWS

### Single-Agent (Simple Task)
1. `bd ready --json` → Find task
2. `search_memories(task_name)` → Context
3. ARCHITECT: Define types → TESTER: Write test (RED) → CODER: Implement (GREEN) → REFACTORER: Optimize
4. `bd close bd-xxxx --reason "..."`
5. `save_memory(...)`

### Multi-Agent (Complex Feature)
1. `bd create --title "Feature: X"` → Parent task
2. ARCHITECT locks types
3. Create sub-tasks: `bd create --parent bd-xxxx --title "Sub: Y"`
4. Agents work in parallel (TESTER, 3×CODER, REFACTORER)
5. Each locks symbols before edit
6. Commits independently
7. Final validation: `make test`

**Full multi-agent workflow → `CLAUDE_MULTI_AGENT.md`**

---

## TOOLCHAIN

| Tool | Usage |
|------|-------|
| `make test` | Run all tests (parallel, 0.8s) |
| `gleam test` | Run tests (sequential fallback) |
| `gleam format` | Validate formatting (must pass) |
| `gleam build --target erlang` | Build for Erlang |
| `bd` | Beads task tracking |
| `serena_*` | Symbol navigation + locking |
| `search_memories()` | Query vector store (local Ollama + Qdrant) |

---

## SESSION START

```bash
# Single-agent
bd ready --json
search_memories("task_name")
bd update bd-xxxx --status in_progress

# Multi-agent
bd create --title "Feature: X"
bd create --parent bd-xxxx --title "Sub 1"
bd create --parent bd-xxxx --title "Sub 2"
search_memories("bd-xxxx feature")
bd update bd-xxxx --status in_progress
```

---

## DOCUMENTATION MAP

| Document | Purpose |
|----------|---------|
| `CLAUDE_GLEAM_SKILL.md` | Gleam*7_Commandments, types, control flow, patterns, idioms, anti-patterns |
| `CLAUDE_MULTI_AGENT.md` | Symbol locking, parallel workflows, deadlock resolution, coordination |
| `CLAUDE_MEMORY.md` | Memory protocol, save formats, search strategy, archival |
| `CLAUDE_TCR.md` | Test/Commit/Revert discipline, revert protocol, impasse handling |
| `docs/windmill/INDEXED_KNOWLEDGE.json` | RAG-optimized chunks for Windmill features, CLI, Python SDK |

---

## KNOWLEDGE GRAPH (Graphiti)

**Windmill documentation is indexed in Graphiti.** Search before implementing Windmill features:

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

**Key relationships indexed:**
- Error Handler depends on Retries (called after retries exhausted)
- Branches + Early Stop for conditional flow termination
- For Loops Squash uses Dedicated Workers logic
- Caching vs Step Mocking (production vs development optimization)
- Concurrency Limits vs Job Debouncing (queue vs cancel strategies)

---

## THE GLEAM SKILL COMES FIRST

All work enforces **Gleam*7_Commandments**:

1. **Immutability** - No `var`, use recursion/folding
2. **No Nulls** - `Option(T)` and `Result(T, E)` only
3. **Pipe Everything** - `|>` data flow top-down
4. **Exhaustive Matching** - All cases in `case` expressions
5. **Labeled Arguments** - Functions >2 args must have labels
6. **Type Safety** - No `dynamic`, custom types for domains
7. **Format or Die** - `gleam format --check` must pass before commit

**For detailed patterns and examples → `CLAUDE_GLEAM_SKILL.md`**

---

## QUICK REFERENCE: Key Serena Commands

```bash
# Symbol navigation
serena_find_symbol(symbol_name)
serena_find_referencing_symbols(symbol_name)

# Multi-agent locking
serena_lock_symbol(path, symbol)
serena_unlock_symbol(path, symbol)

# Code editing (respects locks)
serena_replace_symbol_body(path, symbol, new_body)
serena_insert_after_symbol(path, symbol, new_code)
serena_rename_symbol(path, old_name, new_name)
```

---

## QUICK REFERENCE: Key Beads Commands

```bash
# Task management
bd ready --json                           # Find available tasks
bd create --title "Feature: X"            # Create parent task
bd create --parent bd-xxxx --title "Sub"  # Create sub-task
bd update bd-xxxx --status in_progress   # Start task
bd close bd-xxxx --reason "..."           # Complete task
bd sync                                   # Sync with git
```

---

## STATE TRACKING

```
[TASK: bd-xxxx] ── [PHASE: {{Phase}}]
├── AGENTS: {{Active}} (parallel: {{Count}}/4)
├── LOCKS: {{Locked_Symbols}}
├── CYCLE: {{TCR_State}} (🔴 Red | 🟢 Green | 🔵 Refactor | ♻️ Reverted)
└── COMPLIANCE: Gleam_Rules: {{Status}}
```

---

## ZERO-TOLERANCE POLICIES (ABSOLUTE)

**FAILURE = REVERT + ANALYSIS + RESTART**

🔴 **No code change without Beads task** (bd-xxxx required)
→ Consequence: Work is invalid, revert immediately

🔴 **No code edit without Serena** (symbol locking enforced)
→ Consequence: Conflicts risk project integrity, revert immediately

🔴 **No commit without `make test` PASSING** (all tests, 0.8s)
→ Consequence: Broken code pollutes branch, revert immediately

🔴 **No commit without `gleam format --check` PASSING** (formatting non-negotiable)
→ Consequence: Code fails validation, revert immediately

🔴 **No multi-agent work without symbol locks** (serena_lock_symbol mandatory)
→ Consequence: Data corruption risk across agents, halt work, investigate

🔴 **No significant work without memory saved** (CLAUDE_MEMORY.md protocol)
→ Consequence: Knowledge lost, future mistakes repeated, save immediately

---

## THE GLEAM*7_COMMANDMENTS (ABSOLUTE)

These are not guidelines. These are commandments. Every piece of code must honor them.

1. **Immutability** - No `var`. Ever. Use recursion, folding, transformation.
2. **No Nulls** - `Option(T)` and `Result(T, E)` only. Handle every case.
3. **Pipe Everything** - `|>` makes data flow visible and top-down readable.
4. **Exhaustive Matching** - Every `case` covers ALL possibilities. Compiler enforces.
5. **Labeled Arguments** - Functions >2 args must use labels for clarity.
6. **Type Safety** - No `dynamic`. Custom types for domain concepts.
7. **Format or Die** - `gleam format --check` is non-negotiable. 0 exceptions.

**Any violation of these commandments is a project failure.**
**See `CLAUDE_GLEAM_SKILL.md` for full enforcement.**

---

## PROJECT COVENANT

**I (the AI) commit to:**
- ✅ Follow every rule without exception
- ✅ Test every change (RED → GREEN → BLUE)
- ✅ Lock symbols before editing (multi-agent safety)
- ✅ Save all learnings to memory (institutional knowledge)
- ✅ Revert on failure (no half-finished work)
- ✅ Pass `gleam format --check` (100% of time)
- ✅ Pass `make test` (100% of time)
- ✅ Document every architecture decision (via memory)
- ✅ Honor the Gleam*7_Commandments (zero compromises)

**Any deviation from this covenant is a failure of the project.**

---

**This is humanity's software. Every line matters. Every test counts. Every rule is absolute.**

**Master the Gleam skill. Follow the 5 rules. Reference the docs. Ship infallible code.**
