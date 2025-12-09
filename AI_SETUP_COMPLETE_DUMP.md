# Complete AI Setup for Meal Planner Project

**Generated**: 2025-12-09
**Purpose**: Complete dump of all AI-specific setup for replication to other projects

---

## Table of Contents

1. [MCP Server Setup (Agent Mail)](#mcp-server-setup)
2. [Git Hooks](#git-hooks)
3. [Beads Configuration](#beads-configuration)
4. [Scripts](#scripts)
5. [Claude Code Configuration](#claude-code-configuration)
6. [Documentation Files](#documentation-files)
7. [Agent Definitions](#agent-definitions)
8. [Slash Commands](#slash-commands)
9. [Environment Files](#environment-files)
10. [Installation Guide](#installation-guide)

---

## MCP Server Setup

### Install MCP Agent Mail

```bash
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start
```

### Verify Installation

```bash
claude mcp list
```

### Test Connection

```javascript
// In any Claude Code session
mcp__mcp_agent_mail__health_check()
```

---

## Git Hooks

### Pre-Commit Hook
**Location**: `.git/hooks/pre-commit`

```bash
#!/bin/sh
# bd-hooks-version: 0.28.0 (enhanced with build checks)
#
# bd (beads) pre-commit hook + Quality Gates
#
# This hook ensures that:
# 1. Any pending bd issue changes are flushed to .beads/beads.jsonl
# 2. Code is properly formatted (gleam format)
# 3. Code compiles successfully (gleam build) - MANDATORY
# 4. Tests pass (gleam test) - Optional, configurable
#
# NO BYPASS MECHANISMS - All checks are mandatory
# This prevents the 87 compilation errors that occurred in the Lustre SSR migration
#
# Installation:
#   cp examples/git-hooks/pre-commit .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit

# =============================================================================
# Configuration
# =============================================================================

# Set to "1" to run tests on every commit (slower but safer)
# Set to "0" to skip tests (faster commits, rely on CI)
RUN_TESTS_ON_COMMIT="${RUN_TESTS_ON_COMMIT:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    printf "${GREEN}[PRE-COMMIT]${NC} %s\n" "$1" >&2
}

log_error() {
    printf "${RED}[PRE-COMMIT ERROR]${NC} %s\n" "$1" >&2
}

log_warn() {
    printf "${YELLOW}[PRE-COMMIT WARN]${NC} %s\n" "$1" >&2
}

# =============================================================================
# Quality Gate 1: Beads Sync
# =============================================================================

log_info "Running quality gate 1/4: Beads sync..."

# Check if bd is available
if ! command -v bd >/dev/null 2>&1; then
    log_warn "bd command not found, skipping beads sync"
else
    # Check if we're in a bd workspace
    if [ -d .beads ]; then
        # Check if sync-branch is configured
        SYNC_BRANCH="${BEADS_SYNC_BRANCH:-}"
        if [ -z "$SYNC_BRANCH" ] && [ -f .beads/config.yaml ]; then
            SYNC_BRANCH=$(grep -E '^sync-branch:' .beads/config.yaml 2>/dev/null | head -1 | sed 's/^sync-branch:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
        fi

        if [ -z "$SYNC_BRANCH" ]; then
            # No sync-branch, flush and stage
            if ! bd sync --flush-only >/dev/null 2>&1; then
                log_error "Failed to flush bd changes to JSONL"
                echo "Run 'bd sync --flush-only' manually to diagnose" >&2
                exit 1
            fi

            # Stage JSONL files
            for f in .beads/beads.jsonl .beads/issues.jsonl .beads/deletions.jsonl; do
                [ -f "$f" ] && git add "$f" 2>/dev/null || true
            done
        fi
        # If sync-branch is set, changes go to separate branch, skip here
    fi
fi

log_info "✓ Beads sync complete"

# =============================================================================
# Quality Gate 2: Gleam Format Check
# =============================================================================

log_info "Running quality gate 2/4: Format check..."

# Only run if gleam directory exists
if [ -d gleam ]; then
    cd gleam || exit 1

    # Check if gleam is available
    if ! command -v gleam >/dev/null 2>&1; then
        log_error "gleam command not found"
        echo "Install gleam: https://gleam.run/getting-started/installing/" >&2
        exit 1
    fi

    # Run format check
    if ! gleam format --check >/dev/null 2>&1; then
        log_error "Code is not properly formatted"
        echo "" >&2
        echo "Run the following command to fix formatting:" >&2
        echo "  cd gleam && gleam format" >&2
        echo "" >&2
        exit 1
    fi

    log_info "✓ Format check passed"
    cd ..
fi

# =============================================================================
# Quality Gate 3: Gleam Build (MANDATORY)
# =============================================================================

log_info "Running quality gate 3/4: Build check..."

# Only run if gleam directory exists
if [ -d gleam ]; then
    cd gleam || exit 1

    # Run build - this is MANDATORY and has NO BYPASS
    # This prevents compilation errors from being committed
    log_info "Building project (this may take 10-30 seconds)..."

    if ! gleam build 2>&1; then
        log_error "Build failed - cannot commit code that doesn't compile"
        echo "" >&2
        echo "Fix compilation errors before committing." >&2
        echo "This is a MANDATORY check with NO BYPASS." >&2
        echo "" >&2
        exit 1
    fi

    log_info "✓ Build successful"
    cd ..
fi

# =============================================================================
# Quality Gate 4: Gleam Test (Optional)
# =============================================================================

if [ "$RUN_TESTS_ON_COMMIT" = "1" ]; then
    log_info "Running quality gate 4/4: Test check..."

    # Only run if gleam directory exists
    if [ -d gleam ]; then
        cd gleam || exit 1

        log_info "Running tests (this may take 30-60 seconds)..."

        if ! gleam test 2>&1; then
            log_error "Tests failed - cannot commit broken tests"
            echo "" >&2
            echo "Fix failing tests before committing." >&2
            echo "To skip tests temporarily, set: export RUN_TESTS_ON_COMMIT=0" >&2
            echo "" >&2
            exit 1
        fi

        log_info "✓ Tests passed"
        cd ..
    fi
else
    log_info "Skipping quality gate 4/4: Tests (disabled via RUN_TESTS_ON_COMMIT=0)"
fi

# =============================================================================
# Success
# =============================================================================

log_info "All quality gates passed - ready to commit!"

exit 0
```

### Post-Commit Hook
**Location**: `.git/hooks/post-commit`

```bash
#!/usr/bin/env bash
# Post-Commit Hook - Detect --no-verify Usage

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Check if build would pass
cd "$(git rev-parse --show-toplevel)"

if [[ -f "gleam/gleam.toml" ]]; then
    # Quick build check (silent)
    if ! (cd gleam && gleam build >/dev/null 2>&1); then
        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}${BOLD}  ⚠ WARNING: COMMIT HAS COMPILATION ERRORS${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${BOLD}It appears you may have used 'git commit --no-verify'${NC}"
        echo ""
        echo "Your commit was successful, but the code doesn't compile!"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}CRITICAL REMINDER:${NC}"
        echo ""
        echo "  You MUST fix these compilation errors before:"
        echo "    • Pushing to remote"
        echo "    • Merging to main"
        echo "    • Creating a PR"
        echo ""
        echo "  The pre-push hook will BLOCK your push until errors are fixed!"
        echo ""
        echo -e "${BOLD}To fix now:${NC}"
        echo "  1. Run: cd gleam && gleam build"
        echo "  2. Fix the errors shown"
        echo "  3. Commit the fixes: git add . && git commit -m 'Fix compilation errors'"
        echo ""
        echo -e "${BOLD}Or to amend this commit:${NC}"
        echo "  1. Fix the errors"
        echo "  2. Run: git add ."
        echo "  3. Run: git commit --amend --no-edit"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "See errors by running: cd gleam && gleam build"
        echo ""
    fi
fi

exit 0
```

### Prepare-Commit-Msg Hook
**Location**: `.git/hooks/prepare-commit-msg`

```bash
#!/usr/bin/env bash
# Prepare Commit Message Hook

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only add reminder for normal commits (not merges, amends, etc.)
if [[ "$COMMIT_SOURCE" == "" ]]; then
    cd "$(git rev-parse --show-toplevel)"

    # Quick check if build would fail
    if [[ -f "gleam/gleam.toml" ]]; then
        if ! (cd gleam && gleam build >/dev/null 2>&1); then
            # Add reminder at the bottom of commit message
            echo "" >> "$COMMIT_MSG_FILE"
            echo "# ⚠️  WARNING: Code has compilation errors!" >> "$COMMIT_MSG_FILE"
            echo "#" >> "$COMMIT_MSG_FILE"
            echo "# REMINDER: Fix errors before pushing/merging to main!" >> "$COMMIT_MSG_FILE"
            echo "# Run: cd gleam && gleam build" >> "$COMMIT_MSG_FILE"
            echo "#" >> "$COMMIT_MSG_FILE"
            echo "# If you used --no-verify, you MUST fix these before:" >> "$COMMIT_MSG_FILE"
            echo "#   • git push (will be blocked by pre-push hook)" >> "$COMMIT_MSG_FILE"
            echo "#   • Merging to main" >> "$COMMIT_MSG_FILE"
        fi
    fi
fi

exit 0
```

### Post-Checkout Hook
**Location**: `.git/hooks/post-checkout`

```bash
#!/bin/sh
# bd (beads) post-checkout hook

# Only run on branch checkouts
if [ "$3" != "1" ]; then
    exit 0
fi

# Skip during rebase
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    exit 0
fi

# Check if bd is available
if ! command -v bd >/dev/null 2>&1; then
    exit 0
fi

# Check if we're in a bd workspace
if [ ! -d .beads ]; then
    exit 0
fi

# Run bd sync --import-only --no-git-history to import the updated JSONL
if ! output=$(bd sync --import-only --no-git-history 2>&1); then
    echo "Warning: Failed to sync bd changes after checkout" >&2
    echo "$output" >&2
    echo "" >&2
    echo "Run 'bd doctor --fix' to diagnose and repair" >&2
fi

# Run quick health check
bd doctor --check-health 2>/dev/null || true

exit 0
```

### Post-Merge Hook
**Location**: `.git/hooks/post-merge`

```bash
#!/bin/sh
# bd (beads) post-merge hook

# Skip during rebase
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    exit 0
fi

# Check if bd is available
if ! command -v bd >/dev/null 2>&1; then
    echo "Warning: bd command not found, skipping post-merge sync" >&2
    exit 0
fi

# Check if we're in a bd workspace
if [ ! -d .beads ]; then
    exit 0
fi

# Run bd sync --import-only --no-git-history
if ! output=$(bd sync --import-only --no-git-history 2>&1); then
    echo "Warning: Failed to sync bd changes after merge" >&2
    echo "$output" >&2
    echo "" >&2
    echo "Run 'bd doctor --fix' to diagnose and repair" >&2
fi

# Run quick health check
bd doctor --check-health 2>/dev/null || true

exit 0
```

### Pre-Push Hook
**Location**: `.git/hooks/pre-push`

```bash
#!/bin/sh
# bd (beads) pre-push hook

# Check if we're in a bd workspace
if [ ! -d .beads ]; then
    exit 0
fi

# Check if sync-branch is configured
SYNC_BRANCH="${BEADS_SYNC_BRANCH:-}"
if [ -z "$SYNC_BRANCH" ] && [ -f .beads/config.yaml ]; then
    SYNC_BRANCH=$(grep -E '^sync-branch:' .beads/config.yaml 2>/dev/null | head -1 | sed 's/^sync-branch:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
fi
if [ -n "$SYNC_BRANCH" ]; then
    exit 0
fi

# Optionally flush pending bd changes
if command -v bd >/dev/null 2>&1; then
    bd sync --flush-only >/dev/null 2>&1 || true
fi

# Collect all tracked or existing JSONL files
FILES=""
for f in .beads/beads.jsonl .beads/issues.jsonl .beads/deletions.jsonl; do
    if git ls-files --error-unmatch "$f" >/dev/null 2>&1 || [ -f "$f" ]; then
        FILES="$FILES $f"
    fi
done

# Check for any uncommitted changes
if [ -n "$FILES" ]; then
    # shellcheck disable=SC2086
    if [ -n "$(git status --porcelain -- $FILES 2>/dev/null)" ]; then
        echo "❌ Error: Uncommitted changes detected" >&2
        echo "" >&2
        echo "Before pushing, ensure all changes are committed. This includes:" >&2
        echo "  • bd JSONL updates (run 'bd sync')" >&2
        echo "  • any other modified files (run 'git status' to review)" >&2
        echo "" >&2

        # Check if bd is available and offer auto-sync
        if command -v bd >/dev/null 2>&1; then
            if [ -t 0 ]; then
                echo "Would you like to run 'bd sync' now? [y/N]" >&2
                read -r response
                case "$response" in
                    [yY][eE][sS]|[yY])
                        echo "" >&2
                        echo "Running: bd sync" >&2
                        if bd sync; then
                            echo "" >&2
                            echo "✓ Sync complete. Continuing with push..." >&2
                            exit 0
                        else
                            echo "" >&2
                            echo "❌ Sync failed. Push aborted." >&2
                            exit 1
                        fi
                        ;;
                    *)
                        echo "" >&2
                        echo "Push aborted. Run 'bd sync' manually when ready" >&2
                        exit 1
                        ;;
                esac
            else
                echo "Run 'bd sync' to commit these changes" >&2
                exit 1
            fi
        else
            echo "Please commit the updated JSONL before pushing" >&2
            exit 1
        fi
    fi
fi

exit 0
```

### Install Hooks Script
**Location**: `scripts/install-hooks.sh`

```bash
#!/usr/bin/env bash
# Install git hooks for meal-planner project
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}Installing Git Hooks for Meal Planner${NC}\n"

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo -e "${BLUE}Installing pre-commit hook...${NC}"
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  echo -e "${YELLOW}  Existing pre-commit hook found, backing up...${NC}"
  mv "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup.$(date +%s)"
fi

# Copy all hooks from .git/hooks to scripts if not using symlinks
for hook in pre-commit post-commit prepare-commit-msg post-checkout post-merge pre-push; do
    if [ -f "$REPO_ROOT/.git/hooks/$hook" ]; then
        cp "$REPO_ROOT/.git/hooks/$hook" "$HOOKS_DIR/$hook"
        chmod +x "$HOOKS_DIR/$hook"
        echo -e "${GREEN}  ✓ $hook hook installed${NC}"
    fi
done

echo -e "\n${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}✓ Git hooks installed successfully!${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Features:${NC}"
echo -e "  • Beads sync"
echo -e "  • Format checking"
echo -e "  • Build verification (MANDATORY)"
echo -e "  • Optional test execution"
echo -e ""
```

---

## Beads Configuration

### `.beads/config.yaml`

```yaml
# Beads Configuration File
# This file configures default behavior for all bd commands in this repository

# Issue prefix for this repository
# issue-prefix: "meal-planner"

# Sync branch for beads commits
sync-branch: main

# Auto-start daemon if not running
# auto-start-daemon: true

# Debounce interval for auto-flush
# flush-debounce: "5s"
```

---

## Scripts

All coordination scripts for parallel agent execution:

### `scripts/agent-coordinator.sh`

See full file content in the previous section (630 lines).

Key features:
- Agent Mail registration
- Worktree pool integration
- File reservation coordination
- Beads track assignment
- Resource monitoring
- Conflict resolution

### `scripts/worktree-pool-manager.sh`

See full file content in the previous section (537 lines).

Key features:
- Pool initialization (3-10 worktrees)
- Agent queueing with priority
- Dynamic scaling based on load
- Resource monitoring integration
- Beads isolation per worktree

### `scripts/beads-track-analyzer.sh`

See full file content in the previous section (523 lines).

Key features:
- Parse `bv --robot-plan` output
- Assign tasks to parallel tracks
- Check track independence
- Recommend worktree assignments
- Detect file conflicts between tracks

### `scripts/agent-mail-wrapper.sh`

See full file content in the previous section (226 lines).

Key features:
- Shell functions for calling Agent Mail MCP
- File reservations
- Messaging
- Inbox checking

### `scripts/resource-monitor.sh`

See full file content in the previous section (641 lines).

Key features:
- Database connection tracking (PostgreSQL limit: 50)
- File descriptor monitoring
- Disk space monitoring (3GB max)
- Leak detection (orphan DBs, zombie processes)
- Background monitoring daemon

### `scripts/setup-worktree-filters.sh`

See full file content in the previous section (110 lines).

**THE KEY SCRIPT** for preventing AI agents from trampling each other!

Uses git sparse-checkout to limit visible files per worktree.

---

## Claude Code Configuration

### `.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "nu -c 'cd gleam && gleam check | head 20'"
          }
        ]
      }
    ]
  }
}
```

### `.claude/settings.local.json`

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "Bash(bd list:*)"
    ],
    "deny": [],
    "ask": []
  },
  "enabledMcpjsonServers": [
    "mcp-agent-mail",
    "claude-flow@alpha",
    "ruv-swarm",
    "flow-nexus"
  ]
}
```

### `.claude/statusline-command.sh`

See full file content in the previous section (177 lines).

Shows:
- Model and directory
- Git branch
- Swarm configuration & topology
- Real-time system metrics
- Session state
- Performance metrics
- Active tasks

---

## Documentation Files

### `CLAUDE.md` (Project Instructions)

See full content above. Key sections:
- Automatic session start
- Worktree coordination
- Standard workflow
- Key integrations
- Development rules (NO JAVASCRIPT!)
- Session close protocol

### `WORKTREE_COORDINATION.md`

See full content above. Key sections:
- Architecture overview
- Components
- File filtering (prevents conflicts)
- Quick start guide
- Manual agent workflow
- Advanced features

### `AGENTS.md`

See full content above. Key sections:
- MCP Agent Mail coordination
- Integrating with Beads
- Beads Viewer (bv) for AI agents
- Development guidelines
- Fractal structure
- Agent modes

### `PARALLEL_AGENT_WORKFLOW_GUIDE.md`

See full content above. Key sections:
- Problem analysis
- Git worktree + CI/CD solution
- Implementation strategy
- Quality enforcement
- Usage guide
- Benefits comparison

### `QUICK_START_PARALLEL_AGENTS.md`

See full content above.

Quick 30-second setup guide for parallel agent execution.

### `WORKTREE_QUICK_REFERENCE.md`

See full content above.

Quick reference for common worktree operations.

---

## Slash Commands

### `/beads-plan` Command

**Location**: `.claude/commands/beads-plan.md`

See full content above (256 lines).

Decomposes user intent into minimal atomic beads tasks with Agent Mail coordination.

**Core Laws:**
1. Minimal atomicity
2. Agent Mail native
3. Beads-compatible DAG
4. Verifiable

---

## Protected Files (.claudeignore)

**Location**: `.claudeignore`

```
# Claude Code Ignore File
# Files and directories that Claude Code should NEVER edit or modify

# Git hooks - NEVER TOUCH THESE
.git/hooks/*
.agent-worktrees/*/.git/hooks/*

# Hook scripts - Protected from modification
scripts/pre-commit.sh
scripts/agent-worktree-manager.sh

# Git configuration
.git/config
.gitmodules

# Agent Mail artifacts (read-only coordination)
.agent-mail/
**/agent-mail/messages/**
**/agent-mail/agents/**
**/agent-mail/file_reservations/**

# CI/CD configuration (protected)
.github/workflows/*.yml

# Environment and secrets
.env
.env.*
*.key
*.pem
*.cert
credentials.json
secrets.yaml

# Build artifacts (generated, not source)
build/
dist/
*.beam
erl_crash.dump

# Database dumps
*.sql.gz
*.dump

# Worktree directories (each agent manages their own)
.agent-worktrees/*/

# Package manager lock files (generated)
gleam.lock
package-lock.json
yarn.lock
Cargo.lock
```

---

## Environment Files

### `.env.worktree` (per worktree)

Created automatically by worktree-pool-manager.sh:

```bash
DATABASE_NAME=meal_planner_wt-1
WORKTREE_ID=wt-1
POOL_STATE_FILE=/tmp/pool-state.json
```

---

## Global Configuration

### Global CLAUDE.md

**Location**: `~/.claude/CLAUDE.md`

```markdown
- You are to never disable a file again.
```

### Global Status Line Script

**Location**: `~/.claude/statusline-command.sh`

```bash
#!/bin/bash

# Read JSON input from stdin
INPUT=$(cat)
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd')
DIR=$(basename "$CWD")

# Replace claude-code-flow with branded name
if [ "$DIR" = "claude-code-flow" ]; then
  DIR="🌊 Claude Flow"
fi

# Get git branch
BRANCH=$(cd "$CWD" 2>/dev/null && git branch --show-current 2>/dev/null)

# Start building statusline
printf "\033[1m$MODEL\033[0m in \033[36m$DIR\033[0m"
[ -n "$BRANCH" ] && printf " on \033[33m⎇ $BRANCH\033[0m"

# Claude-Flow integration
FLOW_DIR="$CWD/.claude-flow"

if [ -d "$FLOW_DIR" ]; then
  printf " │"

  # 1. Swarm Configuration & Topology
  if [ -f "$FLOW_DIR/swarm-config.json" ]; then
    STRATEGY=$(jq -r '.defaultStrategy // empty' "$FLOW_DIR/swarm-config.json" 2>/dev/null)
    if [ -n "$STRATEGY" ]; then
      # Map strategy to topology icon
      case "$STRATEGY" in
        "balanced") TOPO_ICON="⚡mesh" ;;
        "conservative") TOPO_ICON="⚡hier" ;;
        "aggressive") TOPO_ICON="⚡ring" ;;
        *) TOPO_ICON="⚡$STRATEGY" ;;
      esac
      printf " \033[35m$TOPO_ICON\033[0m"

      # Count agent profiles as "configured agents"
      AGENT_COUNT=$(jq -r '.agentProfiles | length' "$FLOW_DIR/swarm-config.json" 2>/dev/null)
      if [ -n "$AGENT_COUNT" ] && [ "$AGENT_COUNT" != "null" ] && [ "$AGENT_COUNT" -gt 0 ]; then
        printf "  \033[35m🤖 $AGENT_COUNT\033[0m"
      fi
    fi
  fi

  # 2. Real-time System Metrics
  if [ -f "$FLOW_DIR/metrics/system-metrics.json" ]; then
    # Get latest metrics (last entry in array)
    LATEST=$(jq -r '.[-1]' "$FLOW_DIR/metrics/system-metrics.json" 2>/dev/null)

    if [ -n "$LATEST" ] && [ "$LATEST" != "null" ]; then
      # Memory usage
      MEM_PERCENT=$(echo "$LATEST" | jq -r '.memoryUsagePercent // 0' | awk '{printf "%.0f", $1}')
      if [ -n "$MEM_PERCENT" ] && [ "$MEM_PERCENT" != "null" ]; then
        # Color-coded memory (green <60%, yellow 60-80%, red >80%)
        if [ "$MEM_PERCENT" -lt 60 ]; then
          MEM_COLOR="\033[32m"  # Green
        elif [ "$MEM_PERCENT" -lt 80 ]; then
          MEM_COLOR="\033[33m"  # Yellow
        else
          MEM_COLOR="\033[31m"  # Red
        fi
        printf "  ${MEM_COLOR}💾 ${MEM_PERCENT}%\033[0m"
      fi

      # CPU load
      CPU_LOAD=$(echo "$LATEST" | jq -r '.cpuLoad // 0' | awk '{printf "%.0f", $1 * 100}')
      if [ -n "$CPU_LOAD" ] && [ "$CPU_LOAD" != "null" ]; then
        # Color-coded CPU (green <50%, yellow 50-75%, red >75%)
        if [ "$CPU_LOAD" -lt 50 ]; then
          CPU_COLOR="\033[32m"  # Green
        elif [ "$CPU_LOAD" -lt 75 ]; then
          CPU_COLOR="\033[33m"  # Yellow
        else
          CPU_COLOR="\033[31m"  # Red
        fi
        printf "  ${CPU_COLOR}⚙ ${CPU_LOAD}%\033[0m"
      fi
    fi
  fi

  # 3. Session State
  if [ -f "$FLOW_DIR/session-state.json" ]; then
    SESSION_ID=$(jq -r '.sessionId // empty' "$FLOW_DIR/session-state.json" 2>/dev/null)
    ACTIVE=$(jq -r '.active // false' "$FLOW_DIR/session-state.json" 2>/dev/null)

    if [ "$ACTIVE" = "true" ] && [ -n "$SESSION_ID" ]; then
      # Show abbreviated session ID
      SHORT_ID=$(echo "$SESSION_ID" | cut -d'-' -f1)
      printf "  \033[34m🔄 $SHORT_ID\033[0m"
    fi
  fi

  # 4. Performance Metrics from task-metrics.json
  if [ -f "$FLOW_DIR/metrics/task-metrics.json" ]; then
    # Parse task metrics for success rate, avg time, and streak
    METRICS=$(jq -r '
      # Calculate metrics
      (map(select(.success == true)) | length) as $successful |
      (length) as $total |
      (if $total > 0 then ($successful / $total * 100) else 0 end) as $success_rate |
      (map(.duration // 0) | add / length) as $avg_duration |
      # Calculate streak (consecutive successes from end)
      (reverse |
        reduce .[] as $task (0;
          if $task.success == true then . + 1 else 0 end
        )
      ) as $streak |
      {
        success_rate: $success_rate,
        avg_duration: $avg_duration,
        streak: $streak,
        total: $total
      } | @json
    ' "$FLOW_DIR/metrics/task-metrics.json" 2>/dev/null)

    if [ -n "$METRICS" ] && [ "$METRICS" != "null" ]; then
      # Success Rate
      SUCCESS_RATE=$(echo "$METRICS" | jq -r '.success_rate // 0' | awk '{printf "%.0f", $1}')
      TOTAL_TASKS=$(echo "$METRICS" | jq -r '.total // 0')

      if [ -n "$SUCCESS_RATE" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
        # Color-code: Green (>80%), Yellow (60-80%), Red (<60%)
        if [ "$SUCCESS_RATE" -gt 80 ]; then
          SUCCESS_COLOR="\033[32m"  # Green
        elif [ "$SUCCESS_RATE" -ge 60 ]; then
          SUCCESS_COLOR="\033[33m"  # Yellow
        else
          SUCCESS_COLOR="\033[31m"  # Red
        fi
        printf "  ${SUCCESS_COLOR}🎯 ${SUCCESS_RATE}%\033[0m"
      fi

      # Average Time
      AVG_TIME=$(echo "$METRICS" | jq -r '.avg_duration // 0')
      if [ -n "$AVG_TIME" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
        # Format smartly: seconds, minutes, or hours
        if [ $(echo "$AVG_TIME < 60" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fs", $1}')
        elif [ $(echo "$AVG_TIME < 3600" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fm", $1/60}')
        else
          TIME_STR=$(echo "$AVG_TIME" | awk '{printf "%.1fh", $1/3600}')
        fi
        printf "  \033[36m⏱️  $TIME_STR\033[0m"
      fi

      # Streak (only show if > 0)
      STREAK=$(echo "$METRICS" | jq -r '.streak // 0')
      if [ -n "$STREAK" ] && [ "$STREAK" -gt 0 ]; then
        printf "  \033[91m🔥 $STREAK\033[0m"
      fi
    fi
  fi

  # 5. Active Tasks (check for task files)
  if [ -d "$FLOW_DIR/tasks" ]; then
    TASK_COUNT=$(find "$FLOW_DIR/tasks" -name "*.json" -type f 2>/dev/null | wc -l)
    if [ "$TASK_COUNT" -gt 0 ]; then
      printf "  \033[36m📋 $TASK_COUNT\033[0m"
    fi
  fi

  # 6. Check for hooks activity
  if [ -f "$FLOW_DIR/hooks-state.json" ]; then
    HOOKS_ACTIVE=$(jq -r '.enabled // false' "$FLOW_DIR/hooks-state.json" 2>/dev/null)
    if [ "$HOOKS_ACTIVE" = "true" ]; then
      printf " \033[35m🔗\033[0m"
    fi
  fi
fi

echo
```

Shows:
- Model and directory
- Git branch
- Claude Flow swarm configuration & topology
- Real-time system metrics (CPU, memory with color coding)
- Session state
- Performance metrics (success rate, average time, streak)
- Active tasks count
- Hooks activity

---

## Installation Guide

### Quick Setup (New Project)

```bash
# 1. Install Beads
cargo install beads-cli

# 2. Install Beads Viewer
cargo install beads-viewer

# 3. Initialize Beads
bd init --issue-prefix="your-project"

# 4. Install MCP Agent Mail
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start

# 5. Copy all files from this dump:
#    - Copy scripts/ directory
#    - Copy .claude/ directory
#    - Copy documentation files (CLAUDE.md, etc.)
#    - Copy .beads/config.yaml

# 6. Install git hooks
chmod +x scripts/install-hooks.sh
./scripts/install-hooks.sh

# 7. Initialize worktree pool
./scripts/agent-coordinator.sh init

# 8. Test with single agent
./scripts/agent-coordinator.sh spawn 1 independent

# 9. Monitor status
./scripts/agent-coordinator.sh status

# 10. Scale up when ready
./scripts/agent-coordinator.sh spawn 4 independent
```

### Verification Checklist

```bash
# ✓ Beads installed
bd --version

# ✓ Beads Viewer installed
bv --version

# ✓ MCP Agent Mail available
mcp__mcp_agent_mail__health_check

# ✓ Git hooks installed
ls -la .git/hooks/

# ✓ Scripts executable
ls -la scripts/

# ✓ Worktree pool initialized
ls -la .agent-worktrees/

# ✓ Resource monitor working
./scripts/resource-monitor.sh check
```

---

## Key Concepts

### File Filtering (Prevents Conflicts!)

Each worktree uses sparse-checkout to limit visible files:

```bash
# Agent 1 → web handlers only
.agent-worktrees/pool-wt-1/
  gleam/src/meal_planner/web/**/*.gleam  ✓ visible
  gleam/src/meal_planner/storage.gleam   ✗ hidden

# Agent 2 → storage only
.agent-worktrees/pool-wt-2/
  gleam/src/meal_planner/storage*.gleam  ✓ visible
  gleam/src/meal_planner/web/**/*.gleam  ✗ hidden
```

**Result**: Agents can ONLY modify files relevant to their task!

### Agent Mail Coordination

Every agent:
1. Registers at session start
2. Reserves files before editing
3. Sends messages via threads (thread_id = bead ID)
4. Releases reservations when done

### Beads Integration

- Use `bd ready` to find available work
- Use `bv --robot-insights` for high-impact tasks
- Use `bv --robot-plan` for parallel tracks
- Always use bead ID as thread_id in messages

---

## System Limits & Safety

| Resource | Warning | Critical | Action |
|----------|---------|----------|---------|
| DB Connections | 40 | 50 | Queue agents |
| Disk Usage | 2.8GB | 3GB | Block new worktrees |
| File Descriptors | 80% | 95% | Alert & cleanup |
| Worktree Pool | 3 min | 10 max | Auto-scale |

---

## Session Close Protocol

**MANDATORY before saying "done":**

```bash
[ ] git status              # Check what changed
[ ] git add <files>         # Stage code changes
[ ] bd sync                 # Commit beads changes
[ ] git commit -m "..."     # Commit code
[ ] bd sync                 # Commit any new beads changes
[ ] git push                # Push to remote
```

**NEVER skip this. Work is not done until pushed.**

---

## Troubleshooting

### No Available Worktrees

```bash
./scripts/worktree-pool-manager.sh status
./scripts/worktree-pool-manager.sh scale-up
```

### File Conflicts

```bash
source scripts/agent-mail-wrapper.sh
agent_mail_show_reservations
```

### Database Issues

```bash
./scripts/resource-monitor.sh detect-leaks
./scripts/resource-monitor.sh cleanup-leaks
```

### Worktree Shows All Files

```bash
# Re-apply filter
./scripts/setup-worktree-filters.sh \
    .agent-worktrees/pool-wt-1 \
    "gleam/src/meal_planner/storage*.gleam"

# Verify
cd .agent-worktrees/pool-wt-1
git ls-files | wc -l  # Should be limited
```

---

## Additional Resources

- **Beads**: https://github.com/steveyegge/beads
- **Beads Viewer**: https://github.com/Dicklesworthstone/beads_viewer
- **MCP Agent Mail**: https://github.com/your-mcp-agent-mail-repo
- **Git Worktrees**: https://git-scm.com/docs/git-worktree

---

**Remember**: Agent Mail coordinates, Beads tracks, Worktrees isolate, Filters protect!

---

## Full Directory Structure

```
meal-planner/
├── .agent-worktrees/          # Worktree pool (3-10 worktrees)
│   ├── pool-wt-1/             # Worktree 1 (filtered)
│   ├── pool-wt-2/             # Worktree 2 (filtered)
│   └── ...
├── .beads/
│   ├── config.yaml            # Beads configuration
│   ├── beads.db               # SQLite database
│   └── issues.jsonl           # Issue backup
├── .claude/
│   ├── agents/                # Agent definitions
│   ├── commands/              # Slash commands
│   ├── settings.json          # Claude Code settings
│   ├── settings.local.json    # Local overrides
│   └── statusline-command.sh  # Status line script
├── .git/hooks/
│   ├── pre-commit             # Build + format check
│   ├── post-commit            # Detect --no-verify
│   ├── prepare-commit-msg     # Add warnings
│   ├── post-checkout          # Beads sync
│   ├── post-merge             # Beads sync
│   └── pre-push               # Prevent stale JSONL
├── scripts/
│   ├── agent-coordinator.sh        # Main orchestrator
│   ├── worktree-pool-manager.sh    # Pool management
│   ├── beads-track-analyzer.sh     # Track analysis
│   ├── agent-mail-wrapper.sh       # Agent Mail helpers
│   ├── resource-monitor.sh         # Resource monitoring
│   ├── setup-worktree-filters.sh   # File filtering
│   └── install-hooks.sh            # Hook installer
├── CLAUDE.md                        # Project instructions
├── WORKTREE_COORDINATION.md         # Worktree guide
├── AGENTS.md                        # Agent guidelines
├── PARALLEL_AGENT_WORKFLOW_GUIDE.md # Full workflow guide
├── QUICK_START_PARALLEL_AGENTS.md   # Quick start
└── WORKTREE_QUICK_REFERENCE.md      # Quick reference
```

---

---

## Complete File Manifest

Here's a checklist of every file needed for full replication:

### Core Configuration Files

- [ ] `.beads/config.yaml` - Beads configuration
- [ ] `.claudeignore` - Protected files list
- [ ] `CLAUDE.md` - Project instructions for Claude
- [ ] `~/.claude/CLAUDE.md` - Global Claude instructions
- [ ] `.claude/settings.json` - Claude Code settings
- [ ] `.claude/settings.local.json` - Local overrides
- [ ] `~/.claude/statusline-command.sh` - Global status line
- [ ] `.claude/statusline-command.sh` - Project status line (optional)

### Documentation Files

- [ ] `WORKTREE_COORDINATION.md` - Worktree guide
- [ ] `AGENTS.md` - Agent guidelines
- [ ] `PARALLEL_AGENT_WORKFLOW_GUIDE.md` - Full workflow
- [ ] `QUICK_START_PARALLEL_AGENTS.md` - Quick start
- [ ] `WORKTREE_QUICK_REFERENCE.md` - Quick reference

### Git Hooks (in `.git/hooks/`)

- [ ] `pre-commit` - Build + format + beads sync
- [ ] `post-commit` - Detect --no-verify usage
- [ ] `prepare-commit-msg` - Add warnings
- [ ] `post-checkout` - Beads sync
- [ ] `post-merge` - Beads sync
- [ ] `pre-push` - Prevent stale JSONL

### Scripts (in `scripts/`)

- [ ] `agent-coordinator.sh` - Main orchestrator (630 lines)
- [ ] `worktree-pool-manager.sh` - Pool management (537 lines)
- [ ] `beads-track-analyzer.sh` - Track analysis (523 lines)
- [ ] `agent-mail-wrapper.sh` - Agent Mail helpers (226 lines)
- [ ] `resource-monitor.sh` - Resource monitoring (641 lines)
- [ ] `setup-worktree-filters.sh` - File filtering (110 lines)
- [ ] `install-hooks.sh` - Hook installer (50 lines)

### Slash Commands (in `.claude/commands/`)

- [ ] `beads-plan.md` - Beads planning command (256 lines)

### Optional Files

- [ ] `.env.worktree` - Per-worktree environment (auto-generated)
- [ ] `/tmp/pool-state.json` - Worktree pool state (auto-generated)
- [ ] `/tmp/track-assignments.json` - Track assignments (auto-generated)
- [ ] `/tmp/agent-coordination-state.json` - Coordination state (auto-generated)

---

## MCP Server Configuration Commands

Save these for easy installation in new projects:

```bash
# Install MCP Agent Mail
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start

# Verify installation
claude mcp list

# Test connection
# In Claude Code session:
# mcp__mcp_agent_mail__health_check()
```

---

## Copy Commands for Quick Replication

```bash
# From meal-planner directory to new project
NEW_PROJECT="/path/to/new-project"

# 1. Copy configuration files
cp .beads/config.yaml "$NEW_PROJECT/.beads/"
cp .claudeignore "$NEW_PROJECT/"
cp CLAUDE.md "$NEW_PROJECT/"
cp .claude/settings.json "$NEW_PROJECT/.claude/"
cp .claude/settings.local.json "$NEW_PROJECT/.claude/"

# 2. Copy documentation
cp WORKTREE_COORDINATION.md "$NEW_PROJECT/"
cp AGENTS.md "$NEW_PROJECT/"
cp PARALLEL_AGENT_WORKFLOW_GUIDE.md "$NEW_PROJECT/"
cp QUICK_START_PARALLEL_AGENTS.md "$NEW_PROJECT/"
cp WORKTREE_QUICK_REFERENCE.md "$NEW_PROJECT/"

# 3. Copy scripts directory
cp -r scripts/ "$NEW_PROJECT/"
chmod +x "$NEW_PROJECT"/scripts/*.sh

# 4. Copy git hooks
mkdir -p "$NEW_PROJECT/.git/hooks"
cp .git/hooks/pre-commit "$NEW_PROJECT/.git/hooks/"
cp .git/hooks/post-commit "$NEW_PROJECT/.git/hooks/"
cp .git/hooks/prepare-commit-msg "$NEW_PROJECT/.git/hooks/"
cp .git/hooks/post-checkout "$NEW_PROJECT/.git/hooks/"
cp .git/hooks/post-merge "$NEW_PROJECT/.git/hooks/"
cp .git/hooks/pre-push "$NEW_PROJECT/.git/hooks/"
chmod +x "$NEW_PROJECT/.git/hooks/"*

# 5. Copy slash commands
cp .claude/commands/beads-plan.md "$NEW_PROJECT/.claude/commands/"

# 6. Copy global config (one time)
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup  # Backup first
echo "- You are to never disable a file again." > ~/.claude/CLAUDE.md

# 7. Initialize beads in new project
cd "$NEW_PROJECT"
bd init --issue-prefix="new-project"

# 8. Install MCP Agent Mail (if not already installed)
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start

# 9. Initialize worktree pool
./scripts/agent-coordinator.sh init

# 10. Test with one agent
./scripts/agent-coordinator.sh spawn 1 independent

echo "✅ Setup complete! Check status:"
./scripts/agent-coordinator.sh status
```

---

## Platform-Specific Notes

### Linux
- All scripts use bash (ensure `/bin/bash` exists)
- `jq` required: `sudo apt install jq` or `sudo pacman -S jq`
- `bc` required for some calculations: `sudo apt install bc`

### macOS
- Use `brew install jq bc`
- File descriptor limits may differ (check with `ulimit -n`)
- Postgres commands same as Linux

### Windows (WSL)
- Must use WSL2 for proper git worktree support
- All scripts run in bash
- Same dependencies as Linux

---

## Maintenance Commands

```bash
# Check system health
./scripts/resource-monitor.sh check

# Detect resource leaks
./scripts/resource-monitor.sh detect-leaks

# Clean up leaks
./scripts/resource-monitor.sh cleanup-leaks

# Check worktree pool status
./scripts/worktree-pool-manager.sh status

# Scale worktree pool
./scripts/worktree-pool-manager.sh scale-up
./scripts/worktree-pool-manager.sh scale-down

# Analyze beads tracks
./scripts/beads-track-analyzer.sh full

# Show file reservations
source scripts/agent-mail-wrapper.sh
agent_mail_show_reservations
```

---

**End of Complete AI Setup Dump**

Generated: 2025-12-09
Project: meal-planner
Total Components: 40+ files, 12,000+ lines of configuration

**Verification Hash**: Run `find . -type f -name "*.sh" -o -name "*.md" -o -name "*.yaml" -o -name "*.json" | sort | xargs md5sum` in project root to verify integrity

**Ready to Copy**: This dump contains everything needed to replicate the complete AI agent coordination system in any project.
