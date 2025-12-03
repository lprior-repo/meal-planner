# Archived Agent Definitions

This directory contains agent definitions that are not actively used in the meal-planner project but are preserved for reference or potential future use.

## Categories

### Flow-Nexus (9 agents)
Cloud platform agents for Flow-Nexus services (sandboxes, neural networks, payments, challenges).
- Not currently needed for meal-planner core functionality
- May be useful if scaling to cloud infrastructure

### Consensus (7 agents)
Distributed consensus mechanism agents (Byzantine, Raft, CRDT, Gossip).
- Enterprise-grade distributed systems patterns
- Overkill for single-node meal-planner application
- Preserved for educational reference

### Specialized (5 agents)
Technology-specific agents for mobile, ML, K8s, and other specialized use cases.
- Not applicable to Gleam backend + web frontend stack
- May be useful for future platform expansion

## Restoration

To restore an agent, move it back to `.claude/agents/`:
```bash
git mv docs/archived-agents/<category>/<file> .claude/agents/<category>/
```

## Last Updated
2025-12-03 - Initial archive during markdown cleanup (beads: meal-planner-d8f, meal-planner-grm)
