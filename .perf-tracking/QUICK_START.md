# Compilation Time Tracking - Quick Start Guide

## Quick Reference

### Measure Everything
```bash
./scripts/compile-time-track.sh --both
```

### Measure Clean Build Only
```bash
./scripts/compile-time-track.sh --baseline
```

### Measure Incremental Build Only
```bash
./scripts/compile-time-track.sh --incremental
```

### Update Baselines
```bash
./scripts/compile-time-track.sh --both --update-baselines
```

### Measure JavaScript Target
```bash
./scripts/compile-time-track.sh --both --target javascript
```

## Workflow

### 1. Establish Baseline (Before Refactoring)
```bash
# Checkout stable commit
git checkout <pre-refactoring-commit>

# Measure and set baseline
./scripts/compile-time-track.sh --both --update-baselines
```

### 2. Measure After Changes
```bash
# Checkout refactored code
git checkout <refactored-branch>

# Measure and compare
./scripts/compile-time-track.sh --both
```

### 3. Continuous Monitoring
```bash
# After each significant commit
./scripts/compile-time-track.sh --incremental
```

## Understanding Output

### Success
```
[INFO] Compilation Time Tracking - meal-planner
[INFO] Commit: abc1234 (commit #1642) on branch: fix-compilation-issues

[INFO] === Clean Build Measurement ===
[SUCCESS] clean build (erlang) completed in 3250ms
[METRIC]   Modules compiled: 156

[INFO] Performance within normal range: 3250ms (baseline: 3000ms, +8%)
[SUCCESS] Recorded measurement to .perf-tracking/compile-time.csv
```

### Warning (50% regression)
```
[WARNING] Performance degradation: 4500ms vs baseline 3000ms (+50%)
```

### Critical (100% regression)
```
[ERROR] CRITICAL REGRESSION: 6000ms vs baseline 3000ms (+100%)
```

### Improvement
```
[SUCCESS] Performance improvement: 2400ms vs baseline 3000ms (-20%)
```

## Data Files

### CSV Output
**Location:** `.perf-tracking/compile-time.csv`

**Format:**
```csv
timestamp,commit_hash,commit_number,branch,build_type,target,duration_ms,modules_compiled,warning_count,error_count,notes
2025-12-24T23:32:00Z,c9093041,1642,fix-compilation-issues,clean,erlang,3250,156,2,0,""
```

### Baselines
**Location:** `.perf-tracking/baselines.json`

**Update:**
```bash
./scripts/compile-time-track.sh --baseline --update-baselines
./scripts/compile-time-track.sh --incremental --update-baselines
```

## Thresholds

### Clean Build
- **Baseline:** 3000ms (3 seconds)
- **Warning:** >4500ms (+50%)
- **Critical:** >6000ms (+100%)

### Incremental Build
- **Baseline:** 150ms
- **Warning:** >225ms (+50%)
- **Critical:** >300ms (+100%)

## Troubleshooting

### Build Fails
```bash
# Clean everything
rm -rf build/ _build/
gleam deps download
gleam build --target erlang
```

### Script Not Executable
```bash
chmod +x ./scripts/compile-time-track.sh
```

### Missing Dependencies
```bash
# Install jq (for JSON processing)
# On Arch Linux:
sudo pacman -S jq

# On Ubuntu/Debian:
sudo apt-get install jq

# On macOS:
brew install jq
```

## Common Workflows

### Before Merging PR
```bash
# Measure current branch
./scripts/compile-time-track.sh --both

# Check for regressions in output
# If >50% regression, investigate before merging
```

### After Major Refactoring
```bash
# Clean build to reset cache
gleam clean

# Measure clean build
./scripts/compile-time-track.sh --baseline

# Measure incremental build
./scripts/compile-time-track.sh --incremental

# Compare against baselines
```

### Weekly Performance Check
```bash
# Measure current state
./scripts/compile-time-track.sh --both

# Review trends in CSV
cat .perf-tracking/compile-time.csv | tail -10
```

## Expected Performance

### meal-planner Project (Medium-Large)

| Metric | Expected | Warning | Critical |
|--------|----------|---------|----------|
| Clean Build | 60-90s | >135s | >180s |
| Incremental | 150-250ms | >375ms | >500ms |
| Type Check | 25-35s | >52s | >70s |

## Integration

### Git Hooks
Add to `.git/hooks/post-commit`:
```bash
#!/bin/bash
COMMIT_NUM=$(git rev-list --count HEAD)
if (( COMMIT_NUM % 10 == 0 )); then
  ./scripts/compile-time-track.sh --incremental
fi
```

### CI/CD
Add to GitHub Actions:
```yaml
- name: Track Compilation Performance
  run: |
    ./scripts/compile-time-track.sh --both
    if [ $? -eq 1 ]; then
      echo "::warning::Performance degradation detected"
    elif [ $? -eq 2 ]; then
      echo "::error::Critical regression detected"
      exit 1
    fi
```

## Documentation

- **Full Docs:** `.perf-tracking/COMPILATION_TRACKING_REPORT.md`
- **Analysis:** `.perf-tracking/COMPILATION_BASELINE_ANALYSIS.md`
- **Agent Report:** `AGENT_BENCH_1_REPORT.md`

## Support

For issues or questions:
1. Check build environment (Erlang/OTP, rebar3, Gleam version)
2. Review error logs in script output
3. Consult documentation in `.perf-tracking/`
4. Ensure builds pass before measuring

---

**Quick Tip:** Run `./scripts/compile-time-track.sh --both` after every 5-10 commits to catch regressions early!
