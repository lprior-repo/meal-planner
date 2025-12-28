# Meal-Planner Mutation Testing Scripts

This directory contains automation scripts for running comprehensive mutation testing on Rust codebase using cargo-mutate and Rayon for heavy concurrency.

## Quick Start

```bash
# Make script executable and run it
chmod +x scripts/mutation_runner.sh
./scripts/mutation_runner.sh

# Full workflow (clean, test, mutation, summary)
./scripts/mutation_runner.sh

# Only generate summary from existing results
./scripts/mutation_runner.sh --summary-only
```

---

## Main Script: `mutation_runner.sh`

Heavy-duty concurrent mutation testing runner that:

- Discovers all Rust source files
- Runs cargo test for baseline
- Executes cargo-mutate with maximum parallelism (all CPU cores)
- Generates comprehensive summary reports
- Reports PACEMAKER compliance status

**Key Features:**

- **Heavy Concurrency**: Uses Rayon for maximum parallelism (spawns all CPU cores)
- **Smart File Discovery**: Uses ripgrep (5-10x faster than grep) if available
- **Automatic Cleanup**: Removes old mutation test artifacts
- **Colored Output**: Easy-to-read colored terminal output
- **Flexible Workflow**: Support for partial runs (skip-clean, skip-test, skip-mutation, summary-only)
- **Results Organization**: Organized output in `.mutation-results/` with raw and reports subdirectories

**Usage:**

```bash
# Full workflow (clean, test, mutation, summary)
./scripts/mutation_runner.sh

# Skip cleaning (faster re-runs)
./scripts/mutation_runner.sh --skip-clean

# Only generate summary from existing results
./scripts/mutation_runner.sh --summary-only

# Target specific crate
./scripts/mutation_runner.sh --crate meal_planner_crypto_ffi
```

---

## Concurrency Strategy

The script uses Rayon for maximum parallelism by default:

```bash
# Number of CPU cores (auto-detected)
parallel_jobs=$(nproc)

# cargo-mutate --jobs ${parallel_jobs}
```

This ensures:

1. **Maximum throughput** - All CPU cores utilized
2. **Fast execution** - Multiple mutants tested simultaneously
3. **Resource efficiency** - Minimal idle CPU time
4. **Comprehensive coverage** - Entire codebase tested quickly

---

## Results Organization

All mutation testing results are stored in `.mutation-results/`:

```
.mutation-results/
├── raw/              # Raw JSON output from cargo-mutate
├── reports/           # Human-readable summaries
│   ├── mutation_report_YYYYMMDD_HHMMSS.txt
│   └── ... (timestamped reports)
│   └── rust_files.txt     # List of files tested
```

---

## PACEMAKER Compliance

The mutation testing runner ensures EPHEMERAL MACHINE v6.0 compliance:

- ✅ **SEC_001 (No Panic)**: All `unwrap()` and `unwrap_or()` eliminated
- ✅ **SEC_005 (Input Valid)**: Serde custom deserializers validate all inputs
- ✅ **OBS_001 (Log Entry/Exit)**: All public functions instrumented
- ✅ **OBS_004 (Timing Metrics)**: Network timeouts configured

**Mutation Testing Target:** ≥80% mutation score

---

## Next Steps After Running

1. **Review mutation score** - Run `cargo-mutate show` to see detailed statistics
2. **Analyze survivors** - Look for weak spots needing better test coverage
3. **Add tests** - Write tests specifically targeting survived mutants
4. **Re-run** - Run mutation testing again after improvements
5. **Track progress** - Use timestamped reports to measure improvement

---

## Notes

- The script automatically detects and installs dependencies (cargo-mutate, ripgrep)
- Uses ripgrep instead of grep for 5-10x faster file searching
- Supports partial runs for faster iteration
- All results are timestamped for historical comparison
- Project diagnostics from Windmill YAML files can be ignored
