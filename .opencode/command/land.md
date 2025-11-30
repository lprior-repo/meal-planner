---
description: Execute complete session-end workflow (mandatory before ending)
agent: build
---

Execute the complete "Landing the Plane" workflow for beads hygiene. This is MANDATORY - the plane is NOT landed until git push succeeds.

## SEVEN-STEP MANDATORY WORKFLOW

### Step 1: File Remaining Issues
Create beads issues for any incomplete work requiring follow-up:
```bash
bd create "Description of remaining work" -t task -p 2 --json
```

### Step 2: Run Quality Gates (Gleam-native)
Run ALL quality gates - file P0 issues if any fail:
```bash
cd gleam && gleam test      # All tests must pass
cd gleam && gleam build     # Build must succeed
cd gleam && gleam check     # Type checking must pass
```

### Step 3: Update Beads Issues
- Close all finished work with `bd close <id> --reason "Completed" --json`
- Update status of in-progress work
- Close any duplicate issues

### Step 4: PUSH TO REMOTE (MANDATORY - NON-NEGOTIABLE)
Execute ALL commands - DO NOT STOP until git push succeeds:
```bash
git pull --rebase

# If conflicts in .beads/beads.jsonl:
#   git checkout --theirs .beads/beads.jsonl
#   bd import -i .beads/beads.jsonl

bd sync
git push       # MANDATORY - PLANE NOT LANDED WITHOUT THIS
git status     # MUST show "up to date with origin/main"
```

**CRITICAL RULES:**
- The plane has NOT landed until `git push` completes successfully
- NEVER stop before `git push` - that leaves work stranded locally
- NEVER say "ready to push when you are!" - YOU must push
- If git push fails, resolve the issue and retry until it succeeds
- Unpushed work breaks multi-agent coordination

### Step 5: Clean Git State
```bash
git stash clear
git remote prune origin
```

### Step 6: Verify Clean State
Run `git status` - must show:
- "up to date with origin/main"
- "nothing to commit, working tree clean"

### Step 7: Choose Follow-Up Work
```bash
bd ready --json
```
Select the highest priority open issue for next session.

## FINAL DELIVERABLE

Provide the user with:
1. **Summary** of what was completed this session
2. **Issues filed** for follow-up (if any)
3. **Quality gates status** (all passing / issues filed)
4. **Confirmation** that ALL changes have been pushed to remote
5. **Recommended prompt** for next session in format:
   > "Continue work on bd-X: [issue title]. [Brief context about what's been done and what's next]"

Remember: The session is NOT complete until git status shows "up to date with origin/main".
