---
id: ops/general/moon-ci-pipeline
title: "Build & Test (Moon)"
category: ops
tags: ["build", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>core</category>
  <title>Build &amp; Test (Moon)</title>
  <description>Fast, cached build pipeline with intelligent task skipping.</description>
  <created_at>2026-01-02T19:55:26.822952</created_at>
  <updated_at>2026-01-02T19:55:26.822952</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Common Commands" level="2"/>
    <section name="What It Does" level="2"/>
    <section name="Speed Optimizations" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Binaries Built" level="2"/>
    <section name="Pre-commit Hook" level="2"/>
    <section name="Troubleshooting" level="2"/>
  </sections>
  <features>
    <feature>binaries_built</feature>
    <feature>common_commands</feature>
    <feature>configuration</feature>
    <feature>pre-commit_hook</feature>
    <feature>speed_optimizations</feature>
    <feature>troubleshooting</feature>
    <feature>what_it_does</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/general/architecture</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">ARCHITECTURE.md</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>build,operations</tags>
</doc_metadata>
-->

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
