# Mutation Testing Infrastructure - Complete Guide

## Overview

This project now has **production-grade mutation testing infrastructure** using Avito Tech's `go-mutesting` framework. Two implementations are provided:

### 1. **analyze-mutations.go** - Simple, Fast Version
- Fast per-file concurrent testing
- JSON output only
- Best for: Quick local testing, CI/CD pipelines

### 2. **mutation-testing.go** - Comprehensive, Enterprise Version
- Multi-format reporting (JSON, CSV, HTML)
- Baseline tracking & comparison
- Threshold enforcement
- Hotspot identification
- Mutation statistics by type
- Concurrency control
- Best for: In-depth analysis, trend tracking, team dashboards

---

## Quick Start

### Run Simple Analysis
```bash
go run analyze-mutations.go
# Output: mutation-analysis-report.json
```

### Run Comprehensive Analysis
```bash
go run mutation-testing.go [options]
```

---

## Command-Line Options

### Basic Options
```bash
# Set score threshold (exit 1 if below)
go run mutation-testing.go --threshold=85.0

# Verbose output
go run mutation-testing.go --verbose

# Dry-run (show what would be tested)
go run mutation-testing.go --dry-run

# Control concurrency
go run mutation-testing.go --concurrency=4
```

### Output Options
```bash
# Specify output files
go run mutation-testing.go \
  --json=custom-report.json \
  --csv=custom-report.csv \
  --html=custom-report.html

# Disable specific outputs
go run mutation-testing.go --export-csv=false --export-html=false
```

### Advanced Options
```bash
# Incremental mode (only test changed files)
go run mutation-testing.go --incremental

# Compare with baseline
go run mutation-testing.go --baseline=.mutation-baseline.json

# Use custom config
go run mutation-testing.go --config=custom-go-mutesting.yaml

# Blacklist false positives
go run mutation-testing.go --blacklist=.mutation-blacklist
```

### Full Example
```bash
go run mutation-testing.go \
  --threshold=90.0 \
  --verbose \
  --concurrency=8 \
  --json=reports/mutation-$(date +%Y-%m-%d).json \
  --export-csv \
  --export-html \
  --baseline=.mutation-baseline.json
```

---

## Output Files

### JSON Report (`mutation-analysis-report.json`)
```json
{
  "timestamp": "2025-12-26T...",
  "overall_score": 0.9692,
  "total_mutations": 454,
  "total_passed": 440,
  "total_failed": 14,
  "files": [
    {
      "file": "dag.go",
      "score": 0.95,
      "passed": 95,
      "failed": 5,
      "mutations_by_type": {
        "arithmetic/base": 10,
        "branch/if": 15,
        "loop/condition": 5
      },
      "failed_mutations": [...],
      "duration": "2.5s",
      "has_tests": true
    }
  ],
  "hotspots": [
    {
      "file": "logging.go",
      "score": 0.925,
      "failed_count": 12,
      "priority": "high",
      "recommended_fix": "Add tests for 12 untested code paths"
    }
  ],
  "comparison_with_previous": {
    "previous_score": 0.95,
    "current_score": 0.9692,
    "change": 1.92,
    "trend": "improved"
  }
}
```

### CSV Report (`mutation-analysis-report.csv`)
```csv
File,Score %,Passed,Failed,Total,Has Tests,Duration (s)
dag.go,95.00,95,5,100,true,2.50
runner.go,98.54,135,2,137,true,3.20
logging.go,92.50,148,12,160,true,1.80
```

### HTML Report (`mutation-analysis-report.html`)
- Beautiful dashboard with charts
- Hotspot visualization
- Trend comparison
- Interactive tables
- Export-ready design

---

## Features

### 1. **Massive Concurrency**
- Automatically parallelizes testing across all files
- Configurable concurrency limits
- Resource-aware defaults

### 2. **Intelligent Filtering**
- Skip files without tests (`skip_without_test`)
- Skip build-tagged test files
- Exclude specific directories

### 3. **Baseline Tracking**
- Save baseline: `.mutation-baseline.json`
- Track scores over time
- Show trends (improved/declined/stable)
- Detect regressions

### 4. **Hotspot Identification**
- Rank files by test coverage weakness
- Categorize by priority (critical/high/medium)
- Suggest fixes for each hotspot

### 5. **Threshold Enforcement**
- Set minimum acceptable score
- Exit with error if threshold not met
- Perfect for CI/CD pipelines

### 6. **Mutation Statistics**
- Breakdown by mutator type:
  - arithmetic/base, arithmetic/bitwise
  - branch/if, branch/case, branch/else
  - loop/break, loop/condition, loop/range_break
  - conditional/negated
  - expression/comparison, expression/remove
  - statement/remove
  - numbers/incrementer, numbers/decrementer

### 7. **Incremental Mode**
- Only test files modified since last run
- Fast iteration during development
- Helpful for continuous improvement

### 8. **Multiple Export Formats**
- JSON - For programmatic analysis by AI
- CSV - For spreadsheets and dashboards
- HTML - For visual analysis and sharing

---

## Integration

### GitHub Actions
```yaml
- name: Mutation Testing
  run: |
    go run mutation-testing.go \
      --threshold=85.0 \
      --json=reports/mutations.json \
      --html=reports/mutations.html
  continue-on-error: true

- name: Comment on PR
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v6
  with:
    script: |
      const fs = require('fs');
      const report = JSON.parse(fs.readFileSync('reports/mutations.json'));
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        body: `🧬 Mutation Score: ${(report.overall_score*100).toFixed(2)}%`
      });
```

### GitLab CI
```yaml
mutation_testing:
  script:
    - go run mutation-testing.go --threshold=85.0 --json=report.json
  artifacts:
    reports:
      custom: report.json
```

---

## Workflow Examples

### 1. Local Development
```bash
# Quick check
go run analyze-mutations.go

# Detailed analysis before commit
go run mutation-testing.go --verbose --html

# Open in browser
open mutation-analysis-report.html
```

### 2. Testing Specific Changes
```bash
# Only test modified files
go run mutation-testing.go --incremental --verbose

# Compare with previous baseline
go run mutation-testing.go --baseline=.mutation-baseline.json
```

### 3. CI/CD Pipeline
```bash
# Enforce minimum quality
go run mutation-testing.go \
  --threshold=85.0 \
  --export-csv \
  --export-html

# Fail build if below threshold
# (script exits with code 1 if score < threshold)
```

### 4. Trend Tracking
```bash
# Daily run (cron job)
go run mutation-testing.go \
  --json=logs/mutations-$(date +%Y-%m-%d).json \
  --html=reports/latest.html \
  --baseline=.mutation-baseline.json
```

---

## Key Metrics

### Overall Score
- **Target**: > 95%
- **Good**: 85-95%
- **Action Required**: < 85%

### By File
- **Perfect** (100%): All mutations caught - excellent test coverage
- **Strong** (90-99%): Good coverage - minor gaps possible
- **Attention** (80-89%): Needs work - add targeted tests
- **Critical** (< 80%): High risk - cover untested code paths

---

## Mutation Types Explained

### Arithmetic
- **base**: `+`, `-`, `*`, `/`, `%`
- **bitwise**: `&`, `|`, `^`, `&^`, `<<`, `>>`
- **assignment**: `+=`, `-=`, `*=`, etc.

### Control Flow
- **branch/if**: Empty if/else blocks
- **branch/case**: Empty case bodies
- **branch/else**: Empty else blocks
- **loop/break**: `break` ↔ `continue`
- **loop/condition**: Loop exit condition mutations

### Comparison
- **conditional**: `>` ↔ `>=`, `<` ↔ `<=`, `==` ↔ `!=`
- **expression/comparison**: Off-by-one comparisons

### Logic
- **expression/remove**: `&&` and `||` term removal
- **statement/remove**: Remove assignments, increments

---

## Performance Tips

1. **Concurrency**: Default is 32 parallel tests
   - Reduce for CI environments: `--concurrency=4`
   - Increase on powerful machines: `--concurrency=64`

2. **Incremental**: Use `--incremental` during development
   - First full run: ~2-3 minutes
   - Incremental: ~30-60 seconds

3. **Caching**: Baseline saved automatically
   - Reuse for trend analysis
   - Helps identify regressions early

---

## Troubleshooting

### All Scores 0.00%
- Check that test files exist (`*_test.go`)
- Verify config file: `go-mutesting.yaml`
- Run with `--verbose` to see details

### Threshold Failures
- Increase test coverage for weak files
- Review hotspot recommendations
- Check `failed_mutations` examples

### Performance Issues
- Reduce concurrency: `--concurrency=2`
- Use incremental mode: `--incremental`
- Skip slow test files (put in blacklist)

---

## For AI-Driven Improvements

When sharing `mutation-analysis-report.json` with an AI, it can:

1. **Identify Weak Coverage**
   - Files with score < 90%
   - Specific mutations that weren't caught

2. **Generate Tests**
   - Review `failed_mutations` examples
   - Create tests that catch those mutations

3. **Prioritize**
   - Use `hotspots` array (sorted by priority)
   - Focus on critical files first

4. **Track Progress**
   - Compare with previous baseline
   - Verify improvements over time

---

## Configuration Files

### go-mutesting.yaml
```yaml
skip_without_test: true        # Skip files without _test.go
skip_with_build_tags: true     # Skip build-tagged tests
json_output: true              # Generate JSON report
html_output: true              # Generate HTML report
silent_mode: false             # Show output
exclude_dirs:                  # Exclude paths
  - vendor
  - tools
  - scripts
```

### .mutation-blacklist
```
# MD5 checksums of false-positive mutations
5b1ca0cfedd786d9df136a0e042df23a
0d99114c1ec877ee3773936374ae1a38
```

---

## References

- [go-mutesting GitHub](https://github.com/avito-tech/go-mutesting)
- [Mutation Testing Wikipedia](https://en.wikipedia.org/wiki/Mutation_testing)
- [PIT Framework](https://pitest.org/) - Java equivalent

---

**Last Updated**: 2025-12-26
**Infrastructure**: Production Ready
**Status**: 🟢 Active
