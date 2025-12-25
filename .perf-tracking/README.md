# Performance Tracking Data

This directory contains historical performance metrics for the meal-planner project.

## Structure

- `test-execution.csv` - Test execution time measurements
- `baselines.json` - Performance baselines and thresholds
- `reports/` - Generated performance reports (not tracked in git)

## Data Format

### test-execution.csv
```csv
timestamp,commit_hash,commit_number,test_duration_ms,test_count,pass_count,fail_count,skip_count
```

### baselines.json
```json
{
  "test_execution": {
    "baseline_ms": 800,
    "warning_threshold_percent": 20,
    "critical_threshold_percent": 50
  }
}
```

## Usage

Performance tracking is automatic via git hooks. Data is collected every 5 commits.

Manual tracking:
```bash
./scripts/perf-track.sh
```

Manual analysis:
```bash
./scripts/perf-analyze.sh
```
