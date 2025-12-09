#!/bin/bash
# Agent Worktree Manager - Isolate parallel agent work
# Usage: ./agent-worktree-manager.sh {create|cleanup|list|status} <agent-id> [task-id]

set -euo pipefail

WORKTREE_DIR=".agent-worktrees"
MAIN_BRANCH="main"
INTEGRATION_BRANCH="integration"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Create isolated worktree for agent
create_agent_worktree() {
    local agent_id=$1
    local task_id=${2:-"no-task"}

    if [ -z "$agent_id" ]; then
        error "Agent ID required"
    fi

    # Create worktree directory
    mkdir -p "${WORKTREE_DIR}"

    # Check if worktree already exists
    if [ -d "${WORKTREE_DIR}/${agent_id}" ]; then
        error "Worktree already exists: ${WORKTREE_DIR}/${agent_id}"
    fi

    # Create unique branch name
    local branch="agent-${agent_id}/${task_id}"

    echo "📦 Creating worktree for ${agent_id}..."

    # Create worktree from main
    git worktree add "${WORKTREE_DIR}/${agent_id}" -b "${branch}" "${MAIN_BRANCH}" || error "Failed to create worktree"

    cd "${WORKTREE_DIR}/${agent_id}"

    # Initialize beads with correct prefix
    if [ ! -d ".beads" ]; then
        bd init --issue-prefix="meal-planner" || warning "Beads init failed"
    fi

    # Install pre-commit hook
    cat > .git/hooks/pre-commit << 'HOOK_EOF'
#!/bin/bash
# Pre-commit quality gate

echo "🔍 Running pre-commit quality checks..."

# 1. Build check
echo "  📦 Building..."
cd gleam
if ! gleam build 2>&1 | tail -20; then
    echo "❌ Build failed - commit blocked"
    exit 1
fi

# 2. Test check
echo "  🧪 Running tests..."
if ! gleam test 2>&1 | tail -50; then
    echo "❌ Tests failed - commit blocked"
    exit 1
fi

cd ..

# 3. Beads sync
if [ -d ".beads" ]; then
    echo "  📋 Syncing beads..."
    bd sync --flush-only || echo "⚠️  Beads sync failed (non-blocking)"
fi

# 4. Check for test database leaks
echo "  🔍 Checking for test database leaks..."
test_dbs=$(psql -U postgres -lqt 2>/dev/null | grep -c "test_db_" || echo "0")
if [ "$test_dbs" -gt 0 ]; then
    echo "⚠️  Warning: ${test_dbs} test databases still running"
    echo "   These will be cleaned up automatically"
fi

echo "✅ All pre-commit checks passed"
HOOK_EOF

    chmod +x .git/hooks/pre-commit

    cd ../..

    success "Worktree created: ${WORKTREE_DIR}/${agent_id}"
    echo "   Branch: ${branch}"
    echo "   Task: ${task_id}"
    echo "   Path: $(pwd)/${WORKTREE_DIR}/${agent_id}"
}

# Cleanup agent worktree
cleanup_agent_worktree() {
    local agent_id=$1

    if [ -z "$agent_id" ]; then
        error "Agent ID required"
    fi

    if [ ! -d "${WORKTREE_DIR}/${agent_id}" ]; then
        error "Worktree does not exist: ${WORKTREE_DIR}/${agent_id}"
    fi

    echo "🧹 Cleaning up worktree: ${agent_id}..."

    # Verify tests pass before cleanup
    cd "${WORKTREE_DIR}/${agent_id}/gleam"

    echo "  🧪 Running final test check..."
    if ! gleam test > /tmp/agent-${agent_id}-test.log 2>&1; then
        warning "Tests failing in ${agent_id} - cleanup aborted"
        echo "  Log: /tmp/agent-${agent_id}-test.log"
        cat /tmp/agent-${agent_id}-test.log
        cd ../../..
        return 1
    fi

    cd ..

    # Get current branch
    local branch=$(git rev-parse --abbrev-ref HEAD)

    echo "  📤 Pushing to integration branch..."
    git push origin "${branch}:${INTEGRATION_BRANCH}" || warning "Push failed (may need manual resolution)"

    cd ..

    # Remove worktree
    echo "  🗑️  Removing worktree..."
    git worktree remove "${WORKTREE_DIR}/${agent_id}" || error "Failed to remove worktree"

    # Delete branch (optional - keep for audit trail)
    # git branch -D "${branch}"

    success "Worktree cleaned up: ${agent_id}"
}

# List all agent worktrees
list_agent_worktrees() {
    echo "🔍 Active agent worktrees:"
    git worktree list | grep "${WORKTREE_DIR}" || echo "  (none)"
}

# Show status of specific worktree
status_agent_worktree() {
    local agent_id=$1

    if [ -z "$agent_id" ]; then
        error "Agent ID required"
    fi

    if [ ! -d "${WORKTREE_DIR}/${agent_id}" ]; then
        error "Worktree does not exist: ${WORKTREE_DIR}/${agent_id}"
    fi

    cd "${WORKTREE_DIR}/${agent_id}"

    echo "📊 Status for ${agent_id}:"
    echo ""
    echo "Branch:"
    git rev-parse --abbrev-ref HEAD
    echo ""
    echo "Git status:"
    git status --short
    echo ""
    echo "Recent commits:"
    git log --oneline -5
    echo ""

    if [ -d ".beads" ]; then
        echo "Beads stats:"
        bd stats 2>/dev/null || echo "  (beads not initialized)"
    fi

    cd ../..
}

# Main command dispatcher
case "${1:-}" in
    create)
        create_agent_worktree "${2:-}" "${3:-}"
        ;;
    cleanup)
        cleanup_agent_worktree "${2:-}"
        ;;
    list)
        list_agent_worktrees
        ;;
    status)
        status_agent_worktree "${2:-}"
        ;;
    *)
        echo "Usage: $0 {create|cleanup|list|status} <agent-id> [task-id]"
        echo ""
        echo "Commands:"
        echo "  create <agent-id> <task-id>  - Create new isolated worktree"
        echo "  cleanup <agent-id>           - Verify, push, and remove worktree"
        echo "  list                         - List all active worktrees"
        echo "  status <agent-id>            - Show status of worktree"
        echo ""
        echo "Example:"
        echo "  $0 create agent-1 meal-planner-abc"
        echo "  $0 status agent-1"
        echo "  $0 cleanup agent-1"
        exit 1
        ;;
esac
