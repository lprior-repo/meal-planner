# AI Setup Scaffolding Guide for New Gleam Projects

**Companion to**: `AI_SETUP_COMPLETE_DUMP.md`
**Purpose**: Step-by-step guide for creating a brand new Gleam project with full AI coordination
**Generated**: 2025-12-09

---

## Overview

This guide walks you through creating a **new Gleam project from scratch** with the complete AI coordination system. If you already have a Gleam project and just want to add AI coordination, see the "Quick Setup (Existing Project)" section in `AI_SETUP_COMPLETE_DUMP.md`.

### What You'll Build

A Gleam project with:
- ✅ Full AI coordination (parallel agent execution)
- ✅ Quality gates (mandatory build checks, optional tests)
- ✅ Git-based issue tracking (Beads)
- ✅ Agent communication (MCP Agent Mail)
- ✅ Git worktree isolation (3-10 parallel workspaces)
- ✅ Resource monitoring (DB connections, file descriptors, disk)
- ✅ Automatic git hooks (format, build, test enforcement)

### Time Estimate

- **First-time setup**: 30-45 minutes
- **Subsequent projects**: 10-15 minutes

---

## Table of Contents

1. [Prerequisites Installation](#prerequisites-installation)
2. [Step-by-Step Project Creation](#step-by-step-project-creation)
3. [Verification](#verification)
4. [AI Agent Guidance](#ai-agent-guidance)
5. [Template Files](#template-files)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites Installation

### 1. Install Rust (Required for Beads)

```bash
# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Follow the prompts, then reload your shell
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

### 2. Install Gleam

#### Linux

```bash
# Option 1: Official installer (recommended)
curl -fsSL https://gleam.run/install.sh | sh

# Option 2: Package manager
# Arch Linux
sudo pacman -S gleam

# Ubuntu/Debian - see https://gleam.run/getting-started/installing/
```

#### macOS

```bash
brew install gleam
```

#### Verify Installation

```bash
gleam --version
# Should show: gleam 1.0.0 or higher
```

### 3. Install PostgreSQL

#### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start and enable service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create your user as a PostgreSQL superuser
sudo -u postgres createuser -s $USER
```

#### Linux (Arch)

```bash
sudo pacman -S postgresql

# Initialize database cluster
sudo -u postgres initdb -D /var/lib/postgres/data

# Start and enable service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create your user
sudo -u postgres createuser -s $USER
```

#### macOS

```bash
brew install postgresql@15
brew services start postgresql@15

# Create your user
createuser -s $USER
```

#### Verify Installation

```bash
psql --version
# Should show: psql (PostgreSQL) 15.x or higher

# Test connection
psql -d postgres -c "SELECT version();"
```

### 4. Install Required CLI Tools

#### Linux (Ubuntu/Debian)

```bash
sudo apt install jq bc
```

#### Linux (Arch)

```bash
sudo pacman -S jq bc
```

#### macOS

```bash
brew install jq bc
```

### 5. Install Nushell (Optional but Recommended)

Nushell is used in some hooks for better output formatting.

#### Ubuntu/Debian

```bash
cargo install nu
```

#### Arch

```bash
sudo pacman -S nushell
```

#### macOS

```bash
brew install nushell
```

### 6. Install Beads CLI

```bash
cargo install beads-cli

# Verify installation
bd --version
```

### 7. Install Beads Viewer

```bash
cargo install beads-viewer

# Verify installation
bv --version
```

### 8. Install Claude Code

Follow the official installation guide:
```bash
# See: https://github.com/anthropics/claude-code
```

### 9. Prerequisites Verification Checklist

Run these commands to verify everything is installed:

```bash
echo "✓ Checking prerequisites..."

# Rust
rustc --version && echo "✓ Rust installed" || echo "✗ Rust missing"

# Gleam
gleam --version && echo "✓ Gleam installed" || echo "✗ Gleam missing"

# PostgreSQL
psql --version && echo "✓ PostgreSQL installed" || echo "✗ PostgreSQL missing"

# jq
jq --version && echo "✓ jq installed" || echo "✗ jq missing"

# bc
echo "1+1" | bc && echo "✓ bc installed" || echo "✗ bc missing"

# Nushell (optional)
nu --version && echo "✓ Nushell installed" || echo "⚠ Nushell optional"

# Beads
bd --version && echo "✓ Beads installed" || echo "✗ Beads missing"

# Beads Viewer
bv --version && echo "✓ Beads Viewer installed" || echo "✗ Beads Viewer missing"

# Claude Code
claude --version && echo "✓ Claude Code installed" || echo "✗ Claude Code missing"

echo ""
echo "Prerequisites check complete!"
```

---

## Step-by-Step Project Creation

### Step 1: Create Gleam Project

```bash
# Create new Gleam project
gleam new my-project
cd my-project

# Initialize git repository
git init

# Create project directory structure
mkdir -p gleam/src/my_project/{web,storage,types,utils}
mkdir -p gleam/test/my_project
mkdir -p gleam/migrations_pg

echo "✓ Project structure created"
```

### Step 2: Configure Gleam Project

Create or update `gleam/gleam.toml`:

```bash
cat > gleam/gleam.toml << 'EOF'
name = "my_project"
version = "1.0.0"

# Target Erlang VM
target = "erlang"

# Add dependencies
[dependencies]
gleam_stdlib = ">= 0.34.0 and < 2.0.0"
gleam_erlang = ">= 0.25.0 and < 1.0.0"
gleam_pgo = ">= 0.12.0 and < 1.0.0"  # PostgreSQL
gleam_json = ">= 1.0.0 and < 2.0.0"
gleam_http = ">= 3.6.0 and < 4.0.0"
mist = ">= 1.2.0 and < 2.0.0"  # Web server

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
EOF

echo "✓ gleam.toml configured"
```

### Step 3: Create Basic Gleam Files

#### Main Entry Point

```bash
cat > gleam/src/my_project.gleam << 'EOF'
import gleam/io

pub fn main() {
  io.println("Hello from my_project!")
}
EOF
```

#### Basic Test File

```bash
cat > gleam/test/my_project_test.gleam << 'EOF'
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn hello_world_test() {
  1 + 1
  |> should.equal(2)
}
EOF
```

#### Test That Build Works

```bash
cd gleam
gleam build
gleam test
cd ..

echo "✓ Gleam project builds and tests pass"
```

### Step 4: Setup Database

```bash
# Create project databases
createdb my_project_dev
createdb my_project_test

# Create .env file
cat > .env << 'EOF'
DATABASE_URL=postgresql://localhost/my_project_dev
DATABASE_TEST_URL=postgresql://localhost/my_project_test
EOF

# Add .env to .gitignore
cat > .gitignore << 'EOF'
# Gleam
.build/
*.beam
*.ez
erl_crash.dump

# Environment
.env
.env.*

# Database
*.db
*.db-shm
*.db-wal

# Worktrees (auto-generated)
.agent-worktrees/

# Temp files
/tmp/
*.tmp
*.log

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

# Test database connection
psql my_project_dev -c "SELECT 1;" > /dev/null && echo "✓ Database connection works"
```

### Step 5: Initialize Beads

```bash
# Initialize beads with project-specific prefix
bd init --issue-prefix="my-project"

# Configure beads
cat > .beads/config.yaml << 'EOF'
# Beads Configuration File
sync-branch: main
EOF

# Create first test issue
bd create --title="Setup project structure" --type=task

# Verify beads is working
bd list

echo "✓ Beads initialized"
```

### Step 6: Copy AI Setup Files

**IMPORTANT**: You need the meal-planner project (or another project with this setup) as a reference.

```bash
# Set path to reference project (CHANGE THIS)
MEAL_PLANNER="/path/to/meal-planner"

# Verify reference project exists
if [ ! -d "$MEAL_PLANNER" ]; then
    echo "❌ Error: Reference project not found at $MEAL_PLANNER"
    echo "Please update the MEAL_PLANNER variable with the correct path"
    exit 1
fi

# 1. Copy configuration files
mkdir -p .claude/commands
cp "$MEAL_PLANNER/.claudeignore" .
cp "$MEAL_PLANNER/CLAUDE.md" .
cp "$MEAL_PLANNER/.claude/settings.json" .claude/
cp "$MEAL_PLANNER/.claude/settings.local.json" .claude/

# 2. Copy documentation
cp "$MEAL_PLANNER/WORKTREE_COORDINATION.md" .
cp "$MEAL_PLANNER/AGENTS.md" .
cp "$MEAL_PLANNER/PARALLEL_AGENT_WORKFLOW_GUIDE.md" .
cp "$MEAL_PLANNER/QUICK_START_PARALLEL_AGENTS.md" .
cp "$MEAL_PLANNER/WORKTREE_QUICK_REFERENCE.md" .

# 3. Copy scripts directory
mkdir -p scripts
cp -r "$MEAL_PLANNER/scripts/"* scripts/
chmod +x scripts/*.sh

# 4. Copy slash commands
cp "$MEAL_PLANNER/.claude/commands/beads-plan.md" .claude/commands/

# 5. Update CLAUDE.md with your project path
sed -i "s|/home/lewis/src/meal-planner|$(pwd)|g" CLAUDE.md

# 6. Update project name references
PROJECT_NAME=$(basename $(pwd))
sed -i "s|meal-planner|$PROJECT_NAME|g" CLAUDE.md
sed -i "s|meal_planner|${PROJECT_NAME//-/_}|g" CLAUDE.md

echo "✓ AI setup files copied"
```

### Step 7: Setup Global Claude Configuration

```bash
# Backup existing global config
if [ -f ~/.claude/CLAUDE.md ]; then
    cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup
    echo "✓ Backed up existing ~/.claude/CLAUDE.md"
fi

# Create/update global config
mkdir -p ~/.claude
cat > ~/.claude/CLAUDE.md << 'EOF'
- You are to never disable a file again.
EOF

# Copy global statusline script if available
if [ -f "$MEAL_PLANNER/../.claude/statusline-command.sh" ]; then
    cp "$MEAL_PLANNER/../.claude/statusline-command.sh" ~/.claude/
    chmod +x ~/.claude/statusline-command.sh
    echo "✓ Global statusline installed"
fi

echo "✓ Global Claude configuration complete"
```

### Step 8: Install MCP Agent Mail

```bash
# Install MCP Agent Mail server
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start

# Verify installation
claude mcp list | grep mcp-agent-mail && echo "✓ MCP Agent Mail installed"
```

### Step 9: Install Git Hooks

```bash
# Copy git hooks
mkdir -p .git/hooks
cp "$MEAL_PLANNER/.git/hooks/pre-commit" .git/hooks/
cp "$MEAL_PLANNER/.git/hooks/post-commit" .git/hooks/
cp "$MEAL_PLANNER/.git/hooks/prepare-commit-msg" .git/hooks/
cp "$MEAL_PLANNER/.git/hooks/post-checkout" .git/hooks/
cp "$MEAL_PLANNER/.git/hooks/post-merge" .git/hooks/
cp "$MEAL_PLANNER/.git/hooks/pre-push" .git/hooks/

# Make them executable
chmod +x .git/hooks/*

echo "✓ Git hooks installed"

# Test pre-commit hook with a dummy commit
git add gleam/src/my_project.gleam
git commit --dry-run -m "Test commit" 2>&1 | grep -q "quality gate" && echo "✓ Pre-commit hook working"
```

### Step 10: Initialize Worktree Pool

```bash
# Initialize the worktree coordination system
./scripts/agent-coordinator.sh init

# Verify worktree pool created
ls -la .agent-worktrees/ | grep pool-wt && echo "✓ Worktree pool initialized"
```

### Step 11: Create First Real Tasks

```bash
# Create meaningful tasks for your project
bd create \
  --title="Add basic web server with Mist" \
  --type=feature \
  --description="Setup basic HTTP server using Mist library"

bd create \
  --title="Add database connection pool" \
  --type=feature \
  --description="Setup PostgreSQL connection pool using pgo"

bd create \
  --title="Create basic route handlers" \
  --type=task \
  --description="Implement GET / and GET /health routes"

# Get the IDs of created tasks
WEB_SERVER=$(bd list --status=open | grep "web server" | awk '{print $1}')
DB_POOL=$(bd list --status=open | grep "database" | awk '{print $1}')
ROUTES=$(bd list --status=open | grep "route handlers" | awk '{print $1}')

# Add dependencies (routes depend on web server)
if [ -n "$WEB_SERVER" ] && [ -n "$ROUTES" ]; then
    bd dep add $ROUTES $WEB_SERVER
    echo "✓ Dependencies configured"
fi

# View available work
bd ready
echo ""
echo "✓ Tasks created"
```

### Step 12: Test MCP Agent Mail

```bash
# Start Claude Code session to test
echo "Starting Claude Code to test MCP Agent Mail..."
echo "In the Claude session, run: mcp__mcp_agent_mail__health_check()"
echo ""
echo "Press Enter when ready to continue, or Ctrl+C to stop here"
read

echo "✓ MCP Agent Mail test complete (manual verification)"
```

### Step 13: Commit Initial Setup

```bash
# Stage all files
git add .

# Commit (hooks will run automatically - build must pass!)
git commit -m "Initial project setup with AI coordination

- Setup Gleam project structure
- Configure database (PostgreSQL)
- Initialize Beads issue tracking
- Install AI coordination scripts
- Setup git hooks (format, build, test enforcement)
- Initialize worktree pool for parallel agents
- Create initial tasks"

# Sync beads
bd sync

echo "✓ Initial commit complete"
```

### Step 14: Create Remote Repository and Push

```bash
# Create repository on GitHub/GitLab/etc. (do this manually in your browser)
echo "Create a new repository on GitHub/GitLab/etc."
echo "Then run:"
echo ""
echo "  git remote add origin <your-repo-url>"
echo "  git push -u origin main"
echo ""
echo "Press Enter when ready to continue"
read

# Add remote and push (replace URL)
# git remote add origin https://github.com/yourusername/my-project.git
# git push -u origin main

echo "✓ Repository setup complete"
```

### Step 15: Test Parallel Agent Execution

```bash
# Spawn 2 agents to work on independent tasks
./scripts/agent-coordinator.sh spawn 2 independent

# Monitor progress (Ctrl+C to exit)
./scripts/agent-coordinator.sh monitor

# Check status
./scripts/agent-coordinator.sh status

echo ""
echo "✓ Parallel agent test complete"
```

---

## Verification

### Complete Verification Checklist

Run these commands to verify your setup:

```bash
echo "Running comprehensive verification..."
echo ""

# 1. Gleam builds successfully
echo "1. Testing Gleam build..."
(cd gleam && gleam build) && echo "   ✓ Build passes" || echo "   ✗ Build fails"

# 2. Tests pass
echo "2. Testing Gleam tests..."
(cd gleam && gleam test) && echo "   ✓ Tests pass" || echo "   ✗ Tests fail"

# 3. Beads is working
echo "3. Testing Beads..."
bd list > /dev/null && echo "   ✓ Beads working" || echo "   ✗ Beads failed"

# 4. Beads viewer shows insights
echo "4. Testing Beads Viewer..."
bv --robot-insights > /dev/null && echo "   ✓ Beads Viewer working" || echo "   ✗ Beads Viewer failed"

# 5. MCP Agent Mail is available
echo "5. Testing MCP Agent Mail..."
claude mcp list | grep -q mcp-agent-mail && echo "   ✓ MCP Agent Mail available" || echo "   ✗ MCP Agent Mail missing"

# 6. Git hooks are installed and executable
echo "6. Testing Git hooks..."
[ -x .git/hooks/pre-commit ] && echo "   ✓ Git hooks executable" || echo "   ✗ Git hooks not executable"

# 7. Scripts are executable
echo "7. Testing scripts..."
[ -x scripts/agent-coordinator.sh ] && echo "   ✓ Scripts executable" || echo "   ✗ Scripts not executable"

# 8. Worktree pool is initialized
echo "8. Testing worktree pool..."
[ -d .agent-worktrees/pool-wt-1 ] && echo "   ✓ Worktree pool exists" || echo "   ✗ Worktree pool missing"

# 9. Resource monitor works
echo "9. Testing resource monitor..."
./scripts/resource-monitor.sh check > /dev/null 2>&1 && echo "   ✓ Resource monitor working" || echo "   ✗ Resource monitor failed"

# 10. Database connection works
echo "10. Testing database..."
psql my_project_dev -c "SELECT 1;" > /dev/null 2>&1 && echo "    ✓ Database accessible" || echo "    ✗ Database connection failed"

echo ""
echo "Verification complete!"
```

### What to Do If Verification Fails

See the [Troubleshooting](#troubleshooting) section below.

---

## AI Agent Guidance

### For AI Agents Setting Up New Projects

If you're an AI agent using this guide to set up a project, follow these guidelines:

#### 1. Understand the Goal

The user wants a complete Gleam project with:
- Parallel AI agent execution (2-10 agents working simultaneously)
- Quality enforcement (code must compile before commit)
- Git-based issue tracking (Beads)
- Agent coordination (file reservations, messaging)
- Worktree isolation (each agent has their own workspace)

#### 2. Key Decision Points

**Ask the user before proceeding:**

| Question | Why It Matters |
|----------|----------------|
| "What should the project be called?" | Determines directory name and gleam.toml name |
| "What's the main purpose of this project?" | Helps create initial meaningful tasks |
| "Do you have the meal-planner reference project?" | Required for Step 6 - copying AI setup files |
| "How many parallel agents should we start with?" | Recommend 2-4 for new projects |

#### 3. Verification Strategy

After each major step, verify success:

```bash
# After Gleam setup (Steps 1-3)
cd gleam && gleam build && gleam test && cd ..

# After Beads setup (Step 5)
bd list

# After MCP setup (Step 8)
claude mcp list | grep mcp-agent-mail

# After hooks (Step 9)
ls -la .git/hooks/ | grep pre-commit

# After worktree pool (Step 10)
ls -la .agent-worktrees/ | grep pool-wt-1

# After tasks (Step 11)
bd ready
```

#### 4. Common Pitfalls to Avoid

- ❌ **Don't skip database setup** - Many scripts assume PostgreSQL is running
- ❌ **Don't forget chmod +x** - Scripts won't work without execute permission
- ❌ **Don't skip .env** - Database connection requires proper environment variables
- ❌ **Don't commit .env** - Should be in .gitignore
- ❌ **Don't skip verification** - Always verify each step before proceeding
- ❌ **Don't use relative paths** - Agent Mail requires absolute paths
- ❌ **Don't bypass pre-commit** - Build MUST pass before commit

#### 5. Session Start Protocol

When starting work in a project set up with this system:

```javascript
// 1. Register with Agent Mail
const session = await mcp__mcp_agent_mail__macro_start_session({
  human_key: "/absolute/path/to/project",  // Use $(pwd) to get this
  program: "claude-code",
  model: "claude-sonnet-4-5",
  task_description: "Working on project tasks",
  inbox_limit: 20
});

console.log("Registered as:", session.agent.name);

// 2. Check available work
await Bash({ command: "bd ready --json" });
await Bash({ command: "bv --robot-insights" });

// 3. Select task and reserve files
await mcp__mcp_agent_mail__file_reservation_paths({
  project_key: "/absolute/path/to/project",
  agent_name: session.agent.name,
  paths: ["gleam/src/my_project/**/*.gleam"],
  ttl_seconds: 3600,
  exclusive: true,
  reason: "my-project-123"  // Use actual bead ID
});

// 4. Update task status
await Bash({ command: "bd update my-project-123 --status=in_progress" });

// 5. Do the work...
// (code changes, tests, etc.)

// 6. Complete task
await Bash({ command: "bd close my-project-123" });

// 7. Release files
await mcp__mcp_agent_mail__release_file_reservations({
  project_key: "/absolute/path/to/project",
  agent_name: session.agent.name
});

// 8. Session close protocol (MANDATORY!)
await Bash({ command: "git status" });
await Bash({ command: "git add ." });
await Bash({ command: "bd sync" });
await Bash({ command: 'git commit -m "[my-project-123] Implemented feature"' });
await Bash({ command: "bd sync" });
await Bash({ command: "git push" });
```

#### 6. Explaining to Users

When explaining this setup, emphasize:

1. **Parallel execution**: Multiple AI agents work simultaneously without conflicts
2. **Quality gates**: Pre-commit hooks prevent broken code from being committed
3. **No trampling**: File filtering ensures agents only see relevant files
4. **Coordination**: Agent Mail prevents two agents from editing same files
5. **Lightweight tracking**: Beads provides issue tracking without external dependencies

---

## Template Files

### Minimal gleam.toml

```toml
name = "my_project"
version = "1.0.0"
target = "erlang"

[dependencies]
gleam_stdlib = ">= 0.34.0 and < 2.0.0"
gleam_erlang = ">= 0.25.0 and < 1.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

### Basic Entry Point (src/my_project.gleam)

```gleam
import gleam/io

pub fn main() {
  io.println("Hello from my_project!")
}
```

### Basic Test (test/my_project_test.gleam)

```gleam
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn example_test() {
  1 + 1
  |> should.equal(2)
}
```

### Complete .gitignore

```gitignore
# Gleam
.build/
*.beam
*.ez
erl_crash.dump

# Environment
.env
.env.*

# Database
*.db
*.db-shm
*.db-wal

# Worktrees (auto-generated)
.agent-worktrees/

# Temp files
/tmp/
*.tmp
*.log

# Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "bd command not found"

**Solution:**
```bash
cargo install beads-cli
# Verify
bd --version
```

#### Issue: "MCP server not responding"

**Solution:**
```bash
# Check if installed
claude mcp list

# Reinstall if needed
claude mcp remove mcp-agent-mail
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start
```

#### Issue: "Pre-commit hook failing"

**Solution:**
```bash
# Check if build passes
cd gleam
gleam build

# If build fails, fix errors shown
# Then try commit again
```

#### Issue: "Worktree pool empty"

**Solution:**
```bash
# Re-initialize pool
./scripts/agent-coordinator.sh init

# Check status
./scripts/worktree-pool-manager.sh status
```

#### Issue: "Database connection failed"

**Solution:**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start if not running
sudo systemctl start postgresql

# Test connection
psql -d postgres -c "SELECT 1;"

# Recreate databases if needed
dropdb my_project_dev
dropdb my_project_test
createdb my_project_dev
createdb my_project_test
```

#### Issue: "Permission denied" on scripts

**Solution:**
```bash
# Make all scripts executable
chmod +x scripts/*.sh
chmod +x .git/hooks/*

# Verify
ls -la scripts/ | grep rwx
```

#### Issue: "gleam build hangs"

**Solution:**
```bash
# Check if dependencies are corrupted
rm -rf gleam/build
cd gleam
gleam clean
gleam build
```

#### Issue: "Beads sync fails"

**Solution:**
```bash
# Run doctor to check for issues
bd doctor --fix

# If still failing, check database
ls -la .beads/beads.db

# If corrupted, import from JSONL
bd sync --import-only
```

#### Issue: "Agent Mail tools not available"

**Solution:**
```bash
# Check Claude Code session
claude mcp list

# Restart Claude Code
# Exit current session (Ctrl+C)
# Start new session
claude

# Test again
mcp__mcp_agent_mail__health_check()
```

### Getting Help

If you encounter issues not covered here:

1. **Check the main dump file**: `AI_SETUP_COMPLETE_DUMP.md` has additional troubleshooting
2. **Run diagnostics**: `./scripts/resource-monitor.sh check`
3. **Check logs**: Look for error messages in terminal output
4. **Verify prerequisites**: Run the verification checklist in [Prerequisites](#prerequisites-installation)

---

## Quick Reference

### Essential Commands

```bash
# Beads
bd ready                          # Show available work
bd list --status=open             # All open issues
bd create --title="..." --type=task
bd update <id> --status=in_progress
bd close <id>
bd sync                           # Sync with git

# Beads Viewer
bv --robot-insights              # High-impact tasks
bv --robot-plan                  # Parallel execution plan
bv --robot-priority              # Recommended tasks

# Agent Coordination
./scripts/agent-coordinator.sh init
./scripts/agent-coordinator.sh spawn 4 independent
./scripts/agent-coordinator.sh status
./scripts/agent-coordinator.sh monitor
./scripts/agent-coordinator.sh cleanup

# Resource Monitoring
./scripts/resource-monitor.sh check
./scripts/resource-monitor.sh detect-leaks

# Worktree Pool
./scripts/worktree-pool-manager.sh status
./scripts/worktree-pool-manager.sh scale-up
```

### Session Close Protocol (MANDATORY)

```bash
git status
git add .
bd sync
git commit -m "[bead-id] Description"
bd sync
git push
```

---

## Summary

You now have a complete Gleam project with:

✅ **Quality enforcement** - Code must build before commit
✅ **Parallel agents** - 3-10 agents can work simultaneously
✅ **No conflicts** - File filtering prevents agents from interfering
✅ **Issue tracking** - Beads provides git-based task management
✅ **Agent coordination** - Agent Mail handles file reservations and messaging
✅ **Resource safety** - Automatic monitoring prevents exhaustion

### Next Steps

1. **Create your first feature**:
   ```bash
   bd create --title="Your first feature" --type=feature
   bd ready
   ```

2. **Start Claude Code**:
   ```bash
   claude
   ```

3. **In Claude, check available work**:
   ```javascript
   mcp__mcp_agent_mail__macro_start_session({
     human_key: "/absolute/path/to/your/project",
     program: "claude-code",
     model: "claude-sonnet-4-5"
   })
   ```

4. **Spawn parallel agents when ready**:
   ```bash
   ./scripts/agent-coordinator.sh spawn 4 independent
   ```

---

**For more details**, see:
- `AI_SETUP_COMPLETE_DUMP.md` - Complete infrastructure documentation
- `WORKTREE_COORDINATION.md` - Worktree architecture details
- `PARALLEL_AGENT_WORKFLOW_GUIDE.md` - Full workflow guide
- `QUICK_START_PARALLEL_AGENTS.md` - 30-second quick start

**End of Scaffolding Guide**

Generated: 2025-12-09
Companion to: AI_SETUP_COMPLETE_DUMP.md
Total: 15 detailed steps for new project creation
