# Windmill Scripts

See the root-level skill guides:
- `../CLAUDE_WINDMILL.md` - Windmill flows, CLI, Python SDK
- `../CLAUDE_RUST.md` - Rust script patterns for lambdas
- `../AGENTS.md` - Task tracking with bd (beads)

## Quick Reference

```bash
# Push scripts
wmill script push f/path/to/script.rs

# Run scripts
wmill script run f/path/to/script -d '{"arg": "value"}'

# Generate metadata
wmill script generate-metadata
```
