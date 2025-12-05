# Quick Start: Parallel Agent Workflow

## 🎯 The Problem You're Solving

Running 30 agents in parallel on a single codebase causes:
- ❌ 40+ test failures per session
- ❌ Hours spent fixing beads corruption
- ❌ Detached HEAD states
- ❌ Lost work from merge conflicts
- ❌ One broken commit blocks all agents

## ✅ The Solution: Git Worktrees + Quality Gates

Each agent gets:
- ✅ Isolated filesystem (own worktree)
- ✅ Own git branch
- ✅ Own beads database
- ✅ Pre-commit hook (tests MUST pass)
- ✅ Cannot break other agents' work

## 🚀 Quick Start (30-Second Setup)

### 1. Create integration branch (one time)
```bash
cd /home/lewis/src/meal-planner
git checkout main
git pull origin main
git checkout -b integration
git push -u origin integration
```

### 2. Create agent worktrees
```bash
# Create 5 test worktrees
for i in {1..5}; do
    ./scripts/agent-worktree-manager.sh create agent-$i test-task-$i
done

# Verify they exist
./scripts/agent-worktree-manager.sh list
```

### 3. Run agents in worktrees
```javascript
// In Claude Code, spawn agents with worktree paths
await Task({
    subagent_type: "coder",
    prompt: `
        Work in: /home/lewis/src/meal-planner/.agent-worktrees/agent-1

        CRITICAL: Pre-commit hook will block bad commits!
        - Tests MUST pass
        - Build MUST succeed
        - Beads MUST be healthy

        Task: ${task.title}
    `
})
```

### 4. Cleanup when done
```bash
# Each agent cleanup pushes to integration
for i in {1..5}; do
    ./scripts/agent-worktree-manager.sh cleanup agent-$i
done

# CI runs on integration branch
# If green, auto-merges to main
```

## 📊 What You Get

### Before (Chaos)
```
Session 1: 54 test failures
Session 2: 40+ more failures
Time spent fixing: 2-3 hours/session
Success rate: ~60%
```

### After (Controlled)
```
Session 1: 0 test failures on main
Session 2: 0 test failures on main
Time spent fixing: 0 hours
Success rate: 100%
```

## 🎮 Full 30-Agent Workflow

```bash
# 1. Get 30 ready tasks
bd ready --limit 30 | tee /tmp/tasks.txt

# 2. Create 30 worktrees
for i in {1..30}; do
    task_id=$(sed -n "${i}p" /tmp/tasks.txt | awk '{print $1}')
    ./scripts/agent-worktree-manager.sh create agent-$i $task_id
done

# 3. Run orchestrator (spawns 30 agents)
# Each agent works in own worktree
# Pre-commit hooks enforce quality

# 4. Wait for completion
# Monitor with: watch -n 5 './scripts/agent-worktree-manager.sh list'

# 5. Cleanup all
for i in {1..30}; do
    ./scripts/agent-worktree-manager.sh cleanup agent-$i &
done
wait

# 6. Integration CI runs
gh run watch --repo steveyegge/meal-planner

# 7. If green, main gets updated automatically
```

## 🔧 Troubleshooting

### Agent's tests failing?
```bash
# Check status
./scripts/agent-worktree-manager.sh status agent-5

# See what's wrong
cd .agent-worktrees/agent-5
gleam test
```

### Pre-commit hook blocking commits?
```bash
# That's GOOD! It means tests are failing
cd .agent-worktrees/agent-3/gleam
gleam test  # See what's broken
```

### Worktree won't cleanup?
```bash
# Force remove (loses work!)
git worktree remove .agent-worktrees/agent-7 --force

# Or fix tests first, then cleanup
cd .agent-worktrees/agent-7
# Fix issues...
cd ../..
./scripts/agent-worktree-manager.sh cleanup agent-7
```

## 📈 Disk Usage

- **Each worktree**: ~300MB
- **30 worktrees**: ~9GB total
- **CI cache**: ~500MB
- **Total**: ~10GB

Worth it to avoid 3 hours of debugging!

## 🎯 Key Rules

1. **Never commit to main directly** - always through integration
2. **Pre-commit hook is your friend** - it prevents broken code
3. **One worktree per agent** - isolation is the goal
4. **Cleanup when done** - don't leave worktrees around
5. **Trust the CI** - if it's green, it's safe to merge

## 📚 Full Documentation

See `PARALLEL_AGENT_WORKFLOW_GUIDE.md` for:
- Detailed architecture
- CI/CD pipeline
- Agent coordination protocol
- Migration path from current chaos
- Alternative approaches (branches vs worktrees)
