# AI Feedback Loops - Fractal Development System

## The Fractal Structure

The system is recursive. At every level, the pattern is the same: **attempt, verify, feedback, retry**. The only thing that changes is the granularity.

```
Outer loop:  Feature    → Shipped
Middle loop: Capability → Integrated
Inner loop:  Behavior   → Implemented
Micro loop:  Change     → Verified
```

Each level contains multiple iterations of the level below it.

## Spec Refinement Loops

The spec stage is a series of nested loops that progressively build understanding and artifacts.

### Loop 1: Clarification
- **Input**: Raw intent (e.g., "add retry logic to client")
- **AI Role**: Ask clarifying questions, not answer them
- **Output**: Clarified intent with decisions recorded
- **Agent**: `/clarify`

### Loop 2: Research
- **Input**: Clarified intent
- **AI Role**: Investigate codebase using Serena tools
- **Output**: Research summary with code references
- **Agent**: `/research`

### Loop 3: Architecture Review
- **Input**: Clarified intent + research
- **AI Role**: Propose approach, where code lives, interfaces touched
- **Output**: Architectural decision record
- **Agent**: `/architecture`

### Loop 4: Artifact Generation
- **Input**: Everything above
- **AI Role**: Generate spec, Beads issues, acceptance criteria
- **Output**: Complete spec + Beads issues ready to pull
- **Agent**: `/artifacts`

### Loop 5: Shared Understanding
- **Input**: All artifacts
- **AI Role**: Summarize back what we're building
- **Output**: Locked spec with human confirmation
- **Agent**: Part of `/artifacts` flow

## Implementation Loops

Implementation follows TDD and TCR (Test, Commit, Revert) discipline.

### Loop 1: Contract First
- **Input**: Spec with API contract
- **AI Role**: Write interface/type definitions only
- **Output**: Committed interface + failing tests
- **Agent**: `/contract`

### Loop 2: Red-Green-Refactor (per behavior)

**Red Phase** (`/tdd-red`):
- Write one failing test for one specific behavior
- Test must be minimal, testing exactly one thing
- Commit the failing test

**Green Phase** (`/tdd-green`):
- Write minimal code to make test pass
- Emphasis on minimal, not clever
- If pass → commit; if fail → adjust or revert

**Refactor Phase** (`/tdd-refactor`):
- Look for improvement opportunities
- Run tests after each refactor step
- If tests fail → revert immediately (TCR)

### Loop 3: Hooks and Gates
After each commit, automated checks run:
- Per-change: Format, basic lint (milliseconds)
- Per-commit: Full lint, type check, unit tests (seconds)
- Per-batch: Integration tests, security scan (minutes)
- Per-capability: Full suite, performance tests (minutes-hours)

### Loop 4: Batch Verification
- Run integration tests after several behaviors
- Contract tests to verify API spec
- Human reviews the batch

### Loop 5: Capability Completion
- All behaviors implemented
- All tests pass
- Human final review
- Mark Beads issue done

## TCR Discipline

**The Rule**: If tests pass → commit immediately. If tests fail → revert immediately.

No debugging broken code. Revert and try a smaller change. This forces tiny steps where either they work or the revert cost is trivial.

## Feedback Arrows

At any point, feedback flows backward:

```
TDD-green fails N times → Is test wrong? → Back to TDD-red
                       → Is contract wrong? → Back to contract loop
                       → Is spec wrong? → Back to spec refinement

Integration fails → Is implementation wrong? → Back to TDD
                 → Is contract wrong? → Back to contract
                 → Is architecture wrong? → Back to architecture
```

**Principle**: Fix at the source. Don't paper over a spec problem with implementation hacks.

## State Tracking

Work items track position in nested structure:

```yaml
WorkItem:
  id: "retry-transient-errors"
  feature: "add-retry-logic"
  stage: "implementing"  # spec_refinement | implementing | review | deploy

  # Spec sub-state
  spec_loop: "complete"  # clarifying | researching | architecture | artifacts

  # Implementation sub-state
  impl_loop: "tdd"       # contract | tdd | batch_verify | capability_verify
  tdd_phase: "green"     # red | green | refactor
  current_behavior: "exponential-backoff"
  behaviors_complete: ["retry-once", "retry-max-3"]
  behaviors_remaining: ["retry-429", "retry-504"]
```

## Slash Commands

### Spec Refinement
- `/clarify <task>` - Run clarification loop, output questions
- `/research <task>` - Investigate codebase, output findings
- `/architecture <task>` - Propose approach, output decision record
- `/artifacts <task>` - Generate spec + Beads issues

### Implementation
- `/contract <capability>` - Write interfaces and failing tests
- `/tdd-red <behavior>` - Write one failing test
- `/tdd-green` - Make current failing test pass
- `/tdd-refactor` - Improve without changing behavior

### Orchestration
- `/flow <task>` - Full orchestrator, guides through all loops
- `/plan <task>` - Decompose into atomic beads (existing)

## Agent Modes Summary

| Mode | AI Job | Output |
|------|--------|--------|
| Clarification | Ask questions | Questions for human |
| Research | Investigate codebase | Findings with code refs |
| Architecture | Propose approach | Decision record |
| Artifact | Generate documents | Spec, Beads, test criteria |
| Contract | Write interfaces | Type definitions, signatures |
| TDD-Red | Write failing test | Test code |
| TDD-Green | Make test pass | Implementation code |
| TDD-Refactor | Improve code | Refactored code |
