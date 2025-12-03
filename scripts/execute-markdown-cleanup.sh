#!/bin/bash
# Markdown Migration Cleanup Script - REVISED
# Generated: 2025-12-03
# Beads: meal-planner-d8f, meal-planner-grm
# IMPORTANT: .opencode/ directory is PRESERVED (not touched)

set -e  # Exit on error
cd /home/lewis/src/meal-planner

echo "======================================"
echo "Markdown Migration Cleanup Script"
echo "======================================"
echo ""
echo "NOTE: .opencode/ directory will NOT be modified"
echo ""

# ==============================================================================
# PHASE 1: Archive Unused Agents (21 files)
# Bead: meal-planner-d8f
# ==============================================================================
echo "PHASE 1: Archiving unused agents..."
echo "Affected files: 21 unused agent definitions"
echo ""

# Create archive directories
mkdir -p docs/archived-agents/{flow-nexus,consensus,specialized}

# Archive Flow-Nexus agents (9 files)
echo "Archiving Flow-Nexus agents..."
git mv .claude/agents/flow-nexus/app-store.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/authentication.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/challenges.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/neural-network.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/payments.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/sandbox.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/swarm.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/user-tools.md docs/archived-agents/flow-nexus/
git mv .claude/agents/flow-nexus/workflow.md docs/archived-agents/flow-nexus/
rmdir .claude/agents/flow-nexus

# Archive Consensus agents (7 files)
echo "Archiving consensus mechanism agents..."
git mv .claude/agents/consensus/byzantine-coordinator.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/crdt-synchronizer.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/gossip-coordinator.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/performance-benchmarker.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/quorum-manager.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/raft-manager.md docs/archived-agents/consensus/
git mv .claude/agents/consensus/security-manager.md docs/archived-agents/consensus/
rmdir .claude/agents/consensus

# Archive Specialized agents (5 files)
echo "Archiving specialized agents..."
git mv .claude/agents/specialized/mobile/spec-mobile-react-native.md docs/archived-agents/specialized/
git mv .claude/agents/data/ml/data-ml-model.md docs/archived-agents/specialized/
git mv .claude/agents/development/backend/dev-backend-api.md docs/archived-agents/specialized/
git mv .claude/agents/devops/ci-cd/ops-cicd-github.md docs/archived-agents/specialized/
git mv .claude/agents/documentation/api-docs/docs-api-openapi.md docs/archived-agents/specialized/

# Cleanup empty directories
rmdir .claude/agents/specialized/mobile 2>/dev/null || true
rmdir .claude/agents/data/ml 2>/dev/null || true
rmdir .claude/agents/development/backend 2>/dev/null || true
rmdir .claude/agents/devops/ci-cd 2>/dev/null || true
rmdir .claude/agents/documentation/api-docs 2>/dev/null || true

# Create archive README
cat > docs/archived-agents/README.md << 'ARCHIVE_README'
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
ARCHIVE_README

git add docs/archived-agents/README.md

echo "✓ Phase 1 complete: 21 agents archived"
echo ""

# ==============================================================================
# PHASE 2: Clean up empty .claude/ subdirectories
# ==============================================================================
echo "PHASE 2: Cleaning empty directories..."

# Remove empty subdirectories if they exist
rmdir .claude/agents/specialized 2>/dev/null || true
rmdir .claude/agents/data 2>/dev/null || true
rmdir .claude/agents/development 2>/dev/null || true
rmdir .claude/agents/devops 2>/dev/null || true
rmdir .claude/agents/documentation 2>/dev/null || true

echo "✓ Phase 2 complete: Empty directories cleaned"
echo ""

# ==============================================================================
# COMMIT CHANGES
# ==============================================================================
echo "Committing changes..."

git commit -m "docs: Archive unused agent definitions

Phase 1 - Archive unused agents:
- Archive 9 Flow-Nexus agents to docs/archived-agents/flow-nexus/
- Archive 7 consensus agents to docs/archived-agents/consensus/
- Archive 5 specialized agents to docs/archived-agents/specialized/
- Create docs/archived-agents/README.md

Total: 21 agents archived (preserved, not deleted)
Markdown files: 134 → 113 (16% reduction)

NOTE: .opencode/ directory preserved unchanged

Beads: meal-planner-d8f, meal-planner-grm"

echo ""
echo "======================================"
echo "✓ Cleanup Complete!"
echo "======================================"
echo ""
echo "Summary:"
echo "  - 21 unused agents archived (not deleted)"
echo "  - .opencode/ directory PRESERVED"
echo "  - All critical files intact"
echo "  - Total markdown files: 134 → 113 (16% reduction)"
echo ""
echo "What was preserved:"
echo "  - All .opencode/ files (unchanged)"
echo "  - CLAUDE.md, README.md, AGENTS.md"
echo "  - All .claude/ core agents"
echo "  - All documentation in docs/"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff HEAD~1"
echo "  2. Close beads: bd close meal-planner-{d8f,grm}"
echo "  3. Push changes: git push"
echo ""
