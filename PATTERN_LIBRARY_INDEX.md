# Pattern Library Index

**Project:** meal-planner
**Language:** Gleam
**Generated:** 2024-12-24
**Agent:** Agent-Mem-2 (38/96) - Pattern Library Creation

---

## Overview

This pattern library documents the refactoring strategies, error handling approaches, and module organization patterns discovered during the evolution of the meal-planner codebase from a monolithic structure to a modular, maintainable architecture.

The library consists of three interconnected documents:

1. **REFACTORING_PATTERNS.md** - Pattern theory and best practices
2. **REFACTORING_EXAMPLES.md** - Real code examples from this codebase
3. **PATTERN_LIBRARY_INDEX.md** - This index document

---

## Quick Start

### If you want to...

**Understand a specific pattern:**
→ Read [REFACTORING_PATTERNS.md](./REFACTORING_PATTERNS.md) - Section for that pattern

**See real code examples:**
→ Read [REFACTORING_EXAMPLES.md](./REFACTORING_EXAMPLES.md) - Examples section

**Refactor a large module:**
→ Read [3-Phase Refactoring Strategy](#3-phase-refactoring-strategy-guide)

**Prevent common mistakes:**
→ Read [Anti-Patterns to Avoid](#anti-patterns-quick-reference)

**Learn Gleam idioms:**
→ Read [Gleam-Specific Patterns](#gleam-specific-patterns)

---

## Pattern Categories

### 1. Structural Patterns
Patterns for organizing code into modules and hierarchies.

| Pattern | Use When | Benefits | Doc Reference |
|---------|----------|----------|---------------|
| **Module Split Strategy** | File >500 lines, mixed concerns | Single responsibility, parallel development | [Patterns #1](./REFACTORING_PATTERNS.md#1-module-split-strategy) |
| **mod.gleam Aggregator** | Creating public API for module hierarchy | Backward compatibility, clear entry point | [Patterns #9](./REFACTORING_PATTERNS.md#9-modgleam-aggregator-pattern) |
| **Decoder Separation** | Types mixed with JSON parsing | Independent evolution, easier testing | [Patterns #6](./REFACTORING_PATTERNS.md#6-decoder-module-separation) |

### 2. Type Safety Patterns
Patterns using Gleam's type system for compile-time safety.

| Pattern | Use When | Benefits | Doc Reference |
|---------|----------|----------|---------------|
| **Opaque Types for IDs** | Need to prevent ID type confusion | Compile-time safety, clear intent | [Patterns #2](./REFACTORING_PATTERNS.md#2-opaque-types-for-type-safety) |
| **Validation at Construction** | Need to guarantee data validity | Impossible invalid states, no runtime checks | [Patterns #7](./REFACTORING_PATTERNS.md#7-validation-at-construction) |

### 3. Control Flow Patterns
Patterns for managing complex operations and error handling.

| Pattern | Use When | Benefits | Doc Reference |
|---------|----------|----------|---------------|
| **Result Pipelines with 'use'** | Chaining Result operations | Flat control flow, early returns | [Patterns #4](./REFACTORING_PATTERNS.md#4-result-pipelines-with-use) |
| **Pipe-First Transformations** | Multi-step data transformations | Top-down readability, easy to modify | [Patterns #5](./REFACTORING_PATTERNS.md#5-pipe-first-data-transformations) |
| **Centralized Error Handling** | Duplicate error-to-response code | No duplication, consistent JSON | [Patterns #3](./REFACTORING_PATTERNS.md#3-centralized-error-handling) |

### 4. Process Patterns
Patterns for managing refactoring work.

| Pattern | Use When | Benefits | Doc Reference |
|---------|----------|----------|---------------|
| **3-Phase Refactoring** | Large-scale module refactoring | Working code at each phase, clear progress | [Patterns #8](./REFACTORING_PATTERNS.md#8-3-phase-refactoring-strategy) |

---

## 3-Phase Refactoring Strategy Guide

### When to Refactor
- Module exceeds 500 lines
- Mixed concerns (types + HTTP + business logic + handlers)
- Difficulty testing components in isolation
- Merge conflicts from multiple developers/agents

### Phase Breakdown

#### PHASE 1: Extract Domain Submodules
**Goal:** Split monolithic file into focused modules

**Checklist:**
- [ ] Create `types.gleam` (type definitions only)
- [ ] Create `decoders.gleam` (JSON parsing)
- [ ] Create `helpers.gleam` (utility functions)
- [ ] Create subdirectories for complex domains (e.g., `commands/`)
- [ ] Delete monolithic source file
- [ ] Update all imports in dependent files
- [ ] Run `gleam build` and fix compilation errors
- [ ] Run `make test` to ensure behavior unchanged

**Example:** [Diary refactoring (commit 6bd189f4)](./REFACTORING_EXAMPLES.md#6-phase-1-refactoring-cli-diary)

#### PHASE 2: Refactor API Handlers
**Goal:** Standardize handler structure and extract shared logic

**Checklist:**
- [ ] Split handlers into `handlers.gleam` per domain
- [ ] Extract `error_response` helpers
- [ ] Update handler tests
- [ ] Consolidate duplicate error handling using `shared/error_handlers.gleam`
- [ ] Run tests to verify behavior

**Example:** FatSecret handlers refactoring (commit 75ef8ffd)

#### PHASE 3: Create Client Aggregators
**Goal:** Provide clean public API with backward compatibility

**Checklist:**
- [ ] Create `mod.gleam` as public entry point
- [ ] Re-export commonly used types
- [ ] Add module documentation
- [ ] Update external imports to use mod
- [ ] Preserve backward compatibility where needed

**Example:** Tandoor client aggregator (commit 3d17ec6b)

### Success Metrics
- **Before:** Monolithic 500+ line files
- **After:** Focused <200 line modules
- **Build time:** Should remain similar or improve
- **Test coverage:** Should remain same or increase
- **Team velocity:** Multiple agents can work in parallel

---

## Anti-Patterns Quick Reference

| Anti-Pattern | Problem | Solution | Example |
|--------------|---------|----------|---------|
| **Deep Nesting** | Nested case expressions unreadable | Use `use` for early returns | [Patterns #10.1](./REFACTORING_PATTERNS.md#anti-pattern-1-deep-nesting) |
| **Mixed Concerns** | Single file contains everything | Apply Module Split Strategy | [Patterns #10.2](./REFACTORING_PATTERNS.md#anti-pattern-2-mixed-concerns-in-single-file) |
| **String-Based IDs** | Can mix IDs from different domains | Use Opaque Types | [Patterns #10.3](./REFACTORING_PATTERNS.md#anti-pattern-3-string-based-ids) |
| **Duplicate Error Handling** | Every handler duplicates error code | Centralized Error Handling | [Patterns #10.4](./REFACTORING_PATTERNS.md#anti-pattern-4-duplicate-error-handling) |
| **Validation After Construction** | Runtime checks for validity | Validation at Construction | [Patterns #10.5](./REFACTORING_PATTERNS.md#anti-pattern-5-validation-after-construction) |

---

## Gleam-Specific Patterns

### The 'use' Keyword for Early Returns
Gleam's `use` keyword provides clean early returns in Result pipelines.

**Pattern:**
```gleam
use data <- result.try(fetch_data())
use parsed <- result.try(parse_data(data))
use validated <- result.try(validate_data(parsed))
process(validated)
```

**Replaces:**
```gleam
case fetch_data() {
  Ok(data) ->
    case parse_data(data) {
      Ok(parsed) ->
        case validate_data(parsed) {
          Ok(validated) -> process(validated)
          Error(e) -> Error(e)
        }
      Error(e) -> Error(e)
    }
  Error(e) -> Error(e)
}
```

**Example:** [Result Pipeline with 'use'](./REFACTORING_EXAMPLES.md#4-result-pipeline-with-use)

### Pipe Operator for Data Flow
The `|>` operator makes data transformations read top-to-bottom.

**Pattern:**
```gleam
let result =
  initial_value
  |> transform_step_1
  |> transform_step_2
  |> transform_step_3
```

**Example:** [Pipe-First Data Transformations](./REFACTORING_EXAMPLES.md#5-validation-at-construction)

### Opaque Types for Encapsulation
Opaque types hide internal representation while providing type safety.

**Pattern:**
```gleam
pub opaque type FoodId {
  FoodId(String)
}

pub fn food_id(id: String) -> FoodId {
  FoodId(id)
}

pub fn food_id_to_string(id: FoodId) -> String {
  let FoodId(s) = id
  s
}
```

**Example:** [Opaque Type: FoodEntryId](./REFACTORING_EXAMPLES.md#2-opaque-type-foodentryid)

---

## Real-World Examples from Codebase

### Module Split Examples
1. **FatSecret Diary:** `/src/meal_planner/fatsecret/diary/`
   - types.gleam (312 lines)
   - decoders.gleam
   - client.gleam (406 lines)
   - service.gleam

2. **FatSecret Foods:** `/src/meal_planner/fatsecret/foods/`
   - types.gleam (opaque FoodId, ServingId)
   - decoders.gleam
   - client.gleam
   - handlers.gleam
   - service.gleam

3. **Tandoor Clients:** `/src/meal_planner/tandoor/clients/`
   - auth.gleam (session + bearer auth)
   - meal_plans.gleam
   - request_builder.gleam
   - response.gleam

### Opaque Type Examples
- **FoodEntryId:** `/src/meal_planner/fatsecret/diary/types.gleam`
- **FoodId, ServingId:** `/src/meal_planner/fatsecret/foods/types.gleam`
- **RecipeId:** `/src/meal_planner/id.gleam`
- **MealPlanRecipe:** `/src/meal_planner/types/recipe.gleam`

### Error Handling Examples
- **Central AppError:** `/src/meal_planner/errors.gleam`
- **Error Handlers:** `/src/meal_planner/shared/error_handlers.gleam`
- **Response Encoders:** `/src/meal_planner/shared/response_encoders.gleam`

---

## Refactoring Commit History

Key commits demonstrating refactoring patterns:

| Commit | Date | Description | Pattern |
|--------|------|-------------|---------|
| `6bd189f4` | 2024-12-24 | PHASE 1 diary refactoring | Module Split Strategy |
| `75ef8ffd` | 2024-12-24 | PHASE 2 FatSecret handlers | Error Handling |
| `3d17ec6b` | 2024-12-24 | PHASE 3 Tandoor client aggregator | mod.gleam Pattern |
| `c9105372` | 2024-12-24 | Extract diary decoders | Decoder Separation |
| `7037a8dd` | 2024-12-24 | Fix types module imports (54 files) | Import Refactoring |

View full commit history:
```bash
git log --oneline --grep="refactor\|split\|module" | head -30
```

---

## Pattern Application Decision Tree

```
Do you have a module >500 lines?
├─ YES → Apply Module Split Strategy (PHASE 1)
│         ├─ Create types.gleam
│         ├─ Create decoders.gleam
│         ├─ Create client.gleam
│         └─ Create service.gleam
│
└─ NO → Do you have duplicate error handling?
        ├─ YES → Apply Centralized Error Handling
        │         └─ Use shared/error_handlers.gleam
        │
        └─ NO → Do you have string-based IDs?
                ├─ YES → Apply Opaque Types
                │         ├─ Create opaque type
                │         ├─ Add constructor
                │         └─ Add to_string converter
                │
                └─ NO → Do you have nested case expressions?
                        ├─ YES → Apply Result Pipelines
                        │         └─ Replace with 'use' keyword
                        │
                        └─ NO → Continue with current pattern
```

---

## Memory Integration

This pattern library has been integrated with the project's memory system (mem0) with the following memories:

1. Module split standard structure: types, client, decoders, handlers, service, mod
2. Opaque types pattern for IDs with constructors and converters
3. Centralized error handling with AppError and conversion functions
4. 3-phase refactoring strategy (extract submodules → refactor handlers → create aggregators)
5. Result pipelines with 'use' keyword for flat control flow
6. Validation at construction with Result return types
7. Decoder separation pattern (types.gleam vs decoders.gleam)
8. mod.gleam aggregator pattern for public APIs

Query memories with:
```bash
# Search for refactoring patterns
search_memories("refactoring patterns module split")

# Search for specific patterns
search_memories("opaque types validation error handling")
```

---

## Contributing to This Library

When you discover new refactoring patterns:

1. **Document the pattern** in REFACTORING_PATTERNS.md
   - Pattern name and description
   - When to apply
   - Benefits
   - Example structure

2. **Add real examples** in REFACTORING_EXAMPLES.md
   - Include actual code from codebase
   - Show before/after
   - Link to relevant files

3. **Update this index**
   - Add to appropriate category
   - Update decision tree if needed

4. **Save to memory** using mem0
   ```gleam
   save_memory("Pattern: [name] - [short description with key points]")
   ```

---

## References

### Documentation Files
- [REFACTORING_PATTERNS.md](./REFACTORING_PATTERNS.md) - Pattern theory (10 patterns)
- [REFACTORING_EXAMPLES.md](./REFACTORING_EXAMPLES.md) - Code examples (6 examples)
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall system architecture
- [CLAUDE.md](./CLAUDE.md) - Project guidelines and rules

### External Resources
- [Gleam Language Tour](https://tour.gleam.run/)
- [Gleam Standard Library](https://hexdocs.pm/gleam_stdlib/)
- [Gleam Style Guide](https://gleam.run/writing-gleam/gleam-style-guide/)

### Related Project Documentation
- [CLAUDE_GLEAM_SKILL.md](./CLAUDE_GLEAM_SKILL.md) - Gleam language commandments
- [CLAUDE_MULTI_AGENT.md](./CLAUDE_MULTI_AGENT.md) - Multi-agent coordination
- [CLAUDE_MEMORY.md](./CLAUDE_MEMORY.md) - Memory system protocol

---

## Glossary

**Opaque Type:** Type whose internal structure is hidden from module users, only accessible through provided functions.

**Result Pipeline:** Chain of Result-returning operations using `use` for early returns on Error.

**Decoder:** Function that converts dynamic JSON data to typed Gleam values using `gleam/dynamic/decode`.

**mod.gleam:** Aggregator module that re-exports types and functions from submodules to provide clean public API.

**Validation at Construction:** Pattern where type constructors return Result and validate inputs, guaranteeing valid data.

**AppError:** Central error type in this codebase that all domain errors convert to for consistent HTTP handling.

---

**Generated by:** Agent-Mem-2 (38/96) - Pattern Library Creation
**Date:** 2024-12-24
**Codebase:** /home/lewis/src/meal-planner
**Branch:** fix-compilation-issues
