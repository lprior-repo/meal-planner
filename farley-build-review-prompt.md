# Meal Planner: Farley Build and Review Loop

You are now operating under the **coding-rigor** skill, which enforces Dave Farley's Modern Software Engineering principles:
- **TDD-first development**: Write tests before code
- **Tiny iterations**: Small, incremental changes
- **Clean boundaries**: Clear separation of concerns
- **Functional core / imperative shell**: Business logic pure, I/O at edges
- **Contracts**: Validate inputs/outputs rigorously

## Your Mission

Run continuously until:
1. **All Beads issues are resolved** - No open issues remain
2. **All Rust code is idiomatic** - Follows Rust best practices, patterns, and conventions
3. **Dave Farley would be proud** - Clean architecture, testable code, simple design

## Loop Protocol

```
WHILE beads_remain OR code_needs_improvement:
    1. Invoke coding-rigor skill
    2. Pick ONE issue or code improvement
    3. Apply TDD: Test first, then implement
    4. Run: moon run :ci
    5. Fix any failures immediately
    6. Verify idiomatic Rust (clippy, mdbc, fmt)
    7. Update beads status
    8. Commit with jj
END WHILE
```

## Idiomatic Rust Checklist

- [ ] No `unwrap()` in production code (use `?`, ` anyhow`, or proper error handling)
- [ ] Proper error types with `thiserror` or `anyhow`
- [ ] Tests use `tempfile`, `test_helpers`
- [ ] Public APIs have doc comments
- [ ] `#[warn(clippy::default_construct_unit)]` - no `..Default::default()`
- [ ] No commented-out code
- [ ] Clear function names, single responsibility
- [ ] Small functions (< 50 lines ideal)
- [ ] No magic numbers or strings (use constants)
- [ ] Proper use of `&str` vs `String`, `&[T]` vs `Vec<T>`

## Beads Workflow

```bash
bd list              # See all open issues
bd claim <id>        # Start working on issue
# ... make changes ...
bd resolve <id>      # Mark as resolved
jj describe -m "type: description"
jj new
```

## Quality Gates

**Every iteration must pass:**
```bash
moon run :ci         # lint + test + build
```

**If CI fails:**
- Fix the failure immediately
- Do not skip, workaround, or defer
- Investigate root cause
- Apply fix at the source

## When Stuck

1. Re-read the problem statement
2. Break into smaller steps
3. Write a failing test first
4. Make it pass with minimal code
5. Refactor for clarity
6. Repeat

## Success Criteria

- `jj git push` succeeds
- `bd list` shows zero open issues
- `moon run :ci` passes with zero warnings
- All tests pass
- Code follows Rust idioms and project conventions

## Start Now

Begin by checking bead status and picking the highest priority item. Apply coding-rigor principles rigorously. Do not stop until complete.
