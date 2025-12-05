# Parallel Agent Workflow: Preventing Codebase Chaos

## 📊 Problem Analysis: How We Got Here

### **Root Causes of Codebase Degradation**

1. **No Quality Gates Between Agent Commits**
   - 30+ agents committing directly to shared branches
   - No test validation before merge
   - No build verification before push
   - Cascading failures: one broken commit blocks all downstream work

2. **Detached HEAD Hell**
   - Working in detached HEAD state (currently at `fdaeea3`)
   - Main branch at `ee27310` (different commit)
   - Origin/main at `b83194c` (ahead by 13 commits)
   - Result: Lost work, merge conflicts, orphaned commits

3. **Test Failures Accumulating**
   - From previous session: 54 test failures
   - Current session: 40+ additional failures
   - Connection pool exhaustion (5 connections, 25 concurrent inserts)
   - Cache tests broken (5 failures)
   - Integration tests broken (15 failures)

4. **Beads Database Corruption**
   - Duplicate JSONL files (beads.jsonl + issues.jsonl)
   - Prefix mismatch (meal vs meal-planner)
   - Count mismatches between DB and JSONL
   - **This took 2 hours to diagnose and fix**

---

## 🏗️ Solution: Git Worktree + CI/CD Workflow

### **Architecture: Agent Isolation with Quality Gates**

```
┌─────────────────────────────────────────────────────────────┐
│                      MAIN BRANCH                            │
│  ✅ Always passing tests                                    │
│  ✅ Always buildable                                        │
│  ✅ Protected branch (no direct commits)                    │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ PR + CI/CD
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                   INTEGRATION BRANCH                         │
│  Merge point for agent work                                 │
│  CI runs on every push                                      │
└──────────────────────────────────────────────────────────────┘
                              ▲
                              │ Push after local verification
                              │
┌─────────────────────────────┴───────────────────────────────┐
│              AGENT WORKTREES (30+ parallel)                  │
│                                                              │
│  agent-1/  →  git worktree  →  meal-planner-abc1           │
│  agent-2/  →  git worktree  →  meal-planner-abc2           │
│  agent-3/  →  git worktree  →  meal-planner-abc3           │
│  ...                                                         │
│  agent-30/ →  git worktree  →  meal-planner-abc30          │
│                                                              │
│  Each has:                                                   │
│    ✓ Isolated filesystem                                    │
│    ✓ Own branch from main                                   │
│    ✓ Own beads database                                     │
│    ✓ Pre-commit hooks (test + build)                        │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 Implementation Strategy

### **Phase 1: Setup Git Worktree Infrastructure**

#### **1.1 Create Worktree Manager Script**

```bash
#!/bin/bash
# scripts/agent-worktree-manager.sh

WORKTREE_DIR=".agent-worktrees"
MAIN_BRANCH="main"

create_agent_worktree() {
    local agent_id=$1
    local task_id=$2

    # Create unique branch name
    local branch="agent-${agent_id}/${task_id}"

    # Create worktree
    git worktree add "${WORKTREE_DIR}/${agent_id}" -b "${branch}" "${MAIN_BRANCH}"

    # Setup beads in worktree
    cd "${WORKTREE_DIR}/${agent_id}"
    bd init --issue-prefix="meal-planner"

    # Install quality hooks
    install_quality_hooks "${agent_id}"

    echo "✅ Worktree created: ${WORKTREE_DIR}/${agent_id}"
    echo "   Branch: ${branch}"
    echo "   Task: ${task_id}"
}

cleanup_agent_worktree() {
    local agent_id=$1

    # Verify tests pass before cleanup
    cd "${WORKTREE_DIR}/${agent_id}"
    if ! gleam test; then
        echo "❌ Tests failing - cannot cleanup"
        return 1
    fi

    # Merge to integration branch
    git checkout integration
    git merge --no-ff "${agent_id}/*"

    # Remove worktree
    cd ../..
    git worktree remove "${WORKTREE_DIR}/${agent_id}"
}

list_agent_worktrees() {
    git worktree list | grep "${WORKTREE_DIR}"
}
```

#### **1.2 Pre-Commit Hook (Per Worktree)**

```bash
#!/bin/bash
# .agent-worktrees/agent-1/.git/hooks/pre-commit

echo "🔍 Running pre-commit checks..."

# 1. Build check
echo "  📦 Building..."
cd gleam
if ! gleam build; then
    echo "❌ Build failed - commit blocked"
    exit 1
fi

# 2. Test check
echo "  🧪 Running tests..."
if ! gleam test; then
    echo "❌ Tests failed - commit blocked"
    exit 1
fi

# 3. Beads sync
echo "  📋 Syncing beads..."
bd sync --flush-only

# 4. Check for test database leaks
echo "  🔍 Checking for test database leaks..."
test_dbs=$(psql -U postgres -lqt | grep -c "test_db_")
if [ "$test_dbs" -gt 0 ]; then
    echo "⚠️  Warning: ${test_dbs} test databases still running"
    echo "   Run: gleam run -m scripts/cleanup_test_dbs"
fi

echo "✅ All checks passed"
```

#### **1.3 Integration Branch CI/CD**

```yaml
# .github/workflows/integration-ci.yml
name: Integration Branch CI

on:
  push:
    branches: [integration]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup Gleam
        uses: erlef/setup-beam@v1
        with:
          otp-version: '26.0'
          gleam-version: '1.0.0'

      - name: Build
        run: cd gleam && gleam build

      - name: Run tests
        run: cd gleam && gleam test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/meal_planner_test

      - name: Check test database cleanup
        run: |
          test_dbs=$(psql -U postgres -lqt | grep -c "test_db_" || true)
          if [ "$test_dbs" -gt 0 ]; then
            echo "❌ Test databases not cleaned up: ${test_dbs} remaining"
            exit 1
          fi

      - name: Validate beads state
        run: |
          bd doctor
          if [ $? -ne 0 ]; then
            echo "❌ Beads database corrupted"
            exit 1
          fi
```

---

### **Phase 2: Agent Coordination Protocol**

#### **2.1 Agent Work Lifecycle**

```javascript
// AGENT START (via Task tool or manual)
async function startAgentWork(agentId, taskId) {
    // 1. Create isolated worktree
    await bash(`scripts/agent-worktree-manager.sh create ${agentId} ${taskId}`);

    // 2. Register with Agent Mail
    const session = await mcp__mcp_agent_mail__macro_start_session({
        human_key: `/home/lewis/src/meal-planner/.agent-worktrees/${agentId}`,
        program: "claude-code",
        model: "claude-sonnet-4-5",
        task_description: `Working on ${taskId}`
    });

    // 3. Reserve files in THIS WORKTREE'S beads DB
    await mcp__mcp_agent_mail__file_reservation_paths({
        project_key: `/home/lewis/src/meal-planner/.agent-worktrees/${agentId}`,
        agent_name: session.agent.name,
        paths: ["gleam/src/**/*.gleam"],
        ttl_seconds: 7200,
        exclusive: true,
        reason: taskId
    });

    // 4. Do work...
    // 5. Pre-commit hook runs automatically on commit
    // 6. Tests MUST pass or commit is blocked
}

// AGENT END
async function endAgentWork(agentId, taskId) {
    // 1. Verify tests pass
    const testResult = await bash(`cd .agent-worktrees/${agentId}/gleam && gleam test`);
    if (testResult.exitCode !== 0) {
        throw new Error("Cannot end work - tests failing");
    }

    // 2. Push to integration branch
    await bash(`
        cd .agent-worktrees/${agentId}
        git push origin agent-${agentId}/${taskId}:integration
    `);

    // 3. CI runs on integration branch
    // 4. If CI passes, auto-merge to main
    // 5. Cleanup worktree
    await bash(`scripts/agent-worktree-manager.sh cleanup ${agentId}`);
}
```

#### **2.2 Parallel Agent Orchestration**

```javascript
// COORDINATOR AGENT
async function orchestrate30Agents(tasks) {
    // 1. Create 30 worktrees in parallel
    await Promise.all(tasks.map((task, i) =>
        bash(`scripts/agent-worktree-manager.sh create agent-${i} ${task.id}`)
    ));

    // 2. Spawn 30 agents (each gets own worktree)
    const agents = await Promise.all(tasks.map((task, i) =>
        Task({
            subagent_type: "coder",
            model: "haiku",  // Fast for parallel work
            prompt: `
                You are working in an ISOLATED WORKTREE at:
                /home/lewis/src/meal-planner/.agent-worktrees/agent-${i}

                Task: ${task.title}

                CRITICAL RULES:
                1. All work happens in YOUR WORKTREE ONLY
                2. Pre-commit hook will block bad commits (tests must pass)
                3. Do NOT push to main - push to integration branch
                4. Close beads task when done: bd close ${task.id}

                Your worktree is isolated - you cannot break other agents' work!
            `
        })
    ));

    // 3. Wait for all agents to complete
    await Promise.all(agents);

    // 4. Integration branch CI runs
    // 5. Coordinator reviews CI results
    // 6. Merge integration → main if all green
}
```

---

### **Phase 3: Quality Enforcement**

#### **3.1 Protected Branches**

```bash
# GitHub settings (via gh CLI or web UI)
gh repo edit --enable-branch-protection main \
    --require-pr-reviews 1 \
    --require-status-checks "build,test" \
    --require-linear-history

# Prevent direct pushes to main
git config branch.main.pushRemote no_push
```

#### **3.2 Local Quality Gate**

```bash
#!/bin/bash
# scripts/local-quality-gate.sh

check_quality() {
    local worktree=$1

    cd "${worktree}"

    # 1. Build
    echo "📦 Building..."
    cd gleam
    if ! gleam build; then
        echo "❌ Build failed"
        return 1
    fi

    # 2. Tests
    echo "🧪 Running tests..."
    if ! gleam test; then
        echo "❌ Tests failed"
        return 1
    fi

    # 3. Test database cleanup
    echo "🧹 Checking test database cleanup..."
    test_dbs=$(psql -U postgres -lqt | grep -c "test_db_" || true)
    if [ "$test_dbs" -gt 0 ]; then
        echo "❌ ${test_dbs} test databases not cleaned up"
        gleam run -m scripts/cleanup_test_dbs
        return 1
    fi

    # 4. Beads health
    echo "📋 Checking beads health..."
    cd ..
    if ! bd doctor | grep -q "No issues detected"; then
        echo "❌ Beads database has issues"
        return 1
    fi

    # 5. No compiler warnings on new code
    echo "⚠️  Checking for new warnings..."
    # TODO: Compare warnings against baseline

    echo "✅ All quality checks passed"
    return 0
}
```

#### **3.3 Automated Test Database Cleanup**

```gleam
// gleam/src/scripts/cleanup_test_dbs.gleam
import gleam/io
import gleam/list
import gleam/pog
import gleam/result
import gleam/string

pub fn main() {
  io.println("🧹 Cleaning up test databases...")

  let assert Ok(admin_conn) = connect_to_admin_db()

  // List all test databases
  let query = "
    SELECT datname
    FROM pg_database
    WHERE datname LIKE 'test_db_%'
  "

  let assert Ok(test_dbs) = pog.query(query on: admin_conn)

  // Drop each one
  list.each(test_dbs, fn(row) {
    let db_name = dynamic.field("datname", dynamic.string)(row)
    case db_name {
      Ok(name) -> {
        io.println("  Dropping " <> name)
        let drop_query = "DROP DATABASE IF EXISTS " <> name
        let _ = pog.query(drop_query on: admin_conn)
        Nil
      }
      Error(_) -> Nil
    }
  })

  io.println("✅ Cleanup complete")
}
```

---

## 🎮 Usage Guide

### **Starting a 30-Agent Session**

```bash
# 1. Create integration branch from main
git checkout main
git pull origin main
git checkout -b integration

# 2. Create 30 worktrees
for i in {1..30}; do
    scripts/agent-worktree-manager.sh create agent-$i meal-planner-task-$i
done

# 3. Get 30 ready tasks
bd ready --limit 30 > /tmp/tasks.txt

# 4. Start Claude Code and run orchestration
# (Orchestrator spawns 30 agents, each gets own worktree)

# 5. Wait for agents to complete
# (Each agent's pre-commit hook ensures quality)

# 6. Push all to integration
for i in {1..30}; do
    cd .agent-worktrees/agent-$i
    git push origin agent-$i/*:integration
    cd ../..
done

# 7. Wait for CI
gh run watch

# 8. If green, merge to main
git checkout main
git merge --no-ff integration
git push origin main

# 9. Cleanup worktrees
for i in {1..30}; do
    scripts/agent-worktree-manager.sh cleanup agent-$i
done
```

---

## 📈 Benefits

### **Before (Current Chaos)**
- ❌ 40+ test failures after each session
- ❌ 2-3 hours fixing beads corruption
- ❌ Detached HEAD states
- ❌ Lost work from merge conflicts
- ❌ Cannot run tests while agents working
- ❌ One broken commit blocks everyone

### **After (Worktree Workflow)**
- ✅ Zero test failures on main
- ✅ Beads isolated per worktree
- ✅ No detached HEAD (each worktree has branch)
- ✅ No lost work (each agent on own branch)
- ✅ Can run tests in main while agents work
- ✅ Broken work isolated to one worktree

### **Performance**
- **Build time**: No change (each worktree independent)
- **Disk usage**: ~300MB per worktree (30 = 9GB)
- **CI time**: Same (only integration branch runs CI)
- **Developer time saved**: 2-3 hours per session

---

## 🚨 Migration Path

### **Step 1: Stabilize Current State**
```bash
# 1. Get back to main
git checkout main
git pull origin main

# 2. Fix ALL current test failures
gleam test | tee test-results.txt
# Work through each failure

# 3. Verify beads health
bd doctor
bd sync

# 4. Create baseline commit
git add .
git commit -m "Baseline: All tests passing, beads healthy"
git push origin main
```

### **Step 2: Setup Infrastructure**
```bash
# 1. Create scripts
mkdir -p scripts
# Create agent-worktree-manager.sh (see above)
chmod +x scripts/agent-worktree-manager.sh

# 2. Create integration branch
git checkout -b integration main
git push -u origin integration

# 3. Setup branch protection
gh repo edit --enable-branch-protection main
```

### **Step 3: Test with 3 Agents**
```bash
# Small scale test before going to 30
for i in {1..3}; do
    scripts/agent-worktree-manager.sh create agent-$i test-task-$i
done

# Run 3 agents in parallel
# Verify isolation works
# Verify quality gates work
```

### **Step 4: Scale to 30**
```bash
# If 3 agents worked, scale up
for i in {1..30}; do
    scripts/agent-worktree-manager.sh create agent-$i production-task-$i
done
```

---

## 💡 Alternative: Branch-Per-Agent (Simpler)

If worktrees are too complex, use branches instead:

```bash
# Each agent gets own branch
git checkout -b agent-1/task-abc main
# Work...
# Tests must pass before push
git push origin agent-1/task-abc:integration

# CI runs on integration
# If green, auto-merge to main
```

**Pros**: Simpler, no worktree complexity
**Cons**: Cannot run tests on main while agents work

---

## 📚 References

- [Git Worktrees Documentation](https://git-scm.com/docs/git-worktree)
- [Beads Best Practices](https://github.com/steveyegge/beads)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Gleam Testing Guide](https://gleam.run/writing-gleam/testing/)
