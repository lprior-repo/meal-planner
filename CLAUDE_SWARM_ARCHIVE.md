# CLAUDE Swarm Configuration Archive

**Status:** DEPRECATED - Swarm infrastructure removed on 2025-12-20

This document preserves the multi-agent swarm orchestration configuration that was previously active in this project. The actual `ruv-swarm` package and related infrastructure have been removed.

## Original System Identity
- **NAME:** FRACTAL_SWARM_GLEAM_V2
- **TYPE:** Multi_Agent_Recursive_Dev_System
- **LANGUAGE:** Gleam
- **CORE_DISCIPLINE:** Strict_TCR (Test, Commit, Revert)

## Historical Swarm Roles (No Longer Available)

### ARCHITECT
- **RESPONSIBILITY:** Define Types, Contracts, and JSON Fixtures
- **OUTPUT:** `.gleam` type definitions + `test/fixtures/*.json`

### TESTER
- **RESPONSIBILITY:** Write ONE failing test case (Red Phase)
- **CONSTRAINT:** Must fail for the correct reason

### CODER
- **RESPONSIBILITY:** Make the test pass (Green Phase)
- **CONSTRAINT:** Minimal implementation. "Fake it till you make it"

### REFACTORER
- **RESPONSIBILITY:** Optimize syntax/structure (Blue Phase)
- **CONSTRAINT:** No behavior change

## Original Swarm Delegation Logic (Disabled)

```
TRIGGER: Task_Start
LOGIC:
1. ARCHITECT defines the Type/Interface in `src/types.gleam`
2. ARCHITECT creates `test/fixtures/valid_input.json`
3. HANDOFF -> TESTER
4. TESTER writes assertion against fixture
5. HANDOFF -> CODER
6. CODER implements logic
7. IF (Success) -> HANDOFF -> REFACTORER
```

## Original Impasse Handling (Disabled)

```
TRIGGER: 3 Consecutive Reverts on same Behavior
ACTION: SWARM_CONVENE
STEPS:
1. STOP all coding
2. ARCHITECT reviews the Spec/Type definition
3. TESTER reviews the Test expectation
4. OUTPUT: "Strategy Change Proposal" before next attempt
```

## Visualization HUD Template (No Longer Rendered)

```
[TASK: {{Beads_ID}}] ── [ROLE: {{Current_Subagent}}]
├── LOCKS: {{File_Reservations}}
├── CYCLE: {{TCR_State}} (🔴 Red | 🟢 Green | 🔵 Refactor | ♻️ Reverted)
├── SWARM: [Spec: {{Spec_Status}}] -> [Test: {{Test_Status}}] -> [Impl: {{Impl_Status}}]
└── COMPLIANCE: [Gleam_Rules: {{Compliance_Check}}]
```

## Removed Dependencies

The following infrastructure has been completely removed:
- `ruv-swarm` package and all versions
- `claude-flow` integration module
- MCP logs related to ruv-swarm orchestration
- NPX cache entries for multi-agent coordination

## Migration Notes

Projects that previously relied on swarm orchestration should now use:
- Single-agent TDD workflow (SPEC → TEST → IMPL → REFACTOR)
- Beads for sequential task tracking
- Serena MCP for code navigation
- Manual agent role switching if multi-agent collaboration is needed (via Agent Mail threads)

## Restoring Swarm (If Needed)

To restore swarm functionality in the future, would require:
1. Reinstalling `ruv-swarm` package
2. Updating CLAUDE.md with original swarm configuration
3. Restoring MCP server setup for multi-agent coordination
4. Reconfiguring Agent Mail for cross-agent communication

---

*Archive created: 2025-12-20*
*Reason: Removal of ruv-swarm infrastructure from home directory*
