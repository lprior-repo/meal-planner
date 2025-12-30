---
description: Quick lint check (no tests, no build)
---

Run `moon run :quick` for fast lint checks.

This runs only:
- **fmt** - Rust formatting check
- **clippy** - Rust linter
- **validate-yaml** - YAML validation

Skips tests and build for speed. Use this for rapid feedback during development before committing.
