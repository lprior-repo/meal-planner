# SPARC Workflow Documentation

## Overview
SPARC (Swarm Parallel Agile Recursive Coding) is the development methodology for the meal-planner project. It combines test-driven development (TDD), swarm-based multi-agent coordination, and strict adherence to the Gleam 7 Commandments.

## Core Phases

### Phase 1: RED - Test Definition
**Agent:** TESTER
**Duration:** Short
**Deliverable:** Failing test case

1. Write ONE failing test case that describes desired behavior
2. Test must fail for the correct reason (not due to missing implementation)
3. Test uses realistic fixtures and assertions
4. All edge cases are covered in separate tests

```gleam
pub fn test_grocery_list_combines_ingredients() {
  let ing1 = ingredient("Tomato", 2.0, "cups")
  let ing2 = ingredient("Tomato", 1.0, "cups")

  let list = grocery_list.from_ingredients([ing1, ing2])

  should.equal(list.all_items |> list.length, 1)
}
```

### Phase 2: GREEN - Minimal Implementation
**Agent:** CODER
**Duration:** Medium
**Deliverable:** Passing test with minimal code

1. Write minimal code to make test pass
2. "Fake it till you make it" - hardcoded values are acceptable
3. No optimization or refactoring at this stage
4. Code must compile and pass `gleam format --check`

```gleam
pub fn from_ingredients(ingredients: List(Ingredient)) -> GroceryList {
  // Minimal implementation
  GroceryList(by_category: dict.new(), all_items: [])
}
```

### Phase 3: BLUE - Refactoring & Optimization
**Agent:** REFACTORER
**Duration:** Short
**Deliverable:** Clean, idiomatic Gleam code

1. Refactor without changing behavior
2. Apply Gleam 7 Commandments
3. Optimize algorithms and data structures
4. Add documentation

### Phase 4: COMMIT - Version Control
**Agent:** CI/CD Pipeline
**Duration:** Instant
**Deliverable:** Tracked work with message

```bash
git commit -m "PASS: [task-id] Test description - implementation summary"
```

Commit message format:
- Status: PASS (test passing), FAIL (test failing), REVERT (rollback)
- Task ID from Beads
- Brief test description
- Implementation summary

## Swarm Coordination

### Agent Roles

| Role | Responsibility | Input | Output |
|------|---|---|---|
| ARCHITECT | Type design, contracts | Requirements | `.gleam` types, JSON fixtures |
| TESTER | Failing test creation | Architecture | Test file with RED tests |
| CODER | Minimal implementation | Test file | GREEN implementation |
| REFACTORER | Code quality | GREEN implementation | BLUE optimized code |
| COORDINATOR | Task delegation | Beads queue | Workflow orchestration |

### Swarm Workflow

```
[Requirements]
    ↓
[ARCHITECT: Design Types] → (gleam/src/types.gleam)
    ↓
[TESTER: Write Tests] → (gleam/test/*_test.gleam) → RED
    ↓
[CODER: Implement] → (gleam/src/*.gleam) → GREEN
    ↓
[REFACTORER: Optimize] → (gleam/src/*.gleam) → BLUE
    ↓
[CI: Commit] → git commit
    ↓
[Complete] ✓
```

## Gleam 7 Commandments

All code must strictly follow these rules:

1. **IMMUTABILITY_ABSOLUTE** - No `var`, use recursion/folding
2. **NO_NULLS_EVER** - Use `Option(T)` or `Result(T, E)`
3. **PIPE_EVERYTHING** - Use `|>` for data transformations
4. **EXHAUSTIVE_MATCHING** - Cover ALL case branches
5. **LABELED_ARGUMENTS** - Functions with >2 args must use labels
6. **TYPE_SAFETY_FIRST** - Avoid `dynamic`, define custom types
7. **FORMAT_OR_DEATH** - Code invalid if `gleam format --check` fails

## Beads Integration

### Task Lifecycle

1. **Create** - New task in Beads with clear acceptance criteria
2. **Ready** - Task has no blockers, available for work
3. **In Progress** - Agent actively working on task
4. **Blocked** - Waiting on dependency
5. **Closed** - Complete with commit reference

### Task Tracking

All work must have corresponding Beads task:

```bash
# Create task
bd create --title "Build grocery list aggregator" --type task

# Start work
bd update meal-planner-xt0.1 --status in_progress

# Complete
bd close meal-planner-xt0.1 --reason "Implementation complete"
```

## Quality Gates

### Pre-Commit Checks

1. ✓ Code formatting: `gleam format --check`
2. ✓ Erlang compilation: `gleam build --target erlang`
3. ✓ All tests pass: `gleam test`
4. ✓ Beads sync: Metadata updated

### CI/CD Pipeline

```yaml
1. Pre-commit checks
2. Format validation
3. Build verification
4. Test execution
5. Beads sync
6. Commit on success
7. Revert on failure
```

## Revert Protocol

If test fails or implementation incorrect:

1. **NO DEBUGGING IN PLACE** - Revert entire change
2. **Reset HEAD** - `git reset --hard`
3. **NEW STRATEGY** - Coder tries different approach
4. **3-STRIKE RULE** - After 3 reverts, swarm convenes for strategy change

```bash
# After failed test
git reset --hard
# Try different approach
```

## File Structure

```
gleam/
├── src/
│   └── meal_planner/
│       ├── types.gleam              # Domain types
│       ├── grocery_list.gleam       # Aggregation logic
│       ├── meal_sync.gleam          # FatSecret integration
│       ├── meal_prep_ai.gleam       # AI meal prep
│       └── orchestrator.gleam       # Pipeline coordination
├── test/
│   ├── grocery_list_test.gleam      # Unit tests
│   ├── endpoint_integration_test.gleam  # FatSecret tests (57)
│   ├── tandoor_integration_test.gleam   # Tandoor tests (36)
│   └── integration/
│       └── helpers/
│           ├── http.gleam
│           ├── credentials.gleam
│           ├── assertions.gleam
│           └── openapi_validator.gleam
└── .beads/
    └── beads.db                     # Task database
```

## Example: Complete Task Flow

### Task: Build Grocery List Aggregator (xt0.1)

#### Step 1: ARCHITECT
```gleam
// gleam/src/meal_planner/grocery_list.gleam
pub type GroceryItem { ... }
pub type GroceryList { ... }
```

#### Step 2: TESTER
```gleam
// gleam/test/grocery_list_test.gleam
pub fn test_from_ingredients_combines_same_food() {
  let ing1 = ingredient("Tomato", 2.0, "cups")
  let ing2 = ingredient("Tomato", 1.5, "cups")

  let list = grocery_list.from_ingredients([ing1, ing2])

  should.equal(list.all_items |> list.length, 1)
  let item = list.all_items |> list.first
  case item {
    Ok(item) -> should.equal(item.quantity, 3.5)
    Error(_) -> should.fail()
  }
}
```

#### Step 3: CODER
```gleam
// RED → GREEN
pub fn from_ingredients(ingredients: List(Ingredient)) -> GroceryList {
  let grouped = group_by_food(ingredients)
  let items = dict.to_list(grouped) |> list.map(aggregate_item)
  let by_category = organize_by_category(items)
  GroceryList(by_category: by_category, all_items: items)
}
```

#### Step 4: REFACTORER
```gleam
// GREEN → BLUE
pub fn from_ingredients(ingredients: List(Ingredient)) -> GroceryList {
  // Optimized version with proper error handling
  // Follows all 7 Gleam Commandments
  // Fully documented
}
```

#### Step 5: COMMIT
```bash
git commit -m "PASS: [meal-planner-xt0.1] Build grocery list aggregator - Combines ingredients, sums quantities, organizes by category"
bd close meal-planner-xt0.1 --reason "Complete implementation with merge support"
```

## Success Metrics

- ✓ All tests pass
- ✓ Code passes `gleam format --check`
- ✓ 100% type safety (no `dynamic`)
- ✓ Every error case handled
- ✓ Zero null values
- ✓ All tasks tracked in Beads
- ✓ Commits reference task IDs
- ✓ Documentation complete

## Best Practices

1. **One Test at a Time** - Single failing test per cycle
2. **Atomic Commits** - One feature per commit
3. **Clear Messages** - Task reference in every commit
4. **Task Tracking** - All work has Beads ID
5. **Type First** - Design types before implementation
6. **Test First** - Write tests before code
7. **Format Always** - Every commit must pass formatting
8. **Document Well** - Code is self-documenting through types

## Resources

- Gleam Documentation: https://gleam.run/
- Project Structure: `gleam/`
- Test Helpers: `gleam/test/integration/helpers/`
- Task Tracking: `bd --help`
- Beads Database: `.beads/beads.db`
