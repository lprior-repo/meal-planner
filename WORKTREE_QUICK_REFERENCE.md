# Worktree Quick Reference

## 🎯 Purpose
Each worktree provides an isolated workspace with enforced quality gates via pre-commit hooks.

## 🚀 Quick Commands

### Create a new agent worktree
```bash
./scripts/agent-worktree-manager.sh create agent-1 meal-planner-abc
```

### List all active worktrees
```bash
./scripts/agent-worktree-manager.sh list
```

### Check worktree status
```bash
./scripts/agent-worktree-manager.sh status agent-1
```

### Cleanup when done (runs tests, pushes to integration)
```bash
./scripts/agent-worktree-manager.sh cleanup agent-1
```

## 🛡️ Pre-Commit Hook Protection

Each worktree automatically gets a pre-commit hook that enforces:

1. **Build must succeed** - `gleam build` passes
2. **All tests must pass** - `gleam test` passes
3. **Beads sync** - Changes flushed to `.beads/`
4. **Database leak check** - No leftover test databases

**The hook CANNOT be bypassed by Claude** - protected by `.claudeignore`

## 🔒 Protected Files (Claude Cannot Edit)

The `.claudeignore` file protects:
- `.git/hooks/*` - All git hooks
- `scripts/pre-commit.sh` - Quality gate script
- `scripts/agent-worktree-manager.sh` - Worktree manager
- `.github/workflows/*` - CI/CD configuration
- Environment files and secrets
- Agent Mail coordination artifacts

## 📋 Typical Workflow

### For 30 Parallel Agents:

```bash
# 1. Get 30 ready tasks
bd ready --limit 30 > /tmp/tasks.txt

# 2. Create 30 worktrees
for i in {1..30}; do
    task_id=$(sed -n "${i}p" /tmp/tasks.txt | awk '{print $1}')
    ./scripts/agent-worktree-manager.sh create agent-$i $task_id
done

# 3. Run agents (each in their own worktree)
# Each agent works in: /home/lewis/src/meal-planner/.agent-worktrees/agent-N

# 4. Monitor progress
watch -n 5 './scripts/agent-worktree-manager.sh list'

# 5. Cleanup when done
for i in {1..30}; do
    ./scripts/agent-worktree-manager.sh cleanup agent-$i &
done
wait
```

### For Single Agent:

```bash
# 1. Create worktree
./scripts/agent-worktree-manager.sh create my-agent meal-planner-123

# 2. Work in worktree
cd .agent-worktrees/my-agent

# 3. Make changes (pre-commit hook runs on commit)
git add .
git commit -m "[meal-planner-123] Implementation"
# Hook ensures tests pass before allowing commit

# 4. When done
cd ../..
./scripts/agent-worktree-manager.sh cleanup my-agent
```

## ⚠️ Troubleshooting

### Pre-commit hook blocks commit
**This is GOOD!** It means tests are failing.

```bash
cd .agent-worktrees/agent-N/gleam
gleam test  # See what's wrong
# Fix issues
cd ..
git add .
git commit -m "fix"  # Hook runs again
```

### Can't cleanup worktree (tests failing)
```bash
# Option 1: Fix the tests
cd .agent-worktrees/agent-N
# Fix issues
cd ../..
./scripts/agent-worktree-manager.sh cleanup agent-N

# Option 2: Force remove (LOSES WORK!)
git worktree remove .agent-worktrees/agent-N --force
```

### Worktree already exists
```bash
# Remove old worktree first
./scripts/agent-worktree-manager.sh cleanup agent-1
# Or force remove if needed
git worktree remove .agent-worktrees/agent-1 --force

# Then create new one
./scripts/agent-worktree-manager.sh create agent-1 new-task
```

## 📊 Disk Usage

- **Per worktree**: ~300MB
- **30 worktrees**: ~9GB
- **Worth it**: Prevents hours of debugging merge conflicts and test failures

## 🎯 Key Rules

1. ✅ **Always create worktree before spawning agent**
2. ✅ **Each agent gets exactly ONE worktree**
3. ✅ **Never bypass the pre-commit hook**
4. ✅ **Always cleanup when done**
5. ✅ **Trust the quality gates**

## 📚 Related Documentation

- `PARALLEL_AGENT_WORKFLOW_GUIDE.md` - Full architecture and rationale
- `QUICK_START_PARALLEL_AGENTS.md` - Getting started guide
- `scripts/PRE_COMMIT_HOOK.md` - Pre-commit hook documentation
- `.claudeignore` - Protected files list
