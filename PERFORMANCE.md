# Performance Tracking System

**Agent-Perf-1 (35/96)** - Build performance tracking for test execution

## Overview

This system automatically tracks `make test` execution time every 5 commits, reports any regressions, and alerts on slowdowns. It provides historical performance data, trend analysis, and automatic regression detection.

## Features

- **Automatic Tracking**: Runs every 5 commits via git post-commit hook
- **Performance Baselines**: Configurable baseline metrics with warning/critical thresholds
- **Regression Detection**: Alerts on 20% slowdowns (warning) and 50% slowdowns (critical)
- **Trend Analysis**: Statistical analysis of performance over time
- **Historical Data**: CSV storage of all measurements for long-term tracking
- **Detailed Reports**: Generate comprehensive performance analysis reports

## Quick Start

### Installation

```bash
# Install git hooks for automatic tracking
./scripts/install-perf-hooks.sh
```

This installs a post-commit hook that will automatically track performance every 5 commits.

### Manual Tracking

```bash
# Force tracking on current commit (bypass 5-commit rule)
./scripts/perf-track.sh --force

# Analyze recent performance data
./scripts/perf-analyze.sh

# Generate detailed report
./scripts/perf-analyze.sh --report

# Analyze specific number of recent measurements
./scripts/perf-analyze.sh --last 20
```

## Directory Structure

```
.perf-tracking/
├── README.md                 # Documentation about data format
├── baselines.json            # Performance baselines and thresholds
├── test-execution.csv        # Historical measurement data (gitignored)
└── reports/                  # Generated reports (gitignored)
    └── perf-report-*.txt
```

## Baselines and Thresholds

Current baselines (as of 2025-12-24):

| Metric | Baseline | Warning (+%) | Critical (+%) | Description |
|--------|----------|--------------|---------------|-------------|
| Fast Tests | 800ms | 20% (960ms) | 50% (1200ms) | `gleam run -m test_runner/fast` |
| Full Tests | 5200ms | 15% (5980ms) | 40% (7280ms) | `gleam test` |
| Build | 150ms | 50% (225ms) | 100% (300ms) | `gleam build` |

### Updating Baselines

Edit `.perf-tracking/baselines.json`:

```json
{
  "test_execution": {
    "baseline_ms": 800,
    "warning_threshold_percent": 20,
    "critical_threshold_percent": 50
  }
}
```

## Data Format

### test-execution.csv

```csv
timestamp,commit_hash,commit_number,test_duration_ms,test_type,pass_count,fail_count,skip_count,notes
2025-12-24T12:00:00Z,abc123def,1641,750,fast,487,0,0,
2025-12-24T12:15:00Z,def456abc,1645,820,fast,487,0,0,
```

## Scripts

### perf-track.sh

**Purpose**: Measure and record test execution time

**Usage**:
```bash
./scripts/perf-track.sh [--force]
```

**Behavior**:
- Runs `gleam run -m test_runner/fast` and measures execution time
- Records timestamp, commit hash, duration, test counts
- Compares against baseline and reports status
- Only runs every 5 commits unless `--force` is used
- Outputs color-coded results (green=good, yellow=warning, red=critical)

**Exit Codes**:
- 0: Success
- 1: Test execution failed
- 2: Critical regression detected (50%+ slowdown)

### perf-analyze.sh

**Purpose**: Analyze historical performance data and detect trends

**Usage**:
```bash
./scripts/perf-analyze.sh [--report] [--last N] [--all]
```

**Options**:
- `--report`: Generate detailed report in `.perf-tracking/reports/`
- `--last N`: Analyze last N measurements (default: 10)
- `--all`: Analyze all historical data

**Outputs**:
- Summary statistics (min, max, mean, median, standard deviation)
- Trend detection (improving, stable, degrading)
- Recent measurements table with color-coded performance
- Regression analysis

**Example Output**:
```
Performance Summary (last 10 measurements)

Fast Tests (gleam run -m test_runner/fast):
  Baseline:     800ms
  Min:          720ms
  Max:          850ms
  Mean:         780ms (-2% from baseline)
  Median:       775ms
  Std Dev:      35ms

[SUCCESS] Trend: IMPROVING (performance getting better)

Recent Measurements (last 5)
--------------------------------------------------------------------------------
Timestamp            Commit     Duration     Type       Status
2025-12-24T12:00:00Z abc12345   750ms        fast       ✓
2025-12-24T12:15:00Z def67890   820ms        fast       ✓
```

### install-perf-hooks.sh

**Purpose**: Install git post-commit hook for automatic tracking

**Usage**:
```bash
./scripts/install-perf-hooks.sh
```

**Behavior**:
- Creates or updates `.git/hooks/post-commit`
- Adds performance tracking call that runs after each commit
- Respects 5-commit boundary (only tracks on commits divisible by 5)
- Safe to run multiple times (idempotent)

## Git Hook Integration

After running `install-perf-hooks.sh`, every 5th commit will automatically:

1. Run `make test` (fast tests)
2. Measure execution time
3. Record results to `.perf-tracking/test-execution.csv`
4. Compare against baseline
5. Display status (✓ good, ⚠ warning, ✗ critical)

Example post-commit output:
```
[INFO] Performance Tracking - meal-planner

[INFO] Commit: abc12345 (commit #1645)
[INFO] Triggering performance tracking (commit #1645)

[INFO] Measuring fast test execution...
[SUCCESS] fast tests completed in 780ms

[INFO] Performance within normal range: 780ms (baseline: 800ms, -2%)

[SUCCESS] Performance tracking completed successfully
```

## Interpreting Results

### Performance Status

- **GREEN (✓)**: Performance within 20% of baseline or improving
- **YELLOW (⚠)**: Performance 20-50% slower than baseline (warning)
- **RED (✗)**: Performance 50%+ slower than baseline (critical regression)

### Trends

- **IMPROVING**: Linear regression shows decreasing execution time
- **STABLE**: Execution time consistent with minimal variation
- **DEGRADING**: Linear regression shows increasing execution time

### When to Investigate

Investigate performance issues when:

1. **Critical regression** (50%+ slowdown)
   - Review recent commits for performance-impacting changes
   - Check for added dependencies or complex operations
   - Profile tests to identify slow tests

2. **Consistent warning trend** (3+ consecutive measurements above 20%)
   - Accumulation of small performance degradations
   - May indicate architectural issues
   - Consider refactoring or optimization

3. **High standard deviation** (>15% of mean)
   - Inconsistent test performance
   - May indicate flaky tests or environmental issues
   - Check for resource contention or external dependencies

## Integration with CI/CD

To integrate performance tracking in CI/CD:

```yaml
# .github/workflows/performance.yml
name: Performance Tracking

on:
  push:
    branches: [main]

jobs:
  track-performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Track Performance
        run: |
          ./scripts/perf-track.sh --force
          ./scripts/perf-analyze.sh
```

## Troubleshooting

### No data collected

```bash
# Check if CSV file exists
ls -la .perf-tracking/test-execution.csv

# Force tracking to collect first data point
./scripts/perf-track.sh --force
```

### Hook not running

```bash
# Verify hook is installed
cat .git/hooks/post-commit

# Reinstall if needed
./scripts/install-perf-hooks.sh

# Check hook is executable
ls -la .git/hooks/post-commit
```

### Inaccurate measurements

- Ensure consistent environment (no background processes)
- Run on same hardware for comparability
- Consider averaging multiple runs for baseline
- Exclude first run after system restart (cold cache)

## Best Practices

1. **Establish Baseline Early**: Run tracking on stable builds to establish reliable baseline
2. **Track Consistently**: Ensure tracking runs in consistent environment
3. **Review Trends**: Look at trends, not individual measurements
4. **Update Baselines**: When intentional performance improvements are made, update baseline
5. **Investigate Promptly**: Address regressions before they accumulate
6. **Document Changes**: Add notes to measurements for significant changes

## Performance Goals

Current project goals:

- **Fast tests**: Stay under 1 second (current baseline: 800ms)
- **Full tests**: Stay under 6 seconds (current baseline: 5200ms)
- **Build time**: Stay under 200ms (current baseline: 150ms)

## Future Enhancements

Potential improvements to tracking system:

- [ ] Track build time in addition to test time
- [ ] Track memory usage during tests
- [ ] Generate performance graphs/charts
- [ ] Slack/email alerts on critical regressions
- [ ] Automatic bisect to identify regression-causing commit
- [ ] Performance budgets per module
- [ ] Comparison against main branch baseline

## Related Documentation

- [Makefile](Makefile) - Build system with performance metrics
- [CLAUDE.md](CLAUDE.md) - Development workflow and standards
- [CLAUDE_TCR.md](CLAUDE_TCR.md) - Test/Commit/Revert discipline

## Contact

For issues or questions about performance tracking:
- Check `.perf-tracking/README.md` for data format details
- Review scripts in `scripts/perf-*.sh`
- Create issue with `performance` label

---

**Built by Agent-Perf-1 (35/96)** - Ensuring meal-planner stays fast and efficient.
