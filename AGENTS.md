# AI Agent Workflow Guide

This document describes how to work with AI agents in the meal-planner project using Beads.

## Overview

The meal-planner project uses **Beads** (bd) for issue tracking, dependency management, and agent coordination. All work must go through Beads to ensure proper tracking and visibility.

## Working with Beads

### Creating Issues

```bash
bd add --title "Feature: X" --priority high --label feature
bd add --title "Bug: X fails on Y" --priority high --label bug --description "Steps to reproduce..."
```

### Tracking Progress

```bash
bd claim <issue-id>           # Start working on an issue
bd resolve <issue-id>         # Mark as resolved (needs review)
bd complete <issue-id>        # Mark as completed
```

### Managing Dependencies

```bash
bd link <issue-id-1> <issue-id-2>    # Create dependency
bd unlink <issue-id-1> <issue-id-2>  # Remove dependency
```

## Landing Protocol

After completing work, follow this protocol:

### 1. Commit Your Changes
```bash
git add .
git commit -m "type: description"  # Follow conventional commits
```

### 2. Update Beads (Source of Truth)
```bash
bd claim <issue-id> --status completed --commit-hash <hash>
```

### 3. Save Decisions to mem0
For architecture decisions, bug solutions, and patterns:
```
mem0_add_memory(text="Decision: X. Rationale: Y. Context: Z")
```

### 4. Push to Remote
```bash
git pull --rebase
git push
```

## Commit Message Format

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `chore:` Build, dependencies, tooling
- `docs:` Documentation changes
- `test:` Test additions/modifications

Example:
```
feat: add OAuth token storage with SQLx

- Implement secure token persistence
- Add migration scripts
- Update tests

Closes #MP-123
```

## Issue Labels

- `epic` - Large feature spanning multiple tasks
- `feature` - New functionality
- `bug` - Something broken
- `chore` - Maintenance, refactoring, tooling
- `fatsecret` - FatSecret API related
- `windmill` - Windmill script related
- `p0`, `p1`, `p2` - Priority levels

## Git Workflow

1. Work on issues assigned to you
2. Make commits with conventional format
3. Push to feature branch if needed
4. Update Beads to mark progress
5. Create PR when ready for review

## Helpful Commands

```bash
bd list              # Show all open issues
bd duplicates        # Find and review duplicates
bd doctor            # Check project health
bd ready             # Mark ready for review
```

## Resources

- [Beads Documentation](https://github.com/steveyegge/beads)
- [Conventional Commits](https://www.conventionalcommits.org/)
