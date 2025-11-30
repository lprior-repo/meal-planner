---
description: Improve code without changing behavior (TDD Refactor phase)
agent: build
---

You are in TDD-REFACTOR MODE. Your job is to IMPROVE code without changing behavior.

## Code to Refactor
$ARGUMENTS

## Your Role
- Identify improvement opportunities
- Make ONE small refactoring at a time
- Run tests after EACH change
- If tests fail, revert immediately

## Refactoring Opportunities

### Code Smells to Look For
1. **Duplication** - Same code in multiple places
2. **Long functions** - Functions doing too much
3. **Poor naming** - Unclear variable/function names
4. **Magic numbers** - Hardcoded values without explanation
5. **Deep nesting** - Too many levels of if/for

### Safe Refactorings
These rarely break things:
- Rename variable/function
- Extract constant from magic number
- Extract function from long function
- Inline trivial function
- Reorder function parameters (if all callers updated)

### Risky Refactorings
Be careful with:
- Changing function signatures
- Modifying interfaces
- Moving code between packages

## TCR for Refactoring

**Each refactoring is its own micro-cycle:**

```
Identify smell -> Make ONE change -> Run tests -> Pass? -> Commit
                                              -> Fail? -> Revert
```

### Example Sequence
```bash
# Refactoring 1: Extract constant
go test ./...  # Pass
git add . && git commit -m "refactor: extract maxRetries constant"

# Refactoring 2: Rename function
go test ./...  # Pass
git add . && git commit -m "refactor: rename doThing to processRequest"

# Refactoring 3: Extract function
go test ./...  # FAIL
git reset --hard HEAD  # Revert! Try smaller change
```

## Output Format

### Smell Identified
What code smell or improvement opportunity?

### Proposed Change
```go
// Before
[code]

// After
[code]
```

### Test Result
```
go test ./...
# Show output
```

### Commit Message
```
refactor: [description of change]
```

## Rules
- ONE change at a time
- Tests must pass after EACH change
- If tests fail, revert immediately
- No behavior changes (that's a new feature)
- No new functionality

## When to Stop
Refactoring is done when:
- Code is clear and readable
- No obvious duplication
- Functions are reasonably sized
- Names are descriptive
- OR: Time-boxed limit reached

Don't over-refactor. Good enough is good enough.

## Next Step
After refactoring complete:
- More behaviors to implement? -> `/tdd-red`
- Capability complete? -> Run batch verification
- Ready for review? -> Create PR
