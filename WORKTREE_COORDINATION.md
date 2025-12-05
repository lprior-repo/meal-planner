# Worktree Coordination System

**Prevents AI agents from trampling over each other during parallel work!**

## Overview

This system uses **git worktrees** + **file filtering** + **Agent Mail coordination** to allow multiple AI agents to work on different tasks simultaneously without conflicts.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Agent Coordinator                         │
│  - Orchestrates agent assignments                           │
│  - Integrates Beads, Worktrees, Agent Mail, Resources      │
└─────────────────────────────────────────────────────────────┘
           │              │              │              │
           ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Worktree    │ │    Beads     │ │  Agent Mail  │ │  Resource    │
│  Pool        │ │    Track     │ │  File Res    │ │  Monitor     │
│  Manager     │ │    Analyzer  │ │  & Messaging │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

## Components

### 1. **Worktree Pool Manager** (`worktree-pool-manager.sh`)
- Manages 3-10 git worktrees
- Dynamic pool with queueing
- Automatic scaling based on load
- Each worktree is isolated

### 2. **Beads Track Analyzer** (`beads-track-analyzer.sh`)
- Analyzes dependency graph
- Identifies parallel execution tracks
- Recommends worktree assignments
- Detects file conflicts

### 3. **Agent Mail Integration** (`agent-mail-wrapper.sh`)
- Agent registration
- File reservation coordination
- Inter-agent messaging
- Conflict resolution

### 4. **Resource Monitor** (`resource-monitor.sh`)
- Database connection tracking
- File descriptor monitoring
- Disk space limits
- Leak detection & cleanup

### 5. **Worktree File Filters** (`setup-worktree-filters.sh`)
- **THE KEY TO PREVENTING CONFLICTS!**
- Uses git sparse-checkout per worktree
- Limits visible files based on task
- Prevents accidental modifications

### 6. **Agent Coordinator** (`agent-coordinator.sh`)
- **Main orchestration script**
- Ties everything together
- Spawns and manages agents
- Monitors system health

## How File Filtering Prevents Conflicts

Each worktree gets a **sparse-checkout** configuration that limits which files it can see:

```bash
# Agent 1 working on web handlers
Worktree: pool-wt-1
Visible files: gleam/src/meal_planner/web/**/*.gleam

# Agent 2 working on storage
Worktree: pool-wt-2
Visible files: gleam/src/meal_planner/storage*.gleam

# Agent 3 working on UI
Worktree: pool-wt-3
Visible files: gleam/src/meal_planner/ui/**/*.gleam
```

**Result**: Each agent can ONLY modify files relevant to their task. Git prevents accidental edits to other files.

## Quick Start

### 1. Initialize the System

```bash
./scripts/agent-coordinator.sh init
```

This will:
- Create 4 worktrees in `.agent-worktrees/`
- Initialize resource monitoring
- Set up coordination state

### 2. Spawn Agents for Parallel Work

```bash
# Spawn 4 agents for independent tracks
./scripts/agent-coordinator.sh spawn 4 independent

# Or spawn for all available tracks
./scripts/agent-coordinator.sh spawn 6 all
```

This will:
- Analyze beads dependency graph
- Select appropriate tracks
- Assign worktrees to agents
- Configure file filters
- Reserve files via Agent Mail

### 3. Monitor System Status

```bash
# One-time status check
./scripts/agent-coordinator.sh status

# Continuous monitoring
./scripts/agent-coordinator.sh monitor
```

### 4. Cleanup When Done

```bash
./scripts/agent-coordinator.sh cleanup
```

## Manual Agent Workflow

If you want to manually assign an agent to a track:

### Step 1: Pick a Track

```bash
# See available independent tracks
./scripts/beads-track-analyzer.sh analyze

# Or get recommendations
./scripts/beads-track-analyzer.sh recommend
```

### Step 2: Assign Agent to Worktree

```bash
./scripts/agent-coordinator.sh assign MyAgent meal-planner-abc123
```

### Step 3: Work in the Worktree

```bash
cd .agent-worktrees/pool-wt-1

# The worktree is already filtered to show only relevant files!

# Start work
bd update meal-planner-abc123 --status=in_progress

# Make changes (only to visible files)
vim gleam/src/meal_planner/web/handlers/dashboard.gleam

# Run tests
gleam test

# Commit and close
git add .
git commit -m "[meal-planner-abc123] Implement dashboard handler"
bd close meal-planner-abc123
bd sync
git push
```

## File Reservation Protocol

When an agent is assigned to a track, files are automatically reserved:

```bash
# Automatically called by agent-coordinator
agent_mail_reserve_files "Agent-1" "meal-planner-abc123" "gleam/src/meal_planner/web/**/*.gleam"
```

Other agents attempting to modify reserved files will:
1. Receive a conflict warning
2. Be blocked by sparse-checkout (files not visible)
3. Need to coordinate via Agent Mail

## Advanced Features

### Dynamic Pool Scaling

```bash
# Check pool status
./scripts/worktree-pool-manager.sh status

# Manually scale up (if queue is growing)
./scripts/worktree-pool-manager.sh scale-up

# Scale down (if idle worktrees exist)
./scripts/worktree-pool-manager.sh scale-down
```

### Conflict Detection

```bash
# Detect potential file conflicts between tracks
./scripts/beads-track-analyzer.sh conflicts

# Full analysis report
./scripts/beads-track-analyzer.sh full
```

### Resource Monitoring

```bash
# Run checks once
./scripts/resource-monitor.sh check

# Detect leaks (orphan DBs, zombie processes, stale locks)
./scripts/resource-monitor.sh detect-leaks

# Auto-cleanup leaks
./scripts/resource-monitor.sh cleanup-leaks

# Start background monitoring daemon
./scripts/resource-monitor.sh start

# Stop daemon
./scripts/resource-monitor.sh stop
```

### Manual File Filter Setup

If you need to manually configure a worktree's file filter:

```bash
./scripts/setup-worktree-filters.sh \
    .agent-worktrees/pool-wt-1 \
    "gleam/src/meal_planner/web/**/*.gleam gleam/test/meal_planner/web/**/*.gleam"
```

## Database Isolation

Each worktree uses its own PostgreSQL database:

```
Worktree: pool-wt-1 → Database: meal_planner_wt-1
Worktree: pool-wt-2 → Database: meal_planner_wt-2
Worktree: pool-wt-3 → Database: meal_planner_wt-3
...
```

This prevents test interference between agents.

## Safety Limits

The system enforces these limits:

| Resource | Warning | Critical |
|----------|---------|----------|
| DB Connections | 40 | 50 |
| Disk Usage | 2.8GB | 3GB |
| File Descriptors | 80% | 95% |
| Pool Size | 3 min | 10 max |

When limits are hit:
- Warnings are logged
- Resource monitor alerts
- New agent spawns are queued
- Auto-scale triggers (if below max)

## Troubleshooting

### "No available worktrees"

```bash
# Check pool status
./scripts/worktree-pool-manager.sh status

# Scale up if needed
./scripts/worktree-pool-manager.sh scale-up

# Or wait for agent to release worktree
```

### "File conflict detected"

```bash
# Check active reservations
source scripts/agent-mail-wrapper.sh
agent_mail_show_reservations

# Wait for reservation to expire (1 hour TTL)
# Or coordinate with other agent to release early
```

### "Database connection limit"

```bash
# Check resource status
./scripts/resource-monitor.sh status

# Find orphan databases
./scripts/resource-monitor.sh detect-leaks

# Cleanup
./scripts/resource-monitor.sh cleanup-leaks
```

### "Worktree shows all files"

The sparse-checkout filter wasn't applied:

```bash
# Re-apply filter
./scripts/setup-worktree-filters.sh \
    .agent-worktrees/pool-wt-1 \
    "gleam/src/meal_planner/storage*.gleam"

# Verify
cd .agent-worktrees/pool-wt-1
git ls-files | wc -l  # Should be limited, not full repo
```

## Best Practices

### 1. **Always use agent-coordinator.sh**

Don't manually create worktrees - let the coordinator manage them:

```bash
# ✓ Good
./scripts/agent-coordinator.sh spawn 4 independent

# ✗ Bad
git worktree add .agent-worktrees/my-wt
```

### 2. **Let file filters do their job**

If a file isn't visible in your worktree, there's a reason:

```bash
# ✓ Good - work within your filter
vim gleam/src/meal_planner/web/handlers/home.gleam

# ✗ Bad - trying to edit files outside your scope
vim gleam/src/meal_planner/storage.gleam  # Won't exist in your worktree!
```

### 3. **Close beads when done**

This releases the worktree and file reservations:

```bash
bd close meal-planner-abc123
# Automatically triggers cleanup
```

### 4. **Monitor resource usage**

Run periodic checks during long sessions:

```bash
./scripts/resource-monitor.sh check
```

### 5. **Clean up regularly**

```bash
# At end of session
./scripts/agent-coordinator.sh cleanup

# Periodic leak detection
./scripts/resource-monitor.sh detect-leaks
./scripts/resource-monitor.sh cleanup-leaks
```

## Architecture Decisions

### Why Sparse-Checkout?

Alternative approaches considered:
- ❌ Manual coordination: Too error-prone
- ❌ File locking: Doesn't work with git
- ❌ Separate repos: Too complex
- ✅ **Sparse-checkout**: Native git feature, enforced by VCS

### Why Separate Databases?

- Test isolation (no interference)
- Resource tracking per agent
- Easy cleanup (drop DB when done)
- Parallel test execution

### Why Agent Mail?

- Async coordination (no blocking)
- Audit trail (all messages logged)
- File reservation protocol
- Cross-project coordination

## File Structure

```
meal-planner/
├── .agent-worktrees/          # Worktree pool
│   ├── pool-wt-1/             # Worktree 1
│   │   ├── .git/
│   │   │   └── info/
│   │   │       └── sparse-checkout  # File filter!
│   │   └── .env.worktree      # DB config
│   ├── pool-wt-2/             # Worktree 2
│   └── ...
├── scripts/
│   ├── agent-coordinator.sh        # Main orchestrator
│   ├── worktree-pool-manager.sh   # Pool management
│   ├── beads-track-analyzer.sh    # Track analysis
│   ├── agent-mail-wrapper.sh      # Agent Mail calls
│   ├── resource-monitor.sh        # Resource monitoring
│   └── setup-worktree-filters.sh  # File filtering
└── /tmp/
    ├── pool-state.json              # Pool state
    ├── agent-coordination-state.json # Coordination
    ├── resource-monitor-state.json  # Resources
    ├── file-reservations.json       # Reservations
    └── agent-mail-calls.jsonl       # Message log
```

## Next Steps

1. **Run initialization**:
   ```bash
   ./scripts/agent-coordinator.sh init
   ```

2. **Test with 2 agents**:
   ```bash
   ./scripts/agent-coordinator.sh spawn 2 independent
   ```

3. **Monitor progress**:
   ```bash
   ./scripts/agent-coordinator.sh monitor
   ```

4. **Scale up as needed**:
   ```bash
   ./scripts/agent-coordinator.sh spawn 4 independent
   ```

## Support

For issues or questions:
- Check `./scripts/agent-coordinator.sh` help
- Review `/tmp/agent-mail-calls.jsonl` for coordination log
- Run `./scripts/resource-monitor.sh report` for diagnostics
- Check beads with `bd doctor`

---

**Remember**: The file filtering is what prevents conflicts. Trust the sparse-checkout!
