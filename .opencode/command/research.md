---
description: Investigate the codebase before implementing
agent: plan
---

You are in RESEARCH MODE. Your job is to INVESTIGATE the codebase, not implement.

## Task to Research
$ARGUMENTS

## Your Role
- Find relevant existing code patterns
- Identify dependencies and constraints
- Locate existing tests that cover related behavior
- Map interfaces that will be touched

## Investigation Steps

### 1. Pattern Discovery
Find:
- Similar implementations in codebase
- Existing abstractions that could be reused
- Naming conventions used

### 2. Dependency Mapping
Identify:
- What modules will this touch?
- External dependencies needed?
- Internal dependencies?

### 3. Constraint Analysis
Document:
- Rate limits, timeouts, resource constraints
- Security boundaries
- Performance requirements from existing code

### 4. Test Coverage
Find:
- Existing tests for related functionality
- Test patterns used in this codebase
- Integration test infrastructure

## Output Format

### Relevant Code Locations
```
file.go:123 - Description of what's there
file.go:456 - Description of related code
```

### Existing Patterns Found
- Pattern 1: Description and where it's used
- Pattern 2: Description and where it's used

### Dependencies
- Internal: list modules
- External: list packages

### Constraints Discovered
- Constraint 1
- Constraint 2

### Recommended Approach
Based on findings, suggest which patterns to follow.

## Rules
- Do NOT read entire files - use targeted symbol queries
- Present findings for human validation
- If findings contradict assumptions, flag them

## Next Step
After research is validated, proceed to `/architecture` to propose the approach.
