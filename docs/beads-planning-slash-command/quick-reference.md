# Quick Reference

Cheat sheet for daily TDD/TCR development with Beads.

## HUD Template

```
[TASK: bd-xxxx] ── [ROLE: {ARCHITECT|TESTER|CODER|REFACTORER}]
├── LOCKS: {files being edited}
├── CYCLE: {Red|Green|Blue|Reverted}
├── SWARM: [Spec: {status}] -> [Test: {status}] -> [Impl: {status}]
└── COMPLIANCE: [Gleam_Rules: {status}]
```

## Beads Commands

| Action | Command |
|--------|---------|
| Find work | `mcp__beads__ready` |
| View task | `mcp__beads__show {id}` |
| Start task | `mcp__beads__update {id} --status in_progress` |
| Block task | `mcp__beads__update {id} --status blocked` |
| Close task | `mcp__beads__close {id} --reason "..."` |
| Create sub-task | `mcp__beads__create --deps {parent_id}` |
| Sync with git | `bd sync` |

## Serena Commands

| Phase | Tool | Purpose |
|-------|------|---------|
| ARCHITECT | `get_symbols_overview` | Understand module structure |
| TESTER | `find_symbol` | Locate test insertion point |
| CODER | `insert_after_symbol` | Add new code |
| CODER | `replace_symbol_body` | Update existing code |
| REFACTORER | `find_referencing_symbols` | Impact analysis |

## TCR Flow

```
Write Test → Run Test → FAIL?
                          │
                          ├── NO (unexpected pass) → STOP, investigate
                          │
                          └── YES (expected) → Write Code → Run Test
                                                              │
                              ┌────────────────────────────────┴─────────┐
                              │                                          │
                            PASS                                       FAIL
                              │                                          │
                              ▼                                          ▼
                         git commit                              git reset --hard
                              │                                          │
                              ▼                                          │
                          REFACTOR                                       │
                              │                                          │
                              ▼                                          │
                         git commit ←────────── try different strategy ──┘
```

## Gleam 7 Commandments

1. **IMMUTABILITY** - No `var`, use recursion/folding
2. **NO NULLS** - `Option(T)` or `Result(T, E)`
3. **PIPE EVERYTHING** - `|>` for data transformation
4. **EXHAUSTIVE MATCHING** - All cases covered
5. **LABELED ARGUMENTS** - For >2 params
6. **TYPE SAFETY** - Custom types, no `dynamic`
7. **FORMAT OR DEATH** - `gleam format --check`

## Common Patterns

### Result Chaining
```gleam
value
|> validate_input
|> result.try(transform)
|> result.map(finalize)
```

### Option Handling
```gleam
case optional_value {
  Some(value) -> use_value(value)
  None -> default_behavior()
}
```

### Use Expression
```gleam
use file <- result.try(open_file(path))
use content <- result.try(read_content(file))
Ok(parse(content))
```

## Memory Triggers

**Save When**:
- Learning a user preference
- Making architectural decision
- Solving a non-trivial bug
- Discovering a useful pattern

**Search When**:
- Starting a new task
- Hitting an impasse
- Making a design decision
- Encountering familiar error

## Emergency Commands

| Situation | Command |
|-----------|---------|
| Tests failing | `git reset --hard HEAD` |
| Format broken | `gleam format` |
| Build broken | `gleam build` |
| Full reset | `git clean -fd && gleam build` |
