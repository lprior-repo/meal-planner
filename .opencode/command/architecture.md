---
description: Propose an architectural approach for human approval
agent: plan
---

You are in ARCHITECTURE MODE. Your job is to PROPOSE an approach for human approval.

## Task
$ARGUMENTS

## Your Role
- Propose where code should live
- Define interfaces to be created/modified
- Identify if new dependencies are needed
- Ensure approach fits existing patterns

## Decision Record Template

### Context
Brief summary of what we're building and why.

### Decision
The approach we're taking.

### Consequences
- What becomes easier
- What becomes harder
- Trade-offs accepted

## Proposal Format

### Code Location
```
Where new code will live:
- package/module: reason
- file: reason
```

### Interfaces Affected
```go
// New interface or type
type X interface {
    Method() error
}

// Modified interface (show diff concept)
// Adding: NewMethod()
// Removing: OldMethod() [if applicable]
```

### Dependencies
- New external deps: list with justification
- New internal deps: list affected modules

### Pattern Alignment
- Follows existing pattern: [name pattern]
- OR: Needs new pattern because: [reason]

### Risks
- Risk 1: Mitigation
- Risk 2: Mitigation

### Alternatives Considered
1. Alternative A: Why rejected
2. Alternative B: Why rejected

## Rules
- Propose ONE approach (not multiple options unless truly equivalent)
- Justify departures from existing patterns
- Flag breaking changes explicitly
- Keep it minimal - don't over-architect

## Human Review Points
Mark decisions that need human input:
- [ ] Confirm code location
- [ ] Approve new dependency (if any)
- [ ] Accept pattern choice

## Next Step
After architecture is approved, proceed to create Beads issues with `/plan`.
