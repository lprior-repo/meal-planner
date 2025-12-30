---
description: Run Moon CI pipeline with intelligent caching
---

Run the full CI pipeline using Moon's cached task execution.

Execute: `moon run :ci`

The pipeline runs (in dependency order):
1. `fmt` - Check Rust formatting
2. `clippy` - Run lints with warnings as errors
3. `test` - Run tests with cargo-nextest
4. `build` - Build release binaries
5. `copy-binaries` - Copy binaries to bin/
6. `validate-yaml` - Lint YAML files with yamllint
7. `validate-windmill` - Dry-run Windmill sync

Moon caches task outputs based on input hashes. Unchanged tasks are skipped.

Report:
1. Which tasks ran vs cached
2. Any failures with error details
3. Total execution time
