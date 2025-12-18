# Beads Task Tracking System

This directory contains the Beads database and configuration for the meal-planner project.

## Structure

```
.beads/
├── beads.db                  # SQLite database with all tasks
├── viewer_config.json        # Viewer configuration for parallel planning
└── README.md                 # This file
```

## Quick Start

### View Tasks

```bash
# List all ready tasks
bd ready

# Show specific task
bd show meal-planner-xt0.1

# List all tasks with filters
bd list --status open --priority 1
```

### Create Tasks

```bash
# Create new task
bd create --title "Fix bug in grocery list" --type bug --priority 2

# Create epic
bd create --title "V2 Features" --type epic --priority 3
```

### Update Tasks

```bash
# Mark task as in progress
bd update meal-planner-xt0.1 --status in_progress

# Close task
bd close meal-planner-xt0.1 --reason "Implementation complete"

# Add notes
bd update meal-planner-xt0.1 --notes "Integrated with FatSecret API"
```

### Dependencies

```bash
# Create dependency
bd dep meal-planner-xt0.2 --depends-on meal-planner-xt0.1 --type blocks

# View dependencies
bd show meal-planner-xt0.4
```

## Viewer Configuration

The `viewer_config.json` supports:

- **Status Colors** - Color-coded task statuses for quick visualization
- **Priority Levels** - Map numeric priority to semantic labels
- **Reporting** - Burndown charts, velocity, cycle time analysis
- **Parallel Planning** - Configure multi-agent swarm settings
- **Git Integration** - Auto-link commits to tasks

## Workflow Integration

### Commit Messages

Every commit should reference a Beads task:

```bash
git commit -m "PASS: [meal-planner-xt0.1] Fix grocery list aggregation"
```

## For More Information

See `SPARC_WORKFLOW.md` in project root.

---

**Last Updated:** 2025-12-18
**Status:** Active Development
