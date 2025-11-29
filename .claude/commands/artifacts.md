# Artifact Generation Agent

You are in ARTIFACT MODE. Your job is to GENERATE spec documents and Beads issues.

## Task
$ARGUMENTS

## Your Role
- Create formal spec document
- Break capability into behaviors
- Generate Beads issues with dependencies
- Define testable acceptance criteria

## Spec Document Template

### Overview
One paragraph: what this capability does and why.

### Behaviors
List each discrete behavior that needs to be implemented:

1. **Behavior Name**: Description
   - Input: what triggers it
   - Output: what it produces
   - Edge cases: list them

2. **Behavior Name**: Description
   - Input: ...
   - Output: ...
   - Edge cases: ...

### API Contract
```go
// Types
type ConfigType struct {
    Field Type `json:"field"`
}

// Functions
func FunctionName(param Type) (Result, error)
```

### Test Criteria
For each behavior, define how to test it:

| Behavior | Test | Expected Result |
|----------|------|-----------------|
| Behavior 1 | Input X | Output Y |
| Behavior 1 | Edge case | Handle gracefully |
| Behavior 2 | Input Z | Output W |

### Non-Functional Requirements
- Performance: specific metrics if applicable
- Security: considerations
- Observability: logging, metrics

## Beads Issue Generation

For each behavior, create a Beads issue:

```bash
bd create "Implement [behavior]" -t task -p 2 --json
```

### Dependency Mapping
After creating issues, map dependencies:
- Behavior B depends on Behavior A
- All behaviors depend on Contract

```bash
bd dep add <behavior-id> <contract-id> --type blocks
```

## Shared Understanding Check

Before completing, summarize back:

> "Here's what I understand we're building:
> - [Capability name] that does [X]
> - It has [N] behaviors: [list them]
> - The API looks like [summary]
> - Success means [acceptance criteria summary]
>
> Is this correct?"

## Output Checklist
- [ ] Spec document with all behaviors listed
- [ ] API contract defined
- [ ] Test criteria for each behavior
- [ ] Beads issues created
- [ ] Dependencies mapped
- [ ] Human confirmed understanding

## Next Step
After artifacts approved, proceed to `/contract` to implement interfaces.
