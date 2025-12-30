# Moon CI Pipeline

This document describes the local CI/CD pipeline using Moon for the meal-planner project.

## Overview

Moon is a task orchestrator with intelligent caching. It hashes task inputs and skips unchanged tasks, providing Nx/Turborepo-style caching for monorepos.

## Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `moon run :ci` | Full CI pipeline | Before merging, comprehensive validation |
| `moon run :quick` | Fast lint checks | During development, pre-commit |
| `moon run :deploy` | CI + Windmill push | Deploy to Windmill |
| `moon run :build` | Build release binaries | Create deployable binaries |
| `moon run :test` | Run tests with nextest | Test changes |

## Pipeline Tasks

```
moon run :ci
├── fmt          [parallel] - cargo fmt --check
├── clippy       [parallel] - cargo clippy -- -D warnings
├── validate-yaml [parallel] - yamllint windmill/
│
├── test         [sequential, after lint] - cargo nextest run
├── build        [sequential, after test] - cargo build --release
├── copy-binaries [after build] - copy to bin/
└── validate-windmill [after build] - wmill sync push --dry-run
```

## Speed Optimizations

### Build Tools (via mise)

| Tool | Purpose |
|------|---------|
| **mold** | Fast linker (replaces ld) |
| **sccache** | Compile cache across builds |
| **cargo-nextest** | Parallel test execution |

### Cargo Configuration

`.cargo/config.toml`:
```toml
[build]
rustc-wrapper = "sccache"
jobs = 32                          # Match CPU thread count

[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

### Cargo Profiles

`Cargo.toml`:
```toml
[profile.dev]
opt-level = 0
incremental = true
debug = 0                          # Skip DWARF for faster link

[profile.dev.package."*"]
opt-level = 2                      # Optimize dependencies

[profile.test]
opt-level = 0
debug = 0
incremental = true
```

## Moon Caching

Moon caches task outputs based on input file hashes:

```yaml
# moon.yml
tasks:
  build:
    command: 'cargo build --release'
    inputs:
      - 'src/**/*.rs'
      - 'Cargo.toml'
      - 'Cargo.lock'
    outputs:
      - 'target/release/fatsecret_*'
      - 'target/release/tandoor_*'
```

**Cache behavior:**
- First run: Executes task, caches outputs
- Subsequent runs: If inputs unchanged, skips task (shows "cached")
- Changed inputs: Re-executes task

## Configuration Files

| File | Purpose |
|------|---------|
| `.moon/workspace.yml` | Workspace configuration |
| `.moon/toolchain.yml` | Rust toolchain version |
| `moon.yml` | Task definitions |

## OpenCode Integration

Slash commands available:
- `/ci` - Run full CI pipeline
- `/quick` - Fast lint checks
- `/deploy` - CI + Windmill deploy

## Pre-commit Hook

`.githooks/pre-commit` runs `moon run :quick` for fast feedback before commits.

## Binaries

The pipeline builds these binaries to `bin/`:

| Binary | Purpose |
|--------|---------|
| `fatsecret_oauth_start` | Start OAuth flow |
| `fatsecret_oauth_complete` | Complete OAuth with verifier |
| `fatsecret_oauth_callback` | HTTP callback server for OAuth |
| `fatsecret_get_token` | Get stored access token |
| `fatsecret_get_profile` | Get user profile |
| `tandoor_test_connection` | Test Tandoor API connection |

### Binary Input Format

Binaries accept both Windmill and standalone formats:

**Windmill format** (resource passed as JSON):
```json
{
  "fatsecret": {"consumer_key": "...", "consumer_secret": "..."},
  "callback_url": "oob"
}
```

**Standalone format** (uses environment variables):
```json
{"callback_url": "http://localhost:8765/callback"}
```

## Typical Workflow

```bash
# During development - fast checks
moon run :quick

# Before commit - full validation
moon run :ci

# Deploy to Windmill
moon run :deploy

# Just run tests
moon run :test

# Build binaries only
moon run :build
```

## Troubleshooting

### "sccache not found"
Ensure mise shims are in PATH:
```bash
export PATH="/home/lewis/.local/share/mise/shims:$PATH"
```

### "moon not found"
Ensure moon bin is in PATH:
```bash
export PATH="/home/lewis/.moon/bin:$PATH"
```

### Cache not working
Check inputs are correctly specified in `moon.yml`. Run with `--log debug` for details.

### Wrong Rust version
Moon uses the system Rust. Ensure mise provides the correct version:
```bash
mise install
rustc --version  # Should show 1.92.0
```
