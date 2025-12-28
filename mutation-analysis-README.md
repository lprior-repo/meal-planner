# Mutation Testing Analysis for opencode-sdk-run

## What's Happening

The `analyze-mutations.go` script runs **massive concurrent mutation testing** on each Go file individually:

- **Massive Concurrency**: One goroutine per file running simultaneously
- **Per-File Analysis**: Each file is tested independently 
- **AI-Friendly Output**: Results saved to `mutation-analysis-report.json` for easy parsing

## The Report Structure

```json
{
  "timestamp": "2025-12-26T...",
  "overall_score": 0.75,
  "total_mutations": 1234,
  "total_passed": 925,
  "total_failed": 309,
  "files": [
    {
      "file": "dag.go",
      "score": 0.60,
      "passed": 60,
      "failed": 40,
      "total": 100,
      "failed_mutations": [
        "FAIL: mutation removed break statement",
        "FAIL: mutation changed comparison operator"
      ]
    }
  ]
}
```

## Using the Report

An AI can:
1. **Identify weak test coverage** - Files with lowest scores need better tests
2. **Generate targeted tests** - For each failed mutation, write a test that catches it
3. **Improve test suite quality** - Focus on mutations that aren't being killed
4. **Prioritize improvements** - Sort by score to fix worst files first

## Running the Analysis

```bash
go run analyze-mutations.go
```

Results are saved to: `mutation-analysis-report.json`

## Files Analyzed

- `dag.go` - DAG engine with topological sort
- `runner.go` - Task orchestration  
- `coordinator.go` - Task dependencies
- `verifiers.go` - Build/test verification
- `coverage.go` - Test coverage gates
- `events.go` - WebSocket/SSE streaming
- `git.go` - Git operations
- `beads.go` - Beads CLI integration
- `command_executor.go` - External command execution
- `logging.go` - Structured logging
- And more...

## Output Files

- `mutation-analysis-report.json` - Complete structured report (AI-parseable)
- `mutation-test-output.log` - Raw go-mutesting output (debugging)
