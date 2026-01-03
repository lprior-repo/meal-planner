---
id: ops/general/moon-ci-pipeline
title: "Build & Test (Moon)"
category: ops
tags: ["operations", "build"]
---

# Build & Test (Moon)

> **Context**: Fast, cached build pipeline with intelligent task skipping.

Fast, cached build pipeline with intelligent task skipping.

**For both humans and AI agents**: Links throughout help you navigate between related docs.

## Common Commands

```bash
moon run :ci        # Full validation (fmt, lint, test, build)
moon run :quick     # Fast lint only
moon run :test      # Run tests only
moon run :build     # Build release binaries
```

## What It Does

```
:ci Pipeline
├── fmt       - Rust format check
├── clippy    - Rust lints (-D warnings)
├── validate  - YAML validation
├── test      - cargo nextest (parallel)
├── build     - cargo build --release
└── copy      - Copy binaries to bin/
```

**Caching**: Moon skips unchanged tasks. First build is slow, subsequent builds are fast.

## Speed Optimizations

- **mold**: Fast linker
- **sccache**: Compiler cache
- **nextest**: Parallel test runner
- **incremental**: Build incremental changes fast

## Configuration

| File | Purpose |
|------|---------|
| `.moon/workspace.yml` | Workspace settings |
| `.moon/toolchain.yml` | Rust version |
| `moon.yml` | Task definitions |
| `.cargo/config.toml` | Cargo settings (mold, sccache) |

## Binaries Built

All binaries in `src/bin/` are automatically built:

```
fatsecret_oauth_start
fatsecret_oauth_complete
fatsecret_get_profile
tandoor_test_connection
... (and more)
```

Deployed to: `/usr/local/bin/meal-planner/`

## Pre-commit Hook

`.githooks/pre-commit` runs `moon run :quick` automatically before commits.

## Troubleshooting

**"sccache not found"**: Ensure mise is installed: `mise install`

**"moon not found"**: Check PATH includes `.moon/bin`

**Cache not working**: Check `moon.yml` has correct input paths. Run with `--log debug`.

See: [ARCHITECTURE.md](./ops-general-architecture.md) for how binaries work


## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md)
